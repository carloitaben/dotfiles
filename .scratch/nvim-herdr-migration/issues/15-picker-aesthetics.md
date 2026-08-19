# Task: picker aesthetics cleanup

Type: task
Status: open

## Question

Clean up nvim picker/popup aesthetics to remove "hacky-nerdy" noise the user
dislikes: e.g. the unix permission string and other low-value fields in the
telescope file picker, and any odd symbols/icons. Goal: pickers read clean
and minimal, Zed-like. Concretely: adjust telescope entry_maker / path_display
/ display configuration (and mini.pick if adopted) so the file picker shows
just the useful filename/path, no permission/ownership noise; confirm no
stray default decorations remain.
