# dotfiles

Anthony's macOS dev setup — Catppuccin Mocha everywhere.

```bash
git clone <this repo> ~/dotfiles && ~/dotfiles/install.sh
```

| Path | What |
|---|---|
| `Brewfile` | every CLI tool, app and font |
| `zsh/zshrc` | shell: mise, starship, zoxide, fzf, aliases, plugins |
| `starship/starship.toml` | prompt |
| `ghostty/config` | terminal |
| `git/` | delta, sane defaults, global ignore |
| `mise/config.toml` | Node 24 (reads `.nvmrc`) |

Add a tool: put it in `Brewfile`, run `brew bundle --file ~/dotfiles/Brewfile`, commit.
