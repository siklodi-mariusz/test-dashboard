---
name: quality-check
description: "Run linters and security auditors, then fix any errors found"
disable-model-invocation: true
---

## Verification output

!`bin/verify 2>&1 || true`

## Your task

Review the verification output above carefully.

1. **If all checks passed**, report success to the user and stop.

2. **If any checks failed**, parse the output and create a todo list with one item per distinct error or warning reported by the tools (RuboCop, Herb Linter, Brakeman, bundler-audit).

3. **Fix errors one by one.** Work through each item sequentially:
   - Mark the current item as in_progress.
   - Read the relevant file(s) to understand context.
   - Apply the fix.
   - Mark the item as completed before moving to the next.

4. **Re-run `bin/verify`** after all fixes are applied to confirm everything passes. If new issues appear, repeat from step 2.

## Rules

- Follow existing codebase patterns and conventions.
- For RuboCop violations, prefer auto-correctable fixes (`rubocop -a`) only when the cop is safe to auto-correct. Otherwise fix manually.
- For Brakeman warnings, understand the security concern before applying a fix — do not blindly suppress warnings.
- For bundler-audit vulnerabilities, update the affected gem if possible. If an update is not feasible, explain why to the user.
- Do NOT add `rubocop:disable` comments unless the cop is genuinely inapplicable and you explain why.
- After all fixes pass, delegate to the @test-writer agent to ensure tests still pass.
