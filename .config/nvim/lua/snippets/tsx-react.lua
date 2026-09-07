-- React/Next.js snippets, .tsx only. Ported from .config/zed/snippets/tsx.json
-- (the entries not shared with typescript.json -- those live in ts-shared.lua).
local function pascal_case(name)
    return (name:gsub("[-_](%a)", function(c) return c:upper() end):gsub("^%a", string.upper))
end

return {
    {
        prefix = "page",
        body = {
            'export default function Page(props: PageProps<"$1">) {',
            "\treturn (",
            "\t\t$2",
            "\t)",
            "}",
            "",
        },
        desc = "Next.js page",
    },
    {
        prefix = "layout",
        body = {
            'export default function Layout(props: LayoutProps<"$1">) {',
            "\treturn (",
            "\t\t$2",
            "\t)",
            "}",
            "",
        },
        desc = "Next.js layout",
    },
    {
        prefix = "debug",
        body = {
            "useEffect(() => {",
            "\tfunction onKey(event: KeyboardEvent) {",
            "\t\tswitch (event.key) {",
            '\t\t\tcase "t":',
            "\t\t\t\treturn ${1}",
            "\t\t}",
            "\t}",
            "",
            '\twindow.addEventListener("keypress", onKey)',
            '\treturn () => window.removeEventListener("keypress", onKey)',
            "}, [])",
        },
        desc = "Debug hook",
    },
    -- `rc`'s Zed body used a VS Code `${TM_FILENAME_BASE/.../pascalcase}`
    -- variable transform; mini.snippets doesn't support those (see
    -- MiniSnippets-syntax-specification), so this computes the name in Lua
    -- and bakes it into the body instead -- same result, different mechanism.
    function(_)
        local component_name = pascal_case(vim.fn.expand("%:t:r"))
        return {
            {
                prefix = "rc",
                body = {
                    "export default function " .. component_name .. "() {",
                    "\treturn (",
                    "\t\t$1",
                    "\t)",
                    "}",
                    "",
                },
                desc = "React Component",
            },
        }
    end,
}
