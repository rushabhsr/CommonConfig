#!/bin/bash
# Kiro CLI Aliases and Functions
# Auto-creates agents and provides smart project detection

# ============================================================================
# Configuration
# ============================================================================

# Chat save directory - will be set per project in .kiro/chats
# This is just a placeholder, actual directory is set when starting agent
export KIRO_CHAT_DIR="${KIRO_CHAT_DIR:-}"

# ============================================================================
# Kiro Agent Management
# ============================================================================

# Function to detect project type and tech stack
detect_project_info() {
  local project_dir="$1"
  local project_type="fullstack"
  local tech_stack=""
  local tools='["*"]'
  
  # Detect backend technologies
  if [ -f "$project_dir/manage.py" ] || [ -f "$project_dir/backend/manage.py" ]; then
    tech_stack="${tech_stack}Django, "
  fi
  
  if [ -f "$project_dir/requirements.txt" ] || [ -f "$project_dir/backend/requirements.txt" ]; then
    tech_stack="${tech_stack}Python, "
  fi
  
  if [ -f "$project_dir/package.json" ]; then
    if grep -q "\"django\"" "$project_dir/package.json" 2>/dev/null; then
      tech_stack="${tech_stack}Django, "
    fi
    if grep -q "\"express\"" "$project_dir/package.json" 2>/dev/null; then
      tech_stack="${tech_stack}Express.js, "
    fi
    if grep -q "\"fastify\"" "$project_dir/package.json" 2>/dev/null; then
      tech_stack="${tech_stack}Fastify, "
    fi
  fi
  
  if [ -f "$project_dir/go.mod" ]; then
    tech_stack="${tech_stack}Go, "
  fi
  
  # Detect frontend technologies
  if [ -f "$project_dir/package.json" ] || [ -f "$project_dir/frontend/package.json" ]; then
    local pkg_file="$project_dir/package.json"
    [ -f "$project_dir/frontend/package.json" ] && pkg_file="$project_dir/frontend/package.json"
    
    if grep -q "\"react\"" "$pkg_file" 2>/dev/null; then
      tech_stack="${tech_stack}React, "
    fi
    if grep -q "\"vue\"" "$pkg_file" 2>/dev/null; then
      tech_stack="${tech_stack}Vue.js, "
    fi
    if grep -q "\"@angular\"" "$pkg_file" 2>/dev/null; then
      tech_stack="${tech_stack}Angular, "
    fi
    if grep -q "\"next\"" "$pkg_file" 2>/dev/null; then
      tech_stack="${tech_stack}Next.js, "
    fi
    if grep -q "\"typescript\"" "$pkg_file" 2>/dev/null; then
      tech_stack="${tech_stack}TypeScript, "
    fi
  fi
  
  # Detect databases
  if [ -f "$project_dir/docker-compose.yml" ] || [ -f "$project_dir/docker-compose.yaml" ]; then
    if grep -q "postgres" "$project_dir/docker-compose.yml" 2>/dev/null || grep -q "postgres" "$project_dir/docker-compose.yaml" 2>/dev/null; then
      tech_stack="${tech_stack}PostgreSQL, "
    fi
    if grep -q "mysql" "$project_dir/docker-compose.yml" 2>/dev/null || grep -q "mysql" "$project_dir/docker-compose.yaml" 2>/dev/null; then
      tech_stack="${tech_stack}MySQL, "
    fi
    if grep -q "mongodb" "$project_dir/docker-compose.yml" 2>/dev/null || grep -q "mongodb" "$project_dir/docker-compose.yaml" 2>/dev/null; then
      tech_stack="${tech_stack}MongoDB, "
    fi
    if grep -q "redis" "$project_dir/docker-compose.yml" 2>/dev/null || grep -q "redis" "$project_dir/docker-compose.yaml" 2>/dev/null; then
      tech_stack="${tech_stack}Redis, "
    fi
  fi
  
  # Detect project type and set appropriate tools
  if [ -d "$project_dir/frontend" ] && [ -d "$project_dir/backend" ]; then
    project_type="fullstack"
    tools='["fs_read", "fs_write", "code", "execute_bash", "grep", "glob", "web_search"]'
  elif [ -f "$project_dir/package.json" ] && [ ! -f "$project_dir/manage.py" ] && [ ! -f "$project_dir/requirements.txt" ]; then
    project_type="frontend"
    tools='["fs_read", "fs_write", "code", "execute_bash", "grep", "glob"]'
  elif [ -f "$project_dir/manage.py" ] || [ -f "$project_dir/requirements.txt" ]; then
    if [ ! -d "$project_dir/frontend" ] && [ ! -f "$project_dir/package.json" ]; then
      project_type="backend"
      tools='["fs_read", "fs_write", "code", "execute_bash", "grep", "glob"]'
    fi
  fi
  
  # Remove trailing comma and space
  tech_stack="${tech_stack%, }"
  
  # Default if nothing detected
  [ -z "$tech_stack" ] && tech_stack="General Development"
  
  echo "$project_type|$tech_stack|$tools"
}

# Function to generate dynamic prompt based on tech stack
generate_prompt() {
  local project_name="$1"
  local project_dir="$2"
  local tech_stack="$3"
  local project_type="$4"
  
  cat << EOF
You are an expert software engineer working on the $project_name project.

**Tech Stack:** $tech_stack
**Project Type:** $project_type
**Location:** $project_dir

**IMPORTANT FIRST STEPS:**
1. Run \`/code init\` to enable code intelligence
2. Conversation history is automatically maintained across sessions
3. Use \`/chat save <session-name>\` to save important work sessions
4. Use \`/chat load <session-name>\` to restore saved sessions

**Your Expertise:**
You have deep knowledge of $tech_stack and follow industry best practices. You understand the nuances, common pitfalls, and optimal patterns for this technology stack.

**Core Principles:**
1. **Review Before Action** - Always analyze code thoroughly before making changes
2. **Test After Changes** - Run tests to verify modifications work correctly
3. **Follow Existing Patterns** - Match the project's code style and architecture
4. **Minimal Changes** - Make focused, surgical changes rather than broad refactors
5. **Ask When Unclear** - Request clarification if requirements are ambiguous
6. **Security First** - Never expose secrets, validate inputs, handle errors properly
7. **Performance Aware** - Consider performance implications of changes

**Development Workflow:**
- Add important files with \`/context add <file>\`
- Save progress frequently with \`/chat save <session-name>\`
- Load previous work with \`/chat load <session-name>\`
- Check for errors before committing changes

**Code Quality Standards:**
- Write clean, readable, maintainable code
- Add appropriate comments for complex logic
- Use meaningful variable and function names
- Handle edge cases (null, empty, invalid inputs)
- Follow DRY (Don't Repeat Yourself) principle
- Ensure proper error handling and logging

**Before Implementing:**
1. Understand the full context and requirements
2. Check existing code patterns in the project
3. Consider impact on other parts of the system
4. Plan the approach before coding

**After Implementing:**
1. Review the changes for correctness
2. Run relevant tests
3. Check for potential side effects
4. Verify code follows project conventions

Remember: Quality over speed. It's better to ask questions and get it right than to make assumptions and introduce bugs.

$(local _skills; _skills=$(generate_skills_block); [ -n "$_skills" ] && echo "**Active Skills (from ai-toolkit/):**${_skills}")

**Always-On Skills (loaded for every session):**
- **caveman**: Ultra-compressed communication mode — cuts token usage ~75%. Use when context is getting long or approaching limits.
- **caveman-compress**: Compress memory/context files into caveman format to preserve critical info across sessions.
- **graphify**: Build queryable knowledge graphs from code — use for architecture mapping, dependency analysis, and codebase understanding.
EOF
}

# Extract description from SKILL.md YAML frontmatter (handles single-line and multi-line >)
_extract_skill_desc() {
  local file="$1"
  local desc=""
  desc=$(awk '/^---$/{n++; next} n==1 && /^description:/{
    sub(/^description: */, ""); 
    if ($0 == ">" || $0 == "|") { getline; sub(/^ +/, ""); }
    gsub(/"/, ""); print; exit
  }' "$file" | head -c 120)
  echo "$desc"
}

# Generate skills block — scans ai-toolkit/ only when called
generate_skills_block() {
  local toolkit_dir="$HOME/ai-toolkit"
  local block=""
  local max_desc=80
  # Only include skills from these high-value repos in the prompt
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
      # Only include high-value repos in prompt
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

# Function to ensure kiro agent exists before starting chat
ensure_kiro_agent() {
  local agent_name="$1"
  local project_dir="$2"
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"
  
  # Create sessions directory if it doesn't exist
  mkdir -p "$HOME/.kiro/sessions"
  
  # Create agent if it doesn't exist
  if [ ! -f "$agent_file" ]; then
    echo "Creating agent: $agent_name"
    echo "Analyzing project structure..."
    
    # Detect project info
    local project_info=$(detect_project_info "$project_dir")
    local project_type=$(echo "$project_info" | cut -d'|' -f1)
    local tech_stack=$(echo "$project_info" | cut -d'|' -f2)
    local tools=$(echo "$project_info" | cut -d'|' -f3)
    
    echo "Detected: $project_type project with $tech_stack"
    
    # Generate dynamic prompt
    local prompt=$(generate_prompt "$agent_name" "$project_dir" "$tech_stack" "$project_type")
    
    # Escape prompt for JSON
    local escaped_prompt=$(echo "$prompt" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    
    # Get saved sessions from .kiro/chats directory
    local chat_dir="${project_dir}.kiro/chats"
    local saved_sessions=$(ls -1 "$chat_dir" 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/,$//' | sed 's/,/, /g')
    
    local welcome_msg="🚀 $agent_name Agent Ready!\\\\n\\\\n📦 Tech Stack: $tech_stack\\\\n📁 Project: $project_dir\\\\n\\\\n⚡ Quick Commands:\\\\n  • /code init - Enable code intelligence\\\\n  • /chat save <name> - Save session\\\\n  • /chat load <name> - Resume session"
    
    if [ -n "$saved_sessions" ]; then
      welcome_msg="${welcome_msg}\\\\n\\\\n📚 Saved Sessions: $saved_sessions"
    fi
    
    welcome_msg="${welcome_msg}\\\\n\\\\n💡 Tip: Kiro automatically maintains conversation history!\\\\n"
    
    cat > "$agent_file" << EOF
{
  "name": "$agent_name",
  "description": "AI agent for $agent_name project ($tech_stack)",
  "prompt": "$escaped_prompt",
  "tools": $tools,
  "resources": ["skill://.kiro/skills/**/SKILL.md"],
  "welcomeMessage": "$welcome_msg",
  "hooks": {
    "agentSpawn": [
      {
        "command": "bash -c 'echo \"📂 Project: $agent_name ($tech_stack)\" && echo \"📁 Location: $project_dir\" && echo \"\" && echo \"💡 Conversation history is automatically maintained\" && echo \"💡 Use /chat save <name> to preserve important sessions\"'",
        "timeout_ms": 5000
      }
    ],
    "stop": [
      {
        "command": "bash -c 'echo \"💾 Session saved for $agent_name\" && date >> ~/.kiro/sessions/$agent_name.log'",
        "timeout_ms": 5000
      }
    ]
  }
}
EOF
    echo "Agent created: $agent_file"
  fi

  # Ensure core slash commands are available in project-level skills
  _kiro_ensure_core_skills "$project_dir"
}

# Ensure all / commands available: symlink .kiro/skills + add resource to agent JSON
_kiro_ensure_core_skills() {
  local project_dir="$1"
  local agent_name=$(basename "$project_dir")
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"
  # Symlink project .kiro/skills → global so relative skill:// paths resolve
  if [ -d "${project_dir}.kiro" ]; then
    [ -e "${project_dir}.kiro/skills" ] && [ ! -L "${project_dir}.kiro/skills" ] && rm -rf "${project_dir}.kiro/skills"
    [ ! -e "${project_dir}.kiro/skills" ] && ln -sf "$HOME/.kiro/skills" "${project_dir}.kiro/skills"
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

# Smart kiro command - auto-detect project and use appropriate agent
kiro() {
  local current_dir=$(pwd)
  
  # Quick check: only detect if in applications directory
  if [[ "$current_dir" == "$HOME/applications/"* ]] || [[ "$current_dir" == "$HOME/applications/"* ]]; then
    # Extract project name (first directory after applications/)
    local project_path
    if [[ "$current_dir" == "$HOME/applications/"* ]]; then
      project_path="${current_dir#$HOME/applications/}"
    else
      project_path="${current_dir#$HOME/applications/}"
    fi
    
    local project_name=$(echo "$project_path" | cut -d'/' -f1)
    local agent_name=$(echo "$project_name" | sed 's/_/-/g')
    
    # Get project root directory
    local project_root
    if [[ "$current_dir" == "$HOME/applications/"* ]]; then
      project_root="$HOME/applications/$project_name"
    else
      project_root="$HOME/applications/$project_name"
    fi
    
    # Ensure agent exists
    ensure_kiro_agent "$agent_name" "$project_root"
    
    echo "Starting kiro-cli with agent: $agent_name"
    kiro-start-with-init "$agent_name" "$@"
  else
    # Not in a project directory, use default (no detection)
    kiro-cli chat --resume "$@"
  fi
}

# ============================================================================
# Auto-generate Kiro Aliases for Applications
# ============================================================================

create_kiro_aliases() {
  local apps_dir="$HOME/applications"
  
  if [ -d "$apps_dir" ]; then
    for dir in "$apps_dir"/*/; do
      [ -d "$dir" ] || continue
      local folder_name=$(basename "$dir")
      # Skip folders with spaces (invalid for aliases)
      [[ "$folder_name" == *" "* ]] && continue
      local agent_name=$(echo "$folder_name" | sed 's/_/-/g')
      
      alias "kiro-$folder_name"="ensure_kiro_agent '$agent_name' '$dir' && cd '$dir' && kiro-start-with-init '$agent_name'"
      alias "k-$folder_name"="ensure_kiro_agent '$agent_name' '$dir' && cd '$dir' && _KIRO_RIA_MODE=WRITE && echo '✍️  RIA mode: WRITE' && kiro-start-with-init '$agent_name'"
    done
  fi
}

# Start kiro agent and auto-run /code init
kiro-start-with-init() {
  local agent_name="$1"
  shift
  
  # Start kiro-cli with --resume to trigger hooks
  kiro-cli chat --agent "$agent_name" --resume "$@"
}

# Generate aliases on shell startup
create_kiro_aliases

# Auto-create agents for all projects in ~/applications/ (runs in background)
_kiro_ensure_all_agents() {
  for dir in "$HOME/applications"/*/; do
    [ -d "$dir" ] || continue
    local folder_name=$(basename "$dir")
    [[ "$folder_name" == *" "* ]] && continue
    local agent_name=$(echo "$folder_name" | sed 's/_/-/g')
    [ -f "$HOME/.kiro/agents/${agent_name}.json" ] && continue
    ensure_kiro_agent "$agent_name" "$dir"
  done
}
_kiro_ensure_all_agents &>/dev/null &
disown 2>/dev/null

# ============================================================================
# Agent Memory (persistent memory server)
# ============================================================================

alias mem-start='agentmemory &'
alias mem-stop='agentmemory stop'
alias mem-status='curl -s http://localhost:3111/agentmemory/health 2>/dev/null | jq . || echo "❌ agentmemory not running. Start with: mem-start"'
alias mem-viewer='echo "Opening viewer at http://localhost:3113" && open http://localhost:3113 2>/dev/null || xdg-open http://localhost:3113 2>/dev/null'
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
# Skills Management (npx skills CLI + ai-toolkit/skills/)
# ============================================================================

# Install skills from any GitHub repo into kiro-cli
alias kiro-skills-add='npx skills add -a kiro-cli -g'
alias kiro-skills-list='npx skills list -a kiro-cli'
alias kiro-skills-find='npx skills find'
alias kiro-skills-update='npx skills update -a kiro-cli -g'
alias kiro-skills-remove='npx skills remove -a kiro-cli -g'

# Update all cloned skill repos in ai-toolkit/skills/
kiro-skills-pull() {
  echo "🔄 Updating skill repos in ~/ai-toolkit/skills/..."
  for dir in "$HOME/ai-toolkit/skills"/*/; do
    [ -d "$dir/.git" ] || continue
    local name=$(basename "$dir")
    echo -n "  $name: "
    git -C "$dir" pull --ff-only 2>&1 | tail -1
  done
  echo "✅ Done"
}

# Show all available skills from ai-toolkit/
kiro-skills-catalog() {
  echo "📚 Skills Catalog (~/ai-toolkit/)"
  echo "═══════════════════════════════════"
  for dir in "$HOME/ai-toolkit/skills"/*/; do
    [ -d "$dir" ] || continue
    local name=$(basename "$dir")
    local count=$(find "$dir" -name "SKILL.md" | wc -l)
    printf "  %-25s %3d skills\n" "$name" "$count"
  done
  local tools_count=$(find "$HOME/ai-toolkit/tools" -name "SKILL.md" 2>/dev/null | wc -l)
  printf "  %-25s %3d skills\n" "tools/ (built-in)" "$tools_count"
  echo "─────────────────────────────────────"
  local total=$(find "$HOME/ai-toolkit" -name "SKILL.md" | wc -l)
  printf "  %-25s %3d skills\n" "TOTAL" "$total"
}

# ============================================================================
# Kiro Utility Aliases
# ============================================================================

# Cleanup function - deletes all agents and conversation history
kiro-cleanup() {
  echo "🧹 Cleaning up Kiro CLI data..."

  # Delete all agent configs (except example)
  if [ -d "$HOME/.kiro/agents" ]; then
    echo "Deleting agents..."
    find "$HOME/.kiro/agents" -name "*.json" ! -name "*.example" -delete
    echo "✓ Agents deleted"
  fi

  # Delete conversation history
  if [ -f "$HOME/.kiro/.cli_bash_history" ]; then
    echo "Deleting conversation history..."
    rm -f "$HOME/.kiro/.cli_bash_history"
    echo "✓ History deleted"
  fi

  # Delete any saved conversations (if they exist)
  if [ -d "$HOME/.kiro/conversations" ]; then
    echo "Deleting saved conversations..."
    rm -rf "$HOME/.kiro/conversations"
    echo "✓ Conversations deleted"
  fi

  echo ""
  echo "✅ Cleanup complete!"
  echo ""
  echo "Next time you use 'kiro' or 'kiro-<app>' aliases,"
  echo "agents will be automatically created."
}

# Add /code init hook to all existing agents
kiro-add-hooks() {
  echo "Adding /code init hook to all agents..."
  
  for agent_file in "$HOME/.kiro/agents"/*.json; do
    # Skip example files
    [[ "$agent_file" == *.example ]] && continue
    [[ ! -f "$agent_file" ]] && continue
    
    # Check if hooks already exist
    if ! grep -q '"hooks"' "$agent_file"; then
      # Add hooks before the closing brace
      local agent_name=$(basename "$agent_file" .json)
      echo "  Adding hook to: $agent_name"
      
      # Use jq if available, otherwise manual edit
      if command -v jq &> /dev/null; then
        jq '. + {"hooks": {"agentSpawn": ["/code init"]}}' "$agent_file" > "${agent_file}.tmp" && mv "${agent_file}.tmp" "$agent_file"
      else
        # Manual JSON edit (remove last }, add hooks, add } back)
        sed -i 's/}$/,\n  "hooks": {\n    "agentSpawn": ["\/code init"]\n  }\n}/' "$agent_file"
      fi
    else
      echo "  Skipping $agent_name (already has hooks)"
    fi
  done
  
  echo "✓ Hooks added"
}

# Edit agent prompt
kiro-edit-prompt() {
  local agent_name="$1"
  
  if [ -z "$agent_name" ]; then
    echo "Usage: kiro-edit-prompt <agent-name>"
    echo "Example: kiro-edit-prompt metaxis"
    return 1
  fi
  
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"
  
  if [ ! -f "$agent_file" ]; then
    echo "Error: Agent '$agent_name' not found"
    echo "Available agents:"
    ls -1 "$HOME/.kiro/agents"/*.json 2>/dev/null | xargs -n1 basename | sed 's/.json$//'
    return 1
  fi
  
  # Open in default editor
  ${EDITOR:-vim} "$agent_file"
  echo "✓ Agent prompt updated: $agent_name"
}

# Regenerate agent with updated detection
kiro-regenerate() {
  local agent_name="$1"
  
  if [ -z "$agent_name" ]; then
    echo "Usage: kiro-regenerate <agent-name>"
    echo "Example: kiro-regenerate metaxis"
    echo ""
    echo "This will delete and recreate the agent with updated tech stack detection."
    return 1
  fi
  
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"
  
  if [ ! -f "$agent_file" ]; then
    echo "Error: Agent '$agent_name' not found"
    return 1
  fi
  
  # Find project directory
  local project_dir=""
  if [ -d "$HOME/applications/$agent_name" ]; then
    project_dir="$HOME/applications/$agent_name"
  elif [ -d "$HOME/applications/$agent_name" ]; then
    project_dir="$HOME/applications/$agent_name"
  else
    echo "Error: Could not find project directory for $agent_name"
    return 1
  fi
  
  echo "Regenerating agent: $agent_name"
  rm "$agent_file"
  ensure_kiro_agent "$agent_name" "$project_dir"
  echo "✓ Agent regenerated with updated tech stack detection"
}

# Regenerate all agents
kiro-regenerate-all() {
  echo "Regenerating all agents with updated tech stack detection..."
  
  for agent_file in "$HOME/.kiro/agents"/*.json; do
    [[ "$agent_file" == *.example ]] && continue
    [[ ! -f "$agent_file" ]] && continue
    
    local agent_name=$(basename "$agent_file" .json)
    echo ""
    kiro-regenerate "$agent_name"
  done
  
  echo ""
  echo "✓ All agents regenerated"
}

# Wrap kiro-cli: bare invocation resumes, everything else passes through
kiro-cli() {
  if [ $# -eq 0 ]; then
    command kiro-cli chat --resume
  else
    command kiro-cli "$@"
  fi
}

alias kiro-list='kiro-cli agent list'
alias kiro-agents='ls -lh ~/.kiro/agents/*.json 2>/dev/null || echo "No agents found"'
alias kiro-show='f() { cat ~/.kiro/agents/${1}.json | jq .; }; f'
alias kiro-prompt='f() { cat ~/.kiro/agents/${1}.json | jq -r .prompt; }; f'
alias kiro-sessions='f() { ls -lh ~/applications/${1}/ | grep -E "\.kiro|session" || echo "No saved sessions found"; }; f'
alias kiro-chats='ls -lh "$KIRO_CHAT_DIR"'
alias kiro-chat-dir='echo "Chat directory: $KIRO_CHAT_DIR"'

# ============================================================================
# AI-Powered Git Aliases (Kiro Integration)
# ============================================================================

# Generate commit message from staged changes
alias gcai='f() { echo -e "Generate a concise, conventional commit message for these changes. Format: type(scope): description\n\n$(git diff --cached)" | kiro-cli chat; }; f'

# Code review current changes
alias greview='f() { echo -e "Review this code for issues, bugs, improvements, and best practices. Be specific and actionable.\n\n$(git diff)" | kiro-cli chat; }; f'

# Code review staged changes
alias greview-staged='f() { echo -e "Review these staged changes for issues, bugs, improvements, and best practices. Be specific and actionable.\n\n$(git diff --cached)" | kiro-cli chat; }; f'

# Generate PR description
alias gpr-desc='f() { echo -e "Generate a detailed PR description from these commits. Include: summary, changes made, testing done, and any breaking changes.\n\n$(git log origin/main..HEAD --oneline)" | kiro-cli chat; }; f'

# Generate PR description (custom base branch)
alias gpr-desc-from='f() { echo -e "Generate a detailed PR description from these commits. Include: summary, changes made, testing done, and any breaking changes.\n\n$(git log origin/${1:-main}..HEAD --oneline)" | kiro-cli chat; }; f'

# Explain what changed between branches
alias gexplain='f() { echo -e "Explain what changed in this diff in simple terms. Summarize the key changes and their purpose.\n\n$(git diff ${1:-main}...${2:-HEAD})" | kiro-cli chat; }; f'

# Suggest commit message for current changes
alias gsuggest='f() { echo -e "Suggest a commit message for these changes. Format: type(scope): description\n\n$(git diff)" | kiro-cli chat; }; f'

# ============================================================================
# Kiro Utility Functions
# ============================================================================

kiro-set-chat-dir() {
  local new_dir="$1"
  
  if [ -z "$new_dir" ]; then
    echo "Usage: kiro-set-chat-dir <directory>"
    echo "Current: $KIRO_CHAT_DIR"
    return 1
  fi
  
  # Create directory if it doesn't exist
  mkdir -p "$new_dir"
  
  # Update environment variable
  export KIRO_CHAT_DIR="$new_dir"
  
  # Add to bashrc for persistence
  if ! grep -q "export KIRO_CHAT_DIR=" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Kiro CLI chat directory" >> ~/.bashrc
    echo "export KIRO_CHAT_DIR=\"$new_dir\"" >> ~/.bashrc
  else
    sed -i "s|export KIRO_CHAT_DIR=.*|export KIRO_CHAT_DIR=\"$new_dir\"|" ~/.bashrc
  fi
  
  echo "✓ Chat directory set to: $new_dir"
  echo "✓ Updated ~/.bashrc for persistence"
}


# ============================================================================
# AI Agent Squad - Per-Service Agent Definitions
# ============================================================================
# Each agent has: role, skills, tools, permissions (least privilege)
# Permission levels: READ, WRITE_CODE, GIT_ACCESS, MR_CREATE, MERGE

KIRO_AI_SYSTEM_DIR="${KIRO_AI_SYSTEM_DIR:-$HOME/.kiro/ai-system}"

# Agent definitions as associative-style functions for portability
_agent_def_dev() {
  cat << 'EOF'
{
  "role": "dev",
  "description": "Software development agent - writes production code",
  "skills": ["framework_expertise", "api_design", "db_schema_design", "code_generation"],
  "tools": ["read_file", "write_file", "parse_code_ast", "git_branch", "git_commit", "git_diff", "run_formatter"],
  "permissions": {"write_code": true, "git_access": true, "mr_create": false, "merge": false},
  "restrictions": ["no_merge", "no_push_protected_branches", "no_approve_mr"]
}
EOF
}

_agent_def_test() {
  cat << 'EOF'
{
  "role": "test",
  "description": "Test agent - writes and runs tests only",
  "skills": ["unit_testing", "integration_testing", "edge_case_generation", "test_coverage"],
  "tools": ["read_file", "write_file", "run_tests", "search_files"],
  "permissions": {"write_code": false, "git_access": false, "mr_create": false, "merge": false},
  "restrictions": ["no_modify_production_code", "test_files_only"]
}
EOF
}

_agent_def_quality() {
  cat << 'EOF'
{
  "role": "quality",
  "description": "Code quality agent - linting, formatting, clean architecture",
  "skills": ["clean_architecture", "design_patterns", "refactoring", "code_review"],
  "tools": ["read_file", "write_file", "run_linter", "run_formatter", "parse_code_ast"],
  "permissions": {"write_code": true, "git_access": false, "mr_create": false, "merge": false},
  "restrictions": ["style_and_structure_only"]
}
EOF
}

_agent_def_security() {
  cat << 'EOF'
{
  "role": "security",
  "description": "Security agent - OWASP, auth, input validation, vulnerability scanning",
  "skills": ["owasp_top10", "auth_flows", "input_validation", "secret_scanning", "dependency_audit"],
  "tools": ["read_file", "run_security_scan", "search_files", "dependency_analyzer"],
  "permissions": {"write_code": false, "git_access": false, "mr_create": false, "merge": false},
  "restrictions": ["read_only", "suggestions_via_dev_agent"]
}
EOF
}

_agent_def_contract() {
  cat << 'EOF'
{
  "role": "contract",
  "description": "API contract agent - OpenAPI/schema validation, API consistency",
  "skills": ["openapi_validation", "schema_design", "api_consistency", "backward_compatibility"],
  "tools": ["read_file", "write_file", "api_schema_validator", "search_files"],
  "permissions": {"write_code": true, "git_access": false, "mr_create": false, "merge": false},
  "restrictions": ["schema_and_contract_files_only"]
}
EOF
}

_agent_def_performance() {
  cat << 'EOF'
{
  "role": "performance",
  "description": "Performance agent - query optimization, latency analysis, load testing",
  "skills": ["query_optimization", "api_latency_analysis", "memory_profiling", "load_testing"],
  "tools": ["read_file", "run_tests", "metrics_reader", "search_files"],
  "permissions": {"write_code": false, "git_access": false, "mr_create": false, "merge": false},
  "restrictions": ["read_only", "perf_test_files_only"]
}
EOF
}

_agent_def_refactor() {
  cat << 'EOF'
{
  "role": "refactor",
  "description": "Refactor agent - code simplification, dead code removal",
  "skills": ["code_simplification", "dead_code_removal", "pattern_extraction", "dependency_reduction"],
  "tools": ["read_file", "write_file", "parse_code_ast", "run_linter", "run_tests"],
  "permissions": {"write_code": true, "git_access": false, "mr_create": false, "merge": false},
  "restrictions": ["behavior_preserving_only", "must_pass_tests"]
}
EOF
}

# ============================================================================
# Repo Intelligence Agent (RIA) - The Staff Engineer On-Call
# ============================================================================
# Modes: READ (default) | PLAN | WRITE
# READ  = answer questions, trace flows, explain architecture
# PLAN  = impact analysis, change proposals, diff generation
# WRITE = branch + patch + pipeline + Draft MR (never merges)

_agent_def_ria() {
  local mode="${1:-READ}"
  cat << EOF
{
  "role": "repo-intelligence",
  "mode": "$mode",
  "description": "Repo Intelligence Agent - architect + historian + careful surgeon",
  "skills_by_mode": {
    "READ": ["code_understanding", "dependency_tracing", "architecture_reasoning", "flow_analysis", "impact_preview"],
    "PLAN": ["impact_analysis", "change_planning", "risk_assessment", "diff_generation"],
    "WRITE": ["code_modification", "safe_patching", "branch_management", "mr_creation"]
  },
  "tools_by_mode": {
    "READ": ["read_file", "search_files", "parse_code_ast", "dependency_analyzer", "vector_search", "list_directory"],
    "PLAN": ["read_file", "parse_code_ast", "dependency_analyzer", "git_diff", "search_files"],
    "WRITE": ["read_file", "write_file", "git_branch", "git_commit", "git_diff", "git_push", "create_merge_request", "run_tests", "run_linter", "run_security_scan"]
  },
  "permissions_by_mode": {
    "READ":  {"write_code": false, "git_access": false, "mr_create": false, "merge": false},
    "PLAN":  {"write_code": false, "git_access": false, "mr_create": false, "merge": false},
    "WRITE": {"write_code": true,  "git_access": true,  "mr_create": true,  "merge": false}
  },
  "restrictions": [
    "NEVER merge or approve MRs",
    "NEVER push to protected branches (main, develop)",
    "WRITE mode requires explicit user approval",
    "Default mode is always READ",
    "Must re-index knowledge after code changes",
    "Prefer file-based reasoning over hallucination",
    "Diff-aware edits only (no blind overwrite)",
    "Abort if tests or security scans fail"
  ],
  "knowledge_sources": [
    "knowledge/code-index.json",
    "knowledge/dependency-graph.json",
    "knowledge/api-map.json",
    "knowledge/symbols.json",
    "knowledge/summaries.md"
  ],
  "outputs": {
    "PLAN": ["plan.json", "impact-analysis.md", "proposed-diff.patch"],
    "WRITE": ["feature-branch", "draft-mr", "pipeline-results"]
  }
}
EOF
}

# Global agents
_agent_def_master() {
  cat << 'EOF'
{
  "role": "master",
  "description": "Master orchestrator - task decomposition, system-wide coordination",
  "skills": ["task_decomposition", "system_orchestration", "priority_management", "cross_service_reasoning"],
  "tools": ["read_file", "search_files", "list_directory"],
  "permissions": {"write_code": false, "git_access": false, "mr_create": false, "merge": false},
  "restrictions": ["no_direct_code_modification", "delegates_to_service_agents"]
}
EOF
}

_agent_def_pr_review() {
  cat << 'EOF'
{
  "role": "pr-review",
  "description": "PR review agent - code review, best practices enforcement",
  "skills": ["code_review", "best_practices", "security_review", "performance_review"],
  "tools": ["read_file", "git_diff", "comment_on_mr", "search_files"],
  "permissions": {"write_code": false, "git_access": false, "mr_create": false, "merge": false},
  "restrictions": ["read_only", "comments_only"]
}
EOF
}

_agent_def_release() {
  cat << 'EOF'
{
  "role": "release",
  "description": "Release agent - versioning, changelog, tagging",
  "skills": ["semantic_versioning", "changelog_generation", "release_notes"],
  "tools": ["read_file", "git_tag", "git_commit", "search_files"],
  "permissions": {"write_code": false, "git_access": true, "mr_create": false, "merge": false},
  "restrictions": ["version_files_and_tags_only"]
}
EOF
}

_agent_def_devops() {
  cat << 'EOF'
{
  "role": "devops",
  "description": "DevOps agent - CI/CD, Docker, infrastructure",
  "skills": ["cicd_pipelines", "docker", "infrastructure_debugging", "deployment"],
  "tools": ["read_file", "write_file", "run_commands", "search_files"],
  "permissions": {"write_code": true, "git_access": false, "mr_create": false, "merge": false},
  "restrictions": ["infra_and_ci_files_only"]
}
EOF
}

# ============================================================================
# Permission Matrix Enforcement
# ============================================================================

# Print the permission matrix
kiro-permissions() {
  cat << 'EOF'
┌─────────────────────┬────────────┬────────────┬───────────┬───────┐
│ Agent               │ Write Code │ Git Access │ MR Create │ Merge │
├─────────────────────┼────────────┼────────────┼───────────┼───────┤
│ Dev Agent           │     ✅     │     ✅     │     ❌    │  ❌   │
│ Test Agent          │     ❌     │     ❌     │     ❌    │  ❌   │
│ Quality Agent       │     ✅     │     ❌     │     ❌    │  ❌   │
│ Security Agent      │     ❌     │     ❌     │     ❌    │  ❌   │
│ Contract Agent      │     ✅     │     ❌     │     ❌    │  ❌   │
│ Performance Agent   │     ❌     │     ❌     │     ❌    │  ❌   │
│ Refactor Agent      │     ✅     │     ❌     │     ❌    │  ❌   │
│ RIA (READ)          │     ❌     │     ❌     │     ❌    │  ❌   │
│ RIA (PLAN)          │     ❌     │     ❌     │     ❌    │  ❌   │
│ RIA (WRITE)         │     ✅     │     ✅     │     ✅    │  ❌   │
│ Master Agent        │     ❌     │     ❌     │     ❌    │  ❌   │
│ PR Review Agent     │     ❌     │     ❌     │     ❌    │  ❌   │
│ Release Agent       │     ❌     │     ✅     │     ❌    │  ❌   │
│ DevOps Agent        │     ✅     │     ❌     │     ❌    │  ❌   │
└─────────────────────┴────────────┴────────────┴───────────┴───────┘

Legend: ✅ = Allowed  ❌ = Blocked  
Rule: Only YOU can merge. Always.
EOF
}

# Validate agent permission before action
_kiro_check_permission() {
  local agent_role="$1"
  local action="$2"  # write_code | git_access | mr_create | merge
  
  local def_output
  case "$agent_role" in
    dev)         def_output=$(_agent_def_dev) ;;
    test)        def_output=$(_agent_def_test) ;;
    quality)     def_output=$(_agent_def_quality) ;;
    security)    def_output=$(_agent_def_security) ;;
    contract)    def_output=$(_agent_def_contract) ;;
    performance) def_output=$(_agent_def_performance) ;;
    refactor)    def_output=$(_agent_def_refactor) ;;
    ria-read)    def_output=$(_agent_def_ria READ) ;;
    ria-plan)    def_output=$(_agent_def_ria PLAN) ;;
    ria-write)   def_output=$(_agent_def_ria WRITE) ;;
    master)      def_output=$(_agent_def_master) ;;
    pr-review)   def_output=$(_agent_def_pr_review) ;;
    release)     def_output=$(_agent_def_release) ;;
    devops)      def_output=$(_agent_def_devops) ;;
    *) echo "❌ Unknown agent: $agent_role"; return 1 ;;
  esac
  
  if command -v jq &>/dev/null; then
    local allowed
    if [[ "$agent_role" == ria-* ]]; then
      local mode="${agent_role#ria-}"
      allowed=$(echo "$def_output" | jq -r ".permissions_by_mode.${mode^^}.${action} // false")
    else
      allowed=$(echo "$def_output" | jq -r ".permissions.${action} // false")
    fi
    
    if [ "$allowed" = "true" ]; then
      echo "✅ $agent_role: $action ALLOWED"
      return 0
    else
      echo "🚫 $agent_role: $action BLOCKED"
      return 1
    fi
  else
    echo "⚠️  jq not installed - cannot validate permissions"
    return 1
  fi
}

# Show agent definition
kiro-agent-info() {
  local role="$1"
  if [ -z "$role" ]; then
    echo "Usage: kiro-agent-info <role>"
    echo "Roles: dev test quality security contract performance refactor"
    echo "       ria-read ria-plan ria-write master pr-review release devops"
    return 1
  fi
  case "$role" in
    dev)         _agent_def_dev | jq . ;;
    test)        _agent_def_test | jq . ;;
    quality)     _agent_def_quality | jq . ;;
    security)    _agent_def_security | jq . ;;
    contract)    _agent_def_contract | jq . ;;
    performance) _agent_def_performance | jq . ;;
    refactor)    _agent_def_refactor | jq . ;;
    ria-read)    _agent_def_ria READ | jq . ;;
    ria-plan)    _agent_def_ria PLAN | jq . ;;
    ria-write)   _agent_def_ria WRITE | jq . ;;
    master)      _agent_def_master | jq . ;;
    pr-review)   _agent_def_pr_review | jq . ;;
    release)     _agent_def_release | jq . ;;
    devops)      _agent_def_devops | jq . ;;
    *) echo "Unknown role: $role" ;;
  esac
}

# ============================================================================
# RIA Mode Management
# ============================================================================

# Current RIA mode tracking (per-service)
_KIRO_RIA_MODE="READ"

kiro-ria() {
  local service="$1"
  local mode="${2:-READ}"
  mode=$(echo "$mode" | tr '[:lower:]' '[:upper:]')
  
  if [ -z "$service" ]; then
    echo "Usage: kiro-ria <service> [READ|PLAN|WRITE]"
    echo ""
    echo "Modes:"
    echo "  READ  (default) - Answer questions, trace flows, explain architecture"
    echo "  PLAN  - Impact analysis, change proposals, generate diffs"
    echo "  WRITE - Create branch, apply patch, run pipeline, open Draft MR"
    echo ""
    echo "Current mode: $_KIRO_RIA_MODE"
    return 1
  fi
  
  case "$mode" in
    READ|PLAN)
      _KIRO_RIA_MODE="$mode"
      echo "🧠 RIA [$service] → mode: $mode"
      ;;
    WRITE)
      echo "⚠️  WRITE mode requested for $service"
      echo "   This allows: branch creation, code changes, MR creation"
      echo "   This NEVER allows: merge, approve, push to protected branches"
      read -p "   Confirm WRITE mode? (yes/no): " confirm
      if [ "$confirm" = "yes" ]; then
        _KIRO_RIA_MODE="WRITE"
        echo "✍️  RIA [$service] → mode: WRITE (approved)"
      else
        echo "❌ WRITE mode denied. Staying in $_KIRO_RIA_MODE"
      fi
      ;;
    *)
      echo "❌ Invalid mode: $mode (use READ, PLAN, or WRITE)"
      return 1
      ;;
  esac
}

# Quick aliases for RIA modes
kiro-ria-read() { kiro-ria "${1:-$(basename $(pwd))}" READ; }
kiro-ria-plan() { kiro-ria "${1:-$(basename $(pwd))}" PLAN; }
kiro-ria-write() { kiro-ria "${1:-$(basename $(pwd))}" WRITE; }
kiro-ria-status() { echo "RIA Mode: $_KIRO_RIA_MODE"; }

# ============================================================================
# Knowledge Indexing (RIA Knowledge Backbone)
# ============================================================================
# Maintains: code-index.json, dependency-graph.json, api-map.json, symbols.json

# Initialize knowledge directory for a service
kiro-knowledge-init() {
  local service_dir="${1:-$(pwd)}"
  local knowledge_dir="$service_dir/.kiro/knowledge"
  
  mkdir -p "$knowledge_dir"
  
  # Initialize empty knowledge files
  [ ! -f "$knowledge_dir/code-index.json" ] && echo '{"files": {}, "last_indexed": ""}' > "$knowledge_dir/code-index.json"
  [ ! -f "$knowledge_dir/dependency-graph.json" ] && echo '{"nodes": [], "edges": []}' > "$knowledge_dir/dependency-graph.json"
  [ ! -f "$knowledge_dir/api-map.json" ] && echo '{"routes": [], "handlers": {}, "schemas": {}}' > "$knowledge_dir/api-map.json"
  [ ! -f "$knowledge_dir/symbols.json" ] && echo '{"functions": [], "classes": [], "exports": []}' > "$knowledge_dir/symbols.json"
  [ ! -f "$knowledge_dir/summaries.md" ] && echo "# Service Knowledge Summary\n\nGenerated: $(date -Iseconds)\n" > "$knowledge_dir/summaries.md"
  
  echo "✅ Knowledge directory initialized: $knowledge_dir"
  echo "   Files created:"
  ls -1 "$knowledge_dir"
}

# Build code index (file descriptions)
kiro-knowledge-index() {
  local service_dir="${1:-$(pwd)}"
  local knowledge_dir="$service_dir/.kiro/knowledge"
  
  if [ ! -d "$knowledge_dir" ]; then
    echo "Run 'kiro-knowledge-init' first"
    return 1
  fi
  
  echo "📚 Indexing codebase: $service_dir"
  
  local index_file="$knowledge_dir/code-index.json"
  local tmp_file=$(mktemp)
  
  echo '{"files": {' > "$tmp_file"
  local first=true
  
  # Index source files (skip node_modules, .git, dist, build, __pycache__)
  while IFS= read -r -d '' file; do
    local rel_path="${file#$service_dir/}"
    local ext="${file##*.}"
    local lines=$(wc -l < "$file" 2>/dev/null || echo 0)
    
    if [ "$first" = true ]; then
      first=false
    else
      echo "," >> "$tmp_file"
    fi
    printf '    "%s": {"ext": "%s", "lines": %d}' "$rel_path" "$ext" "$lines" >> "$tmp_file"
  done < <(find "$service_dir" -type f \
    \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.java" -o -name "*.rb" -o -name "*.rs" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/__pycache__/*" ! -path "*/.kiro/*" \
    -print0)
  
  echo "" >> "$tmp_file"
  echo "  }, \"last_indexed\": \"$(date -Iseconds)\", \"total_files\": $(find "$service_dir" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" \) ! -path "*/node_modules/*" ! -path "*/.git/*" | wc -l)}" >> "$tmp_file"
  
  mv "$tmp_file" "$index_file"
  echo "✅ Code index updated: $(jq '.total_files // 0' "$index_file" 2>/dev/null || echo '?') files indexed"
}

# Build dependency graph (imports/requires)
kiro-knowledge-deps() {
  local service_dir="${1:-$(pwd)}"
  local knowledge_dir="$service_dir/.kiro/knowledge"
  
  if [ ! -d "$knowledge_dir" ]; then
    echo "Run 'kiro-knowledge-init' first"
    return 1
  fi
  
  echo "🔗 Building dependency graph: $service_dir"
  
  local graph_file="$knowledge_dir/dependency-graph.json"
  local tmp_file=$(mktemp)
  
  echo '{"edges": [' > "$tmp_file"
  local first=true
  
  # Python imports
  while IFS= read -r -d '' file; do
    local rel_path="${file#$service_dir/}"
    grep -E "^(from|import) " "$file" 2>/dev/null | while read -r line; do
      local dep=$(echo "$line" | sed -E 's/^(from |import )([^ ]+).*/\2/' | tr '.' '/')
      if [ "$first" = true ]; then
        first=false
      else
        printf "," >> "$tmp_file"
      fi
      printf '\n  {"source": "%s", "target": "%s"}' "$rel_path" "$dep" >> "$tmp_file"
    done
  done < <(find "$service_dir" -name "*.py" ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/__pycache__/*" -print0)
  
  # JS/TS imports
  while IFS= read -r -d '' file; do
    local rel_path="${file#$service_dir/}"
    grep -E "^(import|const .* = require)" "$file" 2>/dev/null | grep -oE "(from ['\"]([^'\"]+)['\"]|require\(['\"]([^'\"]+)['\"]\))" | sed -E "s/(from |require\()//;s/['\"\)]//g" | while read -r dep; do
      printf ',\n  {"source": "%s", "target": "%s"}' "$rel_path" "$dep" >> "$tmp_file"
    done
  done < <(find "$service_dir" \( -name "*.js" -o -name "*.ts" \) ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" -print0)
  
  echo "" >> "$tmp_file"
  echo '], "last_built": "'"$(date -Iseconds)"'"}' >> "$tmp_file"
  
  mv "$tmp_file" "$graph_file"
  echo "✅ Dependency graph updated"
}

# Build API map (routes/endpoints)
kiro-knowledge-api() {
  local service_dir="${1:-$(pwd)}"
  local knowledge_dir="$service_dir/.kiro/knowledge"
  
  if [ ! -d "$knowledge_dir" ]; then
    echo "Run 'kiro-knowledge-init' first"
    return 1
  fi
  
  echo "🌐 Building API map: $service_dir"
  
  local api_file="$knowledge_dir/api-map.json"
  local tmp_file=$(mktemp)
  
  echo '{"routes": [' > "$tmp_file"
  local first=true
  
  # Detect Express/Fastify routes
  grep -rn "\\.\(get\|post\|put\|patch\|delete\|all\)(" "$service_dir" \
    --include="*.js" --include="*.ts" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist 2>/dev/null | \
    grep -v "test\|spec\|mock" | head -100 | while IFS=: read -r file line content; do
      local rel="${file#$service_dir/}"
      local method=$(echo "$content" | grep -oE "\.(get|post|put|patch|delete|all)" | tr -d '.')
      local route=$(echo "$content" | grep -oE "['\"/][^'\"]*['\"]" | head -1 | tr -d "'\"")
      if [ -n "$method" ] && [ -n "$route" ]; then
        if [ "$first" = true ]; then first=false; else printf "," >> "$tmp_file"; fi
        printf '\n  {"method": "%s", "path": "%s", "file": "%s", "line": %s}' "$method" "$route" "$rel" "$line" >> "$tmp_file"
      fi
  done
  
  # Detect Django/Flask routes
  grep -rn "@app\.\(route\|get\|post\|put\|delete\)\|path(" "$service_dir" \
    --include="*.py" \
    --exclude-dir=__pycache__ --exclude-dir=.git --exclude-dir=venv 2>/dev/null | \
    head -100 | while IFS=: read -r file line content; do
      local rel="${file#$service_dir/}"
      local route=$(echo "$content" | grep -oE "['\"/][^'\"]*['\"]" | head -1 | tr -d "'\"")
      if [ -n "$route" ]; then
        printf ',\n  {"method": "?", "path": "%s", "file": "%s", "line": %s}' "$route" "$rel" "$line" >> "$tmp_file"
      fi
  done
  
  echo "" >> "$tmp_file"
  echo '], "last_built": "'"$(date -Iseconds)"'"}' >> "$tmp_file"
  
  mv "$tmp_file" "$api_file"
  echo "✅ API map updated"
}

# Full knowledge rebuild
kiro-knowledge-rebuild() {
  local service_dir="${1:-$(pwd)}"
  echo "🔄 Full knowledge rebuild for: $service_dir"
  echo ""
  kiro-knowledge-init "$service_dir"
  kiro-knowledge-index "$service_dir"
  kiro-knowledge-deps "$service_dir"
  kiro-knowledge-api "$service_dir"
  echo ""
  echo "✅ Knowledge rebuild complete"
  echo "   Location: $service_dir/.kiro/knowledge/"
}

# Show knowledge status
kiro-knowledge-status() {
  local service_dir="${1:-$(pwd)}"
  local knowledge_dir="$service_dir/.kiro/knowledge"
  
  if [ ! -d "$knowledge_dir" ]; then
    echo "❌ No knowledge directory found. Run: kiro-knowledge-init"
    return 1
  fi
  
  echo "📚 Knowledge Status: $service_dir"
  echo "─────────────────────────────────────"
  
  for f in code-index.json dependency-graph.json api-map.json symbols.json; do
    if [ -f "$knowledge_dir/$f" ]; then
      local size=$(wc -c < "$knowledge_dir/$f")
      local updated=$(jq -r '.last_indexed // .last_built // "unknown"' "$knowledge_dir/$f" 2>/dev/null || echo "?")
      printf "  ✅ %-25s %6s bytes  (updated: %s)\n" "$f" "$size" "$updated"
    else
      printf "  ❌ %-25s missing\n" "$f"
    fi
  done
}

# ============================================================================
# Agent Squad Orchestration
# ============================================================================

# Run full agent pipeline on a service (Dev → Test → Quality → Security → Contract → Perf)
kiro-squad-pipeline() {
  local service="${1:-$(basename $(pwd))}"
  echo "🚀 Agent Squad Pipeline: $service"
  echo "═══════════════════════════════════════"
  echo ""
  echo "Pipeline order:"
  echo "  1. 🛠️  Dev Agent        → Code generation"
  echo "  2. 🧪 Test Agent       → Test creation & execution"
  echo "  3. 📏 Quality Agent    → Lint, format, architecture"
  echo "  4. 🔐 Security Agent   → Vulnerability scan"
  echo "  5. 📚 Contract Agent   → API schema validation"
  echo "  6. ⚡ Performance Agent → Perf analysis"
  echo "  7. 🧠 RIA (READ)       → Impact verification"
  echo ""
  echo "Use: kiro-cli chat --agent $service"
  echo "Then instruct the agent to run the pipeline."
}

# List all agent roles and their capabilities
kiro-squad-list() {
  echo "🧩 AI Agent Squad - Per-Service Roles"
  echo "══════════════════════════════════════"
  echo ""
  echo "Per-Service Agents:"
  echo "  🛠️  dev          - Writes production code"
  echo "  🧪 test         - Writes and runs tests"
  echo "  📏 quality      - Linting, formatting, clean architecture"
  echo "  🔐 security     - OWASP, auth, vulnerability scanning"
  echo "  📚 contract     - OpenAPI/schema validation"
  echo "  ⚡ performance  - Query optimization, latency analysis"
  echo "  🔄 refactor     - Code simplification, dead code removal"
  echo "  🧠 ria          - Repo Intelligence (READ/PLAN/WRITE)"
  echo ""
  echo "Global Agents:"
  echo "  🎯 master       - Task decomposition, orchestration"
  echo "  🤖 pr-review    - Code review on MRs"
  echo "  🚀 release      - Versioning, changelog, tagging"
  echo "  ⚙️  devops       - CI/CD, Docker, infrastructure"
  echo ""
  echo "Commands:"
  echo "  kiro-agent-info <role>     - Show agent definition"
  echo "  kiro-permissions           - Show permission matrix"
  echo "  kiro-ria <svc> [mode]      - Switch RIA mode"
  echo "  kiro-knowledge-rebuild     - Rebuild knowledge index"
}

# ============================================================================
# AIDLC Workflow Integration
# ============================================================================
# AI-DLC (AI-Driven Development Life Cycle) steering rules
# Phases: Inception → Construction → Operations

# Initialize AIDLC for a project (copies steering rules)
kiro-aidlc-init() {
  local project_dir="${1:-$(pwd)}"
  
  # Source from ai-toolkit (canonical) or fallback to .kiro (legacy)
  local rules_src="$HOME/ai-toolkit/workflows/aidlc-workflows/aidlc-rules/aws-aidlc-rules"
  [ ! -d "$rules_src" ] && rules_src="$HOME/.kiro/steering/aws-aidlc-rules"
  
  local details_src="$HOME/ai-toolkit/workflows/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details"
  [ ! -d "$details_src" ] && details_src="$HOME/.kiro/aws-aidlc-rule-details"
  
  if [ ! -d "$rules_src" ]; then
    echo "❌ AIDLC rules not found"
    echo "   Expected at: ~/ai-toolkit/workflows/aidlc-workflows/aidlc-rules/"
    echo "   Or fallback: ~/.kiro/steering/aws-aidlc-rules/"
    return 1
  fi
  
  mkdir -p "$project_dir/.kiro/steering"
  cp -R "$rules_src" "$project_dir/.kiro/steering/"
  
  if [ -d "$details_src" ]; then
    cp -R "$details_src" "$project_dir/.kiro/"
  fi
  
  echo "✅ AIDLC initialized for: $project_dir"
  echo "   Phases: Inception → Construction → Operations"
  echo "   Source: $rules_src"
  echo ""
  echo "   Start with: 'Describe what you want to build'"
  echo "   The workflow will guide you through structured gates."
}

# Show AIDLC status for current project
kiro-aidlc-status() {
  local project_dir="${1:-$(pwd)}"
  
  echo "📋 AIDLC Status: $project_dir"
  echo "─────────────────────────────────"
  
  if [ -d "$project_dir/.kiro/steering/aws-aidlc-rules" ]; then
    echo "  ✅ Steering rules: loaded"
  else
    echo "  ❌ Steering rules: not found (run kiro-aidlc-init)"
  fi
  
  if [ -d "$project_dir/.kiro/aws-aidlc-rule-details" ]; then
    echo "  ✅ Rule details: loaded"
  else
    echo "  ⚠️  Rule details: not found"
  fi
  
  if [ -d "$project_dir/aidlc-docs" ]; then
    echo "  ✅ AIDLC docs: present"
    echo "     Phases found:"
    [ -d "$project_dir/aidlc-docs/inception" ] && echo "       📝 Inception"
    [ -d "$project_dir/aidlc-docs/construction" ] && echo "       🔨 Construction"
    [ -d "$project_dir/aidlc-docs/operations" ] && echo "       🚀 Operations"
  else
    echo "  ℹ️  AIDLC docs: not yet generated (start a conversation)"
  fi
}

# ============================================================================
# Help
# ============================================================================

kiro-help() {
  cat << 'EOF'
🧠 Kiro AI Agent System - Command Reference
═══════════════════════════════════════════════

BASIC:
  kiro                          Smart start (auto-detect project)
  kiro-<project>                Start agent for specific project
  kiro-cleanup                  Delete all agents and history
  kiro-regenerate <name>        Recreate agent with fresh detection
  kiro-edit-prompt <name>       Edit agent prompt

AGENT SQUAD:
  kiro-squad-list               List all agent roles
  kiro-squad-pipeline <svc>     Show pipeline order
  kiro-agent-info <role>        Show agent tools/skills/permissions
  kiro-permissions              Show permission matrix

REPO INTELLIGENCE (RIA):
  kiro-ria <svc> READ           Safe mode - questions only
  kiro-ria <svc> PLAN           Impact analysis, change proposals
  kiro-ria <svc> WRITE          Branch + patch + MR (needs approval)
  kiro-ria-status               Show current RIA mode

KNOWLEDGE INDEXING:
  kiro-knowledge-init [dir]     Initialize knowledge directory
  kiro-knowledge-index [dir]    Build code file index
  kiro-knowledge-deps [dir]     Build dependency graph
  kiro-knowledge-api [dir]      Build API route map
  kiro-knowledge-rebuild [dir]  Full rebuild (all of the above)
  kiro-knowledge-status [dir]   Show knowledge freshness

AIDLC WORKFLOW:
  kiro-aidlc-init [dir]         Initialize AIDLC for a project
  kiro-aidlc-status [dir]       Show AIDLC phase status

GIT + AI:
  gcai                          Generate commit message from staged
  greview                       Review current diff
  greview-staged                Review staged changes
  gpr-desc                      Generate PR description
EOF
}

# ============================================================================
# Cross-Service Master Agent (Multi-Service Orchestrator)
# ============================================================================
# Creates a master agent aware of ALL services in ~/applications
# Drives development using AIDLC workflow + AI Engineering Toolkit skills
# Communicates with per-service agents to coordinate cross-cutting changes

kiro-master() {
  local requirement="$1"
  local apps_dir="$HOME/applications"
  local agent_name="master-orchestrator"
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"
  
  # Discover all services
  local services=""
  local service_list=""
  for dir in "$apps_dir"/*/; do
    [ -d "$dir" ] || continue
    local svc=$(basename "$dir")
    services="${services}${svc}, "
    local info=$(detect_project_info "$dir")
    local stack=$(echo "$info" | cut -d'|' -f2)
    service_list="${service_list}\\n- ${svc} (${stack})"
  done
  services="${services%, }"
  
  # Always recreate to pick up latest services
  rm -f "$agent_file"
  mkdir -p "$HOME/.kiro/agents"
  
  local prompt=$(cat << PROMPT
You are the MASTER ORCHESTRATOR agent for a multi-service system.

═══════════════════════════════════════════════════════════════
ROLE: Cross-service coordinator and architect
MODE: WRITE (full authority to delegate and drive implementation)
═══════════════════════════════════════════════════════════════

## Services Under Your Command
${service_list}

## Your Capabilities
- Decompose requirements across multiple services
- Delegate tasks to per-service agents (dev, test, quality, security, contract, performance, refactor, RIA)
- Perform cross-service impact analysis before changes
- Coordinate API contracts between services
- Drive the full AIDLC workflow (Inception → Construction → Operations)

## Mandatory Workflow: AIDLC (AI-Driven Development Life Cycle)
You ALWAYS follow the AIDLC phases:

### Phase 1: Inception
- Requirements analysis (ask clarifying questions via markdown files)
- User stories generation
- Application design (architecture, data flow, API contracts)
- Workflow planning (task breakdown per service)

### Phase 2: Construction
- Functional design per service
- NFR requirements (security, performance, scalability)
- Infrastructure design
- Code generation (delegated to service agents)
- Build & test (delegated to service agents)

### Phase 3: Operations
- Deployment planning
- Monitoring and observability

## Mandatory Skills: AI Engineering Toolkit
Apply these on EVERY requirement:

1. **Prompt Evaluator** - Score and optimize any prompts/instructions (≥70/100 baseline)
2. **Context Budget Planner** - Optimize token allocation across services
3. **RAG Pipeline Architect** - When building knowledge/search features
4. **Agent Safety Guard** - Pre-launch security audit on any agent/AI feature
5. **Eval Harness Builder** - Set up evaluation for AI-powered features
6. **Product Sense Coach** - Validate product decisions before coding

## Agent Squad (Per Service)
For each service, you coordinate:
  Dev → Test → Quality → Security → Contract → Performance → Refactor
  With RIA (Repo Intelligence) for impact analysis

## Rules
- NEVER modify code directly — delegate to service agents
- ALWAYS perform cross-service impact analysis before changes
- ALWAYS use conventional commits: type(service): description
- ALWAYS create Draft MRs — never merge
- ALWAYS re-index knowledge after changes (kiro-knowledge-rebuild)
- Ask questions via markdown files, wait for answers
- Only YOU (the human) can approve and merge

## Cross-Service Coordination
Before any change:
1. Ask RIA of each affected service: "Impact of this change?"
2. Verify API contracts remain compatible
3. Check for breaking changes across service boundaries
4. Plan rollout order (dependencies first)

## Output Structure
/aidlc-docs/
  inception/
    requirements.md
    user-stories.md
    architecture.md
    workflow-plan.md
  construction/
    functional-design/
    nfr-design/
    infrastructure/
  operations/
    deployment-plan.md

Start by understanding the requirement, then drive through AIDLC phases.

## Active Skills (auto-loaded)
- caveman / caveman-compress: Context compression when sessions get long
- caveman-commit: Structured conventional commits
- caveman-review: Thorough code reviews
- cavecrew: Multi-agent coordination
- graphify: Build knowledge graphs from code for architecture mapping
- prompt-evaluator, context-budget-planner, rag-pipeline-architect
- agent-safety-guard, eval-harness-builder, product-sense-coach
PROMPT
)

  local escaped_prompt=$(echo "$prompt" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  
  cat > "$agent_file" << EOF
{
  "name": "$agent_name",
  "description": "Cross-service master orchestrator with AIDLC + AI Engineering Toolkit",
  "prompt": "$escaped_prompt",
  "tools": ["*"],
  "welcomeMessage": "🎯 Master Orchestrator Ready\\\\n\\\\n📦 Services: $services\\\\n🔄 Workflow: AIDLC (Inception → Construction → Operations)\\\\n🧠 Skills: AI Engineering Toolkit (6 workflows active)\\\\n\\\\n💡 Describe your requirement and I'll drive it through the full lifecycle.\\\\n",
  "hooks": {
    "agentSpawn": [
      {
        "command": "bash -c 'echo \"🎯 Master Agent initialized\" && echo \"Services: $services\" && echo \"Mode: WRITE (orchestrator)\" && echo \"Workflow: AIDLC + AI Engineering Toolkit\"'",
        "timeout_ms": 5000
      }
    ]
  }
}
EOF

  echo "🎯 Master Orchestrator created"
  echo "   Services: $services"
  echo "   Workflow: AIDLC + AI Engineering Toolkit"
  echo ""
  
  _KIRO_RIA_MODE="WRITE"
  kiro-start-with-init "$agent_name"
}

alias km='kiro-master'

# ============================================================================
# Single-Service AIDLC Driver (kiro-drive / kd)
# ============================================================================
# Like kiro-master but scoped to ONE repo. Drives full AIDLC lifecycle
# with AI Engineering Toolkit skills for a single service.

kiro-drive() {
  local service_dir="${1:-$(pwd)}"
  local service_name=$(basename "$service_dir")
  local agent_name="${service_name}-driver"
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"
  
  # Resolve if just a name was passed
  if [ ! -d "$service_dir" ]; then
    if [ -d "$HOME/applications/$1" ]; then
      service_dir="$HOME/applications/$1"
      service_name="$1"
    elif [ -d "$HOME/my_applications/$1" ]; then
      service_dir="$HOME/my_applications/$1"
      service_name="$1"
    else
      echo "❌ Service not found: $1"
      return 1
    fi
    agent_name="${service_name}-driver"
    agent_file="$HOME/.kiro/agents/${agent_name}.json"
  fi
  
  # Detect tech stack
  local info=$(detect_project_info "$service_dir")
  local tech_stack=$(echo "$info" | cut -d'|' -f2)
  local project_type=$(echo "$info" | cut -d'|' -f1)
  
  # Always recreate for fresh context
  rm -f "$agent_file"
  mkdir -p "$HOME/.kiro/agents"
  
  local prompt=$(cat << PROMPT
You are the AIDLC DRIVER for the ${service_name} service.

═══════════════════════════════════════════════════════════════
SERVICE: ${service_name}
STACK: ${tech_stack}
TYPE: ${project_type}
LOCATION: ${service_dir}
MODE: WRITE (full implementation authority)
═══════════════════════════════════════════════════════════════

## Your Role
Single-service architect + implementer. You own the full lifecycle
of any requirement in this repo — from inception to working code.

## Mandatory Workflow: AIDLC (AI-Driven Development Life Cycle)
You ALWAYS follow these phases in order:

### Phase 1: Inception
1. Requirements analysis — clarify scope, constraints, edge cases
2. User stories — write acceptance criteria
3. Application design — architecture decisions, data model, API design
4. Workflow planning — break into implementable tasks

### Phase 2: Construction
1. Functional design — detailed component/module design
2. NFR requirements — security, performance, scalability considerations
3. Infrastructure design — if infra changes needed
4. Code generation — implement following TDD (test first)
5. Build & test — verify everything passes

### Phase 3: Operations
1. Deployment notes — what needs to change in CI/CD
2. Monitoring — what to observe post-deploy

## Mandatory Skills: AI Engineering Toolkit
Apply these at the right phase:

| Skill | When |
|-------|------|
| **Prompt Evaluator** | Any AI/LLM prompts in the codebase (score ≥70/100) |
| **Context Budget Planner** | Any context window / token allocation decisions |
| **RAG Pipeline Architect** | Any retrieval/search/knowledge features |
| **Agent Safety Guard** | Pre-completion security audit |
| **Eval Harness Builder** | Any AI feature needs eval metrics |
| **Product Sense Coach** | Before coding — validate the "why" |

## Agent Squad (You Coordinate)
Run this pipeline on every change:
  Dev → Test → Quality → Security → Contract → Performance

## Rules
- Follow existing code patterns and conventions in this repo
- Write tests BEFORE implementation (TDD)
- Conventional commits: type(scope): description
- Create feature branches, never push to main/develop directly
- Draft MRs only — never merge
- Re-index knowledge after changes
- Ask clarifying questions via markdown when requirements are ambiguous
- Small, logical, reviewable commits

## Output Structure
aidlc-docs/
  inception/requirements.md
  inception/user-stories.md
  inception/design.md
  construction/functional-design.md
  construction/nfr.md

Start by understanding the requirement, then drive through AIDLC.

## Active Skills (auto-loaded)
- caveman / caveman-compress: Context compression when sessions get long
- caveman-commit: Structured conventional commits
- caveman-review: Thorough code reviews
- cavecrew: Multi-agent coordination
- graphify: Build knowledge graphs from code for architecture mapping
- prompt-evaluator, context-budget-planner, rag-pipeline-architect
- agent-safety-guard, eval-harness-builder, product-sense-coach
PROMPT
)

  local escaped_prompt=$(echo "$prompt" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  
  cat > "$agent_file" << EOF
{
  "name": "$agent_name",
  "description": "AIDLC driver for $service_name ($tech_stack)",
  "prompt": "$escaped_prompt",
  "tools": ["*"],
  "welcomeMessage": "🚀 AIDLC Driver: $service_name\\\\n\\\\n📦 Stack: $tech_stack\\\\n🔄 Workflow: AIDLC (Inception → Construction → Operations)\\\\n🧠 Skills: AI Engineering Toolkit active\\\\n\\\\n💡 Describe your requirement and I'll drive it through the full lifecycle.\\\\n",
  "hooks": {
    "agentSpawn": [
      {
        "command": "bash -c 'echo \"🚀 AIDLC Driver: $service_name\" && echo \"Stack: $tech_stack\" && echo \"Mode: WRITE + AIDLC + AI Engineering Toolkit\"'",
        "timeout_ms": 5000
      }
    ]
  }
}
EOF

  echo "🚀 AIDLC Driver created for: $service_name"
  echo "   Stack: $tech_stack"
  echo "   Workflow: AIDLC + AI Engineering Toolkit"
  echo ""
  
  cd "$service_dir"
  _KIRO_RIA_MODE="WRITE"
  kiro-start-with-init "$agent_name"
}

alias kd='kiro-drive'
