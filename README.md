# Tiền Đây

Personal finance app. One Git repository: `sangthaitest/tien_dau`.

## Current prototype (single source)

**Demo/ is the current V3 UX/UI source of truth. When documentation conflicts with Demo/, Demo/ wins until explicitly changed.**

HTML UX prototype in `Demo/`. Open locally — public GitHub Pages hosting is disabled.

| Path | Role |
|------|------|
| `Demo/index.html` | Entry point. Open in a browser (or `npx serve Demo`). |
| `Demo/style.css` | Prototype styles |
| `Demo/script.js` | Prototype logic |
| `Demo/assets/` | Icons and illustrations |
| Root `index.html` | Redirects to `Demo/` for local preview |

Do not add v4 or a second HTML app.

Production Flutter app (Phase 02 foundation) lives in `app/`. `Demo/` stays the UX/UI source of truth and must not be edited for production architecture.
