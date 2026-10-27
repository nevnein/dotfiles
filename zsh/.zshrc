eval "$(starship init zsh)"

# fnm
FNM_PATH="/opt/homebrew/opt/fnm/bin"
if [ -d "$FNM_PATH" ]; then
  eval "$(fnm env --shell zsh)"
fi

# Allows Node to use the system certificates
export NODE_USE_SYSTEM_CA=1

# opencode
export PATH=/Users/adam.dimario/.opencode/bin:$PATH

# ============================================================
# Terminal quality of life
# ============================================================

# History: larger, shared across tabs, skip duplicates and leading-space commands
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

# Completion: menu under the cursor, case-insensitive, extra completions from brew
FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
autoload -Uz compinit
compinit -C

# List ambiguous matches instead of only beeping; menu on second Tab
setopt AUTO_LIST LIST_AMBIGUOUS AUTO_MENU
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:descriptions' format '[%d]'

# Expand an alias when Space is pressed, then insert the space
function expand-alias-space() {
  zle _expand_alias
  zle self-insert
}
zle -N expand-alias-space
bindkey ' ' expand-alias-space

alias g="git"
alias gs="git status"
alias gd="git diff"
alias gco="git checkout"
alias gp="git push"
alias v="vi"
alias c="clear"
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias lt="eza --tree --level=2 --icons"

# zoxide provides z and zi
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# fzf: Ctrl+R history search, Ctrl+T fuzzy file/finder
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
  # fzf rebinds Tab to its own completion; restore zsh's list/menu
  bindkey '^I' expand-or-complete

  # Ctrl+T fuzzy file finder (fzf --zsh above already binds ^T to fzf-file-widget)
  bindkey '^t' fzf-file-widget
fi

# Grey inline suggestion from history/completion; → or End accepts
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
if [ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  bindkey '^F' autosuggest-accept
  bindkey '^E' autosuggest-execute
fi
bindkey '^[f' forward-word

# ============================================================
# Long-running command notifications
# ============================================================
autoload -Uz add-zsh-hook

typeset -g _notify_threshold=${IED_NOTIFY_THRESHOLD:-30}
typeset -g _notify_start=$SECONDS
typeset -g _notify_cmd=""

_notify_preexec() {
  _notify_start=$SECONDS
  _notify_cmd="$1"
}

_notify_precmd() {
  local exit_code=$?
  [[ -z "$_notify_cmd" ]] && return

  local duration=$(( SECONDS - _notify_start ))
  if (( duration >= _notify_threshold )); then
    local human="${duration}s"
    (( duration >= 60 )) && human="$(( duration / 60 ))m$(( duration % 60 ))s"

    local outcome="finished"
    (( exit_code != 0 )) && outcome="failed (exit $exit_code)"

    local cmd="$_notify_cmd"
    (( ${#cmd} > 90 )) && cmd="${cmd[1,87]}..."

    printf '\e]777;notify;%s;%s\a' "Command $outcome after $human" "$cmd"
  fi

  _notify_cmd=""
}

add-zsh-hook preexec _notify_preexec
add-zsh-hook precmd _notify_precmd

# direnv loads .envrc when entering a directory.
# Syntax highlighting stays below this so it remains the last plugin.
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Syntax highlighting must be loaded last
if [ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
