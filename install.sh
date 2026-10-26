#!/bin/bash
# Anthony's dotfiles installer — installs ONLY: Ghostty, JetBrains Mono Nerd Font,
# Catppuccin colors (fzf/bat/delta), SSH commit signing. Safe to re-run.
DOT="$HOME/dotfiles"
LOG="$DOT/install.log"
exec > >(tee "$LOG") 2>&1
TS=$(date +%Y%m%d%H%M%S)
step() { printf '\n\033[1;35m==> %s\033[0m\n' "$1"; }
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null
command -v brew >/dev/null || { echo "Homebrew not found — stop."; exit 1; }

step "1/5 Ghostty + JetBrains Mono Nerd Font"
for cask in ghostty font-jetbrains-mono-nerd-font; do
  if brew list --cask "$cask" >/dev/null 2>&1; then echo "$cask already installed"
  elif [ "$cask" = ghostty ] && [ -d /Applications/Ghostty.app ]; then echo "Ghostty.app already in /Applications"
  else brew install --cask "$cask"; fi
done

step "2/5 Ghostty config (Catppuccin Mocha)"
GH=/Applications/Ghostty.app/Contents/MacOS/ghostty
if [ -x "$GH" ]; then
  T=$("$GH" +list-themes 2>/dev/null | sed -E 's/ \(.*\)$//' | grep -i -m1 -E '^catppuccin[ -]mocha$')
  [ -n "$T" ] && sed -i '' -E "s/^theme = .*/theme = $T/" "$DOT/ghostty/config" && echo "theme name: $T"
fi
mkdir -p "$HOME/.config/ghostty"
G="$HOME/.config/ghostty/config"
[ -e "$G" ] && [ ! -L "$G" ] && mv "$G" "$G.bak-$TS" && echo "backed up old ghostty config"
ln -sfn "$DOT/ghostty/config" "$G" && echo "linked $G"

step "3/5 Catppuccin for bat / delta / fzf"
if ! bat --list-themes 2>/dev/null | grep -q 'Catppuccin Mocha'; then
  BATDIR="$(bat --config-dir)/themes"; mkdir -p "$BATDIR"
  curl -fsSL -o "$BATDIR/Catppuccin Mocha.tmTheme" \
    "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme" \
    && bat cache --build
fi
bat --list-themes | grep -q 'Catppuccin Mocha' && echo "bat theme OK"
git config --global --get-all include.path | grep -q 'dotfiles/git/gitconfig' \
  || git config --global --add include.path "~/dotfiles/git/gitconfig"
echo "git includes dotfiles/git/gitconfig"

step "4/5 ~/.zshrc"
Z="$HOME/.zshrc"
if ! grep -q 'dotfiles/zsh/zshrc' "$Z"; then
  cp "$Z" "$Z.bak-$TS"
  # replace the earlier dev-setup block with the dotfiles version (same aliases + colors)
  sed -i '' '/# >>> dev-setup >>>/,/# <<< dev-setup <<</d' "$Z"
  printf '\n# dotfiles\nsource ~/dotfiles/zsh/zshrc\n' >> "$Z"
  echo "zshrc updated (backup: $Z.bak-$TS)"
else
  echo "zshrc already sources dotfiles"
fi

step "5/5 SSH commit signing (GitHub Verified badge)"
KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$KEY" ]; then
  echo "Creating SSH key (press Enter for no passphrase, or type one)"
  ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$KEY"
fi
git config --global gpg.format ssh
git config --global user.signingkey "$KEY.pub"
git config --global commit.gpgsign true
git config --global tag.gpgsign true
echo "Authorizing gh to upload a signing key (browser may open)…"
gh auth refresh -h github.com -s admin:ssh_signing_key \
  && gh ssh-key add "$KEY.pub" --type signing --title "$(scutil --get ComputerName) signing" \
  && echo "signing key uploaded"
echo "(Badge shows only if your git email is a verified email on your GitHub account.)"

step "Check"
[ -d /Applications/Ghostty.app ] && echo "Ghostty: OK" || echo "Ghostty: MISSING"
ls ~/Library/Fonts 2>/dev/null | grep -qi 'JetBrainsMonoNerd' && echo "Nerd Font: OK" || echo "Nerd Font: check Font Book"
echo "commit signing: $(git config --global commit.gpgsign) ($(git config --global gpg.format))"
echo; echo "Done. Open Ghostty — new aliases/colors load in new tabs."
