-- nvim's built-in treesitter highlighter always parses asynchronously, and only
-- gives itself a ~3ms slice of work per redraw. Almost any real file's first,
-- full parse blows past that in one slice, so that first frame draws with zero
-- highlights, a later pass picks up where it left off, and only once it
-- finishes does it force a repaint. That gap causes a flash of uncolorized
-- text, both on a normal file open and in a picker preview.
--
-- Other editors avoid this by paying a small, bounded, blocking parse cost as
-- part of the open action itself (before the buffer is ever rendered) instead
-- of inside the render loop, and only fall back to fully async parsing if that
-- budget runs out. That's the shape we're copying here: try synchronously, for
-- a bounded amount of time, before the first paint; give up and hand off to the
-- normal async engine if it's taking too long.
--
-- First attempt at mirroring this: kick off the real parse and just wait on it
-- ourselves for a bit, hoping to give it a bounded window to finish before the
-- first paint. Measured this against a synthetic 50k-line buffer (a fresh full
-- parse takes ~354ms) and it does NOT work: the wait doesn't reliably stop once
-- its budget elapses, because what it's waiting on keeps re-queueing its own
-- next step faster than the wait can check back in. A 5ms budget ended up
-- taking ~500ms in testing -- it silently degraded into "block until actually
-- done," exactly the failure mode we're trying to avoid. So: don't drive it
-- that way.
--
-- What actually works: step the parse forward ourselves, in our own plain loop,
-- checking a real clock deadline between every step, instead of relying on
-- nvim's own scheduling to check the clock for us. Doing this means reaching
-- past the normal public entry point into an internal, undocumented one -- the
-- same underlying step nvim's own engine uses, just driven by our own loop
-- instead of its scheduler. Verified this empirically: bounding to a 50ms
-- deadline against that same 50k-line buffer actually took ~51ms (not ~354ms
-- and not ~500ms), and giving up partway through leaves no half-finished state
-- behind for anything else to trip over -- nvim's normal async engine picks it
-- up fresh from its own point of view. The underlying parser quietly keeps its
-- own progress across separate attempts, though, so that work isn't wasted
-- either way: a subsequent full parse in testing took ~292ms instead of a fresh
-- ~354ms. Net effect: pay for up to `timeout_ms` synchronously before the first
-- paint; if the parse is done by then, that paint has full highlights. If not,
-- we stop blocking and hand off to nvim's normal async engine exactly as if
-- we'd never touched it, except it's already partway done.

local M = {}

local STEP_TIMEOUT_NS = 3 * 1000 * 1000 -- match languagetree.lua's own default_parse_timeout_ns
local DEFAULT_TIMEOUT_MS = 30

function M.sync_highlight(bufnr, opts)
    opts = opts or {}
    local timeout_ms = opts.timeout_ms or DEFAULT_TIMEOUT_MS

    local parser = vim.treesitter.get_parser(bufnr)
    if not parser then
        return
    end

    pcall(function()
        local deadline = vim.uv.hrtime() + timeout_ms * 1e6
        local step = coroutine.wrap(parser._parse)
        local thread_state = {}
        while true do
            thread_state.timeout = STEP_TIMEOUT_NS
            local _, finished = step(parser, true, thread_state)
            if finished or vim.uv.hrtime() >= deadline then
                return
            end
        end
    end)
end

return M
