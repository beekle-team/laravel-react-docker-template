---
description: Validate implementation against requirements, design, and tasks
allowed-tools: Bash, Glob, Grep, Read, LS, Task
argument-hint: [feature-name] [task-numbers]
---

# Implementation Validation

<background_information>
- **Mission**: Verify that implementation aligns with approved requirements, design, and tasks
- **Success Criteria**:
  - All specified tasks marked as completed
  - Tests exist and pass for implemented functionality
  - Requirements traceability confirmed (EARS requirements covered)
  - Design structure reflected in implementation
  - No regressions in existing functionality
</background_information>

<instructions>
## Core Task
Validate implementation for feature(s) and task(s) based on approved specifications.

## Execution Steps

### 1. Detect Validation Target

**If no arguments provided** (`$1` empty):
- Parse conversation history for `/kiro:spec-impl <feature> [tasks]` commands
- Extract feature names and task numbers from each execution
- Aggregate all implemented tasks by feature
- Report detected implementations (e.g., "user-auth: 1.1, 1.2, 1.3")
- If no history found, scan `.kiro/specs/` for features with completed tasks `[x]`

**If feature provided** (`$1` present, `$2` empty):
- Use specified feature
- Detect all completed tasks `[x]` in `.kiro/specs/$1/tasks.md`

**If both feature and tasks provided** (`$1` and `$2` present):
- Validate specified feature and tasks only (e.g., `user-auth 1.1,1.2`)

### 2. Load Context and Delegate to Quality Engineer

**Load context**:
- Read `.kiro/specs/<feature>/spec.json`, `requirements.md`, `design.md`, `tasks.md`
- Read entire `.kiro/steering/` directory

**Delegate validation to quality-engineer subagent**:
```
Task(
  subagent_type: "quality-engineer",
  prompt: "Validate implementation for feature '$1'.

    Context:
    - Requirements: [from requirements.md]
    - Design: [from design.md]
    - Completed tasks: [from tasks.md]

    Validation checks:
    1. Task Completion: All [x] tasks actually implemented
    2. Test Coverage: Tests exist and pass
    3. Requirements Traceability: EARS requirements covered
    4. Design Alignment: Structure matches design.md
    5. Regression Check: No existing tests broken

    Run tests:
    - Flutter: cd apps/mobile && ../../tools/flutterw test
    - Python: cd apps/worker-py && uv run pytest

    Return: GO/NO-GO decision with issues list",
  run_in_background: false
)
```

### 3. Aggregate Results

Collect quality-engineer results and format final report.

## Important Constraints
- **Subagent Delegation**: Use quality-engineer for comprehensive validation
- **Test-first focus**: Test coverage is mandatory for GO decision
- **Traceability required**: All requirements must be traceable to implementation
</instructions>

## Tool Guidance
- **Task tool**: Delegate to quality-engineer subagent
- **Read first**: Load all context before delegating
- **Parallel validation**: For multiple features, run agents in parallel

## Output Description

Provide output in the language specified in spec.json with:

1. **Detected Target**: Features and tasks being validated
2. **Validation Summary**: Brief overview per feature (pass/fail counts)
3. **Issues**: List of validation failures with severity and location
4. **Coverage Report**: Requirements/design/task coverage percentages
5. **Decision**: GO (ready for next phase) / NO-GO (needs fixes)

**Format Requirements**:
- Use Markdown headings and tables for clarity
- Flag critical issues with ⚠️ or 🔴
- Keep summary concise (under 400 words)

## Safety & Fallback

### Error Scenarios
- **No Implementation Found**: If no `/kiro:spec-impl` in history and no `[x]` tasks, report "No implementations detected"
- **Subagent Failure**: Fall back to direct validation
- **Missing Spec Files**: Stop with error

### Next Steps Guidance

**If GO Decision**:
- Implementation validated and ready
- Proceed to deployment or next feature

**If NO-GO Decision**:
- Address critical issues listed
- Re-run `/kiro:spec-impl <feature> [tasks]` for fixes
- Re-validate with `/kiro:validate-impl [feature] [tasks]`
