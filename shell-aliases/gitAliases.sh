#!/bin/bash
# Git Aliases - Extracted from Oh-My-Bash
# Source this file in your ~/.bashrc: source ~/CommonConfig/gitAliases.sh

# ============================================================================
# Helper Functions
# ============================================================================

# Get current branch name
function git_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Check for develop branch variants
function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel development; do
    if command git show-ref -q --verify refs/heads/"$branch"; then
      echo "$branch"
      return
    fi
  done
  echo develop
}

# Check for main/master branch
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default}; do
    if command git show-ref -q --verify "$ref"; then
      echo "${ref##*/}"
      return
    fi
  done
  echo master
}

# ============================================================================
# Basic Git Aliases
# ============================================================================

alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gav='git add --verbose'

# ============================================================================
# Branch Management
# ============================================================================

alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch --delete --force'
alias gbm='git branch --move'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias gbsc='git branch --show-current'
alias gbda='git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | xargs git branch --delete 2>/dev/null'

# ============================================================================
# Checkout & Switch
# ============================================================================

alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout "$(git_main_branch)"'
alias gcd='git checkout "$(git_develop_branch)"'
alias gcor='git checkout --recurse-submodules'

alias gsw='git switch'
alias gswc='git switch --create'
alias gswm='git switch "$(git_main_branch)"'
alias gswd='git switch "$(git_develop_branch)"'

# ============================================================================
# Commit
# ============================================================================

alias gc='git commit --verbose'
alias gc!='git commit --verbose --amend'
alias gca='git commit --verbose --all'
alias gca!='git commit --verbose --all --amend'
alias gcam='git commit --all --message'
alias gcan!='git commit --verbose --all --no-edit --amend'
alias gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias gcas='git commit --all --signoff'
alias gcasm='git commit --all --signoff --message'
alias gcmsg='git commit --message'
alias gcn!='git commit --verbose --no-edit --amend'
alias gcs='git commit --gpg-sign'
alias gcsm='git commit --signoff --message'
alias gcss='git commit --gpg-sign --signoff'
alias gcssm='git commit --gpg-sign --signoff --message'

# ============================================================================
# Clone
# ============================================================================

alias gcl='git clone --recursive'

function gccd() {
  git clone --recurse-submodules "$@"
  local lastarg="${!#}"
  [[ -d "$lastarg" ]] && cd "$lastarg" && return
  lastarg="${lastarg##*/}"
  cd "${lastarg%.git}"
}

# ============================================================================
# Diff
# ============================================================================

alias gd='git diff'
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'
alias gds='git diff --staged'
alias gdw='git diff --word-diff'
alias gdup='git diff @{upstream}'

function gdnolock() {
  git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}

function gdv() {
  git diff -w "$@" | view -
}

# ============================================================================
# Fetch
# ============================================================================

alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gfo='git fetch origin'

# ============================================================================
# Log
# ============================================================================

alias glg='git log --stat'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glgp='git log --stat -p'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'

# ============================================================================
# Merge
# ============================================================================

alias gm='git merge'
alias gma='git merge --abort'
alias gmom='git merge "origin/$(git_main_branch)"'
alias gms='git merge --squash'
alias gmum='git merge "upstream/$(git_main_branch)"'

# ============================================================================
# Pull
# ============================================================================

alias gl='git pull'
alias gup='git pull --rebase'
alias gupa='git pull --rebase --autostash'
alias gupav='git pull --rebase --autostash --verbose'
alias gupv='git pull --rebase --verbose'
alias gpr='git pull --rebase'
alias ggpull='git pull origin "$(git_current_branch)"'
alias glum='git pull upstream "$(git_main_branch)"'
alias gluc='git pull upstream "$(git_current_branch)"'
alias gupom='git pull --rebase origin "$(git_main_branch)"'
alias gupomi='git pull --rebase=interactive origin "$(git_main_branch)"'

function ggl() {
  if [[ $# -ne 0 && $# -ne 1 ]]; then
    git pull origin "$*"
  else
    local b=""
    [[ $# -eq 0 ]] && b=$(git_current_branch)
    git pull origin "${b:-$1}"
  fi
}

function ggu() {
  local b=""
  [[ $# -ne 1 ]] && b=$(git_current_branch)
  git pull --rebase origin "${b:-$1}"
}

# ============================================================================
# Push
# ============================================================================

alias gp='git push'
alias gpd='git push --dry-run'
alias gpf='git push --force-with-lease'
alias gpf!='git push --force'
alias gpoat='git push origin --all && git push origin --tags'
alias gpod='git push origin --delete'
alias gpsup='git push --set-upstream origin "$(git_current_branch)"'
alias gpsupf='git push --set-upstream origin "$(git_current_branch)" --force-with-lease'
alias gpu='git push upstream'
alias gpv='git push --verbose'
alias ggpush='git push origin "$(git_current_branch)"'

function ggp() {
  if [[ $# -ne 0 && $# -ne 1 ]]; then
    git push origin "$*"
  else
    [[ $# -eq 0 ]] && local b=$(git_current_branch)
    git push origin "${b:=$1}"
  fi
}

function ggf() {
  [[ $# -ne 1 ]] && local b=$(git_current_branch)
  git push --force origin "${b:=$1}"
}

function ggfl() {
  [[ $# -ne 1 ]] && local b=$(git_current_branch)
  git push --force-with-lease origin "${b:=$1}"
}

function ggpnp() {
  if [[ $# -eq 0 ]]; then
    ggl && ggp
  else
    ggl "$*" && ggp "$*"
  fi
}

# ============================================================================
# Rebase
# ============================================================================

alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase --interactive'
alias grbo='git rebase --onto'
alias grbs='git rebase --skip'
alias grbd='git rebase "$(git_develop_branch)"'
alias grbm='git rebase "$(git_main_branch)"'
alias grbom='git rebase "origin/$(git_main_branch)"'

# ============================================================================
# Remote
# ============================================================================

alias gr='git remote'
alias gra='git remote add'
alias grmv='git remote rename'
alias grrm='git remote remove'
alias grset='git remote set-url'
alias grup='git remote update'
alias grv='git remote --verbose'

# ============================================================================
# Reset
# ============================================================================

alias grh='git reset'
alias grhh='git reset --hard'
alias grhk='git reset --keep'
alias grhs='git reset --soft'
alias groh='git reset "origin/$(git_current_branch)" --hard'
alias gru='git reset --'
alias gpristine='git reset --hard && git clean --force -dfx'

# ============================================================================
# Restore
# ============================================================================

alias grs='git restore'
alias grss='git restore --source'
alias grst='git restore --staged'

# ============================================================================
# Revert
# ============================================================================

alias grev='git revert'

# ============================================================================
# Remove
# ============================================================================

alias grm='git rm'
alias grmc='git rm --cached'

# ============================================================================
# Stash
# ============================================================================

alias gsta='git stash save'
alias gstaa='git stash apply'
alias gstall='git stash --all'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show'
alias gstu='git stash save --include-untracked'

# ============================================================================
# Status
# ============================================================================

alias gst='git status'
alias gss='git status --short'
alias gsb='git status --short --branch'

# ============================================================================
# Tag
# ============================================================================

alias gta='git tag --annotate'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'

function gtl() {
  git tag --sort=-v:refname -n --list "${1}*"
}

# ============================================================================
# Miscellaneous
# ============================================================================

alias gclean='git clean -fd'
alias gcf='git config --list'
alias gsh='git show'
alias gsps='git show --pretty=short --show-signature'
alias gcount='git shortlog --summary --numbered'
alias gignore='git update-index --assume-unchanged'
alias gunignore='git update-index --no-assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias gfg='git ls-files | grep'
alias grt='cd $(git rev-parse --show-toplevel || echo ".")'

# Cherry-pick
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gcps='git cherry-pick -s'

# Submodules
alias gsi='git submodule init'
alias gsu='git submodule update'

# Worktree
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'

# WIP (Work In Progress)
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'

# ============================================================================
# Diff Aliases
# ============================================================================

# Show staged changes
alias gds='git diff --staged'
alias gdst='git diff --staged'
alias gdcached='git diff --cached'

# Compare two branches
alias gdbr='f() { git diff ${1:-main}...${2:-HEAD}; }; f'
alias gdiff-branches='f() { git diff ${1:-main}...${2:-HEAD}; }; f'

# Show diff stats between branches
alias gdbr-stat='f() { git diff --stat ${1:-main}...${2:-HEAD}; }; f'

# Show files changed between branches
alias gdbr-files='f() { git diff --name-only ${1:-main}...${2:-HEAD}; }; f'

# ============================================================================
# End of Git Aliases
# ============================================================================
