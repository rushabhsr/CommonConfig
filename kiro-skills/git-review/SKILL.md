---
name: git-review
description: Review current git diff for issues, bugs, improvements, and best practices. Use when asked to review code changes, find bugs in diff, or check code quality.
---

# Git Code Review

Review the current git changes for issues, bugs, improvements, and best practices.

## Steps

1. Run `git diff` to get unstaged changes, or `git diff --cached` if the user says "staged"
2. Analyze the diff for:
   - Bugs and logic errors
   - Security vulnerabilities
   - Performance issues
   - Code style violations
   - Missing error handling
   - Missing tests
3. Be specific and actionable — reference exact lines and suggest fixes
4. Categorize findings by severity: 🔴 Critical, 🟡 Warning, 🔵 Suggestion
