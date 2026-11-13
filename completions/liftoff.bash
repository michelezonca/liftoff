# bash completion for liftoff.sh
# Usage (in ~/.bashrc):
#   source /path/to/liftoff/completions/liftoff.bash

LIFTOFF_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/liftoff.sh"

_liftoff() {
  local cur=${COMP_WORDS[COMP_CWORD]} words="" w has_project=0 has_quiet=0 i
  for ((i = 1; i < COMP_CWORD; i++)); do
    w=${COMP_WORDS[i]}
    case "$w" in
      -q|--quiet) has_quiet=1 ;;
      -*) ;;
      *) has_project=1 ;;
    esac
  done

  [ "$has_project" = 1 ] || words="$("$LIFTOFF_SCRIPT" --names 2>/dev/null)"
  [ "$has_quiet" = 1 ] || words="$words --quiet"
  [ "$COMP_CWORD" -eq 1 ] && words="$words --list --help"
  mapfile -t COMPREPLY < <(compgen -W "$words" -- "$cur")
}

complete -F _liftoff liftoff liftoff.sh
