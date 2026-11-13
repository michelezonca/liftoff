# zsh completion for liftoff.sh
# Usage (in ~/.zshrc, after compinit / oh-my-zsh):
#   source /path/to/liftoff/completions/liftoff.zsh

LIFTOFF_SCRIPT="${${(%):-%x}:A:h:h}/liftoff.sh"

_liftoff() {
  local -a projects opts
  projects=(${(f)"$("$LIFTOFF_SCRIPT" --names 2>/dev/null)"})
  opts=(
    '--list:show available projects'
    '--help:show usage'
  )
  if (( CURRENT == 2 )); then
    _describe -t projects 'project' projects
    _describe -t options 'option' opts
  fi
}

compdef _liftoff liftoff liftoff.sh
