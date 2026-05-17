# Kiro AI Agent System

A shell-based AI agent orchestration system that turns `kiro-cli` into a multi-agent development platform with structured workflows, permission enforcement, and knowledge indexing.

## Setup

### Prerequisites

- `kiro-cli` installed and configured
- `jq` (optional, for agent info display)
- `git` for version control operations

### Installation

```bash
# 1. Source the aliases in your shell
echo 'source ~/CommonConfig/shell-aliases/kiroAliases.sh' >> ~/.bashrc
source ~/.bashrc

# 2. Install AI Engineering Toolkit skills
git clone https://github.com/viliawang-pm/ai-engineering-toolkit.git ~/applications/ai-engineering-toolkit
cp -r ~/applications/ai-engineering-toolkit/skills/* ~/.kiro/skills/

# 3. Install AIDLC workflow rules (from aidlc-workflows repo)
cp -R <aidlc-workflows>/aidlc-rules/aws-aidlc-rules ~/.kiro/steering/
cp -R <aidlc-workflows>/aidlc-rules/aws-aidlc-rule-details ~/.kiro/

# 4. Verify
kiro-help
```

### Project Structure Expected

```
~/applications/
  ├── user-service/
  ├── payment-gateway/
  ├── frontend-app/
  └── ...

~/my_applications/
  └── ...
```

Agents are auto-created per project directory.

---

## Quick Reference

| Command | What It Does |
|---------|-------------|
| `kiro` | Smart start — auto-detects project from `pwd` |
| `kiro-<svc>` | Start agent for a service (READ mode) |
| `k-<svc>` | Start agent for a service (WRITE mode) |
| `kd <svc>` | **Single-service AIDLC driver** (full lifecycle) |
| `km` | **Cross-service master orchestrator** (full lifecycle) |

---

## Commands

### Basic Agent Management

```bash
kiro                        # Auto-detect project, start agent
kiro-<project>              # Start specific project agent (READ mode)
k-<project>                 # Start specific project agent (WRITE mode)
kiro-cleanup                # Delete all agents and history
kiro-regenerate <name>      # Recreate agent with fresh tech detection
kiro-regenerate-all         # Recreate all agents
kiro-edit-prompt <name>     # Edit agent JSON directly
```

### AIDLC-Driven Development

```bash
# Single service — full AIDLC + AI Engineering Toolkit
kd user-service             # or: kiro-drive user-service
kiro-drive                  # Uses current directory

# Multi-service — orchestrates across all services
km                          # or: kiro-master
```

Both `kd` and `km` enforce:
- **AIDLC phases**: Inception → Construction → Operations
- **AI Engineering Toolkit**: Prompt Evaluator, Context Budget Planner, RAG Architect, Agent Safety Guard, Eval Harness Builder, Product Sense Coach

### Agent Squad

```bash
kiro-squad-list             # List all agent roles
kiro-squad-pipeline <svc>   # Show pipeline order for a service
kiro-agent-info <role>      # Show tools/skills/permissions for a role
kiro-permissions            # Display full permission matrix
```

Available roles: `dev`, `test`, `quality`, `security`, `contract`, `performance`, `refactor`, `ria-read`, `ria-plan`, `ria-write`, `master`, `pr-review`, `release`, `devops`

### Repo Intelligence Agent (RIA)

```bash
kiro-ria <svc> READ         # Default — answer questions only
kiro-ria <svc> PLAN         # Impact analysis, change proposals
kiro-ria <svc> WRITE        # Branch + patch + MR (requires confirmation)
kiro-ria-status             # Show current mode
```

### Knowledge Indexing

```bash
kiro-knowledge-init [dir]       # Initialize knowledge directory
kiro-knowledge-index [dir]      # Build code file index
kiro-knowledge-deps [dir]       # Build dependency graph (imports)
kiro-knowledge-api [dir]        # Build API route map
kiro-knowledge-rebuild [dir]    # Full rebuild (all above)
kiro-knowledge-status [dir]     # Show index freshness
```

Creates under `<project>/.kiro/knowledge/`:
- `code-index.json` — file inventory with line counts
- `dependency-graph.json` — import/require edges
- `api-map.json` — routes, handlers, endpoints
- `symbols.json` — functions, classes, exports
- `summaries.md` — human-readable overview

### AIDLC Workflow

```bash
kiro-aidlc-init [dir]       # Copy AIDLC steering rules to a project
kiro-aidlc-status [dir]     # Check which phases have been completed
```

### Git + AI

```bash
gcai                        # Generate commit message from staged changes
greview                     # AI review of current diff
greview-staged              # AI review of staged changes
gpr-desc                    # Generate PR description
gpr-desc-from <branch>      # PR description from custom base
gexplain [base] [head]      # Explain diff between branches
```

---

## Architecture

### Agent Hierarchy

```
You (Human) ← final authority, only one who merges
  │
  ├── Master Orchestrator (km) ← cross-service coordination
  │     └── delegates to per-service agents
  │
  └── AIDLC Driver (kd) ← single-service full lifecycle
        └── coordinates agent squad internally

Per-Service Agent Squad:
  Dev → Test → Quality → Security → Contract → Performance → Refactor
                              ↓
                    RIA (Repo Intelligence)
```

### Permission Model

Every agent has declared tools, skills, and hard restrictions.

```
Agent               Write Code   Git Access   MR Create   Merge
─────────────────────────────────────────────────────────────────
Dev Agent              ✅           ✅            ❌         ❌
Test Agent             ❌           ❌            ❌         ❌
Quality Agent          ✅           ❌            ❌         ❌
Security Agent         ❌           ❌            ❌         ❌
RIA (READ)             ❌           ❌            ❌         ❌
RIA (WRITE)            ✅           ✅            ✅         ❌
Master Agent           ❌           ❌            ❌         ❌
```

**Rule: No agent can ever merge. Only you.**

### RIA Modes

| Mode | Can Do | Cannot Do |
|------|--------|-----------|
| READ | Answer questions, trace flows, explain code | Modify anything |
| PLAN | Generate impact-analysis.md, proposed-diff.patch | Edit files |
| WRITE | Create branch, apply patch, open Draft MR | Merge, approve, push to protected branches |

---

## Workflows

### Single-Service Requirement (Recommended)

```bash
cd ~/applications/user-service
kd .
# Describe: "Add email verification to signup flow"
# Agent drives: Inception → Construction → Operations
```

### Cross-Service Requirement

```bash
km
# Describe: "Add SSO across user-service and admin-portal"
# Agent coordinates both services through AIDLC
```

### Quick Fix (No Ceremony)

```bash
k-user-service
# "Fix the null pointer in auth.py line 42"
# Direct WRITE mode, no AIDLC overhead
```

### Knowledge-First Approach

```bash
cd ~/applications/payment-gateway
kiro-knowledge-rebuild
kiro-ria payment-gateway READ
# "What happens when a refund is initiated?"
# "Which services depend on the webhook handler?"
```

---

## How AIDLC Works

1. **You describe a requirement** in natural language
2. **Inception**: Agent writes questions to a markdown file → you answer → agent generates design docs
3. **Construction**: Agent implements following TDD, runs the agent squad pipeline
4. **Operations**: Agent produces deployment notes

At each phase gate, you review and approve before proceeding.

Key principle: **Questions go into files, not chat.** This creates a durable decision record.

---

## Tips

- Run `kiro-knowledge-rebuild` after major changes to keep RIA accurate
- Use `kiro-aidlc-init` on new projects before starting `kd`
- `kiro-permissions` is your quick reference for what each agent can touch
- Install `jq` for pretty-printed agent definitions via `kiro-agent-info`
- Agents are stored in `~/.kiro/agents/*.json` — fully editable
