# Task: install image.nvim + ImageMagick

Type: task
Status: open

## Question

Per research 14, install `3rd/image.nvim` via `vim.pack.add` with
`backend="kitty"`, `processor="magick_cli"`, `hijack_file_patterns` (add
`"*.svg"`), and `brew install imagemagick`. Validate inline image rendering in
Ghostty — both a png and an svg (rasterized to png) rendering in place of the
buffer, Zed-style.
