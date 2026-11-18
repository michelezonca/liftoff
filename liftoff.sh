#!/bin/bash

# Determine the directory of the script
# (resolving symlinks, so it works when linked e.g. into ~/.local/bin)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Use workflows.local.yaml if it exists, otherwise fallback to workflows.yaml
if [ -f "$SCRIPT_DIR/workflows.local.yaml" ]; then
  WORKFLOW_FILE="$SCRIPT_DIR/workflows.local.yaml"
else
  WORKFLOW_FILE="$SCRIPT_DIR/workflows.yaml"
fi

usage() {
  echo "Usage: $0 [--quiet] <project_name> | --list | --help"
}

# Print only when not in quiet mode
log() {
  [ "$QUIET" = 1 ] || echo "$@"
}

# yq is required (works with both mikefarah/yq v4 and the Python yq wrapper)
if ! command -v yq &>/dev/null; then
  echo "Error: 'yq' is not installed. See README.md for installation instructions." >&2
  exit 1
fi

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "Error: configuration file not found: $WORKFLOW_FILE" >&2
  exit 1
fi

# Parse arguments: -q/--quiet can appear before or after the project name
QUIET=0
COMMAND=""
for arg in "$@"; do
  case "$arg" in
    --quiet|-q) QUIET=1 ;;
    *) [ -z "$COMMAND" ] && COMMAND=$arg ;;
  esac
done

case "$COMMAND" in
  --list|-l)
    echo "Available projects:"
    yq -r 'keys | .[]' "$WORKFLOW_FILE" | sed 's/^/  /'
    exit 0
    ;;
  --names)
    # Plain project list, used by shell completion
    yq -r 'keys | .[]' "$WORKFLOW_FILE" 2>/dev/null
    exit 0
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  "")
    usage
    exit 1
    ;;
esac

# Escape double quotes and backslashes so the project name can be used as a yq key
KEY=${COMMAND//\\/\\\\}
KEY=${KEY//\"/\\\"}
SELECTOR=".[\"$KEY\"]"

# Check if the project exists in the YAML file
if ! yq -e "$SELECTOR" "$WORKFLOW_FILE" &>/dev/null; then
  echo "Unknown project: $COMMAND" >&2
  echo "Use '$0 --list' to see available projects." >&2
  exit 2
fi

# Extract directory and commands
DIRECTORY=$(yq -r "$SELECTOR.directory // \"\"" "$WORKFLOW_FILE")
COMMANDS=$(yq -r "($SELECTOR.commands // [])[]" "$WORKFLOW_FILE")

# Optional "terminal" key: commands run in sequence inside a new terminal window
# (an empty list just opens the terminal in the project directory)
HAS_TERMINAL=0
if [ "$(yq -r "$SELECTOR | has(\"terminal\")" "$WORKFLOW_FILE" 2>/dev/null)" = "true" ]; then
  HAS_TERMINAL=1
  TERMINAL_COMMANDS=$(yq -r "($SELECTOR.terminal // [])[]" "$WORKFLOW_FILE")
fi

if [ -z "$COMMANDS" ] && [ "$HAS_TERMINAL" = 0 ]; then
  echo "No commands or terminal defined for project: $COMMAND" >&2
  exit 3
fi

# Run commands from the project directory (with ~ expansion), if defined
if [ -n "$DIRECTORY" ]; then
  DIRECTORY="${DIRECTORY/#\~/$HOME}"
  if ! cd "$DIRECTORY" 2>/dev/null; then
    echo "Warning: directory not found: $DIRECTORY (running from $PWD)" >&2
  fi
fi

log "Starting environment for $COMMAND..."

# Execute each command in the background
while IFS= read -r cmd; do
  [ -z "$cmd" ] && continue
  log "Running: $cmd"
  eval "$cmd" &
done <<< "$COMMANDS"

# Open the terminal and run the "terminal" commands in sequence (stops at the
# first failure); the window then stays open with an interactive shell
if [ "$HAS_TERMINAL" = 1 ]; then
  TERMINAL_SHELL=${SHELL:-/bin/bash}
  SCRIPT=""
  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    SCRIPT+="${SCRIPT:+ && }$cmd"
  done <<< "$TERMINAL_COMMANDS"

  if [ -n "$SCRIPT" ]; then
    log "Opening terminal: $SCRIPT"
    ghostty --working-directory="$PWD" -e "$TERMINAL_SHELL" -ic "$SCRIPT; exec \"$TERMINAL_SHELL\"" >/dev/null 2>&1 &
  else
    log "Opening terminal"
    ghostty --working-directory="$PWD" >/dev/null 2>&1 &
  fi
fi
