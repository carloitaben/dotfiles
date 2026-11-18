// opencode port of ~/.dotfiles/.claude/hooks/skill-toil.sh.
// Nudges toil reporting when a skill run piles up bash calls.
//   start: a `skill` tool call begins a run, unless one is already active in that
//          session, so a skill loading another skill does not reset its caller.
//   count: each bash call in a run counts; at THRESHOLD, one nudge per run is
//          appended to that bash result.
// A subagent is its own session, so it counts separately and gets its own nudge
// once it loads a skill itself. State is in memory, per opencode process.
import type { Plugin } from "@opencode-ai/plugin"

const THRESHOLD = 10

type Run = { skill: string; count: number; nudged: boolean }

export const SkillToil: Plugin = async () => {
  const runs = new Map<string, Run>()

  return {
    "tool.execute.after": async (input, output) => {
      if (input.tool === "skill") {
        if (runs.has(input.sessionID)) return
        runs.set(input.sessionID, { skill: String(input.args?.name ?? "skill"), count: 0, nudged: false })
        return
      }

      if (input.tool !== "bash") return
      const run = runs.get(input.sessionID)
      if (!run) return
      run.count += 1
      if (run.count < THRESHOLD || run.nudged) return
      run.nudged = true
      output.output += `\n\nSkill toil check: /${run.skill} has used ${run.count} bash calls in this session. If some were mechanical steps a script could do, apply the Skill toil rule from the global instructions.`
    },
  }
}
