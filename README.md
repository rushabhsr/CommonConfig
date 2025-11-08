# CommonConfig

A collection of shell utilities and aliases for development workflow automation, particularly focused on Python/Django projects and Docker management.

## 📁 Repository Structure

```
CommonConfig/
├── ZunoCommonFunc.sh          # Django project aliases and Docker log functions
├── fyndCommonFunc.sh          # Database utilities and Kubernetes helpers
├── commFuncParams.sh          # Docker cleanup and SSH agent management
├── create_and_run_port_forward.sh  # WSL port forwarding automation
└── README.md
```

## 🚀 Quick Start

1. **Clone the repository**:
   ```bash
   git clone git@github.com:rushabhsr/CommonConfig.git ~/CommonConfig
   ```

2. **Auto-source all scripts** (adds to ~/.bashrc):
   ```bash
   for file in ~/CommonConfig/*.sh; do echo "source $file" >> ~/.bashrc; done
   ```

3. **Reload your shell**:
   ```bash
   exec $SHELL
   ```

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
source ~/CommonConfig/ZunoCommonFunc.sh      # Django aliases
source ~/CommonConfig/commFuncParams.sh      # Docker utilities
source ~/CommonConfig/fyndCommonFunc.sh      # Database/K8s helpers
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
./create_and_run_port_forward.sh 3000
```
