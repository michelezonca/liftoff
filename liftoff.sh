#!/bin/bash

# Determine the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use workflows.local.yaml if it exists, otherwise fallback to workflows.yaml
if [ -f "$SCRIPT_DIR/workflows.local.yaml" ]; then
  WORKFLOW_FILE="$SCRIPT_DIR/workflows.local.yaml"
else
  WORKFLOW_FILE="$SCRIPT_DIR/workflows.yaml"
fi

COMMAND=$1

# Function to list available projects
list_projects() {
  echo "Available projects:"
  yq -r 'keys' "$WORKFLOW_FILE"
  exit 0
}

# If user asks for help or --list
if [ "$COMMAND" == "--list" ]; then
  list_projects
fi

if [ -z "$COMMAND" ]; then
  echo "Usage: $0 <project_name> | --list"
  exit 1
fi

# Check if the project exists in the YAML file
if ! yq -e ".${COMMAND}" "$WORKFLOW_FILE" &>/dev/null; then
  echo "Unknown project: $COMMAND"
  echo "Use '$0 --list' to see available projects."
  exit 2
fi

# Extract directory and commands
DIRECTORY=$(yq -r ".${COMMAND}.directory" "$WORKFLOW_FILE")
COMMANDS=$(yq -r ".${COMMAND}.commands[]" "$WORKFLOW_FILE")


echo "Starting environment for $COMMAND..."

# Execute each command
while IFS= read -r cmd; do
  echo "Running: $cmd"
  eval "$cmd" &
done <<< "$COMMANDS"