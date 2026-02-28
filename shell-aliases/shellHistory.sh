#!/bin/bash
# Shell History Configuration
# Source this file in your ~/.bashrc: source ~/CommonConfig/shell-aliases/shellHistory.sh

# ============================================================================
# History Settings
# ============================================================================

# Increase history size
export HISTSIZE=10000                    # Number of commands in memory
export HISTFILESIZE=20000                # Number of commands in history file

# Don't put duplicate lines or lines starting with space in the history
export HISTCONTROL=ignoreboth:erasedups

# Append to history file, don't overwrite it
shopt -s histappend

# Save multi-line commands as one command
shopt -s cmdhist

# Record each line as it gets issued
PROMPT_COMMAND='history -a'

# Ignore common commands
export HISTIGNORE="ls:ll:cd:pwd:bg:fg:history:clear:exit"

# Add timestamp to history
export HISTTIMEFORMAT="%F %T "

# ============================================================================
# Up Arrow History Search
# ============================================================================

# Enable up/down arrow to search through history based on what you've typed
# This allows you to type "git" and press up arrow to cycle through git commands
bind '"\e[A": history-search-backward'   # Up arrow
bind '"\e[B": history-search-forward'    # Down arrow

# Alternative: Use Ctrl+P and Ctrl+N for history search
bind '"\C-p": history-search-backward'
bind '"\C-n": history-search-forward'

# ============================================================================
# Additional History Features
# ============================================================================

# Enable Ctrl+R for reverse history search (usually enabled by default)
# This is the interactive search where you type and it finds matches

# Enable history expansion with space
# Type "!!" and press space to see the last command before executing
bind Space:magic-space

# ============================================================================
# End of History Configuration
# ============================================================================
