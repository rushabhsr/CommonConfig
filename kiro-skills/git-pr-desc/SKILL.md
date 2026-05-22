---
name: git-pr-desc
description: Generate a PR/MR description from commits. Use when asked to write a PR description, prepare a pull request, or summarize branch changes.
---

# Generate PR Description

Generate a detailed pull request description from the commits on the current branch.

## Steps

1. Run `git log origin/main..HEAD --oneline` to get commits (try `develop` if `main` fails)
2. Run `git diff origin/main..HEAD --stat` for a file change summary
3. Generate a PR description with:
   - **Summary**: 1-2 sentence overview of what this PR does
   - **Changes**: Bullet list of key changes
   - **Testing**: What was tested and how
   - **Breaking Changes**: Any breaking changes (if applicable)
4. Keep it concise but informative
