# CommonConfig Setup

This repository contains common configuration scripts that can be sourced into your shell environment.

## Installation

To clone this repository and add the configuration scripts to your shell environment, follow the steps below:

1. **Clone the Repository**:
   ```bash
   git clone git@github.com:rushabhsr/CommonConfig.git
   ```

2. **Source All `.sh` Files**:
   ```bash
   for file in ~/CommonConfig/*.sh; do echo "source $file" >> ~/.bashrc; done
   ```

3. **Reload the Shell**:
   ```bash
   $SHELL
   ```

This will ensure that all scripts in the `~/CommonConfig/` directory are sourced into your shell environment.

## Usage

After following the installation steps, the configurations from the scripts will be applied every time you open a new terminal session.

## Notes

- Make sure to verify the contents of each `.sh` file before sourcing them into your environment.
- This setup assumes you are using the `bash` shell. For other shells like `zsh`, use the appropriate configuration file (e.g., `~/.zshrc`).
