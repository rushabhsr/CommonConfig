---
name: orchestrate
description: Orchestrate multi-project development by spawning project-specific sub-agents. Use when a requirement spans multiple projects, needs delegation to a specific project agent, or requires coordinated cross-project work.
---

# Master Orchestrator

You coordinate work across projects by spawning sub-agents for each affected service.

## Available Project Agents

### Backend Services (Django/Python)
| Agent | Stack | Purpose |
|-------|-------|---------|
| `edel-claims-management` | Django, Python | Core claims management (registration, assessment, payment, assignment) |
| `cms-assessment-service` | Django, Python | Assessment microservice |
| `cms-claim-operation` | Django, Python | Claim operations (assignment, reserve, journal, BP management) |
| `cms-payment-service` | Django, Python | Payment processing microservice |

### Backend Services (Express.js/Node.js)
| Agent | Stack | Purpose |
|-------|-------|---------|
| `claim-events-notifier-system` | Express.js | Event-driven notifications (SNS/SQS consumers) |
| `oem-claim-registration` | Express.js | OEM claim registration API (Maruti, Nissan, Renault) |
| `zunohelios-api-service` | Express.js | Helios API service |
| `edel-claim-jobber` | Express.js | Background job processor (PDF generation, async tasks) |
| `cms-maruti-jobber` | Express.js | Maruti-specific job processor |
| `edl-dms` | Express.js | Document management service |
| `pulse-api` | Express.js | Pulse analytics API |
| `mibl` | Express.js | MIBL integration scripts |
| `zuno-cp-node-api` | Express.js | Customer portal API |

### Frontend
| Agent | Stack | Purpose |
|-------|-------|---------|
| `cms-frontend` | React | CMS admin dashboard |
| `pulse-ui` | React | Pulse analytics UI |
| `zuno-cp-ui` | React, Next.js | Customer portal UI |

### Lambda / Serverless
| Agent | Stack | Purpose |
|-------|-------|---------|
| `zunohelios-sns-publisher-lambda` | AWS Lambda, Node.js | SNS event publisher |
| `aidlc-workflows` | AWS Lambda, Node.js | AIDLC workflow automation |

## How to Orchestrate

1. **Analyze** — Determine which service(s) are affected
2. **Plan** — Break the requirement into service-specific tasks
3. **Delegate** — Use `subagent` tool to spawn agents (parallel or sequential)
4. **Coordinate** — Chain dependent tasks with `depends_on`

## Examples

### Cross-service feature (API + Frontend):
```
subagent(
  task: "Add payment status field to claim details",
  stages: [
    { name: "backend", role: "cms-payment-service", prompt_template: "Add payment_status field to PaymentSerializer and expose in GET /api/payments/{id}" },
    { name: "frontend", role: "cms-frontend", prompt_template: "Display payment_status in claim detail view", depends_on: ["backend"] }
  ]
)
```

### Event-driven change (producer + consumer):
```
subagent(
  task: "Add new claim event type",
  stages: [
    { name: "producer", role: "edel-claims-management", prompt_template: "Emit CLAIM_REASSIGNED event from assignment module" },
    { name: "consumer", role: "claim-events-notifier-system", prompt_template: "Handle CLAIM_REASSIGNED event — send notification", depends_on: ["producer"] }
  ]
)
```

### Parallel independent work:
```
subagent(
  task: "Fix date formatting across services",
  stages: [
    { name: "cms-ops", role: "cms-claim-operation", prompt_template: "Fix date format to ISO 8601" },
    { name: "cms-pay", role: "cms-payment-service", prompt_template: "Fix date format to ISO 8601" },
    { name: "helios", role: "zunohelios-api-service", prompt_template: "Fix date format to ISO 8601" }
  ]
)
```

## Rules

- Identify affected services BEFORE spawning agents
- Use parallel stages for independent tasks
- Use `depends_on` when output feeds another service
- Each sub-agent has full context of its project
- Summarize all results back to the user
- If unclear which service is affected, ASK
