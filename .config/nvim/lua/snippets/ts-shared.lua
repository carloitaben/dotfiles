-- Single source of truth for snippets shared between .ts and .tsx (see
-- plugin/mini.lua, which wires this into both `typescript` and
-- `typescriptreact` languages). Ported from .config/zed/snippets/typescript.json
-- (the subset also present in tsx.json). Static per-filetype snippet files
-- (VS Code, Zed) force duplicating these; one Lua file used by both langs
-- doesn't. React-only snippets live in snippets/tsx-react.lua instead.
return {
    { prefix = "wait", body = "await new Promise((resolve) => setTimeout(resolve, $1))", desc = "Wait" },
    { prefix = "dir", body = "console.dir($1, { depth: null })", desc = "Console Dir" },
    { prefix = "efn", body = { "Effect.fn(function* () {", "\t$0", "})" }, desc = "Effect Function" },
    {
        prefix = "efnu",
        body = { "Effect.fnUntraced(function* () {", "\t$0", "})" },
        desc = "Effect Function (untraced)",
    },
    { prefix = "egen", body = { "Effect.gen(function* () {", "\t$0", "})" }, desc = "Effect Gen Function" },
    { prefix = "gen", body = { "function* () {", "\t$0", "}" }, desc = "Gen Function" },
    {
        prefix = "etaggederror",
        body = 'export class ${1} extends Data.TaggedError("${1}")<{ readonly cause: unknown }> {}',
        desc = "Effect Tagged Error",
    },
    {
        prefix = "etaggederrorreason",
        body = {
            'export class ${1} extends Data.TaggedError("${1}")<{ readonly cause: unknown }> {}',
            "",
            'export class ${2} extends Data.TaggedError("${2}")<{ readonly cause: unknown }> {}',
            "",
            "export type ${3}ErrorReason =",
            "\t| ${1}",
            "\t| ${2}",
            "",
            "export class ${3} extends Data.TaggedError(\"${3}\")<{ readonly reason: ${3}ErrorReason }> {}",
        },
        desc = "Effect Tagged Error (reason)",
    },
    {
        prefix = "econtextservicefn",
        body = {
            "interface ${1:Database} {",
            "\treadonly ${2:query}: (${3:sql}: string) => ${4:string}",
            "}",
            "",
            'const ${1} = Context.Service<${1}>("${1}")$0',
        },
        desc = "Effect Context Service (fn)",
    },
    {
        prefix = "econtextservice",
        body = {
            "class ${1} extends Context.Service<${1}, {",
            "\treadonly ${2:query}: (${3:sql}: string) => ${4:string}",
            '}>()("${1}") {}$0',
        },
        desc = "Effect Context Service (class)",
    },
    {
        prefix = "econtextservicemake",
        body = {
            'class ${1} extends Context.Service<${1}>()("${1}", {',
            "\tmake: Effect.gen(function* () {",
            "\t\t${2}",
            "\t})",
            "}) {",
            "\tstatic readonly layer = Layer.effect(this, this.make).pipe(",
            "\t\tLayer.provide(${3}.layer)",
            "\t)",
            "}$0",
        },
        desc = "Effect Context Service (class + make)",
    },
    {
        prefix = "econtextreference",
        body = {
            'const ${1} = Context.Reference<${2}>("${1}", {',
            "\tdefaultValue: () => ${3}",
            "})$0",
        },
        desc = "Effect Context Reference",
    },
}
