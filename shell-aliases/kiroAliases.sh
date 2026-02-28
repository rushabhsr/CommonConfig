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
EOF
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
}

# Smart kiro command - auto-detect project and use appropriate agent
kiro() {
  local current_dir=$(pwd)
  
  # Check if we're in ~/applications or ~/my_applications
  if [[ "$current_dir" == "$HOME/applications/"* ]] || [[ "$current_dir" == "$HOME/my_applications/"* ]]; then
    # Extract project name (first directory after applications/)
    local project_path
    if [[ "$current_dir" == "$HOME/applications/"* ]]; then
      project_path="${current_dir#$HOME/applications/}"
    else
      project_path="${current_dir#$HOME/my_applications/}"
    fi
    
    local project_name=$(echo "$project_path" | cut -d'/' -f1)
    local agent_name=$(echo "$project_name" | sed 's/_/-/g')
    
    # Get project root directory
    local project_root
    if [[ "$current_dir" == "$HOME/applications/"* ]]; then
      project_root="$HOME/applications/$project_name"
    else
      project_root="$HOME/my_applications/$project_name"
    fi
    
    # Ensure agent exists
    ensure_kiro_agent "$agent_name" "$project_root"
    
    echo "Starting kiro-cli with agent: $agent_name"
    kiro-start-with-init "$agent_name" "$@"
  else
    # Not in a project directory, use default
    kiro-cli chat "$@"
  fi
}

# ============================================================================
# Auto-generate Kiro Aliases for Applications
# ============================================================================

create_kiro_aliases() {
  local apps_dir="$HOME/applications"
  local my_apps_dir="$HOME/my_applications"
  
  # Create aliases for ~/applications
  if [ -d "$apps_dir" ]; then
    for dir in "$apps_dir"/*/; do
      [ -d "$dir" ] || continue
      local folder_name=$(basename "$dir")
      local agent_name=$(echo "$folder_name" | sed 's/_/-/g')
      
      alias "kiro-$folder_name"="ensure_kiro_agent '$agent_name' '$dir' && cd '$dir' && kiro-start-with-init '$agent_name'"
      alias "k-$folder_name"="ensure_kiro_agent '$agent_name' '$dir' && cd '$dir' && kiro-start-with-init '$agent_name'"
    done
  fi
  
  # Create aliases for ~/my_applications
  if [ -d "$my_apps_dir" ]; then
    for dir in "$my_apps_dir"/*/; do
      [ -d "$dir" ] || continue
      local folder_name=$(basename "$dir")
      local agent_name=$(echo "$folder_name" | sed 's/_/-/g')
      
      alias "kiro-$folder_name"="ensure_kiro_agent '$agent_name' '$dir' && cd '$dir' && kiro-start-with-init '$agent_name'"
      alias "k-$folder_name"="ensure_kiro_agent '$agent_name' '$dir' && cd '$dir' && kiro-start-with-init '$agent_name'"
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
  elif [ -d "$HOME/my_applications/$agent_name" ]; then
    project_dir="$HOME/my_applications/$agent_name"
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
alias gcai='git diff --cached | kiro-cli chat --prompt "Generate a concise, conventional commit message for these changes. Format: type(scope): description"'

# Code review current changes
alias greview='git diff | kiro-cli chat --prompt "Review this code for issues, bugs, improvements, and best practices. Be specific and actionable."'

# Code review staged changes
alias greview-staged='git diff --cached | kiro-cli chat --prompt "Review these staged changes for issues, bugs, improvements, and best practices. Be specific and actionable."'

# Generate PR description
alias gpr-desc='git log origin/main..HEAD --oneline | kiro-cli chat --prompt "Generate a detailed PR description from these commits. Include: summary, changes made, testing done, and any breaking changes."'

# Generate PR description (custom base branch)
alias gpr-desc-from='f() { git log origin/${1:-main}..HEAD --oneline | kiro-cli chat --prompt "Generate a detailed PR description from these commits. Include: summary, changes made, testing done, and any breaking changes."; }; f'

# Explain what changed between branches
alias gexplain='f() { git diff ${1:-main}...${2:-HEAD} | kiro-cli chat --prompt "Explain what changed in this diff in simple terms. Summarize the key changes and their purpose."; }; f'

# Suggest commit message for current changes
alias gsuggest='git diff | kiro-cli chat --prompt "Suggest a commit message for these changes. Format: type(scope): description"'

# ============================================================================
# Kiro Utility Functions
# ============================================================================
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
