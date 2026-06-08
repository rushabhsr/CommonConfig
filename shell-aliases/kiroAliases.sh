#!/bin/bash
# ============================================================================
# Kiro CLI Aliases & Functions (v2 - optimized)
# Source: ~/CommonConfig/shell-aliases/kiroAliases.sh
# ============================================================================

# ============================================================================
# Core: Project Detection (matches kiro-bootstrap.sh logic)
# ============================================================================

_kiro_detect_stack() {
  local dir="${1%/}"
  if [ -f "$dir/manage.py" ]; then echo "Django, Python"; return; fi
  if [ -f "$dir/requirements.txt" ] && [ ! -f "$dir/package.json" ]; then echo "Python"; return; fi
  if [ -f "$dir/package.json" ]; then
    local pkg="$dir/package.json"
    grep -q '"express"' "$pkg" 2>/dev/null && echo "Express.js" && return
    grep -q '"fastify"' "$pkg" 2>/dev/null && echo "Fastify" && return
    grep -q '"@nestjs' "$pkg" 2>/dev/null && echo "NestJS" && return
    grep -q '"koa"' "$pkg" 2>/dev/null && echo "Koa" && return
    grep -q '"next"' "$pkg" 2>/dev/null && echo "React, Next.js" && return
    grep -q '"react"' "$pkg" 2>/dev/null && echo "React" && return
    grep -q '"vue"' "$pkg" 2>/dev/null && echo "Vue.js" && return
    grep -q '"@angular' "$pkg" 2>/dev/null && echo "Angular" && return
    [ -f "$dir/template.yaml" ] && echo "AWS Lambda, Node.js" && return
    echo "Node.js"; return
  fi
  [ -f "$dir/go.mod" ] && echo "Go" && return
  echo "General Development"
}

_kiro_detect_category() {
  local stack="$1"
  case "$stack" in
    *Django*|*Python*|*Express*|*Fastify*|*NestJS*|*Koa*|*Node.js*|*Lambda*) echo "backend" ;;
    *Next.js*) echo "fullstack" ;;
    *React*|*Vue*|*Angular*) echo "frontend" ;;
    *) echo "general" ;;
  esac
}

# ============================================================================
# Skills Block Generation (scans ai-toolkit/ only when called)
# ============================================================================

_extract_skill_desc() {
  local file="$1"
  sed -n '1s/^#[[:space:]]*//p' "$file" 2>/dev/null | head -1
}

generate_skills_block() {
  local toolkit_dir="$HOME/ai-toolkit"
  local block=""
  local max_desc=80
  local include_repos="ai-engineering-toolkit|superpowers|anthropic-skills|addy-agent-skills|kiro-on-demand"
  local skipped=0

  # Auto-discover skills from ai-toolkit/tools/*/skills/*/SKILL.md
  if [ -d "$toolkit_dir/tools" ]; then
    for skill_dir in "$toolkit_dir"/tools/*/skills/*/; do
      [ -d "$skill_dir" ] || continue
      local skill_name=$(basename "$skill_dir")
      local skill_file="$skill_dir/SKILL.md"
      local desc=""
      if [ -f "$skill_file" ]; then
        desc=$(_extract_skill_desc "$skill_file")
      fi
      [ -z "$desc" ] && desc="$skill_name skill"
      desc="${desc:0:$max_desc}"
      block="${block}\n- **${skill_name}**: ${desc}"
    done
  fi

  # Auto-discover skills from ai-toolkit/skills/*/  (cloned repos)
  if [ -d "$toolkit_dir/skills" ]; then
    while IFS= read -r -d '' skill_file; do
      local skill_name=$(basename "$(dirname "$skill_file")")
      local repo_name=$(echo "$skill_file" | sed "s|$toolkit_dir/skills/||" | cut -d'/' -f1)
      if ! echo "$repo_name" | grep -qE "$include_repos"; then
        skipped=$((skipped + 1))
        continue
      fi
      local desc=""
      desc=$(_extract_skill_desc "$skill_file")
      [ -z "$desc" ] && desc="$skill_name skill"
      desc="${desc:0:$max_desc}"
      block="${block}\n- **${skill_name}** [${repo_name}]: ${desc}"
    done < <(find "$toolkit_dir/skills" -name "SKILL.md" -print0 2>/dev/null)
  fi

  # Graphify (tool-level, no nested skills dir)
  if [ -d "$toolkit_dir/tools/graphify" ]; then
    block="${block}\n- **graphify**: Build queryable knowledge graphs from code — architecture mapping and dependency analysis"
  fi

  if [ $skipped -gt 0 ]; then
    block="${block}\n\n(+${skipped} more skills available in ~/ai-toolkit/skills/ — run kiro-skills-catalog to browse)"
  fi

  echo -e "$block"
}

# ============================================================================
# Core: Agent Creation (lean prompts, correct detection)
# ============================================================================

ensure_kiro_agent() {
  local agent_name="$1"
  local project_dir="${2%/}"
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"

  [ -f "$agent_file" ] && return 0
  mkdir -p "$HOME/.kiro/agents" "$HOME/.kiro/sessions"

  local stack=$(_kiro_detect_stack "$project_dir")
  local category=$(_kiro_detect_category "$stack")

  cat > "$agent_file" << EOF
{
  "name": "$agent_name",
  "description": "AI agent for $agent_name project ($stack)",
  "prompt": "You are an AI agent for the ${agent_name} project.\\n\\nTech: ${stack}\\nType: ${category}\\nPath: ${project_dir}/\\n\\nCode search strategy (ALWAYS follow):\\n1. Use knowledge search tool FIRST to find relevant code\\n2. Use /graphify to map dependencies and architecture\\n3. Use code tool (pattern_search, search_symbols) for precise lookups\\n4. Only read full files after locating the exact target\\n\\nUse caveman mode (compressed output) by default. Read before writing. Test after changes.",
  "tools": ["*"],
  "resources": ["skill://.kiro/skills/**/SKILL.md"],
  "welcomeMessage": "🚀 $agent_name ($stack) — $project_dir/\\n",
  "hooks": {
    "agentSpawn": [{"command": "bash -c 'echo \"📂 $agent_name ($stack) | $category\"'", "timeout_ms": 3000}],
    "stop": [{"command": "bash -c 'date >> ~/.kiro/sessions/$agent_name.log'", "timeout_ms": 2000}]
  }
}
EOF
  echo "✅ Agent created: $agent_name ($stack → $category)"

  # Ensure core slash commands are available in project-level skills
  _kiro_ensure_core_skills "$project_dir"

  # Auto-index codebase into knowledge base on first creation
  _kiro_auto_index "$agent_name" "$project_dir" &
  disown 2>/dev/null
}

# Ensure all / commands available: symlink .kiro/skills + add resource to agent JSON
_kiro_ensure_core_skills() {
  local project_dir="$1"
  local agent_name=$(basename "$project_dir")
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"
  # Symlink project .kiro/skills → global so relative skill:// paths resolve
  if [ -d "${project_dir}/.kiro" ]; then
    [ -e "${project_dir}/.kiro/skills" ] && [ ! -L "${project_dir}/.kiro/skills" ] && rm -rf "${project_dir}/.kiro/skills"
    [ ! -e "${project_dir}/.kiro/skills" ] && ln -sf "$HOME/.kiro/skills" "${project_dir}/.kiro/skills"
  fi
  # Ensure agent JSON has skill resource
  [ ! -f "$agent_file" ] && return 0
  python3 -c "
import json
with open('$agent_file') as f:
    d = json.load(f)
r = 'skill://.kiro/skills/**/SKILL.md'
if r not in d.get('resources', []):
    d['resources'] = d.get('resources', []) + [r]
    with open('$agent_file', 'w') as f:
        json.dump(d, f, indent=2)
" 2>/dev/null
  return 0
}

# Auto-index project into knowledge base (runs in background on first agent creation)
_kiro_auto_index() {
  local agent_name="$1"
  local project_dir="$2"
  local marker="$HOME/.kiro/sessions/.indexed-${agent_name}"
  [ -f "$marker" ] && return 0
  command kiro-cli knowledge add --name "$agent_name" --path "$project_dir" 2>/dev/null
  touch "$marker" 2>/dev/null
}

# ============================================================================
# Core: Smart kiro command
# ============================================================================

kiro() {
  local current_dir=$(pwd)

  if [[ "$current_dir" == "$HOME/applications/"* ]]; then
    local project_name=$(echo "${current_dir#$HOME/applications/}" | cut -d'/' -f1)
    local agent_name=$(echo "$project_name" | sed 's/_/-/g')
    local project_root="$HOME/applications/$project_name"

    ensure_kiro_agent "$agent_name" "$project_root"
    command kiro-cli chat --agent "$agent_name" --resume "$@"
  else
    command kiro-cli chat --resume "$@"
  fi
}

# Wrap bare kiro-cli: no args = resume last session
kiro-cli() {
  if [ $# -eq 0 ]; then
    command kiro-cli chat --resume
  else
    command kiro-cli "$@"
  fi
}

# ============================================================================
# Auto-generate per-project aliases
# ============================================================================

_kiro_create_aliases() {
  for dir in "$HOME/applications"/*/; do
    [ -d "$dir" ] || continue
    local folder=$(basename "$dir")
    [[ "$folder" == *" "* ]] && continue
    local agent=$(echo "$folder" | sed 's/_/-/g')

    alias "kiro-$folder"="ensure_kiro_agent '$agent' '${dir%/}' && cd '${dir%/}' && command kiro-cli chat --agent '$agent' --resume"
    alias "k-$folder"="ensure_kiro_agent '$agent' '${dir%/}' && cd '${dir%/}' && command kiro-cli chat --agent '$agent' --resume"
    alias "kf-$folder"="ensure_kiro_agent '$agent' '${dir%/}' && cd '${dir%/}' && command kiro-cli chat --agent '$agent'"
    alias "kl-$folder"="ensure_kiro_agent '$agent' '${dir%/}' && cd '${dir%/}' && command kiro-cli chat --agent '$agent' --resume-picker"
  done
}
_kiro_create_aliases

# Background: ensure agents exist for all projects
( for dir in "$HOME/applications"/*/; do
    [ -d "$dir" ] || continue
    local folder=$(basename "$dir")
    [[ "$folder" == *" "* ]] && continue
    local agent=$(echo "$folder" | sed 's/_/-/g')
    [ -f "$HOME/.kiro/agents/${agent}.json" ] && continue
    ensure_kiro_agent "$agent" "${dir%/}"
  done
) &>/dev/null &
disown 2>/dev/null

# ============================================================================
# Agent Management
# ============================================================================

kiro-cleanup() {
  echo "🧹 Cleaning up..."
  find "$HOME/.kiro/agents" -name "*.json" ! -name "*.example" -delete 2>/dev/null
  rm -f "$HOME/.kiro/.cli_bash_history"
  echo "✅ Done. Agents will auto-recreate on next use."
}

kiro-regenerate() {
  local agent_name="$1"
  [ -z "$agent_name" ] && echo "Usage: kiro-regenerate <agent-name>" && return 1

  local dir=""
  local folder=$(echo "$agent_name" | sed 's/-/_/g')
  [ -d "$HOME/applications/$agent_name" ] && dir="$HOME/applications/$agent_name"
  [ -d "$HOME/applications/$folder" ] && dir="$HOME/applications/$folder"
  [ -z "$dir" ] && echo "❌ Project not found: $agent_name" && return 1

  rm -f "$HOME/.kiro/agents/${agent_name}.json"
  ensure_kiro_agent "$agent_name" "$dir"
}

kiro-regenerate-all() {
  echo "🔄 Regenerating all agents..."
  find "$HOME/.kiro/agents" -name "*.json" ! -name "*.example" -delete 2>/dev/null
  for dir in "$HOME/applications"/*/; do
    [ -d "$dir" ] || continue
    local folder=$(basename "$dir")
    [[ "$folder" == *" "* ]] && continue
    local agent=$(echo "$folder" | sed 's/_/-/g')
    ensure_kiro_agent "$agent" "${dir%/}"
  done
  echo "✅ All agents regenerated"
}

kiro-edit-prompt() {
  local name="$1"
  [ -z "$name" ] && echo "Usage: kiro-edit-prompt <agent-name>" && return 1
  local f="$HOME/.kiro/agents/${name}.json"
  [ ! -f "$f" ] && echo "❌ Not found: $name" && return 1
  ${EDITOR:-vim} "$f"
}

# ============================================================================
# Master Orchestrator (cross-service, inits from ~/requirements/<ID>/)
# ============================================================================

kiro-master() {
  local jira_id="$1"
  shift 2>/dev/null
  local inline_prompt="$*"
  local agent_name="master-$(echo "$jira_id" | tr '[:upper:]' '[:lower:]')"
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"

  if [ -z "$jira_id" ]; then
    echo "Usage: km <JIRA-ID> [inline prompt]"
    echo ""
    echo "Examples:"
    echo "  km CLAIM-648"
    echo "  km CLAIM-626 \"Fix PG Diversion Summary not displaying in UI\""
    echo ""
    echo "Available:"
    ls ~/requirements/ 2>/dev/null | grep -v "^PR_Reviews$" | sed 's/^/  • /'
    return 1
  fi

  local req_dir="$HOME/requirements/$jira_id"
  mkdir -p "$req_dir"

  local brd_files=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    f=$(echo "$f" | sed 's/[&"\\]/\\&/g')
    brd_files="${brd_files}, ${f}"
  done < <(ls -1 "$req_dir" 2>/dev/null | grep -v "^aidlc-docs$")
  brd_files="${brd_files#, }"

  local svc_list=""
  for dir in "$HOME/applications"/*/; do
    [ -d "$dir" ] || continue
    local name=$(basename "$dir")
    [[ "$name" == *" "* ]] && continue
    local stack=$(_kiro_detect_stack "${dir%/}")
    svc_list="${svc_list}, ${name} (${stack})"
  done
  svc_list="${svc_list#, }"

  # Recreate agent only if new inline prompt given, otherwise resume existing
  local is_new=false
  if [ -n "$inline_prompt" ] || [ ! -f "$agent_file" ]; then
    is_new=true
    rm -f "$agent_file"

  python3 << PYINNER
import json

inline = """$inline_prompt"""
task_section = f"\n## Task\n{inline}" if inline.strip() else ""

data = {
    "name": "$agent_name",
    "description": "Master orchestrator for $jira_id",
    "prompt": f"""You are the MASTER ORCHESTRATOR for requirement $jira_id.

## Requirement: $jira_id
Working directory: $req_dir/
BRD documents: $brd_files
{task_section}

## IMPORTANT
1. Read BRD documents in $req_dir/ FIRST
2. Follow the AIDLC workflow steering rules
3. Use orchestration to delegate to service-specific agents

## AIDLC Workflow (awslabs/aidlc-workflows)
Steering rules: ~/applications/aidlc-workflows/aidlc-rules/aws-aidlc-rules/
Rule details: ~/applications/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details/
Architecture docs: ~/applications/aidlc-docs/

Read and follow these rules for the entire lifecycle.

## AIDLC Output
Generate all docs in: $req_dir/aidlc-docs/
  inception/requirements.md
  inception/user-stories.md
  inception/design.md
  construction/functional-design.md
  construction/nfr.md

## Services
$svc_list

## Orchestration
- Use the orchestrate skill and subagent tool to delegate to service-specific agents
- Each service agent works in ~/applications/<service>/
- Parallel stages for independent work, depends_on for sequential
- Available agent roles match service folder names (e.g. cms-frontend, edel-claims-management, cms-claim-operation)
- ONLY use agents that already exist (pre-created from ~/applications/) — create one only if the service exists but has no agent yet

## Workflow
1. Read BRD docs and AIDLC steering rules
2. Analyze which services are affected
3. Generate AIDLC inception docs
4. Plan changes per service
5. Delegate implementation to per-service sub-agents via subagent tool
6. Generate construction docs as implementation progresses

## Rules
- Read BRDs and AIDLC rules before anything else
- Use caveman mode (compressed output) by default to save tokens
- All AIDLC docs go in $req_dir/aidlc-docs/
- Delegate code changes to service agents via orchestrate skill
- Stage only specific relevant files (git add <file>) — NEVER use git add . or git commit
- Prepare commit message in $req_dir/commit-message.md (conventional format: type($jira_id): description)
- Prepare PR description in $req_dir/pr-description.md
- Never merge - Draft MRs only
- Write ALL analysis, decisions, progress notes, and docs to $req_dir/ so future master agent sessions have full context
- Track progress through AIDLC docs — read $req_dir/aidlc-docs/ at start to know current phase, update docs as you progress""",
    "tools": ["*"],
    "resources": ["skill://.kiro/skills/**/SKILL.md"],
    "welcomeMessage": f"Master Orchestrator - $jira_id\n$req_dir/\nAIDLC: ~/applications/aidlc-workflows/\n{('Task: ' + inline + chr(10)) if inline.strip() else ''}",
    "hooks": {
        "agentSpawn": [{"command": f"bash -c 'echo \"📂 Requirement: $jira_id\" && echo \"\" && echo \"🔧 Services:\" && for d in ~/applications/*/; do [ -d \"$d\" ] && echo \"  • $(basename $d)\"; done && echo \"\" && if [ -d $req_dir/aidlc-docs ]; then echo \"📋 AIDLC Progress:\" && find $req_dir/aidlc-docs -name \"*.md\" -exec echo \"  ✅ {{}}\" \\; ; else echo \"🆕 No AIDLC docs yet\"; fi'", "timeout_ms": 5000}],
        "stop": [{"command": f"bash -c 'echo \"$(date +%Y-%m-%d\\ %H:%M) — Session ended\" >> $req_dir/progress.md && date >> $req_dir/.session-log'", "timeout_ms": 5000}]
    }
}
json.dump(data, open("$agent_file", "w"), indent=2)
PYINNER

    echo "🎯 Master agent created for: $jira_id"
    [ -n "$inline_prompt" ] && echo "📋 Task: $inline_prompt"
  fi

  echo "📁 Req: $req_dir/"
  echo "📐 AIDLC: ~/applications/aidlc-workflows/"

  if [ "$is_new" = true ]; then
    command kiro-cli chat --agent "$agent_name"
  else
    echo "♻️  Resuming previous session for $jira_id"
    command kiro-cli chat --agent "$agent_name" --resume
  fi
}
alias km='kiro-master'
_km_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=($(compgen -W "$(ls ~/requirements/ 2>/dev/null | grep -v '^PR_Reviews$')" -- "$cur"))
}
complete -F _km_completions km kiro-master

# ============================================================================
# General Research Agent (not tied to any project/requirement)
# ============================================================================

kiro-research() {
  local agent_name="research"
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"
  local topic="$*"

  if [ ! -f "$agent_file" ]; then
    cat > "$agent_file" << 'EOF'
{
  "name": "research",
  "description": "General research agent for exploration, learning, and analysis",
  "prompt": "You are a general-purpose research agent.\n\nYou help with:\n- Technical research and exploration\n- Comparing tools, libraries, frameworks\n- Reading documentation and summarizing findings\n- Answering architecture and design questions\n- Exploring unfamiliar codebases\n- Writing notes, summaries, and analysis\n\nCapabilities:\n- Web search for current information\n- File system access for local docs/code\n- Knowledge base search across indexed projects\n- Memory for persisting findings across sessions\n\nBehavior:\n- Be thorough but concise\n- Cite sources when using web results\n- Save important findings to memory for future sessions\n- Write research output to ~/research/ if asked to persist",
  "tools": ["*"],
  "resources": ["skill://.kiro/skills/**/SKILL.md"],
  "welcomeMessage": "🔬 Research Agent — ask me anything\n",
  "hooks": {
    "agentSpawn": [{"command": "bash -c 'echo \"🔬 Research mode\"'", "timeout_ms": 2000}],
    "stop": [{"command": "bash -c 'date >> ~/.kiro/sessions/research.log'", "timeout_ms": 2000}]
  }
}
EOF
    echo "✅ Research agent created"
  fi

  if [ -n "$topic" ]; then
    command kiro-cli chat --agent "$agent_name" "$topic"
  else
    command kiro-cli chat --agent "$agent_name" --resume
  fi
}
alias kr='kiro-research'

# ============================================================================
# Assistant Agent (personal productivity — emails, tasks, notes)
# ============================================================================

kiro-assistant() {
  local agent_name="assistant"
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"
  local assistant_dir="$HOME/assistant"
  local task="$*"

  mkdir -p "$assistant_dir"

  if [ ! -f "$agent_file" ]; then
    cat > "$agent_file" << EOF
{
  "name": "assistant",
  "description": "Personal assistant for tasks, emails, notes, and context",
  "prompt": "You are a personal productivity assistant.\\n\\nYou help with:\\n- Drafting and reviewing emails\\n- Task tracking and prioritization\\n- Meeting notes and summaries\\n- Writing documentation and reports\\n- Maintaining context across sessions\\n- Scheduling and planning\\n\\nContext:\\n- Projects: ~/applications/\\n- Requirements: ~/requirements/\\n- Persistent memory: ~/assistant/ (read/write notes, tasks, drafts here)\\n\\nPersistent Memory Rules:\\n- ALWAYS read ~/assistant/ at session start to restore context\\n- Save important context, decisions, action items to ~/assistant/\\n- Use files like: tasks.md, notes.md, drafts/, contacts.md, standup.md\\n- This directory persists across sessions — treat it as your brain\\n\\nBehavior:\\n- Be concise and actionable\\n- Save important context to ~/assistant/ AND to memory tool\\n- When drafting emails, ask for tone/audience if unclear\\n- Track action items and follow-ups in ~/assistant/tasks.md\\n- Reference past context from ~/assistant/ when relevant",
  "tools": ["*"],
  "resources": ["skill://.kiro/skills/**/SKILL.md"],
  "welcomeMessage": "📋 Assistant — ~/assistant/\\n",
  "hooks": {
    "agentSpawn": [{"command": "bash -c 'echo \"📋 Assistant\" && echo \"📁 ~/assistant/\" && ls ~/assistant/*.md 2>/dev/null | xargs -I{} basename {} | sed \"s/^/  • /\"'", "timeout_ms": 3000}],
    "stop": [{"command": "bash -c 'date >> ~/assistant/.session-log'", "timeout_ms": 2000}]
  }
}
EOF
    echo "✅ Assistant agent created (memory: ~/assistant/)"
  fi

  if [ -n "$task" ]; then
    command kiro-cli chat --agent "$agent_name" "$task"
  else
    command kiro-cli chat --agent "$agent_name" --resume
  fi
}
alias ka='kiro-assistant'

# ============================================================================
# Query Master (read-only access to ALL service codebases)
# ============================================================================

kiro-query() {
  local agent_name="query-master"
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"
  local query="$*"

  # Build service paths list dynamically
  local svc_paths=""
  for dir in "$HOME/applications"/*/; do
    [ -d "$dir" ] || continue
    local name=$(basename "$dir")
    [[ "$name" == *" "* ]] && continue
    local stack=$(_kiro_detect_stack "${dir%/}")
    svc_paths="${svc_paths}\n- ${name} (${stack}): ${dir}"
  done

  if [ ! -f "$agent_file" ]; then
    python3 << PYEOF
import json, os, glob

svc_paths = """$svc_paths"""

# Build list of available agent roles for subagent delegation
roles = []
for d in glob.glob(os.path.expanduser("~/applications/*/")):
    name = os.path.basename(d.rstrip("/"))
    if " " in name:
        continue
    roles.append(name.replace("_", "-"))

data = {
    "name": "query-master",
    "description": "Read-only query agent with access to all service codebases",
    "prompt": f"""You are the QUERY MASTER — a read-only agent with access to ALL service codebases.

## Purpose
Answer questions about any service, find code across projects, trace flows between services, compare implementations, and explain architecture.

## Available Services
{svc_paths}

## Capabilities
- Read files from ANY service in ~/applications/
- Search code across all projects (code tool: pattern_search, search_symbols)
- Query indexed knowledge bases for all services
- Use subagent tool to delegate read queries to service-specific agents
- Trace cross-service flows (API calls, events, shared models)

## Available agent roles for delegation
{', '.join(roles)}

## Rules
- READ ONLY — never modify files, never write code, never create PRs
- Use knowledge base search FIRST before reading files directly
- When answering, cite the exact file path and line
- For cross-service questions, query multiple services and synthesize
- Use subagent tool to delegate to service agents when deep context is needed
- Save useful architectural findings to memory for future sessions

## Strategy
1. Identify which service(s) are relevant to the question
2. Search knowledge bases first (fast, indexed)
3. Use code tool (search_symbols, pattern_search) for precise lookups
4. Read specific files only when needed for full context
5. For complex cross-service queries, spawn read-only sub-agents""",
    "tools": ["*"],
    "resources": ["skill://.kiro/skills/**/SKILL.md"],
    "welcomeMessage": f"🔍 Query Master — read access to all {len(roles)} services\\nAsk about any service, trace flows, compare code\\n",
    "hooks": {
        "agentSpawn": [{"command": "bash -c 'echo \"🔍 Query Master\" && echo \"Services:\" && for d in ~/applications/*/; do [ -d \"$d\" ] && echo \"  • $(basename $d)\"; done'", "timeout_ms": 3000}],
        "stop": [{"command": "bash -c 'date >> ~/.kiro/sessions/query-master.log'", "timeout_ms": 2000}]
    }
}
json.dump(data, open("$agent_file", "w"), indent=2)
PYEOF
    echo "✅ Query master agent created"
  fi

  if [ -n "$query" ]; then
    command kiro-cli chat --agent "$agent_name" "$query"
  else
    command kiro-cli chat --agent "$agent_name" --resume
  fi
}
alias kq='kiro-query'

# ============================================================================
# PR Review Master (read-only multi-PR reviewer + deployment config generator)
# ============================================================================

kiro-pr-review() {
  local agent_name="pr-review-master"
  local release_name=""
  local focus=""
  local target_branch=""
  local source_branch=""
  local pr_urls=()
  local date_str=$(date +%d%m%Y)

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) release_name="$2"; shift 2 ;;
      --focus) focus="$2"; shift 2 ;;
      --target) target_branch="$2"; shift 2 ;;
      --source) source_branch="$2"; shift 2 ;;
      *) pr_urls+=("$1"); shift ;;
    esac
  done

  # Determine release folder name
  if [ -z "$release_name" ]; then
    if [ -n "$target_branch" ]; then
      release_name="Release_${target_branch}_${date_str}"
    else
      release_name="ProductionRelease_${date_str}"
    fi
  fi

  local release_dir="$HOME/requirements/PR_Reviews/${release_name}"
  mkdir -p "$release_dir/review" "$release_dir/deployment"

  # Build initial context for the agent
  local context="Release: ${release_name}\nOutput: ${release_dir}/\n"

  if [ -n "$target_branch" ]; then
    context="${context}Mode: Auto-discover MRs targeting '${target_branch}'\n"
    [ -n "$source_branch" ] && context="${context}Source branch: ${source_branch}\n"
  fi

  if [ ${#pr_urls[@]} -gt 0 ]; then
    context="${context}PRs to review:\n"
    for url in "${pr_urls[@]}"; do
      context="${context}  - ${url}\n"
    done
  fi

  [ -n "$focus" ] && context="${context}Focus areas: ${focus}\n"

  # Write pr-links.md
  {
    echo "# PR Review Session — ${release_name}"
    echo ""
    echo "**Date**: $(date '+%Y-%m-%d %H:%M')"
    echo "**Release**: ${release_name}"
    [ -n "$target_branch" ] && echo "**Target Branch**: ${target_branch}"
    [ -n "$source_branch" ] && echo "**Source Branch**: ${source_branch}"
    [ -n "$focus" ] && echo "**Focus**: ${focus}"
    echo ""
    echo "## PRs"
    if [ ${#pr_urls[@]} -gt 0 ]; then
      for url in "${pr_urls[@]}"; do
        echo "- ${url}"
      done
    elif [ -n "$target_branch" ]; then
      echo "_Auto-discovering from ${target_branch} branch_"
    fi
  } > "$release_dir/pr-links.md"

  echo "🔍 PR Review Master"
  echo "═══════════════════"
  echo "📁 Output: $release_dir/"
  [ ${#pr_urls[@]} -gt 0 ] && echo "📋 PRs: ${#pr_urls[@]} provided"
  [ -n "$target_branch" ] && echo "🎯 Target: $target_branch"
  [ -n "$focus" ] && echo "🔎 Focus: $focus"
  echo ""

  export FLOW_RELEASE_DIR="$release_dir"
  export FLOW_RELEASE_NAME="$release_name"

  command kiro-cli chat --agent "$agent_name" --trust-tools=shell,read,write,code,knowledge,memory_save,memory_recall,subagent "$context"

  # Post-review: generate HTML checklist if CSV was produced
  local csv_file="$release_dir/deployment/checklist_config.csv"
  if [ -f "$csv_file" ]; then
    echo ""
    echo "📝 Generating deployment checklist..."
    (cd "$release_dir/deployment" && python3 ~/applications/Deployment/generate_checklist.py checklist_config.csv "checklist_${release_name}")
    echo "✅ Generated: deployment/checklist_${release_name}.html"
    echo "✅ Generated: deployment/checklist_${release_name}.md"
    echo "✅ Generated: deployment/index.html (live)"
  fi
}
alias kpr='kiro-pr-review'

# ============================================================================
# Git + AI aliases
# ============================================================================

alias gcai='f() { echo -e "Generate a conventional commit message:\n\n$(git diff --cached)" | command kiro-cli chat; }; f'
alias greview='f() { echo -e "Review for issues and improvements:\n\n$(git diff)" | command kiro-cli chat; }; f'
alias greview-staged='f() { echo -e "Review staged changes:\n\n$(git diff --cached)" | command kiro-cli chat; }; f'
alias gpr-desc='f() { echo -e "Generate PR description:\n\n$(git log origin/main..HEAD --oneline)" | command kiro-cli chat; }; f'

# ============================================================================
# Utility aliases
# ============================================================================

alias kiro-list='command kiro-cli agent list'
alias kiro-agents='ls -1 ~/.kiro/agents/*.json 2>/dev/null | xargs -n1 basename | sed "s/.json$//"'
alias kiro-show='f() { cat ~/.kiro/agents/${1}.json 2>/dev/null | python3 -m json.tool 2>/dev/null || cat ~/.kiro/agents/${1}.json; }; f'

kiro-status() {
  echo "🧠 Kiro Status"
  echo "═══════════════"
  local count=$(ls ~/.kiro/agents/*.json 2>/dev/null | wc -l)
  echo "Agents: $count"
  echo ""
  echo "Recent sessions:"
  find ~/.kiro/sessions/ -name "*.log" -printf "  %T+ %f\n" 2>/dev/null | sort -r | head -5 | sed 's/\.log$//'
  find ~/requirements/ -name ".session-log" -printf "  %T+ %h\n" 2>/dev/null | sort -r | head -3 | sed 's|.*/||'
  find ~/assistant/ -name ".session-log" -printf "  %T+ assistant\n" 2>/dev/null | head -1
  echo ""
  echo "Memory: $(curl -s http://localhost:3111/ 2>/dev/null && echo "✅ running" || echo "❌ not running")"
  echo ""
  echo "Indexed: $(ls ~/.kiro/sessions/.indexed-* 2>/dev/null | wc -l) projects"
}

# Memory server
alias mem-start='/home/rushabhsr/.nvm/versions/node/v24.16.0/bin/agentmemory &'
alias mem-stop='pkill -f agentmemory'
alias mem-status='curl -s http://localhost:3111/ 2>/dev/null && echo "✅ running" || echo "❌ not running"'
alias mem-search='f() { curl -s -X POST http://localhost:3111/agentmemory/smart-search -H "Content-Type: application/json" -d "{\"query\": \"$*\"}" | jq .; }; f'

# ============================================================================
# MCP Server Profiles (switch between minimal and full configs)
# ============================================================================

kiro-mcp-design() {
  cp ~/.kiro/settings/mcp-design.json ~/.kiro/settings/mcp.json
  echo "🎨 Design mode: agentmemory + 21st-dev + screenshot + browser-tools + magic-ui"
}
kiro-mcp-minimal() {
  cp ~/.kiro/settings/mcp-minimal.json ~/.kiro/settings/mcp.json
  echo "⚡ Minimal mode: agentmemory only"
}
kiro-mcp-status() {
  echo "Active MCP servers:"; jq -r '.mcpServers | keys[]' ~/.kiro/settings/mcp.json 2>/dev/null
}

# ============================================================================
# Skill Profiles (swap ~/.kiro/skills/ before starting a session)
# ============================================================================

kiro-skill-load() {
  local skill="$1"
  [ -z "$skill" ] && { echo "Usage: kiro-skill-load <skill-name>"; return 1; }
  local src=$(find ~/ai-toolkit/skills -type d -name "$skill" | grep -v node_modules | head -1)
  [ -z "$src" ] && { echo "❌ Skill '$skill' not found in ~/ai-toolkit/skills/"; return 1; }
  cp -r "$src" ~/.kiro/skills/ && echo "✅ $skill loaded"
}
kiro-skill-unload() {
  [ -z "$1" ] && { echo "Usage: kiro-skill-unload <skill-name>"; return 1; }
  rm -rf ~/.kiro/skills/"$1" && echo "✅ $1 unloaded"
}
kiro-skill-clear() { rm -rf ~/.kiro/skills/*; echo "✅ All skills cleared"; }
kiro-skill-active() { echo "Active skills:"; ls ~/.kiro/skills/ 2>/dev/null || echo "(none)"; }
kiro-skill-profile() {
  local profile="$1"
  rm -rf ~/.kiro/skills/*
  case "$profile" in
    frontend) for s in frontend-design tailwind-theme-builder landing-page design-review color-palette responsiveness-check react-patterns seo-local-business ai-seo seo; do kiro-skill-load "$s" 2>/dev/null; done ;;
    backend) for s in hono-api-scaffolder vitest deep-research; do kiro-skill-load "$s" 2>/dev/null; done ;;
    none) echo "✅ Clean slate" ;;
    *) echo "Profiles: frontend, backend, none" ;;
  esac
}

# ============================================================================
# Skills CLI (npx skills) — install any skill on the fly
# ============================================================================

alias skill-add='npx skills add -a kiro-cli -g'
alias skill-add-here='npx skills add -a kiro-cli'
alias skill-find='npx skills find'
alias skill-list='npx skills list -a kiro-cli'
alias skill-remove='npx skills remove -a kiro-cli -g'
alias skill-update='npx skills update -a kiro-cli -g -y'

# Quick-install popular skill packs
alias skill-add-caveman='npx skills add JuliusBrussee/caveman -a kiro-cli -g -y'
alias skill-add-graphify='npx skills add safishamsi/graphify -a kiro-cli -g -y'
alias skill-add-superpowers='npx skills add obra/superpowers -a kiro-cli -g -y'
alias skill-add-anthropic='npx skills add anthropics/skills -a kiro-cli -g -y'
alias skill-add-google='npx skills add google/skills -a kiro-cli -g -y'
alias skill-add-addy='npx skills add addyosmani/agent-skills -a kiro-cli -g -y'

# Skills management (ai-toolkit repos)
kiro-skills-pull() {
  echo "🔄 Updating ai-toolkit repos..."
  for d in ~/ai-toolkit/tools/*/ ~/ai-toolkit/skills/*/; do
    [ -d "$d/.git" ] || continue
    echo -n "  $(basename $d): "
    git -C "$d" pull --ff-only 2>&1 | tail -1
  done
  # Re-copy caveman + graphify to global skills
  [ -d ~/ai-toolkit/tools/caveman/skills ] && cp -r ~/ai-toolkit/tools/caveman/skills/{caveman,caveman-compress,cavecrew,caveman-review,caveman-commit} ~/.kiro/skills/ 2>/dev/null
  [ -f ~/ai-toolkit/tools/graphify/graphify/skill.md ] && mkdir -p ~/.kiro/skills/graphify && cp ~/ai-toolkit/tools/graphify/graphify/skill.md ~/.kiro/skills/graphify/SKILL.md
  echo "✅ Done"
}

kiro-skills-catalog() {
  echo "📚 AI Toolkit (~/ai-toolkit/)"
  echo "═══════════════════════════════"
  echo ""
  echo "Tools:"
  for d in ~/ai-toolkit/tools/*/; do [ -d "$d" ] && printf "  • %-20s %d skills\n" "$(basename $d)" "$(find "$d" -name 'SKILL.md' | wc -l)"; done
  echo ""
  echo "Skill Packs:"
  for d in ~/ai-toolkit/skills/*/; do [ -d "$d" ] && printf "  • %-25s %d skills\n" "$(basename $d)" "$(find "$d" -name 'SKILL.md' | wc -l)"; done
  echo ""
  echo "Total: $(find ~/ai-toolkit -name 'SKILL.md' 2>/dev/null | wc -l) SKILL.md files"
}

# ============================================================================
# Help
# ============================================================================

kiro-help() {
  cat << 'EOF'
🧠 Kiro AI — Command Reference

BASIC:
  kiro                    Smart start (auto-detect project)
  kiro-<project>          Start agent for specific project
  ka / kiro-assistant     Personal assistant (tasks, emails, notes)
  kr / kiro-research      General research agent
  km / kiro-master        Cross-service orchestrator (work only)
  kq / kiro-query         Query all services (work only)

SKILLS (install any skill on the fly):
  skill-add <repo>        Install skill globally (npx skills add)
  skill-add-here <repo>   Install skill to current project only
  skill-find [query]      Search skill registry (skills.sh)
  skill-list              List installed skills
  skill-update            Update all installed skills
  skill-remove            Remove skills

  Quick installs:
  skill-add-caveman       Token compression (65% savings)
  skill-add-graphify      Code → knowledge graph
  skill-add-superpowers   Agentic dev framework
  skill-add-anthropic     Official Anthropic skills
  skill-add-google        GCP/Firebase skills
  skill-add-addy          Production engineering workflows

SKILL PROFILES:
  kiro-skill-profile frontend   Load frontend skills
  kiro-skill-profile backend    Load backend skills
  kiro-skill-profile none       Clear all skills
  kiro-skill-load <name>        Load single skill
  kiro-skill-unload <name>      Remove single skill
  kiro-skill-active             Show loaded skills

MCP PROFILES:
  kiro-mcp-design         Full MCP (design tools + memory)
  kiro-mcp-minimal        Minimal (agentmemory only)
  kiro-mcp-status         Show active MCP servers

PR REVIEW:
  kpr <urls...>           Review PRs (multiple URLs)
  kpr --target production Auto-discover all prod MRs
  kpr --source <b> --target <b>  MRs between branches
  kpr --name <name> <urls>       Custom release name
  kpr --focus "area" <urls>      Focus review areas

MANAGEMENT:
  kiro-agents             List all agents
  kiro-show <name>        Show agent config
  kiro-edit-prompt <name> Edit agent prompt
  kiro-regenerate <name>  Recreate agent with fresh detection
  kiro-regenerate-all     Recreate all agents
  kiro-cleanup            Delete all agents (auto-recreate on use)
  kiro-skills-pull        Update ai-toolkit repos
  kiro-skills-catalog     Show installed skill packs

GIT + AI:
  gcai                    Generate commit message from staged
  greview                 Review current diff
  greview-staged          Review staged changes
  gpr-desc               Generate PR description

MEMORY:
  mem-start / mem-stop    Agentmemory server
  mem-status              Check health
EOF
}
