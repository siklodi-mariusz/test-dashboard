---
name: implement-plan
description: "Implement a technical plan from .claude/plans/"
---

Implement the plan matching "$ARGUMENTS" from the `.claude/plans/` directory.

## Process

1. **Find the plan.** Look in `.claude/plans/` for a file matching the argument. If ambiguous, list matches and ask the user to pick one.

2. **Read the plan.** Understand the full scope — summary, requirements, technical approach, what is already marked as DONE, and out-of-scope items.

3. **Study the codebase.** Before writing code, read the existing files referenced in the plan to understand current patterns and conventions.

4. **Implement step by step.** Follow the technical approach section in order. After completing each major step (migration, model, controller, views, etc.), mark the step in the plan as DONE, summarize what you did, and **ask the user for confirmation before moving to the next step**.

5. **Delegate to agents.** Where a task is better suited to a specialized agent (as defined in AGENTS.md), delegate it rather than doing it yourself.

6. **Verify.** Run the tests to confirm everything passes.

## Rules

- Follow existing codebase patterns and conventions.
- If the plan references a UI prototype or design handoff, use the Figma agent or read the prototype HTML to match the design.
- Only implement what's in scope — respect the "Out of Scope" section.
- If you hit a blocker or ambiguity not covered by the plan, ask the user before proceeding.
