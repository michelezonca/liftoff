#!/bin/bash

# Determine the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use workflows.local.yaml if it exists, otherwise fallback to workflows.yaml
if [ -f "$SCRIPT_DIR/workflows.local.yaml" ]; then
  WORKFLOW_FILE="$SCRIPT_DIR/workflows.local.yaml"
else
  WORKFLOW_FILE="$SCRIPT_DIR/workflows.yaml"
fi

usage() {
  echo "Usage: $0 <project_name> | --list | --help"
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

COMMAND=$1

case "$COMMAND" in
  --list|-l)
    echo "Available projects:"
    yq -r 'keys | .[]' "$WORKFLOW_FILE" | sed 's/^/  /'
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

if [ -z "$COMMANDS" ]; then
  echo "No commands defined for project: $COMMAND" >&2
  exit 3
fi

# Run commands from the project directory (with ~ expansion), if defined
if [ -n "$DIRECTORY" ]; then
  DIRECTORY="${DIRECTORY/#\~/$HOME}"
  if ! cd "$DIRECTORY" 2>/dev/null; then
    echo "Warning: directory not found: $DIRECTORY (running from $PWD)" >&2
  fi
fi

echo "Starting environment for $COMMAND..."

# Execute each command in the background
while IFS= read -r cmd; do
  [ -z "$cmd" ] && continue
  echo "Running: $cmd"
  eval "$cmd" &
done <<< "$COMMANDS"
