# Kiro CLI - Complete Development Guide

A comprehensive guide for developers to efficiently use Kiro CLI with all available tools and features.

## 📑 Table of Contents

1. [Initial Setup](#initial-setup)
2. [Daily Development Workflow](#daily-development-workflow)
3. [Code Intelligence (LSP)](#code-intelligence-lsp)
4. [Planning Mode](#planning-mode)
5. [Testing AI-Generated Code](#testing-ai-generated-code)
6. [Subagents for Parallel Work](#subagents-for-parallel-work)
7. [Context Management](#context-management)
8. [MCP Server Setup](#mcp-server-setup)
9. [Best Practices](#best-practices)
10. [Command Reference](#command-reference)

---

## Initial Setup

### Step 1: Install Kiro CLI

```bash
# Installation command (check official docs for latest)
# Typically: npm install -g kiro-cli or similar
```

### Step 2: Start Your First Session

```bash
cd ~/applications/your-project
kiro-cli chat
```

### Step 3: Enable Code Intelligence (LSP)

```bash
# Inside Kiro CLI chat
/code init
```

**What this does:**
- Creates `.kiro/settings/lsp.json` in your project root
- Starts language servers for your project type
- Enables semantic code understanding

**Supported languages:**
- TypeScript/JavaScript
- Python
- Rust
- Go
- Java
- Ruby
- C/C++

**To disable:**
```bash
rm .kiro/settings/lsp.json
```

---

## Daily Development Workflow

### Starting a New Feature

#### Simple Tasks (< 5 steps)

**Direct approach:**
```
"Add email validation to the User model in models.py"
```

**Example request:**
```
"Create a new API endpoint /api/users/{id}/profile that returns user profile data"
```

#### Complex Tasks (Multiple files, architecture changes)

**Use Planning Mode:**

1. Press `Shift + Tab` to toggle planner
2. Describe your feature:
   ```
   "I need to add a caching layer to all API endpoints with Redis"
   ```
3. Review the structured plan
4. Press `Shift + Tab` to exit planner
5. Execute step by step:
   ```
   "Implement step 1 from the plan"
   ```

### Making Code Changes

**Effective request structure:**

```
Context: [What file/module]
Goal: [What you want to achieve]
Constraints: [What NOT to change]
```

**Example:**
```
Context: The authentication is in api/auth.py
Goal: Add rate limiting to prevent brute force attacks
Constraints: Don't modify the existing token generation logic
```

### Reviewing Changes

After I make changes, I'll show you:
- File paths modified
- Code diffs
- Explanation of changes

**Your review checklist:**
1. Does it solve the problem?
2. Are there unintended changes?
3. Does it follow your project conventions?
4. Are there security concerns?

---

## Code Intelligence (LSP)

### Available Operations

#### 1. Search for Symbols

**Find functions, classes, methods across codebase:**
```
"Search for the authenticate function"
"Find all classes related to Payment"
"Show me where UserSerializer is defined"
```

#### 2. Go to Definition

```
"Go to the definition of process_payment"
"Show me where the User class is defined"
```

#### 3. Find All References

```
"Find all references to User.authenticate()"
"Show me everywhere calculate_total is called"
```

#### 4. Get Diagnostics

```
"Check for errors in api/views.py"
"Show me all type errors in this file"
"List all linting issues in the payments module"
```

#### 5. Rename Symbol

```
"Rename the function old_name to new_name across the entire codebase"
```

### LSP Workflow Example

```
Step 1: "Find all references to legacy_auth_method"
Step 2: Review the 15 locations where it's used
Step 3: "Replace all calls to legacy_auth_method with new_auth_method"
Step 4: "Check for any errors in the modified files"
```

---

## Planning Mode

### When to Use

- Architecture decisions
- Multi-file refactoring
- New feature implementation (> 5 steps)
- Database schema changes
- API design

### How to Use

**Step 1: Toggle Planner**
```
Press: Shift + Tab
```

**Step 2: Describe Your Goal**
```
"I want to implement a notification system that supports email, SMS, and push notifications"
```

**Step 3: Review the Plan**

Planner will provide:
- Requirements breakdown
- Implementation steps
- File structure suggestions
- Potential challenges
- Testing strategy

**Step 4: Exit Planner**
```
Press: Shift + Tab
```

**Step 5: Execute**
```
"Implement step 1: Create the notification base class"
"Now implement step 2: Add email notification handler"
```

### Planning Mode Features

- **Read-only**: Won't make changes, only plans
- **Structured output**: Clear step-by-step breakdown
- **Consideration of trade-offs**: Discusses pros/cons
- **Testing recommendations**: Suggests test strategies

---

## Testing AI-Generated Code

### Testing Workflow

#### Step 1: Let AI Make Changes
```
"Add input validation to the registration form"
```

#### Step 2: Review the Diff
- Check modified files
- Verify logic correctness
- Look for edge cases

#### Step 3: Run Existing Tests
```bash
# Python/Django
python manage.py test

# Python with pytest
pytest

# JavaScript/Node
npm test

# With coverage
pytest --cov=myapp tests/
```

#### Step 4: Handle Test Failures
```
"The test_user_registration failed with: AssertionError: Expected 400, got 500
Fix the validation logic"
```

#### Step 5: Request New Tests (When Needed)
```
"Write unit tests for the new validation function"
"Add integration tests for the registration endpoint"
```

### Testing Best Practices

**1. Always run tests after AI changes**
```bash
# Quick smoke test
python manage.py test app.tests.test_critical

# Full test suite
python manage.py test
```

**2. Use LSP diagnostics**
```
"Check for type errors in the modified files"
```

**3. Request specific test types**
```
"Write unit tests for calculate_discount function"
"Add integration tests for the payment flow"
"Create edge case tests for empty input"
```

**4. Incremental testing**
- Test after each logical change
- Don't accumulate untested changes

**5. Review test coverage**
```
"Show me the test coverage for the auth module"
```

---

## Subagents for Parallel Work

### What Are Subagents?

- Specialized AI agents spawned for specific tasks
- Run in parallel (up to 4 simultaneously)
- Isolated context (don't share memory with main agent)
- Useful for independent subtasks

### When to Use Subagents

**Good use cases:**
- Code review while implementing
- Documentation while coding
- Research while debugging
- Analyzing different modules simultaneously

**Not suitable for:**
- Sequential dependent tasks
- Tasks requiring shared context
- Simple single-step operations

### How to Use Subagents

#### Example 1: Parallel Analysis
```
"Spawn a subagent to analyze the database schema in models.py while you review the API endpoints in views.py"
```

#### Example 2: Research + Implementation
```
"Create a subagent to research best practices for rate limiting while you implement the basic endpoint structure"
```

#### Example 3: Multi-Module Review
```
"Spawn 3 subagents:
1. Review security in auth module
2. Check performance in database queries
3. Analyze error handling in API views"
```

### Subagent Workflow

**Step 1: Identify independent tasks**
- Task A: Analyze authentication flow
- Task B: Review database indexes
- (These don't depend on each other)

**Step 2: Spawn subagents**
```
"Create two subagents:
1. Analyze the authentication flow and identify security issues
2. Review database models and suggest index optimizations"
```

**Step 3: Review results**
- Each subagent reports back independently
- Consolidate findings
- Make decisions based on combined insights

---

## Context Management

### Conversation Management

#### Starting New Conversations
```bash
# New chat session
kiro-cli chat

# When to start new:
# - Unrelated feature/bug
# - Context getting too large
# - Switching projects
```

#### Saving Conversations
```bash
# Inside Kiro CLI
/save feature-authentication
/save bugfix-payment-issue
/save refactor-api-layer
```

#### Loading Conversations
```bash
/load feature-authentication
```

#### Listing Saved Conversations
```bash
/save  # Shows list of saved conversations
```

### Context Files

#### Adding Context
```bash
/context add path/to/important/file.py
/context add docs/architecture.md
```

#### Removing Context
```bash
/context remove path/to/file.py
```

#### Viewing Context
```bash
/context list
```

### Providing Effective Context

#### Good Context Examples

**1. Error logs:**
```
"I'm getting this error:
[paste full stack trace]

The code is in api/views.py lines 45-60
Fix the issue"
```

**2. Related files:**
```
"I need to modify the payment processing.
Relevant files:
- payments/models.py (Payment model)
- payments/views.py (process_payment function)
- payments/serializers.py (PaymentSerializer)

Add support for refunds"
```

**3. Requirements:**
```
"Add user authentication with these requirements:
- JWT tokens
- Refresh token support
- Token expiry: 1 hour
- Store tokens in Redis
- Follow the existing pattern in auth/jwt_handler.py"
```

---

## MCP Server Setup

### What is MCP?

**Model Context Protocol (MCP):**
- Extends AI capabilities with custom tools
- Runs as local server processes
- Provides application-specific context
- Enables custom workflows

### Use Cases

- Project-specific deployment commands
- Custom database operations
- Application-specific testing workflows
- Integration with internal tools

### Setting Up MCP Servers

#### Step 1: Check Configuration Location

```bash
# Find where Kiro CLI stores MCP config
kiro-cli --help | grep -i mcp

# Common locations:
# ~/.config/kiro-cli/mcp.json
# ~/.kiro/mcp.json
```

#### Step 2: Create MCP Configuration

**Example: `~/.config/kiro-cli/mcp.json`**

```json
{
  "mcpServers": {
    "cms-tools": {
      "command": "node",
      "args": ["/home/rushabh/applications/cms/mcp-server.js"],
      "env": {
        "APP_ROOT": "/home/rushabh/applications/cms",
        "VENV_PATH": "/home/rushabh/applications/cms/venv"
      }
    },
    "payment-tools": {
      "command": "python",
      "args": ["/home/rushabh/applications/payment/mcp_server.py"],
      "env": {
        "APP_ROOT": "/home/rushabh/applications/payment"
      }
    }
  }
}
```

#### Step 3: Create MCP Server Script

**Example: Node.js MCP Server**

`~/applications/cms/mcp-server.js`:

```javascript
#!/usr/bin/env node

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

const server = new Server(
  {
    name: 'cms-tools',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Tool: Run CMS migrations
server.setRequestHandler('tools/call', async (request) => {
  if (request.params.name === 'run_cms_migrations') {
    const cmd = `cd ${process.env.APP_ROOT} && source ${process.env.VENV_PATH}/bin/activate && python manage.py migrate`;
    const { stdout, stderr } = await execAsync(cmd);
    return {
      content: [
        {
          type: 'text',
          text: stdout || stderr,
        },
      ],
    };
  }
  
  if (request.params.name === 'get_cms_logs') {
    const lines = request.params.arguments?.lines || 50;
    const cmd = `tail -n ${lines} ${process.env.APP_ROOT}/logs/cms.log`;
    const { stdout } = await execAsync(cmd);
    return {
      content: [
        {
          type: 'text',
          text: stdout,
        },
      ],
    };
  }
});

// List available tools
server.setRequestHandler('tools/list', async () => {
  return {
    tools: [
      {
        name: 'run_cms_migrations',
        description: 'Run Django migrations for CMS project',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
      {
        name: 'get_cms_logs',
        description: 'Get CMS application logs',
        inputSchema: {
          type: 'object',
          properties: {
            lines: {
              type: 'number',
              description: 'Number of log lines to retrieve',
              default: 50,
            },
          },
        },
      },
    ],
  };
});

const transport = new StdioServerTransport();
server.connect(transport);
```

**Example: Python MCP Server**

`~/applications/payment/mcp_server.py`:

```python
#!/usr/bin/env python3

import asyncio
import os
import subprocess
from mcp.server import Server
from mcp.server.stdio import stdio_server

app = Server("payment-tools")

@app.call_tool()
async def run_payment_tests(arguments: dict) -> str:
    """Run payment module tests"""
    app_root = os.environ.get('APP_ROOT')
    cmd = f"cd {app_root} && pytest tests/test_payment.py -v"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout + result.stderr

@app.call_tool()
async def check_payment_status(arguments: dict) -> str:
    """Check payment processing status"""
    payment_id = arguments.get('payment_id')
    # Your logic here
    return f"Status for payment {payment_id}"

@app.list_tools()
async def list_tools() -> list:
    return [
        {
            "name": "run_payment_tests",
            "description": "Run payment module test suite",
            "inputSchema": {
                "type": "object",
                "properties": {}
            }
        },
        {
            "name": "check_payment_status",
            "description": "Check status of a payment",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "payment_id": {
                        "type": "string",
                        "description": "Payment ID to check"
                    }
                },
                "required": ["payment_id"]
            }
        }
    ]

async def main():
    async with stdio_server() as streams:
        await app.run(
            streams[0],
            streams[1],
            app.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main())
```

#### Step 4: Make Scripts Executable

```bash
chmod +x ~/applications/cms/mcp-server.js
chmod +x ~/applications/payment/mcp_server.py
```

#### Step 5: Install Dependencies

```bash
# For Node.js MCP server
cd ~/applications/cms
npm install @modelcontextprotocol/sdk

# For Python MCP server
cd ~/applications/payment
pip install mcp
```

#### Step 6: Restart Kiro CLI

```bash
# Exit current session
/quit

# Start new session (loads MCP servers)
kiro-cli chat
```

#### Step 7: Use MCP Tools

```
"Run CMS migrations using the MCP tool"
"Get the last 100 lines of CMS logs"
"Check payment status for payment ID 12345"
```

### MCP Server Per Application

**Directory structure:**

```
~/applications/
├── cms/
│   ├── mcp-server.js
│   └── ... (project files)
├── payment/
│   ├── mcp_server.py
│   └── ... (project files)
├── audit/
│   ├── mcp-server.js
│   └── ... (project files)
└── ops/
    ├── mcp_server.py
    └── ... (project files)
```

**Benefits:**
- Project-specific tools available in any Kiro session
- Consistent workflows across projects
- Integration with existing scripts (CommonConfig)
- Reduced manual command typing

---

## Best Practices

### 1. Request Formulation

#### Be Specific
```
❌ "Fix the bug"
✅ "Fix the NullPointerException in UserService.authenticate() at line 45"

❌ "Improve performance"
✅ "Add database indexes to the User.email and User.created_at fields"

❌ "Update the API"
✅ "Add pagination to the /api/users endpoint with page_size parameter"
```

#### Provide Constraints
```
"Add logging to the payment processing function
Constraints:
- Use the existing logger instance
- Don't modify the return value
- Log at INFO level for success, ERROR for failures"
```

#### Specify Scope
```
"Refactor the authentication logic in auth/views.py
Scope: Only the login and logout functions
Don't touch: Token generation, password hashing"
```

### 2. Incremental Development

**Work in small steps:**

```
Step 1: "Create the User model with basic fields"
[Review and test]

Step 2: "Add email validation to the User model"
[Review and test]

Step 3: "Add password hashing to the User model"
[Review and test]
```

**Benefits:**
- Easier to review
- Faster to test
- Simpler to debug
- Better understanding of changes

### 3. Code Review Checklist

After AI makes changes, check:

- [ ] Does it solve the stated problem?
- [ ] Are there unintended side effects?
- [ ] Does it follow project conventions?
- [ ] Are there security implications?
- [ ] Is error handling adequate?
- [ ] Are edge cases covered?
- [ ] Does it maintain backward compatibility?
- [ ] Is the code readable and maintainable?

### 4. Testing Strategy

**Test pyramid:**

1. **Unit tests** (most)
   ```
   "Write unit tests for the calculate_discount function"
   ```

2. **Integration tests** (medium)
   ```
   "Add integration tests for the payment processing flow"
   ```

3. **End-to-end tests** (least)
   ```
   "Create an e2e test for the user registration flow"
   ```

### 5. Context Window Management

**Keep conversations focused:**

- One feature per conversation
- Start fresh for unrelated work
- Save important conversations
- Use `/context` for persistent files

**When context gets large:**
```
"Summarize the changes we've made so far"
[Start new conversation]
"Continue from: [paste summary]"
```

### 6. Leverage Existing Code

**Reference your patterns:**
```
"Add a new API endpoint following the same pattern as /api/users"
"Create a model similar to the Payment model but for Refunds"
```

**Use your utilities:**
```
"Add a new function to ZunoCommonFunc.sh that runs tests with coverage"
"Create a Docker cleanup script similar to dockerclean but for images only"
```

### 7. Documentation

**Request documentation:**
```
"Add docstrings to all functions in this file"
"Create API documentation for the new endpoints"
"Update the README with the new feature"
```

**Keep docs in sync:**
```
"Update the API docs to reflect the new pagination parameters"
```

### 8. Security Considerations

**Always review for:**
- SQL injection vulnerabilities
- XSS vulnerabilities
- Authentication/authorization issues
- Sensitive data exposure
- Input validation

**Request security review:**
```
"Review the authentication logic for security issues"
"Check if the API endpoint is vulnerable to SQL injection"
```

### 9. Performance

**Request performance considerations:**
```
"Optimize the database query in get_user_orders"
"Add caching to the expensive calculation in calculate_metrics"
"Review the API endpoint for N+1 query issues"
```

### 10. Error Handling

**Ensure proper error handling:**
```
"Add error handling to the payment processing function
- Handle network timeouts
- Handle invalid payment data
- Handle database errors
- Return appropriate HTTP status codes"
```

---

## Command Reference

### Chat Commands

```bash
/code init              # Initialize LSP for code intelligence
/model                  # Show current model and available options
/save <name>            # Save current conversation
/load <name>            # Load saved conversation
/context add <path>     # Add file to persistent context
/context remove <path>  # Remove file from context
/context list           # List files in context
/help                   # Show help information
/quit                   # Exit Kiro CLI
```

### Keyboard Shortcuts

```
Shift + Tab            # Toggle planning mode
Up Arrow               # Previous command in history
Down Arrow             # Next command in history
Ctrl + C               # Cancel current operation
```

### CLI Commands

```bash
kiro-cli chat          # Start interactive chat session
kiro-cli --help        # Show CLI help
```

---

## Quick Reference Card

### Starting a Task

| Task Type | Approach |
|-----------|----------|
| Simple (< 5 steps) | Direct request |
| Complex (> 5 steps) | Use planner (Shift + Tab) |
| Multi-module | Use subagents |
| Research needed | Subagent for research |

### Code Operations

| Operation | Command Example |
|-----------|-----------------|
| Find symbol | "Search for authenticate function" |
| Go to definition | "Go to definition of User class" |
| Find references | "Find all references to process_payment" |
| Check errors | "Check for errors in views.py" |
| Rename | "Rename old_func to new_func" |

### Testing

| Stage | Action |
|-------|--------|
| After changes | Run existing tests |
| Test fails | "Fix the failing test: [error]" |
| Need new tests | "Write tests for [function]" |
| Coverage check | "Show test coverage" |

### Context Management

| Situation | Action |
|-----------|--------|
| New feature | Start new conversation |
| Context too large | Save and start fresh |
| Important files | `/context add <path>` |
| Switch projects | Start new conversation |

---

## Troubleshooting

### LSP Not Working

**Problem:** Code intelligence features not available

**Solutions:**
1. Check if LSP is initialized: `ls .kiro/settings/lsp.json`
2. Reinitialize: `/code init`
3. Check language support (TypeScript, Python, Rust, Go, Java, Ruby, C/C++)
4. Restart Kiro CLI

### MCP Server Not Loading

**Problem:** Custom tools not available

**Solutions:**
1. Check MCP config location: `kiro-cli --help | grep -i mcp`
2. Verify JSON syntax in config file
3. Check server script is executable: `chmod +x mcp-server.js`
4. Check dependencies installed
5. Restart Kiro CLI
6. Check server logs for errors

### Context Window Full

**Problem:** "Context window exceeded" error

**Solutions:**
1. Start new conversation: `/quit` then `kiro-cli chat`
2. Remove unnecessary context: `/context remove <path>`
3. Summarize and continue in new session
4. Use subagents for parallel work

### Tests Failing After Changes

**Problem:** Tests break after AI modifications

**Solutions:**
1. Share the test failure: "Test failed with: [error]"
2. Request fix: "Fix the failing test"
3. Review changes: "Show me what you changed in [file]"
4. Rollback if needed: Use git to revert

### Unclear AI Response

**Problem:** AI response doesn't address your need

**Solutions:**
1. Be more specific in your request
2. Provide more context
3. Break down into smaller steps
4. Use planner mode for complex tasks
5. Rephrase your question

---

## Learning Path

### Week 1: Basics
- [ ] Start daily development with Kiro CLI
- [ ] Use for simple code changes
- [ ] Practice reviewing AI-generated code
- [ ] Run tests after each change

### Week 2: Code Intelligence
- [ ] Initialize LSP in main project: `/code init`
- [ ] Use symbol search
- [ ] Try go-to-definition
- [ ] Find references across codebase

### Week 3: Advanced Features
- [ ] Use planning mode for complex feature
- [ ] Try subagents for parallel work
- [ ] Save and load conversations
- [ ] Manage context files

### Week 4: Customization
- [ ] Set up first MCP server
- [ ] Create project-specific tools
- [ ] Integrate with CommonConfig scripts
- [ ] Optimize your workflow

---

## Additional Resources

### Getting Help

```bash
# CLI help
kiro-cli --help

# In-chat help
/help

# Model information
/model
```

### Community & Support

- Check official Kiro CLI documentation
- GitHub issues for bug reports
- Community forums for questions

### Integration with CommonConfig

Your existing shell utilities can be enhanced:

```bash
# Add Kiro-specific aliases to ZunoCommonFunc.sh
alias kiro-cms='cd ~/applications/cms && kiro-cli chat'
alias kiro-payment='cd ~/applications/payment && kiro-cli chat'

# Create MCP tools that use your existing functions
# Example: MCP tool that calls dockerclean from commFuncParams.sh
```

---

## Appendix: Example Workflows

### Workflow 1: Adding a New API Endpoint

```
Step 1: "Create a new API endpoint /api/products that returns a list of products"
Step 2: Review the generated code
Step 3: Run tests: pytest tests/test_api.py
Step 4: "Add pagination to the products endpoint"
Step 5: "Write tests for the products endpoint"
Step 6: Run tests again
Step 7: "Update the API documentation"
```

### Workflow 2: Debugging a Production Issue

```
Step 1: "Here's the error from production logs: [paste]"
Step 2: "Find all references to the failing function"
Step 3: Review the code paths
Step 4: "The issue is in line 45, fix the null check"
Step 5: "Write a test that reproduces this bug"
Step 6: Run the test to verify fix
Step 7: "Add logging to prevent this in future"
```

### Workflow 3: Refactoring Legacy Code

```
Step 1: Shift + Tab (enter planner mode)
Step 2: "I need to refactor the authentication module to use JWT instead of sessions"
Step 3: Review the plan
Step 4: Shift + Tab (exit planner)
Step 5: "Implement step 1: Create JWT utility functions"
Step 6: Run tests
Step 7: "Implement step 2: Update login endpoint"
Step 8: Run tests
Step 9: Continue through remaining steps
```

### Workflow 4: Performance Optimization

```
Step 1: "Analyze the database queries in api/views.py for N+1 issues"
Step 2: Review findings
Step 3: "Add select_related to the User query in get_user_orders"
Step 4: "Add database indexes to User.email and Order.created_at"
Step 5: "Show me the query execution plan"
Step 6: Run performance tests
```

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-28  
**Author:** Kiro CLI Guide for Developers
