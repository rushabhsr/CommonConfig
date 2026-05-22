---
name: git-commit-msg
description: Generate a conventional commit message from staged changes. Use when asked to write a commit message, generate commit, or prepare a commit.
---

# Generate Commit Message

Generate a concise conventional commit message from the currently staged changes.

## Steps

1. Run `git diff --cached` to see staged changes
2. Analyze what changed and why
3. Generate a commit message in format: `type(scope): description`
   - Types: feat, fix, refactor, docs, style, test, chore, perf, ci, build
   - Scope: the module/component affected
   - Description: imperative mood, lowercase, no period, under 72 chars
4. If changes are complex, add a body with bullet points explaining the "why"
5. Present the message for user approval
