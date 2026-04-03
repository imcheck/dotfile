---
name: planner
description: "Create a detailed execution plan (ExecPlan) for complex, multi-step tasks before implementing. Use when the user says '계획 세워줘', '플랜 짜줘', 'plan this', 'make a plan', '어떻게 하면 될까', '설계해줘', or asks for an approach/strategy for a complex problem. Also trigger when the user explicitly invokes /planner. Do NOT trigger for simple tasks that can be done in under 3 steps."
disable-model-invocation: false
---

# Execution Plan — 복잡한 작업을 위한 실행 계획 생성

Your job is to create a detailed, self-contained execution plan (ExecPlan) for complex, multi-step tasks. The plan serves as a living document that guides implementation end-to-end without external context.

## Plan Creation Flow

1. **Understand the task**: Read the user's request carefully. Ask clarifying questions only if critical information is missing.

2. **Research**: Thoroughly explore the codebase — read relevant files, understand existing patterns, identify dependencies. Embed all necessary knowledge within the plan itself.

3. **Write the ExecPlan**: Use the skeleton below. Every section must be filled out. The plan must be self-contained — a developer with no prior context should be able to execute it.

4. **Save the ExecPlan**: Save the plan as a file with the naming format `YYYYMMDD-{PLAN_NAME}.md` (e.g. `20260314-auth-middleware-rewrite.md`). `PLAN_NAME` should be a short, kebab-case summary of the task. Save it in the current working directory unless the user specifies otherwise.

5. **Present the plan**: Show the full plan to the user and wait for approval before implementing.

## ExecPlan Skeleton

```markdown
# [Action-oriented title]

> Follows ExecPlan format. This is a living document — update as work progresses.

## Purpose / Big Picture

[What the user will be able to do after this is complete. Describe observable outcomes, not internal changes.]

## Context and Orientation

[Relevant file paths, current state, key definitions. Define every non-standard term in plain language.]

- `path/to/file.ts` — [what it does, why it matters]
- `path/to/other.ts` — [what it does, why it matters]

## Plan of Work

[Prose description of what changes are needed, where, and why. Connect each change back to the user-visible outcome.]

## Concrete Steps

[Exact sequence of edits, commands, and validations. Each step should specify:]

### Step 1: [Description]

- **File**: `path/to/file`
- **Change**: [What to add/modify/remove]
- **Why**: [How this contributes to the goal]

### Step 2: [Description]

...

## Validation and Acceptance

[How to verify the plan succeeded. Include exact commands, expected outputs, and user-visible behaviors to test.]

- [ ] [Acceptance criterion 1 — phrased as observable behavior]
- [ ] [Acceptance criterion 2]

## Interfaces and Dependencies

[External libraries, APIs, types, or signatures involved. Specify versions if relevant.]

## Idempotence and Recovery

[How to safely retry or rollback if something goes wrong.]

## Progress

[Updated during implementation with timestamps]

- [ ] Step 1 — [not started]
- [ ] Step 2 — [not started]

## Surprises & Discoveries

[Unexpected findings during research or implementation. Include evidence.]

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
|      |          |           |
```

## Non-Negotiable Principles

1. **Self-contained**: The plan contains ALL knowledge needed. No "see the docs" or "check the wiki" — embed it.
2. **Living document**: Update Progress, Surprises, and Decision Log continuously during implementation.
3. **Observable outcomes**: Acceptance criteria describe what users can DO, not internal structure.
4. **Define all terms**: If a term isn't obvious, define it in plain language or eliminate it.
5. **No ambiguity**: Don't outsource decisions to the implementer. Resolve ambiguities in the plan.

## Implementation Phase Rules

Once the user approves the plan:

- Proceed through steps without asking "should I continue?" at each step.
- After completing each step, update the Progress section with a timestamp.
- If something unexpected happens, log it in Surprises & Discoveries and adapt.
- If a design decision changes, record the old and new approach in the Decision Log with rationale.
- At completion, write an Outcomes summary.

## Important Rules

- Always research the codebase BEFORE writing the plan. Never guess about file contents or project structure.
- Keep prose concise but complete. Avoid filler.
- If the task is simple enough to not need a plan (< 3 steps, single file), tell the user and just do it.
- Write plans in the same language the user is using in conversation.
