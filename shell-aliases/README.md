# Kiro AI Agent System

A portable, self-bootstrapping AI development environment that turns `kiro-cli` into a multi-agent platform with persistent memory, 229+ skills, structured workflows, and cross-project orchestration.

## First-Time Setup (New Device)

```bash
# 1. Clone this repo
git clone git@github.com:rushabhsr/CommonConfig.git ~/CommonConfig

# 2. Run bootstrap (installs everything)
bash ~/CommonConfig/kiro-bootstrap.sh

# 3. Reload shell
source ~/.bashrc
```

**That's it.** The bootstrap handles:
- iii-engine + agentmemory (persistent memory server)
- 229+ skills from 8 curated GitHub repos → `~/ai-toolkit/skills/`
- MCP wiring (agentmemory → kiro-cli)
- Custom slash commands → `~/.kiro/skills/`
- `.bashrc` updates (PATH, sources, agentmemory auto-start)
- Agents auto-create for all projects in `~/applications/`

### Prerequisites

- `git`, `node` (v20+), `npm`
- `kiro-cli` installed ([kiro.dev](https://kiro.dev))
- `jq` (optional, for agent info display)

### Project Structure

```
~/applications/          ← Your projects (agents auto-created per folder)
  ├── ArtTales/          → React, Next.js, TypeScript
  ├── metaxis/           → React
  ├── karmine/           → MySQL
  ├── rm-law/            → React
  └── ...

~/ai-toolkit/            ← Skills & tools (cloned by bootstrap)
  ├── skills/            → 229 SKILL.md files from 8 repos
  │   ├── superpowers/         (202k⭐) TDD, debugging, planning
  │   ├── anthropic-skills/    (139k⭐) Official Anthropic skills
  │   ├── addy-agent-skills/   (44.6k⭐) Spec→Plan→Build→Test→Review→Ship
  │   ├── google-cloud-skills/ (10.3k⭐) GCP: BigQuery, Cloud Run, Firebase
  │   ├── techleads-skills/    (4.4k⭐) AWS, Playwright, Figma, security
  │   ├── cloudflare-skills/   (1.6k⭐) Workers, Agents SDK, Durable Objects
  │   ├── letta-skills/        (105⭐) GitHub, Slack, Notion, Discord, PDF
  │   └── agent-browser/       Browser automation, Electron, QA/dogfood
  └── tools/             → Always-on tools
      ├── caveman/             Context compression (~75% token savings)
      ├── graphify/            Code → knowledge graph
      └── ai-engineering-toolkit/  Prompt eval, RAG design, agent safety

~/CommonConfig/          ← This repo (portable across devices)
  ├── kiro-bootstrap.sh  → One-command setup
  ├── kiro-skills/       → Custom slash commands
  └── shell-aliases/
      └── kiroAliases.sh → All agent logic
```

---

## Quick Reference

| Command | What It Does |
|---------|-------------|
| `kiro` | Smart start — auto-detects project from `pwd` |
| `kiro-cli` | Resume last chat in current directory |
| `kiro-<project>` | Start agent for a project (READ mode) |
| `k-<project>` | Start agent for a project (WRITE mode) |
| `kd <project>` | Single-project AIDLC driver (full lifecycle) |
| `km` | Cross-project master orchestrator |

### Slash Commands (inside a session)

| Command | What It Does |
|---------|-------------|
| `/git-review` | Review current git diff for bugs/issues |
| `/git-commit-msg` | Generate conventional commit from staged changes |
| `/git-pr-desc` | Generate PR description from branch commits |
| `/orchestrate` | Spawn project-specific sub-agents for cross-project work |

---

## Persistent Memory (agentmemory)

All agents share a persistent memory server that eliminates re-explaining across sessions.

| Command | What It Does |
|---------|-------------|
| `mem-start` | Start agentmemory (auto-starts on shell login) |
| `mem-stop` | Stop the server |
| `mem-status` | Check health |
| `mem-viewer` | Open web UI at localhost:3113 |
| `mem-search <query>` | Search memory from terminal |

**How it works:** agentmemory captures observations from every session via MCP hooks, compresses them into searchable memory, and injects relevant context (~2000 tokens) at the start of each new session. 92% fewer tokens vs loading full context.

**Data location:** `~/data/state_store.db` (iii-engine KV store)

---

## Skills Management

| Command | What It Does |
|---------|-------------|
| `kiro-skills-catalog` | Show all available skills (229+) |
| `kiro-skills-pull` | `git pull` all skill repos |
| `kiro-skills-add <repo>` | Install from any GitHub repo via `npx skills` |
| `kiro-skills-find` | Search the skills ecosystem |

Skills are auto-discovered from `~/ai-toolkit/` and included in agent prompts. Always-on skills (every session): **caveman**, **caveman-compress**, **graphify**.

---

## Agent Management

```bash
kiro-cleanup                # Delete all agents and history
kiro-regenerate <name>      # Recreate agent with fresh tech detection
kiro-regenerate-all         # Recreate all agents
kiro-edit-prompt <name>     # Edit agent JSON directly
kiro-agents                 # List all agent files
kiro-show <name>            # Pretty-print agent JSON
```

---

## Agent Squad & Permissions

```bash
kiro-squad-list             # List all agent roles
kiro-agent-info <role>      # Show tools/skills/permissions
kiro-permissions            # Display full permission matrix
```

Roles: `dev`, `test`, `quality`, `security`, `contract`, `performance`, `refactor`, `ria-read`, `ria-plan`, `ria-write`, `master`, `pr-review`, `release`, `devops`

**Rule: No agent can ever merge. Only you.**

---

## Repo Intelligence Agent (RIA)

```bash
kiro-ria <project> READ     # Answer questions, trace flows
kiro-ria <project> PLAN     # Impact analysis, change proposals
kiro-ria <project> WRITE    # Branch + patch + Draft MR (requires confirmation)
kiro-ria-status             # Show current mode
```

---

## Knowledge Indexing

```bash
kiro-knowledge-rebuild [dir]    # Full rebuild (index + deps + API map)
kiro-knowledge-status [dir]     # Show index freshness
```

Creates `<project>/.kiro/knowledge/`: code-index.json, dependency-graph.json, api-map.json, symbols.json, summaries.md

---

## AIDLC Workflow

```bash
kiro-aidlc-init [dir]       # Copy AIDLC steering rules to a project
kiro-aidlc-status [dir]     # Check phase status
```

Phases: **Inception** (requirements, design) → **Construction** (implement, test) → **Operations** (deploy, monitor)

---

## Workflows

### Single-Project Requirement
```bash
cd ~/applications/metaxis
kd .
# "Add dark mode toggle to the settings page"
# Agent drives: Inception → Construction → Operations
```

### Cross-Project Requirement
```bash
km
# "Add blog API in karmine and display posts in metaxis"
# Master spawns karmine agent (API) → metaxis agent (frontend)
```

### Quick Fix
```bash
k-metaxis
# "Fix the null check in Header.tsx line 12"
# Direct WRITE mode, no ceremony
```

### Inside a Session
```
> /git-review          ← review your current diff
> /git-commit-msg      ← generate commit message
> /orchestrate         ← delegate to other project agents
```

---

## Updating

```bash
# Update all skill repos
kiro-skills-pull

# Update agentmemory
npm update -g @agentmemory/agentmemory

# Regenerate agents after kiroAliases.sh changes
kiro-regenerate-all
```

---

## Architecture

```
You (Human) ← final authority, only one who merges
  │
  ├── Master Orchestrator (km) ← cross-project coordination
  │     └── spawns project-specific sub-agents
  │
  └── AIDLC Driver (kd) ← single-project full lifecycle
        └── coordinates agent squad internally

Per-Project Agent Squad:
  Dev → Test → Quality → Security → Contract → Performance → Refactor
                              ↓
                    RIA (Repo Intelligence)

Infrastructure (always running):
  agentmemory ← persistent memory across all sessions
  caveman     ← token compression when context gets long
  graphify    ← code knowledge graphs
```
