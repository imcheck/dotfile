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
for zsh_abbr_plugin in \
  /usr/share/zsh-abbr/zsh-abbr.plugin.zsh \
  /opt/homebrew/share/zsh-abbr/zsh-abbr.plugin.zsh \
  /usr/local/share/zsh-abbr/zsh-abbr.plugin.zsh
do
  if [ -f "$zsh_abbr_plugin" ]; then
    source "$zsh_abbr_plugin"
    break
  fi
done

for zsh_syntax_plugin in \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  if [ -f "$zsh_syntax_plugin" ]; then
    source "$zsh_syntax_plugin"
    break
  fi
done

# Abbreviations
abbr -q -f l='ls -alh --color=auto'
abbr -q -f g='git'
abbr -q -f gst='git status'
abbr -q -f ga='git add'
abbr -q -f gc='git commit'
abbr -q -f gco='git checkout'
abbr -q -f gp='git push'
abbr -q -f gpr='git pull --rebase'
abbr -q -f gl='git pull'
abbr -q -f gd='git diff'
abbr -q -f gds='git diff --staged'
abbr -q -f gpsup='git push --set-upstream origin $(git branch --show-current)'
abbr -q -f nv='nvim'
abbr -q -f c='claude'

# Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PS1='%F{cyan}%~%f%F{yellow}${vcs_info_msg_0_}%f %F{blue}%#%f '
export PATH="$HOME/.local/bin:$PATH"

# fzf
for fzf_shell_dir in \
  /usr/share/doc/fzf/examples \
  /opt/homebrew/opt/fzf/shell \
  /usr/local/opt/fzf/shell
do
  if [ -f "$fzf_shell_dir/key-bindings.zsh" ] && [ -f "$fzf_shell_dir/completion.zsh" ]; then
    source "$fzf_shell_dir/key-bindings.zsh"
    source "$fzf_shell_dir/completion.zsh"
    break
  fi
done
