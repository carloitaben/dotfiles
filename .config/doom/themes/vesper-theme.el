;;; vesper-theme.el --- Vesper dark theme -*- lexical-binding: t; no-byte-compile: t; -*-
;;
;; Port of https://github.com/vladzima/vesper-theme, colors taken from the
;; official VSCode source (VSCode/Vesper.json) and cross-checked against the
;; nvim port (nexxeln/vesper.nvim) for a clean, unblended palette.

(deftheme vesper "A dark, minimal theme with a warm orange/apricot accent.")

(let* ((bg          "#101010")
       (bg-elevated "#1A1A1A")
       (bg-hover    "#282828")
       (bg-selected "#232323")
       (fg          "#FFFFFF")
       (fg-muted    "#A0A0A0")
       (fg-dim      "#7E7E7E")
       (comment     "#5C5C5C")
       (accent      "#FFC799")
       (accent-2    "#FFD1A8")
       (string      "#99FFE4")
       (error-c     "#FF8080")
       (line-nr     "#505050")
       (border      "#282828"))

  (custom-theme-set-faces
   'vesper

   ;; Core
   `(default ((t (:background ,bg :foreground ,fg))))
   `(cursor ((t (:background ,fg))))
   `(fringe ((t (:background ,bg))))
   `(region ((t (:background ,bg-selected))))
   `(secondary-selection ((t (:background ,bg-selected))))
   `(highlight ((t (:background ,bg-hover))))
   `(hl-line ((t (:background ,bg-elevated))))
   `(shadow ((t (:foreground ,comment))))
   `(minibuffer-prompt ((t (:foreground ,accent :weight bold))))
   `(vertical-border ((t (:foreground ,border))))
   `(window-divider ((t (:foreground ,border))))
   `(link ((t (:foreground ,accent :underline t))))
   `(link-visited ((t (:foreground ,accent-2 :underline t))))

   ;; Line numbers
   `(line-number ((t (:foreground ,line-nr :background ,bg))))
   `(line-number-current-line ((t (:foreground ,fg :background ,bg-elevated :weight bold))))

   ;; Mode line
   `(mode-line ((t (:background ,bg-elevated :foreground ,fg :box (:line-width 1 :color ,border)))))
   `(mode-line-inactive ((t (:background ,bg :foreground ,fg-dim :box (:line-width 1 :color ,border)))))
   `(mode-line-emphasis ((t (:foreground ,accent))))

   ;; Search / matches
   `(isearch ((t (:background ,accent :foreground ,bg))))
   `(lazy-highlight ((t (:background ,bg-hover :foreground ,fg))))
   `(show-paren-match ((t (:background ,bg-hover :foreground ,accent :weight bold))))
   `(show-paren-mismatch ((t (:background ,error-c :foreground ,bg))))

   ;; Diagnostics
   `(error ((t (:foreground ,error-c :weight bold))))
   `(warning ((t (:foreground ,accent :weight bold))))
   `(success ((t (:foreground ,string :weight bold))))

   ;; Font-lock (syntax highlighting)
   `(font-lock-comment-face ((t (:foreground ,comment :slant italic))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,comment))))
   `(font-lock-doc-face ((t (:foreground ,comment :slant italic))))
   `(font-lock-string-face ((t (:foreground ,string))))
   `(font-lock-keyword-face ((t (:foreground ,fg-muted))))
   `(font-lock-builtin-face ((t (:foreground ,accent))))
   `(font-lock-function-name-face ((t (:foreground ,accent))))
   `(font-lock-variable-name-face ((t (:foreground ,fg))))
   `(font-lock-variable-use-face ((t (:foreground ,fg))))
   `(font-lock-type-face ((t (:foreground ,accent))))
   `(font-lock-constant-face ((t (:foreground ,accent))))
   `(font-lock-number-face ((t (:foreground ,accent))))
   `(font-lock-negation-char-face ((t (:foreground ,fg-muted))))
   `(font-lock-preprocessor-face ((t (:foreground ,fg-muted))))
   `(font-lock-warning-face ((t (:foreground ,error-c))))
   `(font-lock-property-name-face ((t (:foreground ,fg))))
   `(font-lock-property-use-face ((t (:foreground ,fg))))
   `(font-lock-punctuation-face ((t (:foreground ,fg-muted))))
   `(font-lock-bracket-face ((t (:foreground ,fg-muted))))
   `(font-lock-delimiter-face ((t (:foreground ,fg-muted))))
   `(font-lock-operator-face ((t (:foreground ,fg-muted))))
   `(font-lock-escape-face ((t (:foreground ,fg-muted))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,fg-muted))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,fg-muted))))

   ;; Diff / VC
   `(diff-added ((t (:foreground ,string))))
   `(diff-removed ((t (:foreground ,error-c))))
   `(diff-changed ((t (:foreground ,accent))))
   `(vc-edited-state ((t (:foreground ,accent))))
   `(vc-locally-added-state ((t (:foreground ,string))))
   `(vc-removed-state ((t (:foreground ,error-c))))
   `(diff-hl-insert ((t (:foreground ,string :background ,string))))
   `(diff-hl-delete ((t (:foreground ,error-c :background ,error-c))))
   `(diff-hl-change ((t (:foreground ,accent :background ,accent))))

   ;; Completion UI (Doom defaults: vertico + corfu)
   `(vertico-current ((t (:background ,bg-selected :extend t))))
   `(corfu-current ((t (:background ,bg-selected :foreground ,fg))))
   `(corfu-default ((t (:background ,bg-elevated :foreground ,fg))))
   `(corfu-border ((t (:background ,border))))
   `(orderless-match-face-0 ((t (:foreground ,accent :weight bold))))
   `(orderless-match-face-1 ((t (:foreground ,string :weight bold))))

   ;; which-key
   `(which-key-key-face ((t (:foreground ,accent))))
   `(which-key-command-description-face ((t (:foreground ,fg))))
   `(which-key-group-description-face ((t (:foreground ,fg-muted))))
   `(which-key-separator-face ((t (:foreground ,comment))))

   ;; org-mode
   `(org-level-1 ((t (:foreground ,accent :weight bold))))
   `(org-level-2 ((t (:foreground ,string :weight bold))))
   `(org-level-3 ((t (:foreground ,fg-muted :weight bold))))
   `(org-todo ((t (:foreground ,error-c :weight bold))))
   `(org-done ((t (:foreground ,string :weight bold))))
   `(org-link ((t (:foreground ,accent :underline t))))
   `(org-block ((t (:background ,bg-elevated))))
   `(org-code ((t (:foreground ,string))))

   ;; markdown
   `(markdown-header-face ((t (:foreground ,accent :weight bold))))
   `(markdown-code-face ((t (:background ,bg-elevated))))
   `(markdown-link-face ((t (:foreground ,accent))))

   ;; magit
   `(magit-section-heading ((t (:foreground ,accent :weight bold))))
   `(magit-branch-current ((t (:foreground ,string))))
   `(magit-diff-added ((t (:foreground ,string))))
   `(magit-diff-removed ((t (:foreground ,error-c))))

   ;; Doom-specific
   `(doom-modeline-buffer-modified ((t (:foreground ,accent))))
   `(doom-dashboard-banner ((t (:foreground ,accent))))))

(provide-theme 'vesper)

;;; vesper-theme.el ends here
