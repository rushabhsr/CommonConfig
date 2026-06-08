#!/bin/bash
# ============================================================================
# Kiro AI Environment Bootstrap (v2 - optimized)
# Run: bash ~/CommonConfig/kiro-bootstrap.sh
# ============================================================================
set -e

echo "🚀 Kiro AI Environment Bootstrap v2"
echo "═══════════════════════════════════"

# ============================================================================
# 1. Prerequisites
# ============================================================================
echo ""
echo "📋 Checking prerequisites..."
command -v git >/dev/null || { echo "❌ git not found"; exit 1; }
command -v node >/dev/null || { echo "❌ node not found"; exit 1; }
echo "  ✅ git, node found"

# ============================================================================
# 2. Directory structure
# ============================================================================
echo ""
echo "📁 Setting up directories..."
mkdir -p ~/.local/bin ~/.kiro/{agents,skills,settings,sessions} ~/applications
echo "  ✅ Done"

# ============================================================================
# 3. MCP config
# ============================================================================
echo ""
echo "🔌 Configuring MCP..."
cat > ~/.kiro/settings/mcp.json << 'EOF'
{
  "mcpServers": {
    "agentmemory": {
      "command": "npx",
      "args": ["-y", "@agentmemory/mcp"],
      "env": { "AGENTMEMORY_URL": "http://localhost:3111" }
    }
  }
}
EOF
echo "  ✅ MCP config written"

# ============================================================================
# 4. Kiro skills (from CommonConfig)
# ============================================================================
echo ""
echo "⚡ Setting up Kiro skills..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/kiro-skills" ]; then
  mkdir -p ~/.kiro/skills
  cp -r "$SCRIPT_DIR/kiro-skills"/* ~/.kiro/skills/ 2>/dev/null
  echo "  ✅ Skills copied"
else
  echo "  ⚠️  No kiro-skills/ found"
fi

# ============================================================================
# 5. Detect project type (FIXED - properly identifies Express.js backends)
# ============================================================================

detect_project_type() {
  local dir="$1"

  # Django/Python backend
  if [ -f "$dir/manage.py" ] || [ -f "$dir/requirements.txt" ]; then
    if [ -f "$dir/manage.py" ]; then
      echo "Django, Python"
    else
      echo "Python"
    fi
    return
  fi

  # Node.js projects - distinguish backend from frontend
  if [ -f "$dir/package.json" ]; then
    local pkg="$dir/package.json"

    # Check for backend frameworks FIRST
    if grep -qE '"(express|fastify|koa|hapi|nestjs|@nestjs)' "$pkg" 2>/dev/null; then
      local framework=""
      grep -q '"express"' "$pkg" && framework="Express.js"
      grep -q '"fastify"' "$pkg" && framework="Fastify"
      grep -q '"@nestjs' "$pkg" && framework="NestJS"
      grep -q '"koa"' "$pkg" && framework="Koa"
      [ -z "$framework" ] && framework="Node.js"
      echo "$framework"
      return
    fi

    # Check for frontend frameworks
    if grep -qE '"(react|vue|@angular|next|nuxt|svelte)' "$pkg" 2>/dev/null; then
      local framework=""
      grep -q '"next"' "$pkg" && framework="React, Next.js" && echo "$framework" && return
      grep -q '"react"' "$pkg" && framework="React"
      grep -q '"vue"' "$pkg" && framework="Vue.js"
      grep -q '"@angular' "$pkg" && framework="Angular"
      grep -q '"svelte"' "$pkg" && framework="Svelte"
      [ -z "$framework" ] && framework="Frontend"
      echo "$framework"
      return
    fi

    # AWS Lambda (SAM/Serverless)
    if [ -f "$dir/template.yaml" ] || [ -f "$dir/serverless.yml" ]; then
      echo "AWS Lambda, Node.js"
      return
    fi

    # Has src/ with .js files but no framework = Node.js scripts/jobs
    if [ -d "$dir/src" ]; then
      echo "Node.js"
      return
    fi

    echo "Node.js"
    return
  fi

  # Go
  [ -f "$dir/go.mod" ] && echo "Go" && return

  # Rust
  [ -f "$dir/Cargo.toml" ] && echo "Rust" && return

  # Static files / docs / scripts
  if [ -d "$dir/.git" ]; then
    # Check if mostly docs/scripts
    local py_count=$(find "$dir" -maxdepth 2 -name "*.py" ! -path "*/.git/*" 2>/dev/null | wc -l)
    local sh_count=$(find "$dir" -maxdepth 2 -name "*.sh" ! -path "*/.git/*" 2>/dev/null | wc -l)
    local md_count=$(find "$dir" -maxdepth 2 -name "*.md" ! -path "*/.git/*" 2>/dev/null | wc -l)

    if [ "$py_count" -gt 0 ] && [ "$sh_count" -gt 0 ]; then
      echo "Scripts (Python, Shell)"
      return
    fi
    [ "$sh_count" -gt 2 ] && echo "Shell Scripts" && return
    [ "$md_count" -gt 2 ] && echo "Documentation" && return
  fi

  echo "General Development"
}

detect_project_category() {
  local dir="$1"
  local stack="$2"

  case "$stack" in
    *Django*|*Python*|*Express*|*Fastify*|*NestJS*|*Koa*|*Node.js*)
      # Backend if it has routes/controllers/API patterns
      if [ -f "$dir/manage.py" ] || grep -rql "router\|app\.\(get\|post\|put\)" "$dir/src" 2>/dev/null || [ -f "$dir/Dockerfile" ]; then
        echo "backend"
      else
        echo "backend"
      fi
      ;;
    *React*|*Vue*|*Angular*|*Svelte*|*Frontend*)
      echo "frontend"
      ;;
    *Next.js*)
      echo "fullstack"
      ;;
    *Lambda*)
      echo "lambda"
      ;;
    *Scripts*|*Shell*)
      echo "scripts"
      ;;
    *Documentation*)
      echo "docs"
      ;;
    *)
      echo "general"
      ;;
  esac
}

# ============================================================================
# 6. Generate lean agent configs for all services
# ============================================================================
echo ""
echo "🤖 Generating agent configs..."

generate_agent() {
  local dir="${1%/}"
  local folder_name=$(basename "$dir")
  local agent_name=$(echo "$folder_name" | sed 's/_/-/g')
  local agent_file="$HOME/.kiro/agents/${agent_name}.json"

  # Skip non-project dirs
  [[ "$folder_name" == *" "* ]] && return
  [ ! -d "$dir/.git" ] && [ ! -f "$dir/package.json" ] && [ ! -f "$dir/manage.py" ] && [ ! -f "$dir/requirements.txt" ] && return

  local stack=$(detect_project_type "$dir")
  local category=$(detect_project_category "$dir" "$stack")

  # Lean prompt - only service-specific context, no generic advice
  local prompt="You are an AI agent for the ${agent_name} project.\\n\\nTech: ${stack}\\nType: ${category}\\nPath: ${dir}/\\n\\nCode search strategy (ALWAYS follow):\\n1. Use knowledge search tool FIRST to find relevant code\\n2. Use /graphify to map dependencies and architecture\\n3. Use code tool (pattern_search, search_symbols) for precise lookups\\n4. Only read full files after locating the exact target\\n\\nUse caveman mode (compressed output) by default. Read before writing. Test after changes."

  cat > "$agent_file" << EOF
{
  "name": "$agent_name",
  "description": "AI agent for $agent_name project ($stack)",
  "prompt": "$prompt",
  "tools": ["*"],
  "welcomeMessage": "🚀 $agent_name ($stack) — $dir/\\n",
  "hooks": {
    "agentSpawn": [{"command": "bash -c 'echo \"📂 $agent_name ($stack) | $category\"'", "timeout_ms": 3000}],
    "stop": [{"command": "bash -c 'date >> ~/.kiro/sessions/$agent_name.log'", "timeout_ms": 2000}]
  }
}
EOF
  echo "  ✅ $agent_name ($stack → $category)"
}

# Process all application directories
for dir in "$HOME/applications"/*/; do
  [ -d "$dir" ] || continue
  generate_agent "$dir"
done

# ============================================================================
# 7. Ensure .bashrc sources kiroAliases
# ============================================================================
echo ""
echo "📝 Checking .bashrc..."
grep -q '\.local/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
if ! grep -q "kiroAliases.sh" ~/.bashrc 2>/dev/null; then
  echo -e '\n# Kiro AI aliases\nsource "$HOME/CommonConfig/shell-aliases/kiroAliases.sh"' >> ~/.bashrc
fi
echo "  ✅ .bashrc configured"

# ============================================================================
# 8. Summary
# ============================================================================
echo ""
echo "═══════════════════════════════════"
echo "✅ Bootstrap complete!"
echo ""
echo "Agents created: $(ls ~/.kiro/agents/*.json 2>/dev/null | wc -l)"
echo "Skills: $(ls ~/.kiro/skills/ 2>/dev/null | wc -l) slash commands"
echo ""
echo "Next: source ~/.bashrc && kiro (in any project)"
