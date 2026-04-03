vim.pack.add({
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter",
        version = "main",
    },
})

local languages = {
    "astro",
    "c",
    "comment",
    "css",
    "csv",
    "diff",
    "dockerfile",
    "fish",
    "git_config",
    "gitcommit",
    "gitignore",
    "go",
    "graphql",
    "html",
    "javascript",
    "jq",
    "jsdoc",
    "json",
    "lua",
    "luadoc",
    "markdown",
    "markdown_inline",
    "query",
    "regex",
    "scss",
    "sql",
    "tsx",
    "typescript",
    "yaml",
}

-- enable treesitter highlighting, folding and indents
vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        local filetype = args.match
        local lang = vim.treesitter.language.get_lang(filetype)
        if vim.treesitter.language.add(lang) then
            vim.wo.foldmethod = "expr"
            vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            vim.treesitter.start()
        end
    end,
})

-- Rebuild parsers after the treesitter plugin itself updates.
vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
        local name, kind = ev.data.spec.name, ev.data.kind
        if name == "nvim-treesitter" and kind == "update" then
            if not ev.data.active then
                vim.cmd.packadd("nvim-treesitter")
            end
            vim.cmd("TSUpdate")
        end
    end,
})

local ts = require("nvim-treesitter")

ts.install(languages)
ts.update("all")
