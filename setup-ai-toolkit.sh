#!/bin/bash
# ============================================================================
# AI Toolkit Setup — clones verified public skill/tool repos
# Run: bash ~/CommonConfig/setup-ai-toolkit.sh
# ============================================================================
set -e

TOOLKIT_DIR="$HOME/ai-toolkit"
mkdir -p "$TOOLKIT_DIR"/{skills,tools}

echo "🧠 AI Toolkit Setup"
echo "═══════════════════"

clone_repo() {
  local repo="$1" dir="$2" desc="$3"
  local target="$TOOLKIT_DIR/$dir"
  if [ -d "$target" ]; then
    echo "  ✅ $dir (exists)"
  else
    echo "  📥 $desc"
    if git clone --depth 1 "https://github.com/$repo.git" "$target" 2>/dev/null; then
      echo "     → $dir ✅"
    else
      echo "     → $dir ❌ (clone failed)"
    fi
  fi
}

echo ""
echo "═══ Tools ═══"
clone_repo "JuliusBrussee/caveman"       "tools/caveman"       "Caveman — 65% token compression"
clone_repo "safishamsi/graphify"          "tools/graphify"      "Graphify — code→knowledge graph"

echo ""
echo "═══ Skill Packs ═══"
clone_repo "obra/superpowers"             "skills/superpowers"           "Superpowers — agentic dev framework (57k★)"
clone_repo "anthropics/skills"            "skills/anthropic-skills"      "Anthropic — official agent skills"
clone_repo "addyosmani/agent-skills"      "skills/addy-agent-skills"     "Addy Osmani — production engineering skills"
clone_repo "google/skills"                "skills/google-skills"         "Google — GCP/Firebase/Cloud skills"
clone_repo "tech-leads-club/agent-skills" "skills/techleads-skills"      "Tech Leads Club — curated skill registry"
clone_repo "cloudflare/skills"            "skills/cloudflare-skills"     "Cloudflare — Workers/Pages/D1 skills"
clone_repo "letta-ai/skills"              "skills/letta-skills"          "Letta AI — shared agent skills"
clone_repo "vercel-labs/agent-browser"    "skills/agent-browser"         "Vercel — browser automation for agents"
clone_repo "microsoft/agent-skills"       "skills/microsoft-agent-skills" "Microsoft — Copilot agent skills"

echo ""
echo "═══════════════════"
echo "✅ Done!"
echo ""
echo "Installed:"
echo "  Tools:  $(ls -1d "$TOOLKIT_DIR"/tools/*/ 2>/dev/null | wc -l)"
echo "  Skills: $(ls -1d "$TOOLKIT_DIR"/skills/*/ 2>/dev/null | wc -l)"
echo ""
echo "Total SKILL.md files: $(find "$TOOLKIT_DIR" -name 'SKILL.md' 2>/dev/null | wc -l)"
echo ""
echo "Update later: kiro-skills-pull"
