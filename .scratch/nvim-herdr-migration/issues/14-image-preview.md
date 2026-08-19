# Research: image preview via ghostty graphics protocol

Type: research
Status: resolved

## Question

Survey nvim options to render images (png/jpg/svg) inline in a buffer, using
Ghostty's kitty graphics protocol. Zed opens an image and shows it in place
of the code editor; the user wants the same. Candidates: image.nvim
(3rd/image.nvim) and any newer alternatives; confirm Ghostty
graphics-protocol support and whether a plugin renders inline without a
separate floating window. Report maintenance status and a concrete pick.

## Answer

Full findings: `.scratch/nvim-herdr-migration/research/image-preview.md`.

Ghostty implements the kitty graphics protocol and its unicode-placeholder
virtual-placement feature. The protocol is raster-only (RGB/RGBA/PNG), so SVG
is never native — every plugin rasterizes SVG→PNG via ImageMagick.

**Pick: `3rd/image.nvim`** — `backend="kitty"`, `processor="magick_cli"`
(`brew install imagemagick`), `hijack_file_patterns` (add `"*.svg"`) for
Zed-style open-in-place (clears the buffer, renders the image over it,
`filetype=image_nvim`). Default `kitty_method="normal"` uses absolute cursor
positioning, confirmed working in Ghostty. snacks.image works too but is
heavier (rejected per mini-first).
