# dotfiles

Anthony's macOS dev setup — Catppuccin Mocha.

```bash
~/dotfiles/install.sh                         # this Mac: Ghostty, font, colors, commit signing
brew bundle --file ~/dotfiles/Brewfile        # new Mac: everything in the Brewfile
```

| Path | What |
|---|---|
| `Brewfile` | record of brew tools/apps on this Mac |
| `zsh/zshrc` | zoxide, fzf, aliases, Catppuccin colors (sourced from `~/.zshrc`) |
| `ghostty/config` | terminal (linked to `~/.config/ghostty/config`) |
| `git/gitconfig` | delta + Catppuccin (included from `~/.gitconfig`) |

Node stays on nvm (Node 24) + corepack pnpm.
