---
name: git-workflow
description: Safely manage Git changes for Tiền Đây inside the single approved repository.
---

# Git Workflow Skill

## Workflow
1. Check current repository and git status.
2. Confirm work is inside the existing Tiền Đây repository.
3. Inspect the diff before committing.
4. Verify no unrelated files or generated junk are included.
5. Run relevant tests/build checks.
6. Summarize the changes.
7. Commit only when the user/project workflow calls for a commit.

## Commit guidance
- Keep commits focused.
- Use clear messages describing the actual change.
- Do not mix unrelated features in one commit when avoidable.

## Hard guardrails
- Never create a second repository.
- Never create a duplicate project to implement a feature.
- Never force-push.
- Never discard unrelated user work.
- Never rewrite history unless explicitly requested.
