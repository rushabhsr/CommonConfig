# CommonConfig

Shell utilities, AI agent management, and development workflow automation for Python/Django, Docker, databases, and git workflows.

## 📁 Repository Structure

```
CommonConfig/
├── README.md
├── .gitignore
│
├── shell-aliases/                     # Shell functions to be sourced
│   ├── kiroAliases.sh                # Kiro AI agent management (core)
│   ├── ZunoCommonFunc.sh             # Django/Docker aliases
│   ├── fyndCommonFunc.sh             # Database/K8s utilities
│   ├── commFuncParams.sh             # Docker cleanup/SSH agent/system aliases
│   ├── gitAliases.sh                 # 100+ Git aliases (from oh-my-bash)
│   └── shellHistory.sh               # History config with up arrow search
│
├── kiro-skills/                       # AI skills (caveman, graphify, orchestrate)
│   ├── caveman/                       # Token compression
│   ├── caveman-compress/              # File compression scripts
│   ├── caveman-commit/                # Commit message generation
│   ├── caveman-review/                # Code review
│   ├── cavecrew/                      # Multi-agent coordination
│   ├── graphify/                      # Code → knowledge graph
│   └── orchestrate/                   # Cross-project delegation
│
├── kiro-bootstrap.sh                  # Auto-generate agent configs from projects
├── setup-ai-toolkit.sh                # Clone and setup ai-toolkit repos
│
├── db-managers/                       # Database management tools
│   ├── postgres_db_manager.sh
│   ├── clickhouse_db_manager.sh
│   └── *.config.example
│
├── git-tools/                         # Git utilities
│   └── sync_branches.sh
│
├── network-tools/                     # Network utilities
│   └── create_and_run_port_forward.sh
│
├── checklist-generator/               # Checklist/planner tools
│   └── generate_checklist.py
│
└── docs/
    └── KIRO_CLI_GUIDE.md
```

## 🚀 Quick Start

### Setup

```bash
git clone git@github.com:rushabhsr/CommonConfig.git ~/CommonConfig

# Add all shell aliases (bash)
for file in ~/CommonConfig/shell-aliases/*.sh; do 
  echo "source \"$file\"" >> ~/.bashrc
done

source ~/.bashrc
```

### Verify

```bash
kiro-help    # Show all Kiro AI commands
gst          # git status
kiro-status  # Agent & memory health
```

## 🤖 Kiro AI Agent Architecture

### Agent Types

| Command | Agent | Purpose |
|---------|-------|---------|
| `kiro` | Auto-detected | Smart start from current project dir |
| `k-<project>` | Service agent | Resume session for specific project |
| `kf-<project>` | Service agent | **Fresh** session (no resume) |
| `ka` | Assistant | Tasks, emails, notes → persists to `~/assistant/` |
| `kr` | Research | General exploration, not tied to any project |
| `kq` | Query Master | Read-only search across ALL service codebases |
| `km <ID>` | Master | Cross-service orchestrator, inits from `~/requirements/<ID>/` |
| `kpr` | PR Review | Multi-MR review + deployment checklist |

### How It Works

```
~/applications/<project>/  →  Service agents (auto-created, auto-indexed)
~/requirements/<JIRA-ID>/  →  Master agents (BRDs, AIDLC docs, progress)
~/assistant/               →  Assistant agent persistent memory
~/.kiro/agents/            →  Agent JSON configs
~/.kiro/skills/            →  Global skills (symlinked into projects)
```

- **Service agents** auto-create when you first `cd ~/applications/<project> && kiro`
- **Knowledge base** auto-indexes the project on first creation (background)
- **Master agents** read BRDs, delegate to service agents, track progress in `~/requirements/<ID>/progress.md`
- **Assistant** persists notes/tasks/drafts to `~/assistant/` across sessions
- **Tab completion**: `km` + Tab autocompletes JIRA IDs from `~/requirements/`

### Management

```bash
kiro-status              # Agents, sessions, memory health, indexed count
kiro-agents              # List all agent names
kiro-show <name>         # View agent config
kiro-edit-prompt <name>  # Edit agent prompt
kiro-regenerate <name>   # Recreate agent
kiro-regenerate-all      # Recreate all
kiro-cleanup             # Delete all (auto-recreate on use)
```

### Skills & MCP

```bash
skill-add <repo>                # Install skill globally
skill-find [query]              # Search registry
kiro-skill-profile frontend     # Load frontend skill set
kiro-skill-profile backend      # Load backend skill set
kiro-skills-catalog             # Browse ai-toolkit skills
kiro-mcp-design                 # Full MCP (design tools + memory)
kiro-mcp-minimal                # Agentmemory only
```

### Git + AI

```bash
gcai            # Generate commit message from staged
greview         # Review current diff
greview-staged  # Review staged changes
gpr-desc        # Generate PR description
```

## 📋 Shell Aliases

### Django Development
- `cms`, `cmsops`, `cas`, `cmspay`, `audit` — Quick navigation with venv
- `runserver`, `runcas`, `runops`, `runpay` — Django server shortcuts
- `migrate`, `mm`, `dbshell` — Database management
- `cascelery`, `cmscelery`, `opscelery` — Celery workers

### Docker
- `opslogs [lines]`, `payclogs [lines]`, `caslogs [lines]` — Log tailing
- `dockerclean [prefix]` — Clean containers/images by prefix
- `dps`, `dpsa`, `dex`, `dlogs` — Docker shortcuts

### Utilities
- `getDbUrl <pattern>` — Extract database URLs
- `getCM <id> <description>` — Format commit messages
- `conPod <name>` — Connect to K8s pods
- `redis-clear [pattern]` — Clear Redis keys
- `spillover` — Track work session time

### Git (100+ aliases)
- `gst` — git status
- `gco` — git checkout
- `gcb` — git checkout -b
- `glog` — pretty log with graph
- `gp` / `gl` — push / pull

### System
- `ll`, `la`, `lt` — ls variants
- `ff`, `fd` — find file/directory
- `ports`, `myip` — network info
- `py`, `pip`, `venv`, `activate` — Python shortcuts

## 🔧 Configuration

### Shell Compatibility
- Primary: **bash** (`~/.bashrc`)
- Also works with **zsh** (`~/.zshrc`)

### Customization
Edit individual `.sh` files to match your project paths, service names, and Docker container names.

## ⚠️ Notes

- Review scripts before sourcing — contains paths specific to the author
- SSH agent auto-starts if not running
- Some commands require `sudo` (Docker)
- Memory server: `mem-start` / `mem-stop` / `mem-status`
