# Editor
export EDITOR=nvim

# History
HISTFILE=~/.zsh_history
HISTSIZE=90000
SAVEHIST=90000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Plugins
source /usr/share/zsh-abbr/zsh-abbr.plugin.zsh

if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  # Alpine
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  # Debian / Raspberry Pi OS
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Abbreviations
abbr -q -f l='ls -alh --color=auto'
abbr -q -f g='git'
abbr -q -f gst='git status'
abbr -q -f ga='git add'
abbr -q -f gc='git commit'
abbr -q -f gco='git checkout'
abbr -q -f gp='git push'
abbr -q -f gl='git pull'
abbr -q -f gd='git diff'
abbr -q -f gds='git diff --staged'
abbr -q -f gpsup='git push --set-upstream origin $(git branch --show-current)'

# Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PS1='%F{cyan}%~%f%F{yellow}${vcs_info_msg_0_}%f %F{blue}%#%f '
