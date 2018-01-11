#
# Maintains a frequently used file and directory list for fast access.
#
# Authors:
#   Wei Dai <x@wei23.net>
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Load dependencies.
pmodload 'editor'

# If the command doesn't exist externally, we need to fall back to the bundled
# submodule.
if (( ! $+commands[fasd] )); then
  source "${0:h}/external/fasd" || return 1
fi

#
# Initialization
#

cache_file="${TMPDIR:-/tmp}/prezto-fasd-cache.$UID.zsh"
if [[ "${commands[fasd]}" -nt "$cache_file" || ! -s "$cache_file"  ]]; then
  # Set the base init arguments.
  init_args=(zsh-hook)

  # Set fasd completion init arguments, if applicable.
  if zstyle -t ':prezto:module:completion' loaded; then
    init_args+=(zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install)
  fi

  # Cache init code.
  fasd --init "$init_args[@]" >! "$cache_file" 2> /dev/null
fi

source "$cache_file"

unset cache_file init_args

function fasd_cd {
  local fasd_ret="$(fasd -d "$@")"
  if [[ -d "$fasd_ret" ]]; then
    cd "$fasd_ret"
  else
    print "$fasd_ret"
  fi
}

function fcd {
  local file="$@"
  if [[ -d "$file" ]]; then
    cd "$file"
  else
    print "$file"
  fi
}

_fasd_generate_matches() {
  fasd -l "$@" 2>&1 | sed '/^$/d' | sed -e "s,^$HOME,~,"
}

_fasd_zsh_completion() {
  setopt localoptions noshwordsplit noksh_arrays noposixbuiltins nonomatch
  local args cmd selected slug

  args=(${(z)LBUFFER})
  cmd=${args[1]}

  if [[ "$cmd" != "fcd" || "$LBUFFER" =~ "^\s*fcd$" ]]; then
    zle ${_fasd_zsh_default_completion:-expand-or-complete}
    return
  fi

  if [[ "${#args}" -gt 1 ]]; then
    eval "slug=${args[-1]}"
  fi

  if [[ "$(_fasd_generate_matches "$slug" | head | wc -l)" -gt 1 ]]; then
    selected=$(_fasd_generate_matches "$slug" \
      | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse \
      --bind 'shift-tab:up,tab:down' $FZF_DEFAULT_OPTS" fzf-tmux)
  elif [[ "$(_fasd_generate_matches "$slug" | head | wc -l)" -eq 1 ]]; then
    selected=$(_fasd_generate_matches "$slug")
  else
    return
  fi

  if [[ -n "$selected" ]]; then
    LBUFFER="$cmd $selected"
  fi

  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
}

_fasd_init_zsh_completion() {
  zle -N _fasd_zsh_completion
  bindkey '^I' _fasd_zsh_completion
}

_fasd_init_zsh_completion

#
# Aliases
#

alias a='fasd -a'        # any
alias s='fasd -si'       # show / search / select
alias d='fasd -d'        # directory
alias f='fasd -f'        # file
alias sd='fasd -sid'     # interactive directory selection
alias sf='fasd -sif'     # interactive file selection
alias z='fasd_cd -d'     # cd, same functionality as j in autojump
alias zz='fasd_cd -d -i' # cd with interactive selection
alias j='fasd_cd -i'     # cd with interactive selection
