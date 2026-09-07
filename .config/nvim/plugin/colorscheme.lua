vim.pack.add({
    { src = "https://github.com/jwbaldwin/oscura.nvim" },
    { src = "https://github.com/nexxeln/vesper.nvim" },
})

local function blend(fg, bg, alpha)
    local function hex_to_rgb(hex)
        return {
            tonumber(hex:sub(2, 3), 16),
            tonumber(hex:sub(4, 5), 16),
            tonumber(hex:sub(6, 7), 16),
        }
    end

    local function rgb_to_hex(rgb)
        return string.format("#%02x%02x%02x", rgb[1], rgb[2], rgb[3])
    end

    local fg_rgb = hex_to_rgb(fg)
    local bg_rgb = hex_to_rgb(bg)
    local blended = {}

    for i = 1, 3 do
        blended[i] = math.floor((alpha * fg_rgb[i]) + ((1 - alpha) * bg_rgb[i]) + 0.5)
    end

    return rgb_to_hex(blended)
end

local function set_diagnostic_line_highlights()
    local colors = require("vesper.palette").colors
    vim.api.nvim_set_hl(0, "DiagnosticLineError", { bg = blend(colors.error, colors.bg, 0.10) })
    vim.api.nvim_set_hl(0, "DiagnosticLineWarn", { bg = blend(colors.warning, colors.bg, 0.10) })
    vim.api.nvim_set_hl(0, "DiagnosticLineInfo", { bg = blend(colors.info, colors.bg, 0.10) })
    vim.api.nvim_set_hl(0, "DiagnosticLineHint", { bg = blend(colors.hint, colors.bg, 0.10) })
end

-- vesper's own Diff* groups set an explicit fg, which stomps syntax
-- highlighting in diff mode. Drop the fg and use a translucent bg wash
-- instead, so text keeps its normal syntax colors (like Zed's diff view).
local function set_diff_highlights()
    local colors = require("vesper.palette").colors
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = blend(colors.added, colors.bg, 0.15) })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = blend(colors.deleted, colors.bg, 0.15) })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = blend(colors.changed, colors.bg, 0.15) })
    vim.api.nvim_set_hl(0, "DiffText", { bg = blend(colors.changed, colors.bg, 0.30) })
end

vim.cmd("colorscheme vesper")

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "vesper",
    callback = function()
        set_diagnostic_line_highlights()
        set_diff_highlights()
    end,
})

set_diagnostic_line_highlights()
set_diff_highlights()
