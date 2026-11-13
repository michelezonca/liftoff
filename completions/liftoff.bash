# bash completion for liftoff.sh
# Usage (in ~/.bashrc):
#   source /path/to/liftoff/completions/liftoff.bash

LIFTOFF_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/liftoff.sh"

_liftoff() {
  if [ "$COMP_CWORD" -eq 1 ]; then
    local words
    words="$("$LIFTOFF_SCRIPT" --names 2>/dev/null) --list --help"
    mapfile -t COMPREPLY < <(compgen -W "$words" -- "${COMP_WORDS[1]}")
  fi
}

complete -F _liftoff liftoff liftoff.sh
