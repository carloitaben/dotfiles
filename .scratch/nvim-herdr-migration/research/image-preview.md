# Inline Image Rendering in Neovim (Ghostty, macOS)

Goal: render images (png/jpg/svg) **inline in the buffer** — Zed-style, where opening
an image file replaces the editor with the image — via Ghostty's **Kitty graphics
protocol**. No separate floating window. Terminal: Ghostty on macOS.

## Key architectural facts

1. **Ghostty implements the Kitty graphics protocol.** Official Ghostty docs list
   "Kitty graphics protocol" under features; kitty's own spec lists Ghostty as an
   implementing terminal. Sources:
   https://ghostty.org/docs/features ; https://ghostty.org/docs/about ;
   https://sw.kovidgoyal.net/kitty/graphics-protocol/ ("Other terminals that have
   implemented the graphics protocol" → Ghostty).

2. **Ghostty also supports the unicode-placeholder / virtual-placement feature**
   (`U+10EEEE`). `src/terminal/kitty/graphics_unicode.zig` fully implements it
   (placeholder codepoint, diacritic decoding, aspect-ratio-preserving placement
   rendering, with unit tests). The `graphics.zig` header comment still lists
   "virtual placement w/ unicode" as TODO, but that comment is **stale** — the
   feature is implemented. Sources:
   https://github.com/ghostty-org/ghostty/blob/main/src/terminal/kitty/graphics_unicode.zig ;
   https://deepwiki.com/ghostty-org/ghostty/5.4-image-rendering ("Virtual Unicode
   Placements … Ghostty supports Kitty's virtual placement feature").

3. **The kitty protocol only transmits raster data** — 24-bit RGB, 32-bit RGBA, or
   PNG (`f=32/24/100`). There is **no native SVG** in the protocol. Every plugin
   below rasterizes SVG (and any other non-PNG source) to PNG using **ImageMagick**
   before transmitting. So "SVG support" == "ImageMagick can rasterize SVG", not a
   terminal-level feature. Source: https://sw.kovidgoyal.net/kitty/graphics-protocol/
   ("Transferring pixel data" — formats `f=32`, `f=24`, `f=100`).

4. Ghostty's kitty-graphics implementation is described in its own source as
   "not great" on performance (v1 implementation), and earlier releases had
   temporary-file-transfer naming bugs (fixed in 1.1.0) and alpha-blending bugs
   (fixed in 1.1.0). Sources:
   https://github.com/ghostty-org/ghostty/blob/main/src/terminal/kitty/graphics.zig
   ("Performance" note); https://github.com/ghostty-org/website/blob/main/docs/install/release-notes/1-1-0.mdx
   (fixes #5189 alpha blending, #4451 temp-file naming).

---

## 1. 3rd/image.nvim — the purpose-built pick

Adds image support to Neovim using the kitty graphics protocol (or ueberzugpp /
sixel). Recommended `kitty` backend (>= kitty 28.0). Source: https://github.com/3rd/image.nvim

- **Inline in buffer: yes.** Markdown/asciidoc/neorg/rst/typst integrations render
  images inline in the buffer, reserving vertical space with extmarks ("virtual
  padding"), so text flows around the image. Default integrations enabled:
  `markdown`, `asciidoc`, `typst`, `neorg`, `syslang`. Source: README `default_options`
  in https://raw.githubusercontent.com/3rd/image.nvim/master/lua/image/init.lua
- **Open image in place (Zed-style): yes.** `hijack_file_patterns` defaults to
  `{"*.png","*.jpg","*.jpeg","*.gif","*.webp","*.avif"}`; `hijack_buffer()` sets
  `buftype=nowrite`, `filetype=image_nvim`, clears the buffer and renders the image
  over it — the image *replaces* the code editor, matching the Zed behavior.
  Source: `hijack_buffer` in the same file.
- **Kitty rendering method:** `kitty_method = "normal"` (default) uses absolute
  cursor positioning + `z-index=-1` (image under text) — this does **not** depend on
  unicode placeholders and works in any kitty-protocol terminal including Ghostty
  and WezTerm. `kitty_method = "unicode-placeholders"` is an alternative that uses
  `U+10EEEE` virtual placements (also supported by Ghostty now). Source:
  `default_options.kitty_method` (init.lua) and
  https://raw.githubusercontent.com/3rd/image.nvim/master/lua/image/backends/kitty/init.lua
  (`with_virtual_placeholders` branch).
- **Ghostty compatibility: confirmed working.** Discussion #274 ("It does indeed
  work in Ghostty") and issue #233 ("works in ghostty (which supports kitty image
  protocol)"). README notes Ghostty support is "SUBJECT TO CHANGE" (an old note).
  Sources: https://github.com/3rd/image.nvim/discussions/274 ;
  https://github.com/3rd/image.nvim/issues/233
- **SVG:** ImageMagick (`magick_cli`, the default processor) converts any non-PNG
  source format to PNG before transmission, so markdown `![](x.svg)` renders if
  ImageMagick can rasterize SVG. But **svg is not in the default `hijack_file_patterns`**
  — to open a bare `.svg` in place you must add `"*.svg"` to that list. Source:
  README "ImageMagick" + default `hijack_file_patterns`.
- **Dependencies:** ImageMagick (`brew install imagemagick`; may need
  `DYLD_FALLBACK_LIBRARY_PATH="$(brew --prefix)/lib"` on macOS). cURL for remote
  images. No LuaRocks unless you switch to the optional `magick_rock` processor.
  Source: README "macOS" section.
- **Maintenance:** active — v1.4.0 released 2025-09-07, 2.0k stars, 62 open issues.
  Sources: https://github.com/3rd/image.nvim/blob/master/CHANGELOG.md ;
  repo page.

**Fit:** best match for the exact requirement (inline + open-in-place, focused, one
real dependency).

---

## 2. folke/snacks.nvim — image support inside the big plugin

`snacks.image` uses the kitty graphics protocol; terminal support list explicitly
includes `ghostty`. Source: https://github.com/folke/snacks.nvim/blob/main/docs/image.md

- **Inline in buffer: yes.** Inline rendering for `markdown`, `html`, `norg`, `tsx`,
  `javascript`, `css`, `vue`, `svelte`, `scss`, `latex`, `typst`. **Inlining is
  unicode-placeholder-based** — `doc.inline` is silently disabled when the env does
  not support placeholders, falling back to a floating window. Ghostty *does*
  support placeholders, so inline works; `:checkhealth snacks` reports "`ghostty`
  supports unicode placeholders … Inline images are available". Sources:
  docs/image.md (`doc.inline` comment); `Snacks.health` in
  https://raw.githubusercontent.com/folke/snacks.nvim/main/lua/snacks/image/init.lua
  ("does not support placeholders. Fallback rendering will be used … Inline images
  are disabled").
- **Open image in place: yes.** `BufReadCmd` autocmd attaches an `filetype=image`
  buffer for the configured formats — much wider than image.nvim:
  `png jpg jpeg gif bmp webp tiff heic avif mp4 mov avi mkv webm pdf icns`.
  Source: docs/image.md + `M.setup` autocmd.
- **SVG:** not in the default `formats` list (so no auto-open), but the convert
  config has a dedicated `vector = { "-density", "192", ... }` profile "used by
  vector images like svg", so SVG is rasterized via ImageMagick when referenced.
  Source: docs/image.md `convert.magick.vector`.
- **Ghostty compatibility:** supported + actively exercised (folke's own docs and
  issue threads). One macOS/Ghostty-specific inline bug (empty placeholders, #1333)
  was fixed upstream. Sources: docs/image.md terminal table;
  https://github.com/folke/snacks.nvim/issues/1333
- **Dependencies:** ImageMagick (`magick`); optional extras for PDF (`gs`), LaTeX
  math (`tectonic`/`pdflatex`), mermaid (`mmdc`). Heavier overall, and you get the
  whole snacks ecosystem whether you want it or not.
- **Maintenance:** very active (folke).

**Fit:** strong if you already run snacks.nvim and want math/mermaid/pdf/video too;
overkill as a standalone image renderer.

---

## 3. HakonHarnes/img-clip.nvim — paste/embed, NOT a renderer

Pastes images from the clipboard, drag-and-drop, or URL into markup (Markdown,
LaTeX, Typst, HTML, …) as a file reference, URL, or base64, with configurable
templates and per-filetype/directory settings. It **does not render anything
inline** — it writes markup + saves the image file. Source:
https://github.com/hakonharnes/img-clip.nvim

- Rendering is left to image.nvim / snacks. It is *complementary* to the two above,
  not a substitute.
- Drag-and-drop terminal capability table (X11/Wayland/macOS/Windows) lists Kitty,
  Konsole, Alacritty, WezTerm, foot, Terminal.app, iTerm.app, Windows Terminal —
  **Ghostty is not listed** (untested/unsupported for drag-and-drop). Clipboard
  paste works on macOS. Source: README "drag and drop" table.
- Maintenance: active (HakonHarnes).

**Fit:** adopt only for the paste/insert workflow; pair it with #1 or #2.

---

## 4. Ruled out

- **samodostal/image.nvim** — a different project sharing the name; renders images as
  **ASCII art**, not kitty graphics. **Archived**; its README points users to
  3rd/image.nvim. Sources: https://github.com/samodostal/image.nvim (archived
  banner + "switch to 3rd/image.nvim").
- **edluffy/hologram.nvim** — original kitty-graphics viewer; largely superseded by
  image.nvim (which credits it in its README); not maintained at the same pace.
  Source: https://github.com/edluffy/hologram.nvim
- **kui.nvim** — kitty-graphics UI toolkit, not an image previewer. Source:
  https://github.com/romgrk/kui.nvim (via kitty protocol "applications" list).

---

## Recommendation

**Use `3rd/image.nvim`**, `backend = "kitty"`, `processor = "magick_cli"`.

```lua
{ "3rd/image.nvim", build = false, opts = { processor = "magick_cli" } }
```

Plus `brew install imagemagick` (and, if needed, add `$(brew --prefix)/lib` to
`DYLD_FALLBACK_LIBRARY_PATH`). To open bare `.svg` files in place, add `"*.svg"` to
`hijack_file_patterns`.

Rationale: it is the purpose-built tool for exactly this — inline rendering in the
buffer and Zed-style "open image in place" via `hijack_file_patterns` — with a single
real dependency (ImageMagick). Its default `kitty_method = "normal"` (absolute cursor
positioning, no unicode placeholders) is confirmed working in Ghostty and avoids the
placeholder path entirely. SVG works through ImageMagick rasterization. If you are
already on snacks.nvim and also want PDF/video/math/mermaid, `snacks.image` is the
legitimate alternative (Ghostty placeholders are supported, so inline works there
too); but as a focused image renderer it drags in the whole snacks stack. Add
`img-clip.nvim` on top if you also want clipboard-paste/insert workflows.
