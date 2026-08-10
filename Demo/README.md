# Tiền Đây — Interactive HTML Prototype

Modern personal finance mobile app prototype for UX review before Flutter implementation.

**Not production code.** Open `index.html` in a browser — no build step, no frameworks.

## Quick start

1. Open `index.html` in Chrome / Edge / Firefox  
   (or serve locally if you prefer: `npx serve .`)
2. Flow: **Splash → Onboarding → Login → Home**
3. Use the bottom nav, FAB, and sheets to explore

## What's included

| Screen | Features |
|--------|----------|
| Splash | Animated logo + loader |
| Onboarding | 3 slides, dots, skip / next |
| Login | Google, Apple, continue as guest |
| Home | Balance, stats, quick actions, recent tx, budget, bills, tips, FAB |
| Transactions | Search, category chips, grouped list, swipe-to-reveal |
| Add Transaction | Bottom sheet: amount, type, category, account, date/time, note, attachments |
| Budget | Summary, warnings, category progress bars, savings goal empty state |
| Statistics | Period tabs, pie chart, bar chart, top spending |
| Settings | Profile, currency, language, **dark mode**, notifications, export, backup, about |

## Design system

- **Style:** Material 3–inspired, warm & premium (Monzo / YNAB / Money Lover vibe)
- **Primary:** `#4CAF50` · Expense `#EF5350` · Income `#26A69A`
- **Fonts:** Outfit (display) + Plus Jakarta Sans · Material Symbols Rounded
- **Phone frame:** ~390×844, notch, status bar, bottom nav, safe areas
- **Motion:** page transitions, ripples, FAB spring, progress/bar animations, sheet slide-up

## File structure

```
tien_dau/
├── index.html
├── style.css
├── script.js
├── README.md
└── assets/
    ├── icons/
    │   └── favicon.svg
    └── illustrations/
        ├── logo.svg
        ├── empty-wallet.svg
        ├── piggy-bank.svg
        ├── budget.svg
        ├── statistics.svg
        ├── onboarding-1.svg … onboarding-3.svg
        ├── login.svg, receipt.svg, coffee.svg, food.svg
        ├── transport.svg, home-cat.svg, salary.svg, shopping.svg
        ├── calendar.svg, saving.svg, goal.svg
        └── …
```

## Interactions to try

- Bottom navigation with animated indicator
- Floating **+** button → add transaction sheet
- Save a transaction (appears in Home + Transactions)
- Dark mode toggle in Settings (persists via `localStorage`)
- Transaction chips / search filter
- Week / Month / Year charts
- Swipe-style reveal on transaction rows (tap to toggle)

## Mock data

Vietnamese-realistic sample data: Lương, Highlands, Grab, Shopee, Điện/Nước/Internet, thuê nhà, VinMart, etc.

## Notes for Flutter port

- Color tokens and spacing live as CSS variables in `style.css` (`:root` / `[data-theme="dark"]`) — map 1:1 to a Flutter theme.
- Screen list and nav model in `script.js` `state.mainScreens` mirror a typical `BottomNavigationBar` + shell.
- Charts are CSS/SVG mocks; replace with `fl_chart` or similar in Flutter.
- Illustrations are SVG assets ready to reuse or redraw for Flutter (`flutter_svg`).

## Browser support

Modern evergreen browsers. Best reviewed at phone width (~390px) or full phone frame on desktop.
