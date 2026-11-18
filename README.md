# liftoff.sh

**liftoff.sh** is a simple and extensible Bash script to launch project-specific development environments based on a YAML configuration file.

## Features

- Launches apps, terminals, and custom commands for each project
- Configuration stored cleanly in `workflows.yaml`
- Easily list available environments with `--list`


## Requirements

- Bash
- `yq` for parsing YAML. Both flavours are supported:
  - [mikefarah/yq](https://github.com/mikefarah/yq) v4 (`sudo snap install yq`)
  - the Python [kislyuk/yq](https://github.com/kislyuk/yq) wrapper around `jq` (`sudo apt install yq`)

## Usage
```
./liftoff.sh <project-name>   # Launch a specific project
./liftoff.sh --list           # Show available projects
./liftoff.sh --help           # Show usage
./liftoff.sh -q <project-name> # Launch without printing liftoff output
```

## Shell completion

Project names and options can be tab-completed. Make the script available as
`liftoff` (alias or symlink) and source the completion file for your shell:

```zsh
# ~/.zshrc (after oh-my-zsh / compinit)
alias liftoff=~/develop/liftoff/liftoff.sh
source ~/develop/liftoff/completions/liftoff.zsh
```

```bash
# ~/.bashrc
alias liftoff=~/develop/liftoff/liftoff.sh
source ~/develop/liftoff/completions/liftoff.bash
```

## Configure your environments

The script uses `workflows.yaml` by default for configuration. If a `workflows.local.yaml` file exists, it will override the default configuration, allowing you to maintain local customizations without modifying the main file.


Each project has:

- `directory` (optional): working directory the commands are run from (`~` is expanded)
- `commands` (optional): list of shell commands, each launched in the background (in parallel)
- `terminal` (optional): list of commands run **in sequence** inside a new [Ghostty](https://ghostty.org) window opened in the project directory. They are chained with `&&` (it stops at the first failure) and the window then stays open with your interactive `$SHELL`. Use `terminal: []` to just open the terminal.

At least one of `commands` or `terminal` is required.

### Example workflows.local.yaml

```yaml
project1:
   directory: ~/dev/project1
   commands:
    - xdg-open ~/dev/project1
    - gnome-terminal -- bash -c "cd ~/dev/project1 && docker compose up; exec bash"
    - code ~/dev/project1
    - firefox http://localhost:3000

project2:
   directory: ~/dev/project2
   terminal:
    - git pull
    - claude
```
