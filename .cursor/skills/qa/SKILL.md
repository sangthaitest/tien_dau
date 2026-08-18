---
name: qa
description: Validate Tiền Đây UX, functional behavior, persistence, and regression after changes.
---

# QA Skill

## Core flows
Test:
1. Home → + → amount → category → save → Home.
2. Create → view transaction.
3. Edit → updated transaction and totals.
4. Delete → transaction removed and totals updated.
5. Home → Financial → PIN → financial data.
6. Statistics reflects real transaction data.

## UI checks
- Mobile layout
- Touch targets
- Keyboard behavior
- Empty states
- Selected/pressed states
- Text overflow
- Currency formatting
- Back navigation

## Data checks
- Create persists.
- Edit persists.
- Delete persists.
- Reload does not lose valid data.
- Totals match transaction data.

## Regression
- Check screens outside the requested scope for accidental breakage.
- Review git diff for unintended changes.

## Output
Classify findings as:
- PASS
- FAIL
- BUG
- FIXED
- REMAINING
