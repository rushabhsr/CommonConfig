#!/bin/bash
# ============================================================================
# Kiro AI Environment Bootstrap
# Run on any new device: bash ~/CommonConfig/kiro-bootstrap.sh
# ============================================================================
set -e

echo "🚀 Kiro AI Environment Bootstrap"
echo "═══════════════════════════════════"

# ============================================================================
# 1. Prerequisites check
# ============================================================================
echo ""
echo "📋 Checking prerequisites..."

command -v git >/dev/null || { echo "❌ git not found. Install git first."; exit 1; }
command -v node >/dev/null || { echo "❌ node not found. Install Node.js first."; exit 1; }
command -v npm >/dev/null || { echo "❌ npm not found. Install Node.js first."; exit 1; }

echo "  ✅ git, node, npm found"

# ============================================================================
# 2. Directory structure
# ============================================================================
echo ""
echo "📁 Setting up directories..."

mkdir -p ~/.local/bin
mkdir -p ~/.kiro/{agents,skills,settings,sessions}
mkdir -p ~/ai-toolkit/{skills,tools,workflows}
mkdir -p ~/applications
mkdir -p ~/.agentmemory

echo "  ✅ Directories created"

# ============================================================================
# 3. Install iii-engine (agentmemory runtime)
# ============================================================================
echo ""
echo "⚙️  Installing iii-engine..."

if ! command -v iii >/dev/null 2>&1; then
  ARCH=$(uname -m)
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  
  case "$OS-$ARCH" in
    linux-x86_64)   TARGET="x86_64-unknown-linux-gnu" ;;
    linux-aarch64)  TARGET="aarch64-unknown-linux-gnu" ;;
    darwin-arm64)   TARGET="aarch64-apple-darwin" ;;
    darwin-x86_64)  TARGET="x86_64-apple-darwin" ;;
    *) echo "  ⚠️  Unsupported platform: $OS-$ARCH. Install iii manually."; TARGET="" ;;
  esac
  
  if [ -n "$TARGET" ]; then
    curl -fsSL "https://github.com/iii-hq/iii/releases/download/iii%2Fv0.11.2/iii-${TARGET}.tar.gz" | tar -xz -C ~/.local/bin
    chmod +x ~/.local/bin/iii
    echo "  ✅ iii-engine v0.11.2 installed"
  fi
else
  echo "  ✅ iii-engine already installed ($(iii --version))"
fi

# ============================================================================
# 4. Install npm globals
# ============================================================================
echo ""
echo "📦 Installing npm packages..."

npm list -g @agentmemory/agentmemory >/dev/null 2>&1 || npm install -g @agentmemory/agentmemory
echo "  ✅ agentmemory installed"

# ============================================================================
# 5. Clone ai-toolkit skill repos
# ============================================================================
echo ""
echo "🧠 Setting up ai-toolkit skills..."

SKILL_REPOS=(
  "obra/superpowers|superpowers"
  "anthropics/skills|anthropic-skills"
  "addyosmani/agent-skills|addy-agent-skills"
  "google/skills|google-cloud-skills"
  "tech-leads-club/agent-skills|techleads-skills"
  "cloudflare/skills|cloudflare-skills"
  "letta-ai/skills|letta-skills"
  "vercel-labs/agent-browser|agent-browser"
)

TOOL_REPOS=(
  "JuliusBrussee/caveman|caveman"
  "safishamsi/graphify|graphify"
  "viliawang-pm/ai-engineering-toolkit|ai-engineering-toolkit"
)

for entry in "${SKILL_REPOS[@]}"; do
  repo="${entry%%|*}"
  dir="${entry##*|}"
  target="$HOME/ai-toolkit/skills/$dir"
  if [ ! -d "$target" ]; then
    echo "  Cloning $repo → skills/$dir"
    git clone --depth 1 "https://github.com/$repo.git" "$target" 2>/dev/null
  else
    echo "  ✅ skills/$dir exists"
  fi
done

for entry in "${TOOL_REPOS[@]}"; do
  repo="${entry%%|*}"
  dir="${entry##*|}"
  target="$HOME/ai-toolkit/tools/$dir"
  if [ ! -d "$target" ]; then
    echo "  Cloning $repo → tools/$dir"
    git clone --depth 1 "https://github.com/$repo.git" "$target" 2>/dev/null
  else
    echo "  ✅ tools/$dir exists"
  fi
done

# ============================================================================
# 6. Setup ~/.kiro/skills (global skills as slash commands)
# ============================================================================
echo ""
echo "⚡ Setting up Kiro skills..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/kiro-skills"

if [ -d "$SKILLS_SRC" ]; then
  cp -r "$SKILLS_SRC"/* ~/.kiro/skills/ 2>/dev/null
  echo "  ✅ Skills copied from CommonConfig/kiro-skills/"
else
  echo "  ⚠️  No kiro-skills/ dir in CommonConfig — skills already in ~/.kiro/skills/"
fi

# ============================================================================
# 7. Setup ~/.kiro/settings/mcp.json
# ============================================================================
echo ""
echo "🔌 Configuring MCP servers..."

cat > ~/.kiro/settings/mcp.json << 'MCPEOF'
{
  "mcpServers": {
    "agentmemory": {
      "command": "npx",
      "args": ["-y", "@agentmemory/mcp"],
      "env": {
        "AGENTMEMORY_URL": "http://localhost:3111"
      }
    }
  }
}
MCPEOF
echo "  ✅ MCP config written"

# ============================================================================
# 8. Setup ~/.agentmemory/.env
# ============================================================================
echo ""
echo "🧠 Configuring agentmemory..."

cat > ~/.agentmemory/.env << 'AMEOF'
EMBEDDING_PROVIDER=local
TOKEN_BUDGET=2000
AGENTMEMORY_AUTO_COMPRESS=false
CONSOLIDATION_ENABLED=true
LESSON_DECAY_ENABLED=true
GRAPH_EXTRACTION_ENABLED=true
AGENTMEMORY_TOOLS=all
AMEOF
echo "  ✅ agentmemory config written"

# ============================================================================
# 9. Ensure .bashrc has the required lines
# ============================================================================
echo ""
echo "📝 Updating .bashrc..."

# PATH
grep -q '\.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Source kiroAliases (if CommonConfig is cloned)
if ! grep -q "kiroAliases.sh" ~/.bashrc; then
  echo "" >> ~/.bashrc
  echo "# Kiro AI aliases" >> ~/.bashrc
  echo "source \"\$HOME/CommonConfig/shell-aliases/kiroAliases.sh\"" >> ~/.bashrc
fi

# Agentmemory auto-start
if ! grep -q "agentmemory" ~/.bashrc; then
  cat >> ~/.bashrc << 'BASHEOF'

# Start agentmemory if not already running
if ! curl -s http://localhost:3111/agentmemory/health >/dev/null 2>&1; then
  agentmemory >/dev/null 2>&1 &
  disown
fi
BASHEOF
fi

echo "  ✅ .bashrc updated"

# ============================================================================
# 10. Summary
# ============================================================================
echo ""
echo "═══════════════════════════════════"
echo "✅ Bootstrap complete!"
echo ""
echo "What was set up:"
echo "  • iii-engine (agentmemory runtime)"
echo "  • agentmemory (persistent memory server)"
echo "  • ai-toolkit/ ($(find ~/ai-toolkit -name 'SKILL.md' 2>/dev/null | wc -l) skills)"
echo "  • ~/.kiro/skills/ (slash commands: /git-review, /git-commit-msg, /git-pr-desc, /orchestrate)"
echo "  • MCP: agentmemory wired to kiro-cli"
echo "  • kiroAliases.sh sourced (agents auto-created per project)"
echo ""
echo "Next steps:"
echo "  1. source ~/.bashrc"
echo "  2. Clone your projects into ~/applications/"
echo "  3. Run 'kiro' in any project — agent auto-creates"
echo "  4. Run 'kiro-master' for cross-project orchestration"
echo ""
echo "To update skills later: kiro-skills-pull"
