# Created by newuser for 5.8.1

# 起動時にtmuxも起動
# https://qiita.com/ssh0/items/a9956a74bff8254a606a
if [[ ! -n $TMUX && $- == *l* ]]; then
  # get the IDs
  ID="`tmux list-sessions`"
  if [[ -z "$ID" ]]; then
    tmux new-session
  fi
  create_new_session="Create New Session"
  ID="$ID\n${create_new_session}:"
  ID="`echo $ID | $PERCOL | cut -d: -f1`"
  if [[ "$ID" = "${create_new_session}" ]]; then
    tmux new-session
  elif [[ -n "$ID" ]]; then
    tmux attach-session -t "$ID"
  else
    :  # Start terminal normally
  fi
fi

# Node.js関連の設定
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# PATH設定
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/git/omnisharp-linux-x64-net6.0:$PATH"
export PATH="$HOME/git/netcoredbg-linux-amd64:$PATH"

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# fzfオプション設定
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_CTRL_T_OPTS='--preview "cat {}"'
export FZF_ALT_C_OPTS='--preview "ls -la {}"'

# fd - cd to selected directory
# https://qiita.com/kamykn/items/aa9920f07487559c0c7e
fcd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# ghq - fzf to selected repository
ghq-fzf() {
  # Readme
  #local src=$(ghq list | fzf --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/README.*")
  # コミットログ
  local src=$(ghq list | fzf --preview "git --git-dir $(ghq root)/{}/.git log --date=short --pretty=format:'-%C(yellow)%d%Creset %s %Cgreen(%cd) %C(bold blue)<%an>%Creset' --color")
  # ファイルリスト
  #local src=$(ghq list | fzf --preview "ls -laTp $(ghq root)/{} | tail -n+4 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}'")
  if [ -n "$dev" ]; then
    BUFFER="cd $(ghq root)/$dev"
    zle accept-line
  fi
  zle -R -c
}
zle -N ghq-fzf

alias emacs='TERM=xterm-direct emacs'

