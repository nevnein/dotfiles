#!/bin/bash
# Idempotent dotfiles bootstrap for Homebrew, zsh, and Ghostty.
# Safe to run more than once: existing files are backed up, correct
# symlinks are left alone, and Brewfile installs are declarative.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[INFO] Dotfiles directory: $DOTFILES_DIR"

if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  echo "[ACTION] Installing Homebrew for Apple Silicon..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
else
  echo "[ERROR] Homebrew is not available after install." >&2
  exit 1
fi

echo "[ACTION] Applying Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

# link_file SOURCE DEST
# Point DEST at SOURCE. Parent directories are created. A destination that
# already points at SOURCE is left unchanged. Any other file, directory, or
# symlink (including a broken one) is moved aside before linking.
link_file() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    echo "[ERROR] Source missing: $src" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" && -e "$dest" ]]; then
    if [[ "$(realpath "$dest")" == "$(realpath "$src")" ]]; then
      echo "[INFO] Already linked: $dest -> $src"
      return 0
    fi
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    local stamp backup_dir backup_path
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup_dir="$HOME/.dotfiles_backup/$stamp"
    mkdir -p "$backup_dir"
    backup_path="$backup_dir/$(basename "$dest")"
    if [[ -e "$backup_path" || -L "$backup_path" ]]; then
      backup_path="${backup_path}.$$"
    fi
    mv "$dest" "$backup_path"
    echo "[ACTION] Backed up $dest -> $backup_path"
  fi

  ln -s "$src" "$dest"
  echo "[ACTION] Linked $dest -> $src"
}

link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

chmod +x "$DOTFILES_DIR/bootstrap.sh"

echo "[OK] Bootstrap completed"
