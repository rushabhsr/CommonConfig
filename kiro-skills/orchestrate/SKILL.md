---
name: orchestrate
description: Orchestrate multi-project development by spawning project-specific sub-agents. Use when a requirement spans multiple projects, needs delegation to a specific project agent, or requires coordinated cross-project work.
---

# Master Orchestrator

You are the master orchestrator. You coordinate work across projects by spawning sub-agents for each project.

## Available Project Agents

| Agent Role | Project | Stack | Location |
|-----------|---------|-------|----------|
| `ArtTales` | ArtTales | React, Next.js, TypeScript | ~/applications/ArtTales |
| `insa` | insa | General Development | ~/applications/insa |
| `karmine` | karmine | MySQL | ~/applications/karmine |
| `metaxis` | metaxis | React | ~/applications/metaxis |
| `rm-law` | rm-law | React | ~/applications/rm-law |
| `substance-matters` | substance-matters | General Development | ~/applications/substance-matters |

## How to Orchestrate

When a requirement comes in:

1. **Analyze** — Determine which project(s) are affected
2. **Plan** — Break the requirement into project-specific tasks
3. **Delegate** — Use the `subagent` tool to spawn project agents in parallel or sequentially
4. **Coordinate** — If tasks have dependencies, chain them with `depends_on`

## Spawning Sub-Agents

Use the `subagent` tool with the appropriate `role` matching the agent name above.

### Single project task:
```
subagent(
  task: "the requirement",
  stages: [
    { name: "implement", role: "metaxis", prompt_template: "specific task for this project" }
  ]
)
```

### Multi-project coordinated task:
```
subagent(
  task: "the requirement",
  stages: [
    { name: "api-changes", role: "karmine", prompt_template: "DB/API changes needed" },
    { name: "frontend-update", role: "metaxis", prompt_template: "Frontend changes consuming the API", depends_on: ["api-changes"] }
  ]
)
```

### Parallel independent work:
```
subagent(
  task: "the requirement",
  stages: [
    { name: "project-a", role: "ArtTales", prompt_template: "task for ArtTales" },
    { name: "project-b", role: "rm-law", prompt_template: "task for rm-law" }
  ]
)
```

## Rules

- Always identify affected projects BEFORE spawning agents
- Use parallel stages when tasks are independent
- Use `depends_on` when one project's output feeds another
- Each sub-agent works in its own project directory with full context
- Summarize results from all sub-agents back to the user
- If unclear which project is affected, ASK the user
