local function system(cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd, text = true }):wait()
    if result.code ~= 0 then
        return nil
    end
    return vim.trim(result.stdout)
end

local function github_http_url(remote)
    local https_repo = remote:match("^https://github%.com/(.+)%.git$") or remote:match("^https://github%.com/(.+)$")
    if https_repo then
        return "https://github.com/" .. https_repo
    end

    local ssh_repo = remote:match("^git@github%.com:(.+)%.git$") or remote:match("^git@github%.com:(.+)$")
    if ssh_repo then
        return "https://github.com/" .. ssh_repo
    end

    return nil
end

local function permalink(opts)
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
        vim.notify("No file in current buffer", vim.log.levels.ERROR)
        return nil
    end

    local dir = vim.fs.dirname(file)
    local root = system({ "git", "rev-parse", "--show-toplevel" }, dir)
    if not root then
        vim.notify("Current file is not in a git repo", vim.log.levels.ERROR)
        return nil
    end

    local remote = system({ "git", "remote", "get-url", "origin" }, root)
    if not remote then
        vim.notify("Git remote 'origin' not found", vim.log.levels.ERROR)
        return nil
    end

    local repo = github_http_url(remote)
    if not repo then
        vim.notify("Only GitHub remotes are supported", vim.log.levels.ERROR)
        return nil
    end

    local rev = system({ "git", "rev-parse", "HEAD" }, root)
    if not rev then
        vim.notify("Could not resolve HEAD revision", vim.log.levels.ERROR)
        return nil
    end

    local relative = vim.fs.relpath(root, file)
    if not relative then
        vim.notify("Could not compute repo-relative path", vim.log.levels.ERROR)
        return nil
    end

    local first = opts.line1
    local last = opts.line2

    if opts.range == 0 then
        first = vim.api.nvim_win_get_cursor(0)[1]
        last = first
    end

    local fragment = first == last and ("#L" .. first) or ("#L" .. first .. "-L" .. last)

    return string.format("%s/blob/%s/%s%s", repo, rev, relative, fragment)
end

vim.api.nvim_create_user_command("CopyPermalink", function(opts)
    local url = permalink(opts)
    if not url then
        return
    end

    vim.fn.setreg("+", url)
    vim.fn.setreg('"', url)
end, { range = true })

vim.api.nvim_create_user_command("OpenPermalink", function(opts)
    local url = permalink(opts)
    if not url then
        return
    end

    vim.ui.open(url)
end, { range = true })
