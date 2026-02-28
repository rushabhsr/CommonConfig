# Generic Git Branch Synchronization Script

A powerful and configurable script for automating git branch synchronization workflows with support for GitLab and GitHub.

## Features

- **Configurable Sync Workflows**: Define custom branch sync patterns
- **GitLab & GitHub Support**: Automatic MR/PR creation and merging
- **Safe Operations**: Automatic stashing and branch cleanup
- **Flexible Configuration**: External config files for different projects
- **Retry Logic**: Robust merge handling with automatic retries
- **Branch Cleanup**: Automated cleanup of old sync branches

## Quick Start

1. **Copy files to your project directory:**
   ```bash
   cp ~/CommonConfig/sync_branches.sh /path/to/your/project/
   cp ~/CommonConfig/sync_branches.config.example /path/to/your/project/sync_branches.config
   ```

2. **Edit configuration:**
   ```bash
   nano sync_branches.config
   ```

3. **Make executable:**
   ```bash
   chmod +x sync_branches.sh
   ```

## Configuration

Edit `sync_branches.config` with your settings:

```bash
# Date format for branch naming
DATE_FORMAT="%d%m%Y"

# Default branch for cleanup operations
DEFAULT_BRANCH="development"

# Protected branches (won't be deleted during cleanup)
PROTECTED_BRANCHES=("main" "master" "development" "staging" "production" "uat" "qa")

# Platform configuration
USE_GITLAB="true"
USE_GITHUB="false"

# Merge settings
AUTO_MERGE="true"
MERGE_DELAY="6"
MR_LABELS="sync,automated"

# Sync configurations
declare -A SYNC_CONFIGS=(
    ["prod-to-uat"]="production:uat:prod_to_uat_sync"
    ["uat-to-qa"]="uat:qa:uat_to_qa_sync"
    ["qa-to-dev"]="qa:development:qa_to_dev_sync"
)
```

## Usage

### Basic Commands

```bash
# Sync production to UAT
./sync_branches.sh prod-to-uat

# Sync UAT to QA
./sync_branches.sh uat-to-qa

# Sync QA to development
./sync_branches.sh qa-to-dev

# Clean up old branches
./sync_branches.sh cleanup
```

### Custom Configuration

```bash
# Use custom config file
./sync_branches.sh prod-to-uat --config=./my_project.config

# Different project setup
./sync_branches.sh staging-to-main --config=./production.config
```

## Sync Workflow

### What the script does:

1. **Stash Changes**: Automatically stashes any uncommitted changes
2. **Branch Preparation**: Checks out and pulls latest changes from source and target branches
3. **Sync Branch Creation**: Creates a dated sync branch (e.g., `prod_to_uat_sync_03122025`)
4. **Merge Operation**: Merges source branch into sync branch
5. **Push & MR/PR**: Pushes sync branch and creates merge request/pull request
6. **Auto-Merge**: Optionally auto-merges the MR/PR after a delay
7. **Cleanup**: Restores stashed changes

### Example Workflow:
```
production → prod_to_uat_sync_03122025 → uat
     ↓              ↓                      ↓
  (source)    (sync branch)          (target)
```

## Platform Support

### GitLab Integration
- Uses `glab` CLI tool
- Creates merge requests with labels
- Supports auto-merge with retry logic
- Handles GitLab-specific MR operations

### GitHub Integration  
- Uses `gh` CLI tool
- Creates pull requests
- Supports auto-merge functionality
- Handles GitHub-specific PR operations

## Configuration Options

### Sync Configuration Format
```bash
["sync-name"]="source_branch:target_branch:branch_prefix"
```

**Example:**
```bash
["prod-to-uat"]="production:uat:prod_to_uat_sync"
```
- **sync-name**: Command line argument
- **source_branch**: Branch to sync from
- **target_branch**: Branch to sync to  
- **branch_prefix**: Prefix for sync branch name

### Date Formats
```bash
DATE_FORMAT="%d%m%Y"    # 03122025
DATE_FORMAT="%Y%m%d"    # 20251203
DATE_FORMAT="%b%d"      # dec03
```

### Protected Branches
Branches listed in `PROTECTED_BRANCHES` won't be deleted during cleanup:
```bash
PROTECTED_BRANCHES=("main" "master" "development" "staging" "production")
```

## Advanced Usage

### Multiple Project Configurations

**Project A (GitLab):**
```bash
# project_a.config
USE_GITLAB="true"
USE_GITHUB="false"
SYNC_CONFIGS=(
    ["prod-to-uat"]="production:uat:prod_sync"
    ["uat-to-qa"]="uat:qa:uat_sync"
)
```

**Project B (GitHub):**
```bash
# project_b.config  
USE_GITLAB="false"
USE_GITHUB="true"
SYNC_CONFIGS=(
    ["main-to-staging"]="main:staging:main_sync"
    ["staging-to-dev"]="staging:development:staging_sync"
)
```

### Custom Workflows

```bash
# Emergency hotfix sync
["hotfix-to-prod"]="hotfix/critical:production:emergency_sync"

# Feature branch promotion
["feature-to-staging"]="feature/new-ui:staging:feature_promotion"

# Release preparation
["release-to-main"]="release/v2.1:main:release_sync"
```

## Error Handling

### Common Issues

1. **Config file not found**
   ```
   ❌ Configuration file not found: ./sync_branches.config
   ```
   **Solution**: Copy `sync_branches.config.example` to `sync_branches.config`

2. **Unknown sync type**
   ```
   ❌ Unknown sync type: invalid-sync
   ```
   **Solution**: Check available sync types in your config file

3. **Branch checkout failed**
   ```
   [ERROR] Failed to switch to production branch
   ```
   **Solution**: Ensure branch exists and you have proper permissions

4. **Merge conflicts**
   ```
   [ERROR] Failed to merge production into sync branch
   ```
   **Solution**: Resolve conflicts manually and re-run

### Retry Logic

The script includes automatic retry logic for:
- Merge request/pull request creation
- Auto-merge operations (3 attempts with 3-second delays)
- Network-related failures

## Requirements

### GitLab Projects
- `glab` CLI tool installed and configured
- GitLab project access with MR creation permissions
- Git repository with GitLab remote

### GitHub Projects  
- `gh` CLI tool installed and configured
- GitHub repository access with PR creation permissions
- Git repository with GitHub remote

### General Requirements
- Git 2.0+
- Bash 4.0+ (for associative arrays)
- Network access to Git remote

## Installation

### GitLab CLI (glab)
```bash
# Ubuntu/Debian
curl -s https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_linux_amd64.deb -o glab.deb
sudo dpkg -i glab.deb

# Configure
glab auth login
```

### GitHub CLI (gh)
```bash
# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# Configure  
gh auth login
```

## Security Notes

- Script automatically stashes uncommitted changes
- Protected branches prevent accidental deletion
- Retry logic prevents partial failures
- All operations are logged with timestamps

## Troubleshooting

### Debug Mode
Add debug output by modifying the script:
```bash
set -ex  # Enable debug mode
```

### Manual Recovery
If script fails mid-execution:
```bash
# Check current branch
git branch

# Restore stashed changes
git stash pop

# Clean up sync branches manually
git branch -D sync_branch_name
```

### Log Analysis
All operations are logged with timestamps:
```bash
[INFO] 2025-12-03 20:30:15 - Starting sync: prod-to-uat
[INFO] 2025-12-03 20:30:16 - Switching to production branch
[INFO] 2025-12-03 20:30:18 - Creating sync branch: prod_to_uat_sync_03122025
```

## License

This script is provided as-is for git workflow automation purposes.
