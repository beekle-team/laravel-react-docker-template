---
description: Execute spec tasks using TDD methodology
allowed-tools: Bash, Read, Write, Edit, MultiEdit, Grep, Glob, LS, WebFetch, WebSearch, Task
argument-hint: <feature-name> [task-numbers]
---

# Implementation Task Executor

<background_information>
- **Mission**: Execute implementation tasks using Test-Driven Development methodology based on approved specifications
- **Success Criteria**:
  - All tests written before implementation code
  - Code passes all tests with no regressions
  - Tasks marked as completed in tasks.md
  - Implementation aligns with design and requirements
</background_information>

<instructions>
## Core Task
Execute implementation tasks for feature **$1** using Test-Driven Development.

## Execution Steps

### Step 1: Load Context

**Read all necessary context**:
- `.kiro/specs/$1/spec.json`, `requirements.md`, `design.md`, `tasks.md`
- **Entire `.kiro/steering/` directory** for complete project memory

**Validate approvals**:
- Verify tasks are approved in spec.json (stop if not, see Safety & Fallback)

### Step 2: Analyze and Delegate

**Determine task domain from design.md**:
- **Backend tasks** (Python, API, DB): Use `backend-architect` subagent
- **Frontend tasks** (Flutter, UI): Use `frontend-architect` subagent
- **Mixed tasks**: Run both agents in parallel

**Use the Task tool to delegate**:
```
Task(
  subagent_type: "backend-architect" or "frontend-architect",
  prompt: "Implement task X.Y for feature '$1' using TDD methodology.
    Context:
    - Requirements: [from requirements.md]
    - Design: [from design.md]
    - Task: [specific task description]

    Follow TDD cycle: RED (write failing test) → GREEN (minimal impl) → REFACTOR
    Mark task complete in tasks.md when done.",
  run_in_background: false  # or true for parallel tasks
)
```

### Step 3: Parallel Execution (for multiple tasks)

**If multiple independent tasks**:
- Launch multiple subagents in parallel using `run_in_background: true`
- Monitor progress with TaskOutput
- Aggregate results

### Step 4: Requirements Check (Gherkin)

**Before implementing each task**:
1. Check if behavior is documented in `requirements.md`
2. If NOT documented: Add Gherkin scenario BEFORE implementing
3. Format:
   ```gherkin
   ### REQ-XXX: [Title]
   **Scenario**: [Name]
     Given [context]
     When [action]
     Then [outcome]
   ```

### Step 5: API Testing (curl)

**If task involves API changes**:
1. Ensure `make dev-server` is running
2. Test endpoint with curl:
   ```bash
   curl -X POST http://localhost:8787/api/your-endpoint \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"key": "value"}' | jq .
   ```
3. Verify: happy path, error cases (400/401/404), response schema

**Mandatory for**: Auth, file upload, WebSocket, Durable Objects, external APIs

### Step 6: Verify and Mark Complete

After each task:
1. Run tests to verify no regressions
2. Update checkbox from `- [ ]` to `- [x]` in tasks.md
3. **Add Implementation Report** under the completed task:
   ```markdown
   - [x] Task X.Y: [Description]

     **Implementation Report:**
     - **Files Changed**: [list of files]
     - **Tests Added**: [test files]
     - **Key Decisions**: [design choices]
     - **Notes**: [caveats, follow-ups]
   ```
4. Report completion status

## Critical Constraints
- **TDD Mandatory**: Tests MUST be written before implementation code
- **Subagent Delegation**: Use specialized agents for domain-specific implementation
- **Parallel When Possible**: Independent tasks run concurrently
- **No Regressions**: Existing tests must continue to pass
</instructions>

## Tool Guidance
- **Task tool**: Primary tool for delegation to specialized agents
- **Read first**: Load all context before delegating
- **Parallel execution**: Use `run_in_background: true` for independent tasks
- **TaskOutput**: Monitor background tasks

## Output Description

Provide brief summary in the language specified in spec.json:

1. **Tasks Executed**: Task numbers and agent used
2. **Status**: Completed tasks, test results, remaining count

**Format**: Concise (under 150 words)

## Safety & Fallback

### Error Scenarios

**Tasks Not Approved or Missing Spec Files**:
- **Stop Execution**: All spec files must exist and tasks must be approved
- **Suggested Action**: "Complete previous phases: `/kiro:spec-requirements`, `/kiro:spec-design`, `/kiro:spec-tasks`"

**Subagent Failures**:
- **Retry**: Attempt with more context
- **Fallback**: Execute directly if agent unavailable

### Task Execution

**Execute specific task(s)**:
- `/kiro:spec-impl $1 1.1` - Single task
- `/kiro:spec-impl $1 1,2,3` - Multiple tasks (parallel if independent)

**Execute all pending**:
- `/kiro:spec-impl $1` - All unchecked tasks

think
