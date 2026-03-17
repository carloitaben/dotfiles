import { mkdir } from "node:fs/promises";
import path from "node:path";

type CommandSpec = {
  skillName: string;
  requestText: string;
  description?: string;
  commandName?: string;
  agent?: string;
  subtask?: true;
};

type ResolvedCommandSpec = {
  skillName: string;
  description: string;
  requestText: string;
  commandName?: string;
  agent?: string;
  subtask?: true;
};

type WriteStatus = "created" | "updated" | "unchanged";

const commandSpecs: readonly CommandSpec[] = [
  {
    skillName: "grill-me",
    requestText:
      "Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree.",
  },
  {
    skillName: "design-an-interface",
    requestText:
      "Generate multiple radically different interface designs for a module using parallel sub-agents.",
  },
  {
    skillName: "edit-article",
    requestText:
      "Edit and improve articles by restructuring sections, improving clarity, and tightening prose.",
  },
];

const scriptDir = import.meta.dir;
const rootDir = path.resolve(scriptDir, "..");
const commandDir = path.join(rootDir, "command");
const skillsDir = path.join(rootDir, "skills");

function ensureSlug(value: string, label: string): string {
  if (!/^[a-z0-9-]+$/.test(value)) {
    throw new Error(`${label} must be kebab-case: ${value}`);
  }

  return value;
}

function ensureSingleLine(value: string, label: string): string {
  if (value.includes("\n")) {
    throw new Error(`${label} must be a single line`);
  }

  const trimmedValue = value.trim();

  if (trimmedValue.length === 0) {
    throw new Error(`${label} must not be empty`);
  }

  return trimmedValue;
}

function stripWrappingQuotes(value: string): string {
  if (value.length < 2) {
    return value;
  }

  const firstCharacter = value[0];
  const lastCharacter = value[value.length - 1];

  if (
    (firstCharacter === '"' && lastCharacter === '"') ||
    (firstCharacter === "'" && lastCharacter === "'")
  ) {
    return value.slice(1, -1);
  }

  return value;
}

function extractDescriptionFromSkill(
  skillContent: string,
  skillName: string,
): string {
  const lines = skillContent.split("\n");

  if (lines[0] !== "---") {
    throw new Error(`skill is missing frontmatter: ${skillName}`);
  }

  for (const line of lines.slice(1)) {
    if (line === "---") {
      break;
    }

    if (!line.startsWith("description:")) {
      continue;
    }

    const description = stripWrappingQuotes(
      line.slice("description:".length).trim(),
    );

    return ensureSingleLine(description, `description for ${skillName}`);
  }

  throw new Error(`skill description not found: ${skillName}`);
}

async function readSkillDescription(skillName: string): Promise<string> {
  const skillFilePath = path.join(skillsDir, skillName, "SKILL.md");
  const skillFile = Bun.file(skillFilePath);

  if (!(await skillFile.exists())) {
    throw new Error(`skill file not found: ${skillFilePath}`);
  }

  return extractDescriptionFromSkill(await skillFile.text(), skillName);
}

async function resolveCommandSpec(
  spec: CommandSpec,
): Promise<ResolvedCommandSpec> {
  const skillName = ensureSlug(spec.skillName, "skillName");
  const requestText = ensureSingleLine(spec.requestText, "requestText");
  const description = ensureSingleLine(
    spec.description ?? (await readSkillDescription(skillName)),
    "description",
  );

  return {
    ...spec,
    skillName,
    requestText,
    description,
  };
}

function renderFrontmatter(spec: ResolvedCommandSpec): string[] {
  const lines = ["---", `description: ${JSON.stringify(spec.description)}`];

  if (spec.agent !== undefined) {
    lines.push(`agent: ${ensureSlug(spec.agent, "agent")}`);
  }

  if (spec.subtask === true) {
    lines.push("subtask: true");
  }

  lines.push("---");

  return lines;
}

function renderCommand(spec: ResolvedCommandSpec): string {
  return [
    ...renderFrontmatter(spec),
    "",
    spec.requestText,
    "",
    "```js",
    `skill({ name: '${spec.skillName}' })`,
    "```",
    "",
    "<user-request>",
    "$ARGUMENTS",
    "</user-request>",
    "",
  ].join("\n");
}

async function readExistingContent(filePath: string): Promise<string | null> {
  const file = Bun.file(filePath);

  if (!(await file.exists())) {
    return null;
  }

  return file.text();
}

async function writeCommandFile(spec: CommandSpec): Promise<WriteStatus> {
  const resolvedSpec = await resolveCommandSpec(spec);
  const commandName = ensureSlug(
    resolvedSpec.commandName ?? resolvedSpec.skillName,
    "commandName",
  );
  const filePath = path.join(commandDir, `${commandName}.md`);
  const nextContent = renderCommand(resolvedSpec);
  const existingContent = await readExistingContent(filePath);

  if (existingContent === nextContent) {
    return "unchanged";
  }

  await Bun.write(filePath, nextContent);

  if (existingContent === null) {
    return "created";
  }

  return "updated";
}

async function main(): Promise<void> {
  await mkdir(commandDir, { recursive: true });

  const seenCommandNames = new Set<string>();

  for (const spec of commandSpecs) {
    const commandName = ensureSlug(
      spec.commandName ?? spec.skillName,
      "commandName",
    );

    if (seenCommandNames.has(commandName)) {
      throw new Error(`duplicate commandName: ${commandName}`);
    }

    seenCommandNames.add(commandName);
  }

  if (commandSpecs.length === 0) {
    console.log("No command specs configured.");
    return;
  }

  for (const spec of commandSpecs) {
    const commandName = ensureSlug(
      spec.commandName ?? spec.skillName,
      "commandName",
    );
    const status = await writeCommandFile(spec);
    console.log(`${status}: command/${commandName}.md`);
  }
}

await main();
