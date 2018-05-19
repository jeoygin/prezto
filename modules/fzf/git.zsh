export FZF_PREVIEW_DEFAULT_BINDING="ctrl-j:preview-down,ctrl-k:preview-up,ctrl-f:preview-page-down,ctrl-b:preview-page-up,ctrl-space:toggle-preview,alt-enter:toggle-preview-wrap,ctrl-v:page-down,alt-v:page-up"

is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

fzf-down() {
  fzf --height 80% "$@" --border
}

fzf-gf() {
  is_in_git_repo || return
  git -c color.status=always status --short |
  fzf-down -m --ansi --nth 2..,.. \
    --bind "${FZF_PREVIEW_BINDING:-$FZF_PREVIEW_DEFAULT_BINDING}" \
    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
  cut -c4- | sed 's/.* -> //'
}

fzf-gg() {
  is_in_git_repo || return
  local _files=$( git -c color.status=always status --short |
  fzf-down -m --ansi --nth 2..,.. \
    --bind "${FZF_PREVIEW_BINDING:-$FZF_PREVIEW_DEFAULT_BINDING}" \
    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
  cut -c4- | sed 's/.* -> //' )
  if [[ -n "$_files" ]]; then
    echo "$_files" | while read file
    do
      git add "$file"
    done
  fi
}

fzf-gb() {
  is_in_git_repo || return
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --multi --tac --preview-window right:70% \
    --bind "${FZF_PREVIEW_BINDING:-$FZF_PREVIEW_DEFAULT_BINDING}" \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

fzf-gt() {
  is_in_git_repo || return
  git tag --sort -version:refname |
  fzf-down --multi --preview-window right:70% \
    --bind "${FZF_PREVIEW_BINDING:-$FZF_PREVIEW_DEFAULT_BINDING}" \
    --preview 'git show --color=always {} | head -'$LINES
}

fzf-gh() {
  is_in_git_repo || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi \
    --bind "ctrl-s:toggle-sort,${FZF_PREVIEW_BINDING:-$FZF_PREVIEW_DEFAULT_BINDING}" \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -'$LINES |
  grep -o "[a-f0-9]\{7,\}"
}

fzf-gw() {
  is_in_git_repo || return
  local _dest_branch=${1:-HEAD}
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi \
    --bind "${FZF_PREVIEW_BINDING:-$FZF_PREVIEW_DEFAULT_BINDING}" \
    --header "Diff to $_dest_branch" \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs -I{} git diff --color=always {}..'"$_dest_branch"' | head -500' |
  grep -o "[a-f0-9]\{7,\}"
}

fzf-gr() {
  is_in_git_repo || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  fzf-down --tac \
    --bind "${FZF_PREVIEW_BINDING:-$FZF_PREVIEW_DEFAULT_BINDING}" \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1} | head -200' |
  cut -d$'\t' -f1
}

join-lines() {
  local item
  while read item; do
    echo -n "${(q)item} "
  done
}

bind-git-helper() {
  local char
  for c in $@; do
    eval "fzf-g$c-widget() { local result=\$(fzf-g$c | join-lines); zle reset-prompt; LBUFFER+=\$result }"
    eval "zle -N fzf-g$c-widget"
    eval "bindkey '^g^$c' fzf-g$c-widget"
  done
}

bind-git-helper f g b t r h w
unset -f bind-git-helper
