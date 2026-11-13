# zsh completion for liftoff.sh
# Usage (in ~/.zshrc, after compinit / oh-my-zsh):
#   source /path/to/liftoff/completions/liftoff.zsh

LIFTOFF_SCRIPT="${${(%):-%x}:A:h:h}/liftoff.sh"

_liftoff() {
  local -a projects opts
  projects=(${(f)"$("$LIFTOFF_SCRIPT" --names 2>/dev/null)"})
  local has_project=0 has_quiet=0 w
  for w in ${words[2,CURRENT-1]}; do
    case $w in
      -q|--quiet) has_quiet=1 ;;
      -*) ;;
      *) has_project=1 ;;
    esac
  done

  opts=()
  (( has_quiet )) || opts+=('--quiet:hide liftoff output')
  if (( CURRENT == 2 )); then
    opts+=('--list:show available projects' '--help:show usage')
  fi

  (( has_project )) || _describe -t projects 'project' projects
  (( ${#opts} )) && _describe -t options 'option' opts
}

compdef _liftoff liftoff liftoff.sh
