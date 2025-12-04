#!/bin/bash

# GitLab Branch Synchronization Script
# Usage: sync-branches [sync_type]
# Example: sync-branches prod-to-uat

set -e  # Abort on any command failure

# Use single global config file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/sync_branches.config"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Get the current date in the configured format
CURRENT_DATE=$(date +"$DATE_FORMAT")
SYNC_TYPE="$1"

# Function for logging messages
log_message() {
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Function for handling errors
handle_error() {
    echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $1"
    exit 1
}

# Function to show usage
show_usage() {
    echo "Usage: sync-branches [sync_type]"
    echo ""
    echo "Available sync types:"
    for sync_name in "${!SYNC_CONFIGS[@]}"; do
        echo "  $sync_name"
    done
    echo "  cleanup - Clean up old branches"
    echo ""
    echo "Examples:"
    echo "  sync-branches prod-to-uat"
    echo "  sync-branches cleanup"
}

# Function to switch branches and pull changes
checkout_and_pull() {
    local branch_name=$1
    log_message "Switching to $branch_name branch."
    
    # Delete local branch if it exists (to avoid conflicts)
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        git branch -D "$branch_name" 2>/dev/null && log_message "Deleted local branch: $branch_name"
    fi
    
    git checkout "$branch_name" || handle_error "Failed to switch to $branch_name branch."
    git pull origin "$branch_name" || handle_error "Failed to pull latest changes from $branch_name."
}

# Function to create a new branch, merge, and push changes
create_merge_push() {
    local source_branch=$1
    local target_branch=$2
    local branch_prefix=$3
    local branch_name="${branch_prefix}_$CURRENT_DATE"

    log_message "Creating sync branch: $branch_name (from $source_branch to $target_branch)."
    
    # Switch to target branch first
    checkout_and_pull "$target_branch"
    
    # Create or switch to sync branch
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        log_message "Branch $branch_name already exists. Switching to it."
        git checkout "$branch_name" || handle_error "Failed to switch to existing branch $branch_name."
    else
        log_message "Creating new branch: $branch_name."
        git checkout -b "$branch_name" || handle_error "Failed to create branch $branch_name."
    fi
    
    # Merge source branch into sync branch
    log_message "Merging $source_branch into $branch_name."
    git pull origin "$source_branch" --ff || handle_error "Failed to merge $source_branch into $branch_name."
    
    # Check for additional commits
    if git ls-remote --exit-code --heads origin "$branch_name" >/dev/null 2>&1 && [[ $(git rev-list --count HEAD ^origin/"$branch_name" 2>/dev/null || echo "0") -gt 0 ]]; then
        log_message "There are additional commits in $branch_name that are not in $source_branch."
        log_message "Changes between $source_branch and $branch_name:"
        git log --oneline "origin/$source_branch..$branch_name" 2>/dev/null || echo "No commits to show"
    else
        log_message "No additional commits in $branch_name compared to $source_branch."
    fi
    
    # Push sync branch
    git push origin "$branch_name" || handle_error "Failed to push changes to $branch_name."
    
    # Create and merge GitLab MR
    create_and_merge_gitlab_mr "$branch_name" "$target_branch" "$branch_prefix"
}

# Function to create and merge GitLab MR
create_and_merge_gitlab_mr() {
    local branch_name=$1
    local target_branch=$2
    local branch_prefix=$3
    
    log_message "Creating GitLab merge request..."
    
    local mr_output
    mr_output=$(glab mr create \
        --source-branch "$branch_name" \
        --target-branch "$target_branch" \
        --title "Sync: $branch_prefix" \
        --description "Automated branch synchronization: $branch_prefix" \
        --label "$MR_LABELS" \
        -y 2>/dev/null || echo "MR creation failed")
    
    echo "$mr_output"
    
    local mr_id
    mr_id=$(echo "$mr_output" | grep -oP '\d+' | head -n 1)
    
    if [[ -n "$mr_id" ]]; then
        log_message "Merge request created: !$mr_id"
        
        if [[ "$AUTO_MERGE" == "true" ]]; then
            log_message "Auto-merging in $MERGE_DELAY seconds..."
            sleep "$MERGE_DELAY"
            
            # Retry logic for merge
            local max_retries=3
            local retry_count=0
            
            while [ $retry_count -lt $max_retries ]; do
                if glab mr merge "$mr_id" --yes --auto-merge 2>/dev/null; then
                    log_message "Merged MR !$mr_id successfully!"
                    break
                else
                    retry_count=$((retry_count + 1))
                    if [ $retry_count -lt $max_retries ]; then
                        log_message "Merge failed, retrying in 3 seconds... (Attempt $retry_count of $max_retries)"
                        sleep 3
                    else
                        log_message "Failed to merge after $max_retries attempts. Please check manually."
                        return 1
                    fi
                fi
            done
        else
            log_message "Auto-merge disabled. Please merge manually: !$mr_id"
        fi
    else
        log_message "Failed to extract MR ID. Please check GitLab manually."
    fi
}

# Function to delete branches except specified ones
delete_branches_except() {
    local branches_to_keep=("$@")
    
    # Convert the array to a grep pattern
    local keep_pattern=$(printf "|%s" "${branches_to_keep[@]}")
    keep_pattern="${keep_pattern:1}"  # Remove the leading '|'
    
    # Get the list of branches to delete
    local branches_to_delete
    branches_to_delete=$(git branch | grep -vE "(^\*|${keep_pattern})" | sed 's/^[ \t]*//' || echo "")
    
    # If no branches to delete, exit
    if [ -z "$branches_to_delete" ]; then
        log_message "No branches to delete."
        return
    fi
    
    # Delete the branches
    log_message "Deleting branches:"
    echo "$branches_to_delete"
    echo "$branches_to_delete" | xargs git branch -D
}

# Main execution
if [[ -z "$SYNC_TYPE" ]]; then
    show_usage
    exit 1
fi

# Stash any uncommitted changes
git stash push -q -m "sync_branches_auto_stash_$(date +%s)" || true

case "$SYNC_TYPE" in
    cleanup)
        log_message "Starting cleanup process..."
        checkout_and_pull "$DEFAULT_BRANCH"
        delete_branches_except "${PROTECTED_BRANCHES[@]}"
        ;;
    *)
        # Check if sync type exists in configuration
        if [[ -n "${SYNC_CONFIGS[$SYNC_TYPE]}" ]]; then
            # Parse sync configuration
            IFS=':' read -r source_branch target_branch branch_prefix <<< "${SYNC_CONFIGS[$SYNC_TYPE]}"
            
            log_message "Starting sync: $SYNC_TYPE ($source_branch -> $target_branch)"
            checkout_and_pull "$source_branch"
            checkout_and_pull "$target_branch"
            create_merge_push "$source_branch" "$target_branch" "$branch_prefix"
        else
            echo "❌ Unknown sync type: $SYNC_TYPE"
            show_usage
            exit 1
        fi
        ;;
esac

# Restore stashed changes
git stash pop -q 2>/dev/null || true

log_message "Script completed successfully."

