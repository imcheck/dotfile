# History
HISTFILE=~/.zsh_history
HISTSIZE=90000
SAVEHIST=90000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Plugins
source /usr/share/zsh-abbr/zsh-abbr.plugin.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Abbreviations
abbr -q l='ls --color=auto'
abbr -q g='git'
abbr -q gst='git status'
abbr -q ga='git add'
abbr -q gc='git commit'
abbr -q gco='git checkout'
abbr -q gp='git push'
abbr -q gl='git pull'
abbr -q gd='git diff'
abbr -q gds='git diff --staged'
abbr -q gpsup='git push --set-upstream origin $(git branch --show-current)'

# Prompt
PS1='%F{blue}%~%f %# '
