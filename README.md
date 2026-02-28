# CommonConfig

A collection of shell utilities and aliases for development workflow automation, particularly focused on Python/Django projects, Docker management, database operations, and git workflows.

## 📁 Repository Structure

```
CommonConfig/
├── README.md
├── .gitignore
│
├── docs/                              # Documentation
│   └── KIRO_CLI_GUIDE.md             # Complete guide for Kiro CLI usage
│
├── shell-aliases/                     # Shell functions to be sourced
│   ├── ZunoCommonFunc.sh             # Django/Docker aliases
│   ├── fyndCommonFunc.sh             # Database/K8s utilities
│   ├── commFuncParams.sh             # Docker cleanup/SSH agent
│   ├── gitAliases.sh                 # 100+ Git aliases (from oh-my-bash)
│   └── shellHistory.sh               # History config with up arrow search
│
├── db-managers/                       # Database management tools
│   ├── postgres_db_manager.sh
│   ├── clickhouse_db_manager.sh
│   ├── *.config.example
│   └── README_*.md
│
├── git-tools/                         # Git utilities
│   ├── sync_branches.sh
│   └── README_sync_branches.md
│
├── network-tools/                     # Network utilities
│   └── create_and_run_port_forward.sh
│
└── checklist-generator/               # Checklist/planner tools
    ├── generate_checklist.py
    ├── checklist_config.csv
    └── templates (html/md)
```

## 🚀 Quick Start

### Automatic Setup (Recommended)

1. **Clone the repository**:
   ```bash
   git clone git@github.com:rushabhsr/CommonConfig.git ~/CommonConfig
   ```

2. **Add all shell aliases to your system**:
   
   For **bash** users (adds to `~/.bashrc`):
   ```bash
   for file in ~/CommonConfig/shell-aliases/*.sh; do 
     echo "source \"$file\"" >> ~/.bashrc
   done
   ```
   
   For **zsh** users (adds to `~/.zshrc`):
   ```bash
   for file in ~/CommonConfig/shell-aliases/*.sh; do 
     echo "source \"$file\"" >> ~/.zshrc
   done
   ```

3. **Reload your shell**:
   ```bash
   source ~/.bashrc  # or source ~/.zshrc for zsh
   # OR restart terminal
   exec $SHELL
   ```

### Verify Installation

Test that aliases are loaded:
```bash
# Test git aliases
gst  # Should show git status

# Test utility functions
type dockerclean  # Should show function definition
type getCM        # Should show function definition
```

### What Gets Added

All `.sh` files from `shell-aliases/` directory:
- ✅ `ZunoCommonFunc.sh` - Django/Docker log functions
- ✅ `fyndCommonFunc.sh` - K8s/Database utilities  
- ✅ `commFuncParams.sh` - Docker cleanup & SSH agent
- ✅ `gitAliases.sh` - 100+ git shortcuts
- ✅ `shellHistory.sh` - Enhanced history search
- ✅ `kiroAliases.sh` - Kiro CLI integration (if present)

## 📋 Features

### Django Development Aliases
- `cms`, `cmsops`, `cas`, `cmspay`, `audit` - Quick navigation with venv activation
- `runserver`, `runcas`, `runops`, `runpay` - Django server shortcuts
- `migrate`, `mm`, `dbshell` - Database management
- `cascelery`, `cmscelery`, `opscelery` - Celery worker shortcuts

### Docker Log Functions
- `opslogs [lines]`, `payclogs [lines]`, `caslogs [lines]` - Service-specific log tailing
- `dockerclean [prefix]` - Clean containers/images by prefix or full system prune

### Utilities
- `getDbUrl <pattern>` - Extract database URLs (macOS clipboard integration)
- `getCM <id> <description> [complete%] [hours]` - Format commit messages
- `conPod <name>` - Connect to Kubernetes pods
- `DEBUG <message>` - Timestamped debug logging

### WSL Port Forwarding
- `create_and_run_port_forward.sh [port]` - Automated WSL to Windows port forwarding

## 🔧 Configuration

### Shell Compatibility
- Primary: `bash` (modify `~/.bashrc`)
- For `zsh`: Use `~/.zshrc` instead
- For `fish`: Manual adaptation required

### Customization
Edit individual `.sh` files to match your:
- Project paths
- Service names  
- Docker container names
- Database connection files

## ⚠️ Important Notes

- **Review scripts before sourcing** - Contains hardcoded paths specific to the author's setup
- **SSH agent management** - Automatically starts if not running
- **macOS dependencies** - Some functions use `pbcopy` (clipboard)
- **Docker permissions** - Some commands require `sudo`

## 🛠️ Manual Setup (Alternative)

Source individual scripts as needed:
```bash
source ~/CommonConfig/shell-aliases/ZunoCommonFunc.sh      # Django aliases
source ~/CommonConfig/shell-aliases/commFuncParams.sh      # Docker utilities
source ~/CommonConfig/shell-aliases/fyndCommonFunc.sh      # Database/K8s helpers
source ~/CommonConfig/shell-aliases/gitAliases.sh          # Git aliases
source ~/CommonConfig/shell-aliases/shellHistory.sh        # History with up arrow search
```

## 📝 Usage Examples

```bash
# Navigate to project and activate venv
cms

# Run Django server on specific port
runcas  # Runs on port 8005

# View last 50 lines of service logs
opslogs 50

# Clean all Docker resources with 'test' prefix
dockerclean test

# Forward WSL port 3000 to Windows
./network-tools/create_and_run_port_forward.sh 3000

# Use git aliases
gst              # git status
gco main         # git checkout main
gcam "message"   # git commit -all -message
glog             # pretty git log
```

## 📚 Additional Features

### Git Aliases (100+ aliases)
- `gst` - git status
- `gco` - git checkout
- `gcb` - git checkout -b (new branch)
- `glog` - pretty git log with graph
- `gp` - git push
- `gl` - git pull
- And many more! See `shell-aliases/gitAliases.sh`

### Shell History with Up Arrow Search
- Type partial command and press ↑ to search history
- Example: Type "git" and press ↑ to cycle through git commands
- Increased history size (10,000 commands)
- Duplicate removal and timestamps
