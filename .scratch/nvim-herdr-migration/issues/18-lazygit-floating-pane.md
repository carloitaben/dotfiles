# Grill: lazygit as a floating pane

Type: grilling
Status: open

## Question

Run lazygit as a proper floating pane rather than "another tab" — the user's
stated preference over Zed's task-as-tab. Decide where this lives given the
standing decision "herdr owns every terminal/process, nvim never opens a
:terminal split again": a herdr floating/overlay pane, or an nvim floating
terminal (toggleterm-style)? The tension: the user wants a *floating*
lazygit, and herdr's native pane model vs nvim's float both could host it.
Decide which multiplexer owns the lazygit float, then wire it (herdr overlay
pane vs nvim toggleterm-style float). Small, but decide before building.
