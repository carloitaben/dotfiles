vim.pack.add({
    { src = "https://github.com/jake-stewart/multicursor.nvim" },
})

local multicursor = require("multicursor-nvim")

multicursor.setup()

multicursor.addKeymapLayer(function(layerSet)
    -- Select a different cursor as the main one.
    -- layerSet({"n", "x"}, "<left>", mc.prevCursor)
    -- layerSet({"n", "x"}, "<right>", mc.nextCursor)

    -- Delete the main cursor.
    -- layerSet({"n", "x"}, "<leader>x", mc.deleteCursor)

    -- Enable and clear cursors using escape.
    layerSet({ "n", "x" }, "<esc>", function()
        if not multicursor.cursorsEnabled() then
            multicursor.enableCursors()
        else
            multicursor.clearCursors()
        end
    end)
end)

-- ⌘+shift-l to add a cursor for all matches of cursor word/selection in the document
vim.keymap.set({ "n", "x" }, "<D-S-l>", multicursor.matchAllAddCursors)

-- ⌘+d to add a cursor
vim.keymap.set({ "n", "x" }, "<D-d>", function() multicursor.matchAddCursor(1) end)

-- Add or skip adding a new cursor by matching word/selection
-- vim.keymap.set({ "n", "x" }, "<leader>n", function() multicursor.matchAddCursor(1) end)
-- vim.keymap.set({ "n", "x" }, "<leader>N", function() multicursor.matchAddCursor(-1) end)
--
-- -- Add and remove cursors with control + left click.
-- vim.keymap.set("n", "<c-leftmouse>", multicursor.handleMouse)
-- vim.keymap.set("n", "<c-leftdrag>", multicursor.handleMouseDrag)
-- vim.keymap.set("n", "<c-leftrelease>", multicursor.handleMouseRelease)
