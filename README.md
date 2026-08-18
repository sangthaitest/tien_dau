# Tiền Đây

Personal finance app. One Git repository: `sangthaitest/tien_dau`.

## Current prototype (single source)

**Demo/ is the current V3 UX/UI source of truth. When documentation conflicts with Demo/, Demo/ wins until explicitly changed.**

HTML UX prototype in `Demo/`. GitHub Pages for this repo: [https://sangthaitest.github.io/tien_dau/](https://sangthaitest.github.io/tien_dau/).

| Path | Role |
|------|------|
| `Demo/index.html` | Entry point. Open in a browser (or `npx serve Demo`). |
| `Demo/style.css` | Prototype styles |
| `Demo/script.js` | Prototype logic |
| `Demo/assets/` | Icons and illustrations |
| Root `index.html` | Redirects to `Demo/` (GitHub Pages) |

Do not add v4 or a second HTML app.

Production Flutter app (Phase 02 foundation) lives in `app/`. `Demo/` stays the UX/UI source of truth and must not be edited for production architecture.

The user Pages repo `sangthaitest.github.io` is **hosting only** for the live `?v=3` URL. Edit this repo, then deploy a copy there when the live site needs an update.
