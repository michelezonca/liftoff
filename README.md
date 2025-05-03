# liftoff.sh

**liftoff.sh** is a simple and extensible Bash script to launch project-specific development environments based on a YAML configuration file.

## Features

- Launches apps, terminals, and custom commands for each project
- Configuration stored cleanly in `workflows.yaml`
- Easily list available environments with `--list`


## Requirements

- Bash
- [`yq`](https://github.com/mikefarah/yq) for parsing YAML

Install `yq` on Ubuntu:

```bash
sudo snap install yq
# or
sudo apt install yq
```

## Usage
```
./liftoff.sh <project-name>   # Launch a specific project
./liftoff.sh --list           # Show available projects
```

## Configure your environments

The script uses `workflows.yaml` by default for configuration. If a `workflows.local.yaml` file exists, it will override the default configuration, allowing you to maintain local customizations without modifying the main file.


### Example workflows.local.yaml

```yaml
project1:
   directory: ~/dev/project1
   commands:
    - xdg-open ~/dev/project1
    - gnome-terminal -- bash -c "cd ~/dev/project1 && docker compose up; exec bash"
    - code ~/dev/project1
    - firefox http://localhost:3000
```
