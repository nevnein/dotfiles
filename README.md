# dotfiles

Portable dotfiles for zsh, Ghostty, and friends — installed with a single bootstrap script.

## Install

```bash
git clone <your-dotfiles-repo-url> ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

## What gets installed

| Source | Destination |
| --- | --- |
| `zsh/.zshrc` | `~/.zshrc` |
| `ghostty/config` | `~/.config/ghostty/config` |

Starship is installed via the `Brewfile` and runs with its built-in default prompt.

## Requirements

- macOS (primary)
- [Homebrew](https://brew.sh)
- bash

The bootstrap is idempotent: re-running it is safe, backs up changed files,
and skips files that are already identical.
