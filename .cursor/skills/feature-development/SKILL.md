---
name: feature-development
description: Build a Tiền Đây feature from an approved requirement through implementation and verification.
---

# Feature Development Skill

## Workflow
1. Read the requested feature and identify acceptance criteria.
2. Inspect the current architecture and data flow.
3. Identify the smallest implementation that satisfies the requirement.
4. Plan model/state/UI changes before editing.
5. Implement in the existing codebase.
6. Connect the feature to real application state/persistence when required.
7. Test the primary flow and relevant edge cases.
8. Review the diff for unrelated changes.
9. Report:
   - What changed
   - Files changed
   - Tests/checks run
   - Remaining limitations

## Guardrails
- One feature at a time.
- No unrelated refactor.
- No new framework or architecture without approval.
- No hard-coded production behavior.
