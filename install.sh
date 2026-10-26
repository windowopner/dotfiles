#!/bin/bash
# Anthony's dotfiles installer — Catppuccin Mocha setup
# Usage: ~/dotfiles/install.sh     (safe to re-run)
DOT="$HOME/dotfiles"
LOG="$DOT/install.log"
exec > >(tee "$LOG") 2>&1
TS=$(date +%Y%m%d%H%M%S)
step() { printf '\n\033[1;35m==> %s\033[0m\n' "$1"; }

# backup a real file (not our symlink) before replacing it
link() {
  src="$1"; dst="$2"; mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.bak-$TS"; echo "backed up $dst"; fi
  ln -sfn "$src" "$dst" && echo "linked $dst -> $src"
}

step "1/8 Homebrew"
if [ ! -x /opt/homebrew/bin/brew ]; then
  echo "Installing Homebrew (enter your Mac password when asked)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
grep -qs 'brew shellenv' "$HOME/.zprofile" || echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"

step "2/8 Packages & apps (Brewfile)"
brew bundle --file "$DOT/Brewfile" || echo "!! some Brewfile items failed — see above (apps already installed manually show up here)"

step "3/8 Config symlinks"
link "$DOT/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOT/mise/config.toml"       "$HOME/.config/mise/config.toml"
GH=/Applications/Ghostty.app/Contents/MacOS/ghostty
if [ -x "$GH" ]; then
  T=$("$GH" +list-themes 2>/dev/null | sed -E 's/ \(.*\)$//' | grep -i -m1 -E '^catppuccin[ -]mocha$')
  [ -n "$T" ] && sed -i '' -E "s/^theme = .*/theme = $T/" "$DOT/ghostty/config" && echo "ghostty theme: $T"
fi
link "$DOT/ghostty/config" "$HOME/.config/ghostty/config"

step "4/8 ~/.zshrc"
touch "$HOME/.zshrc"
if ! grep -q 'dotfiles/zsh/zshrc' "$HOME/.zshrc"; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.bak-$TS"
  # nvm -> mise: disable nvm lines (backup kept)
  sed -i '' -E '/NVM_DIR|nvm\.sh|nvm\/bash_completion/ s/^([^#])/# [nvm->mise] \1/' "$HOME/.zshrc"
  printf '\n# dotfiles\nsource ~/dotfiles/zsh/zshrc\n' >> "$HOME/.zshrc"
  echo "zshrc updated (backup: ~/.zshrc.bak-$TS)"
else
  echo "zshrc already sources dotfiles"
fi

step "5/8 Git"
git config --global --get-all include.path | grep -q 'dotfiles/git/gitconfig' \
  || git config --global --add include.path "~/dotfiles/git/gitconfig"
echo "git: $(git config --global user.name) <$(git config --global user.email)>"

step "6/8 Runtimes (mise)"
mise install && mise ls

step "7/8 Catppuccin for bat/delta + editors"
if ! bat --list-themes 2>/dev/null | grep -q 'Catppuccin Mocha'; then
  BATDIR="$(bat --config-dir)/themes"; mkdir -p "$BATDIR"
  curl -fsSL -o "$BATDIR/Catppuccin Mocha.tmTheme" \
    "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme" && bat cache --build
fi
for ed in cursor code; do
  if command -v "$ed" >/dev/null; then
    "$ed" --install-extension Catppuccin.catppuccin-vsc --force
    "$ed" --install-extension Catppuccin.catppuccin-vsc-icons --force
  fi
done

step "8/8 Optional: SSH commit signing (GitHub 'Verified' badge)"
read -r -p "Set up commit signing now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  KEY="$HOME/.ssh/id_ed25519"
  [ -f "$KEY" ] || ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$KEY"
  git config --global gpg.format ssh
  git config --global user.signingkey "$KEY.pub"
  git config --global commit.gpgsign true
  gh auth refresh -h github.com -s admin:ssh_signing_key \
    && gh ssh-key add "$KEY.pub" --type signing --title "$(scutil --get ComputerName) signing"
  echo "Note: your git email must be a verified email on your GitHub account for the badge."
fi

step "Check"
for c in brew git gh mise node pnpm uv vercel supabase starship zoxide fzf eza bat delta lazygit gitleaks jq rg fd btop dust xh tldr litecli; do
  printf '%-9s ' "$c"; (command -v "$c" >/dev/null && "$c" --version 2>/dev/null | head -1) || echo "MISSING"
done
for a in Ghostty OrbStack Raycast "DB Browser for SQLite"; do [ -d "/Applications/$a.app" ] && echo "app OK: $a" || echo "app MISSING: $a"; done
echo; echo "Done. Quit Terminal and open Ghostty. Then in Cursor/VS Code: Cmd+K Cmd+T -> 'Catppuccin Mocha'."
