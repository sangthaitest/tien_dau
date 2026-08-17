/**
 * Tiền Đây — Interactive Prototype
 * Vanilla JS · No frameworks
 */

/* ============================================================
   MOCK DATA — Realistic Vietnamese finance data
   ============================================================ */
const CATEGORIES = {
  food:       { name: 'Ăn uống',    icon: 'restaurant',     color: '#FF8A5B', bg: '#FFF0EA', img: 'assets/illustrations/food.svg' },
  coffee:     { name: 'Cà phê',     icon: 'local_cafe',     color: '#A0785A', bg: '#F5EDE6', img: 'assets/illustrations/coffee.svg' },
  transport:  { name: 'Di chuyển',  icon: 'directions_car', color: '#4DA3FF', bg: '#E8F3FF', img: 'assets/illustrations/transport.svg' },
  shopping:   { name: 'Mua sắm',    icon: 'shopping_bag',   color: '#B57BFF', bg: '#F3EBFF', img: 'assets/illustrations/shopping.svg' },
  home:       { name: 'Nhà cửa',    icon: 'home',           color: '#00B67A', bg: '#E6F8EF', img: 'assets/illustrations/home-cat.svg' },
  utilities:  { name: 'Hóa đơn',    icon: 'bolt',           color: '#FFB020', bg: '#FFF6E5', img: 'assets/illustrations/receipt.svg' },
  salary:     { name: 'Lương',      icon: 'payments',       color: '#00A3A1', bg: '#E0F7F5', img: 'assets/illustrations/salary.svg' },
  entertainment: { name: 'Giải trí', icon: 'movie',         color: '#FF6B9D', bg: '#FFE8F0', img: null },
  health:     { name: 'Sức khỏe',   icon: 'favorite',       color: '#FF6B6B', bg: '#FFECEC', img: null },
  education:  { name: 'Học tập',    icon: 'school',         color: '#6B7CFF', bg: '#EEF0FF', img: null },
  other:      { name: 'Khác',       icon: 'more_horiz',     color: '#8B93A0', bg: '#EEF1F5', img: null },
};

const TRANSACTIONS = [
  { id: 21, title: 'Ăn sáng',             category: 'food',      type: 'expense', amount: 35000,    date: '2026-08-07', time: '07:15', note: '', account: 'Tiền mặt' },
  { id: 1,  title: 'Lương tháng 8',       category: 'salary',    type: 'income',  amount: 18500000, date: '2026-08-01', time: '09:00', note: 'TechCorp VN', account: 'Vietcombank' },
  { id: 2,  title: 'Tiền thuê nhà',       category: 'home',      type: 'expense', amount: 4500000,  date: '2026-08-02', time: '10:30', note: 'Căn hộ Q7', account: 'Vietcombank' },
  { id: 3,  title: 'Highlands Coffee',    category: 'coffee',    type: 'expense', amount: 55000,    date: '2026-08-07', time: '08:15', note: 'Phin sữa đá', account: 'MoMo' },
  { id: 4,  title: 'Grab Bike',           category: 'transport', type: 'expense', amount: 42000,    date: '2026-08-07', time: '08:40', note: 'Đến công ty', account: 'MoMo' },
  { id: 5,  title: 'Cơm tấm Sài Gòn',     category: 'food',      type: 'expense', amount: 65000,    date: '2026-08-06', time: '12:30', note: '', account: 'Tiền mặt' },
  { id: 6,  title: 'Shopee — Áo thun',    category: 'shopping',  type: 'expense', amount: 289000,   date: '2026-08-06', time: '21:00', note: 'Flash sale', account: 'Techcombank' },
  { id: 7,  title: 'Xăng xe',             category: 'transport', type: 'expense', amount: 200000,   date: '2026-08-05', time: '17:45', note: 'Petrolimex', account: 'Tiền mặt' },
  { id: 8,  title: 'Điện tháng 7',        category: 'utilities', type: 'expense', amount: 485000,   date: '2026-08-05', time: '09:00', note: 'EVN', account: 'Vietcombank' },
  { id: 9,  title: 'Nước tháng 7',        category: 'utilities', type: 'expense', amount: 120000,   date: '2026-08-05', time: '09:05', note: 'Sawaco', account: 'Vietcombank' },
  { id: 10, title: 'Internet FPT',        category: 'utilities', type: 'expense', amount: 220000,   date: '2026-08-04', time: '14:00', note: 'Gói 100Mbps', account: 'MoMo' },
  { id: 11, title: 'Siêu thị VinMart',    category: 'shopping',  type: 'expense', amount: 456000,   date: '2026-08-04', time: '19:20', note: 'Mua đồ tuần', account: 'Vietcombank' },
  { id: 12, title: 'The Coffee House',    category: 'coffee',    type: 'expense', amount: 69000,    date: '2026-08-03', time: '15:00', note: 'Meeting', account: 'MoMo' },
  { id: 13, title: 'Netflix',             category: 'entertainment', type: 'expense', amount: 180000, date: '2026-08-03', time: '00:01', note: 'Gói Premium', account: 'Techcombank' },
  { id: 14, title: 'Phở Hòa Pasteur',     category: 'food',      type: 'expense', amount: 85000,    date: '2026-08-03', time: '07:30', note: '', account: 'Tiền mặt' },
  { id: 15, title: 'Grab Car',            category: 'transport', type: 'expense', amount: 125000,   date: '2026-08-02', time: '20:15', note: 'Về nhà', account: 'MoMo' },
  { id: 16, title: 'Khám răng',           category: 'health',    type: 'expense', amount: 350000,   date: '2026-08-02', time: '14:00', note: 'Nha khoa Paris', account: 'Vietcombank' },
  { id: 17, title: 'Freelance design',    category: 'salary',    type: 'income',  amount: 2500000,  date: '2026-08-01', time: '16:00', note: 'Logo project', account: 'Techcombank' },
  { id: 18, title: 'Sách kỹ năng',        category: 'education', type: 'expense', amount: 175000,   date: '2026-07-31', time: '11:00', note: 'Fahasa', account: 'MoMo' },
  { id: 19, title: 'Bún chả Hà Nội',      category: 'food',      type: 'expense', amount: 75000,    date: '2026-07-31', time: '12:15', note: '', account: 'Tiền mặt' },
  { id: 20, title: 'Xem phim CGV',        category: 'entertainment', type: 'expense', amount: 210000, date: '2026-07-30', time: '19:30', note: '2 vé + bắp', account: 'MoMo' },
];

const BUDGETS = [
  { category: 'food',       limit: 2500000, spent: 2280000 },
  { category: 'transport',  limit: 1500000, spent: 980000 },
  { category: 'shopping',   limit: 2000000, spent: 745000 },
  { category: 'utilities',  limit: 1200000, spent: 825000 },
  { category: 'coffee',     limit: 500000,  spent: 312000 },
  { category: 'entertainment', limit: 800000, spent: 390000 },
  { category: 'health',     limit: 1000000, spent: 350000 },
  { category: 'education',  limit: 500000,  spent: 175000 },
];

const BILLS = [
  { title: 'Điện tháng 8',    amount: 520000, day: 15, mon: 'T8', category: 'utilities' },
  { title: 'Internet FPT',    amount: 220000, day: 18, mon: 'T8', category: 'utilities' },
  { title: 'Tiền thuê nhà',   amount: 4500000, day: 2, mon: 'T9', category: 'home' },
  { title: 'Netflix',         amount: 180000, day: 3, mon: 'T9', category: 'entertainment' },
];

const TIPS = [
  'Quy tắc 50/30/20 không phải luật — hãy điều chỉnh cho cuộc sống thật của bạn 💚',
  'Ghi ngay khi chi: 5 giây hôm nay = sự rõ ràng cả tháng.',
  'Chuyển 10% lương sang tiết kiệm ngay khi nhận — “pay yourself first”.',
  'Review ngân sách 10 phút mỗi Chủ nhật = ít stress cả tuần.',
  'Cà phê mang đi mỗi ngày ≈ 1.5 triệu/tháng. Thử pha nhà 2 ngày/tuần nhé!',
];

const PIE_DATA = [
  { key: 'food',       pct: 28, color: '#FF8A5B' },
  { key: 'home',       pct: 35, color: '#00B67A' },
  { key: 'transport',  pct: 12, color: '#4DA3FF' },
  { key: 'shopping',   pct: 9,  color: '#B57BFF' },
  { key: 'utilities',  pct: 10, color: '#FFB020' },
  { key: 'other',      pct: 6,  color: '#8B93A0' },
];

const BAR_DATA = {
  week:  [
    { label: 'T2', value: 45 }, { label: 'T3', value: 62 }, { label: 'T4', value: 38 },
    { label: 'T5', value: 80 }, { label: 'T6', value: 95 }, { label: 'T7', value: 70 }, { label: 'CN', value: 55 },
  ],
  month: [
    { label: 'T1', value: 40 }, { label: 'T2', value: 55 }, { label: 'T3', value: 48 },
    { label: 'T4', value: 70 }, { label: 'T5', value: 62 }, { label: 'T6', value: 85 },
    { label: 'T7', value: 78 }, { label: 'T8', value: 65 },
  ],
  year:  [
    { label: '2022', value: 50 }, { label: '2023', value: 65 },
    { label: '2024', value: 80 }, { label: '2025', value: 72 }, { label: '2026', value: 58 },
  ],
};

const TOP_SPENDING = [
  { title: 'Tiền thuê nhà', amount: 4500000, category: 'home' },
  { title: 'Siêu thị VinMart', amount: 456000, category: 'shopping' },
  { title: 'Điện tháng 7', amount: 485000, category: 'utilities' },
  { title: 'Khám răng', amount: 350000, category: 'health' },
  { title: 'Shopee — Áo thun', amount: 289000, category: 'shopping' },
];

/* ============================================================
   STATE
   ============================================================ */
const state = {
  currentScreen: 'splash',
  onboardingStep: 0,
  txFilter: 'all',
  txSearch: '',
  period: 'month',
  darkMode: false,
  selectedCategory: 'food',
  txType: 'expense',
  balanceHidden: false,
  balanceValue: 24850000,
  editingTxId: null,
  mainScreens: ['home', 'transactions', 'budget', 'statistics', 'settings'],
};

const PRIVACY_MASK = '•••••••';

/* ============================================================
   UTILITIES
   ============================================================ */
function formatVND(n, short = false) {
  const abs = Math.abs(n);
  if (short) {
    if (abs >= 1_000_000) return (n / 1_000_000).toFixed(1).replace('.0', '') + 'tr';
    if (abs >= 1_000) return Math.round(n / 1_000) + 'k';
  }
  return abs.toLocaleString('vi-VN') + ' ₫';
}

function formatSigned(n, short = false) {
  const sign = n >= 0 ? '+' : '−';
  return sign + formatVND(Math.abs(n), short);
}

function formatDateLabel(dateStr) {
  const d = new Date(dateStr + 'T00:00:00');
  const today = new Date('2026-08-07T00:00:00');
  const yesterday = new Date('2026-08-06T00:00:00');
  if (d.getTime() === today.getTime()) return 'Hôm nay';
  if (d.getTime() === yesterday.getTime()) return 'Hôm qua';
  const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  return `${days[d.getDay()]}, ${d.getDate()}/${d.getMonth() + 1}`;
}

function isBreakfastTx(tx) {
  return tx && (tx.title === 'Ăn sáng' || /ăn sáng/i.test(tx.title || ''));
}

function monthExpenseTotal() {
  return TRANSACTIONS
    .filter(t => t.type === 'expense' && String(t.date).startsWith('2026-08'))
    .reduce((s, t) => s + t.amount, 0);
}

function budgetTotals() {
  const limit = BUDGETS.reduce((s, b) => s + b.limit, 0);
  const spent = BUDGETS.reduce((s, b) => s + b.spent, 0);
  return { limit, spent, remaining: Math.max(0, limit - spent) };
}

function groupByDate(txs) {
  const map = {};
  txs.forEach(t => {
    if (!map[t.date]) map[t.date] = [];
    map[t.date].push(t);
  });
  return Object.entries(map).sort((a, b) => b[0].localeCompare(a[0]));
}

function $(sel, root = document) { return root.querySelector(sel); }
function $$(sel, root = document) { return [...root.querySelectorAll(sel)]; }

function showToast(msg, ms = 2200) {
  const el = $('#toast');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(el._timer);
  el._timer = setTimeout(() => el.classList.remove('show'), ms);
}

function showDialog({ title, msg, icon = 'check_circle' }) {
  $('#dialog-icon').textContent = icon;
  $('#dialog-title').textContent = title;
  $('#dialog-msg').textContent = msg;
  $('#dialog-overlay').classList.add('open');
}

function closeDialog() {
  $('#dialog-overlay').classList.remove('open');
}

/* ============================================================
   RIPPLE EFFECT
   ============================================================ */
function createRipple(e) {
  const btn = e.currentTarget;
  const rect = btn.getBoundingClientRect();
  const size = Math.max(rect.width, rect.height);
  const x = e.clientX - rect.left - size / 2;
  const y = e.clientY - rect.top - size / 2;
  const ripple = document.createElement('span');
  ripple.className = 'ripple';
  ripple.style.width = ripple.style.height = size + 'px';
  ripple.style.left = x + 'px';
  ripple.style.top = y + 'px';
  btn.appendChild(ripple);
  setTimeout(() => ripple.remove(), 600);
}

function initRipples() {
  $$('.btn, .nav-item, .fab, .chip, .quick-action, .settings-item, .tx-item, .attach-btn, .type-btn, .period-tab, .cat-option').forEach(el => {
    if (el._ripple) return;
    el._ripple = true;
    el.addEventListener('click', createRipple);
  });
}

/* ============================================================
   NAVIGATION
   ============================================================ */
function showScreen(name, { animate = true } = {}) {
  state.currentScreen = name;

  $$('.screen').forEach(s => {
    const isTarget = s.dataset.screen === name;
    if (isTarget) {
      s.classList.add('active');
      s.classList.remove('slide-out-left');
    } else if (s.classList.contains('active')) {
      if (animate) s.classList.add('slide-out-left');
      s.classList.remove('active');
      setTimeout(() => s.classList.remove('slide-out-left'), 300);
    }
  });

  const isMain = state.mainScreens.includes(name);
  $('#bottom-nav').classList.toggle('visible', isMain);
  $('#fab').classList.toggle('visible', isMain && name !== 'settings');

  // Status bar contrast on green hero screens
  const lightStatus = name === 'splash' || name === 'home';
  document.querySelector('.phone-status')?.classList.toggle('on-dark', lightStatus);

  $$('.nav-item').forEach(item => {
    item.classList.toggle('active', item.dataset.nav === name);
  });

  if (name === 'budget') {
    requestAnimationFrame(() => animateProgressBars());
  }
  if (name === 'statistics') {
    requestAnimationFrame(() => renderCharts());
  }
}

function navigateMain(name) {
  if (!state.mainScreens.includes(name)) return;
  showScreen(name);
}

/* ============================================================
   RENDER HELPERS
   ============================================================ */
function renderTxItem(tx, { swipeable = false } = {}) {
  const cat = CATEGORIES[tx.category] || CATEGORIES.other;
  const breakfast = isBreakfastTx(tx);
  const sign = tx.type === 'income' ? '+' : '−';
  const maskIncome = state.balanceHidden && tx.type === 'income';
  const amountText = maskIncome ? PRIVACY_MASK : `${sign}${formatVND(tx.amount)}`;
  const iconHtml = breakfast
    ? `<span class="tx-emoji" aria-hidden="true">🍳</span>`
    : cat.img
      ? `<img src="${cat.img}" alt="" />`
      : `<span class="ms" style="color:${cat.color}">${cat.icon}</span>`;
  const iconBg = breakfast ? '#FFF0EA' : cat.bg;
  const extraClass = [
    swipeable ? 'swipeable' : '',
    breakfast ? 'is-breakfast' : '',
  ].filter(Boolean).join(' ');

  const inner = `
    <div class="tx-item ${extraClass}" data-id="${tx.id}" role="button" tabindex="0">
      <div class="tx-icon" style="background:${iconBg}">${iconHtml}</div>
      <div class="tx-info">
        <div class="title">${tx.title}</div>
        <div class="meta">${cat.name} · ${tx.time || ''}${tx.account ? ' · ' + tx.account : ''}</div>
      </div>
      <div class="tx-amount ${tx.type}">${amountText}</div>
    </div>
  `;

  if (!swipeable) return inner;

  return `
    <div class="tx-swipe-wrap" data-id="${tx.id}">
      <div class="tx-swipe-actions">
        <button type="button" class="tx-delete" data-delete="${tx.id}" aria-label="Xóa giao dịch">
          <span class="ms">delete</span>
          Xóa
        </button>
      </div>
      ${inner}
    </div>
  `;
}

function renderBudgetItem(b) {
  const cat = CATEGORIES[b.category] || CATEGORIES.other;
  const pct = Math.min(100, Math.round((b.spent / b.limit) * 100));
  const remaining = b.limit - b.spent;
  let fillClass = '';
  let badge = '<span class="status-badge ok">Ổn</span>';
  if (pct >= 90) {
    fillClass = 'danger';
    badge = '<span class="status-badge danger">Nguy hiểm</span>';
  } else if (pct >= 75) {
    fillClass = 'warning';
    badge = '<span class="status-badge warn">Cảnh báo</span>';
  }

  return `
    <div class="budget-item">
      <div class="budget-item-top">
        <div class="budget-item-left">
          <div class="budget-cat-icon" style="background:${cat.bg};color:${cat.color}">
            <span class="ms">${cat.icon}</span>
          </div>
          <div>
            <div style="font-weight:650;font-size:14px;display:flex;align-items:center;gap:8px">${cat.name} ${badge}</div>
            <div class="tiny">Ngân sách ${formatVND(b.limit, true)}</div>
          </div>
        </div>
        <div class="tiny" style="text-align:right">${pct}%</div>
      </div>
      <div class="progress-bar" role="progressbar" aria-valuenow="${pct}" aria-valuemin="0" aria-valuemax="100" aria-label="${cat.name}">
        <div class="progress-fill ${fillClass}" data-pct="${pct}"></div>
      </div>
      <div class="budget-meta">
        <span>Đã dùng ${formatVND(b.spent)}</span>
        <span>Còn ${formatVND(Math.max(0, remaining))}</span>
      </div>
    </div>
  `;
}

function animateProgressBars() {
  $$('.progress-fill[data-pct]').forEach(el => {
    const pct = el.dataset.pct;
    el.style.width = '0%';
    requestAnimationFrame(() => {
      requestAnimationFrame(() => { el.style.width = pct + '%'; });
    });
  });
  const totalBar = $('#budget-total-bar');
  if (totalBar) {
    const { limit, spent } = budgetTotals();
    const pct = limit ? Math.min(100, Math.round((spent / limit) * 100)) : 0;
    totalBar.style.width = '0%';
    requestAnimationFrame(() => {
      requestAnimationFrame(() => { totalBar.style.width = pct + '%'; });
    });
  }
}

/* ============================================================
   SCREEN RENDERERS
   ============================================================ */
function renderHome() {
  updatePrivacyDisplay();
  const recent = TRANSACTIONS.filter(t => t.type === 'expense').slice(0, 8);
  $('#home-tx-list').innerHTML = recent.map(t => renderTxItem(t)).join('');

  $('#upcoming-bills').innerHTML = BILLS.slice(0, 3).map(b => {
    const cat = CATEGORIES[b.category] || CATEGORIES.other;
    return `
      <div class="bill-item">
        <div class="bill-date">
          <span class="day">${b.day}</span>
          <span class="mon">${b.mon}</span>
        </div>
        <div class="bill-info">
          <div class="title">${b.title}</div>
          <div class="meta">${cat.name}</div>
        </div>
        <div class="amount" style="font-size:13px;margin-right:4px">${formatVND(b.amount, true)}</div>
        <button class="btn-pay" type="button" data-bill="${b.title}">Thanh toán</button>
      </div>
    `;
  }).join('');

  $$('[data-bill]').forEach(btn => {
    btn.addEventListener('click', e => {
      e.stopPropagation();
      showToast(`Đã nhắc thanh toán: ${btn.dataset.bill}`);
    });
  });

  const tipEl = $('#financial-tip');
  if (tipEl && !tipEl.dataset.ready) {
    tipEl.textContent = TIPS[Math.floor(Math.random() * TIPS.length)];
    tipEl.dataset.ready = '1';
  }
  initRipples();
}

function updatePrivacyDisplay() {
  const el = $('#current-balance');
  if (el) {
    if (state.balanceHidden) {
      el.textContent = PRIVACY_MASK;
      $('#balance-row')?.classList.add('balance-hidden');
    } else {
      el.textContent = formatVND(monthExpenseTotal());
      $('#balance-row')?.classList.remove('balance-hidden');
    }
  }
  const statsIncome = $('.compare-card.income .val');
  if (statsIncome) statsIncome.textContent = state.balanceHidden ? PRIVACY_MASK : '21.0tr';
}

function renderTransactions() {
  let list = [...TRANSACTIONS];

  if (state.txFilter === 'expense' || state.txFilter === 'income') {
    list = list.filter(t => t.type === state.txFilter);
  } else if (state.txFilter !== 'all') {
    list = list.filter(t => t.category === state.txFilter);
  }

  if (state.txSearch) {
    const q = state.txSearch.toLowerCase();
    list = list.filter(t =>
      t.title.toLowerCase().includes(q) ||
      (CATEGORIES[t.category]?.name || '').toLowerCase().includes(q) ||
      (t.note || '').toLowerCase().includes(q)
    );
  }

  // Summary for filtered set
  const incomeSum = list.filter(t => t.type === 'income').reduce((s, t) => s + t.amount, 0);
  const expenseSum = list.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
  const sumIn = $('#tx-sum-income');
  const sumOut = $('#tx-sum-expense');
  if (sumIn) sumIn.textContent = state.balanceHidden ? PRIVACY_MASK : '+' + formatVND(incomeSum, true);
  if (sumOut) sumOut.textContent = '−' + formatVND(expenseSum, true);

  const empty = $('#tx-empty');
  const container = $('#tx-list-full');

  if (list.length === 0) {
    container.innerHTML = '';
    empty.classList.remove('hidden');
    return;
  }
  empty.classList.add('hidden');

  const groups = groupByDate(list);
  container.innerHTML = groups.map(([date, txs]) => {
    const hasIncome = txs.some(t => t.type === 'income');
    const dayNet = txs.reduce((s, t) => s + (t.type === 'income' ? t.amount : -t.amount), 0);
    const dayExpense = txs.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
    let dayLabel;
    if (state.balanceHidden && hasIncome) {
      dayLabel = PRIVACY_MASK;
    } else if (hasIncome) {
      dayLabel = (dayNet >= 0 ? '+' : '−') + formatVND(Math.abs(dayNet), true);
    } else {
      dayLabel = '−' + formatVND(dayExpense, true);
    }
    return `
      <div class="date-group">
        <div class="date-label-row">
          <div class="date-label">${formatDateLabel(date)}</div>
          <div class="day-total">${dayLabel}</div>
        </div>
        <div class="tx-list">
          ${txs.map(t => renderTxItem(t, { swipeable: true })).join('')}
        </div>
      </div>
    `;
  }).join('');

  $$('.tx-swipe-wrap', container).forEach(bindTxSwipe);

  $$('[data-delete]', container).forEach(btn => {
    btn.addEventListener('click', e => {
      e.stopPropagation();
      const id = Number(btn.dataset.delete);
      const idx = TRANSACTIONS.findIndex(t => t.id === id);
      if (idx >= 0) TRANSACTIONS.splice(idx, 1);
      renderTransactions();
      renderHome();
      showToast('Đã xóa giao dịch');
    });
  });

  initRipples();
}

function renderBudget() {
  const { limit, spent, remaining } = budgetTotals();
  const pct = limit ? Math.round((spent / limit) * 100) : 0;
  const setText = (id, text) => { const el = $(id); if (el) el.textContent = text; };
  setText('#budget-limit', formatVND(limit));
  setText('#budget-spent', formatVND(spent));
  setText('#budget-remaining', formatVND(remaining));
  setText('#budget-pct-label', `Đã dùng ${pct}%`);
  $('#budget-list-full').innerHTML = BUDGETS.map(b => renderBudgetItem(b)).join('');
  setTimeout(animateProgressBars, 50);
}

function renderCharts() {
  // Pie chart via conic-gradient
  let acc = 0;
  const stops = PIE_DATA.map(d => {
    const start = acc;
    acc += d.pct;
    return `${d.color} ${start}% ${acc}%`;
  }).join(', ');
  const pie = $('#pie-chart');
  pie.style.background = `conic-gradient(${stops})`;

  const totalExpense = 8240000;
  $('#pie-legend').innerHTML = PIE_DATA.map(d => {
    const cat = CATEGORIES[d.key] || CATEGORIES.other;
    const amt = Math.round(totalExpense * d.pct / 100);
    return `
      <div class="legend-item">
        <span class="legend-dot" style="background:${d.color}"></span>
        <span class="name">${cat.name}<span class="amt">${formatVND(amt, true)}</span></span>
        <span class="val">${d.pct}%</span>
      </div>
    `;
  }).join('');

  // Bar chart with values
  const data = BAR_DATA[state.period] || BAR_DATA.month;
  const max = Math.max(...data.map(d => d.value));
  const highlightIdx = data.length - 1;
  const scale = state.period === 'year' ? 1000000 : state.period === 'week' ? 50000 : 200000;
  $('#bar-chart').innerHTML = data.map((d, i) => {
    const h = Math.round((d.value / max) * 100);
    const approx = formatVND(d.value * scale / 100, true);
    return `
      <div class="bar-col" title="${approx}">
        <span class="bar-val">${i === highlightIdx ? approx : ''}</span>
        <div class="bar ${i === highlightIdx ? 'highlight' : ''}" style="height:0%" data-h="${h}"></div>
        <span class="label">${d.label}</span>
      </div>
    `;
  }).join('');

  requestAnimationFrame(() => {
    $$('#bar-chart .bar').forEach(b => {
      requestAnimationFrame(() => { b.style.height = b.dataset.h + '%'; });
    });
  });

  const labels = { week: 'Tuần này', month: '8 tháng gần đây', year: '5 năm gần đây' };
  $('#bar-period-label').textContent = labels[state.period];

  // Top spending
  $('#top-spending').innerHTML = TOP_SPENDING.map((t, i) => {
    const cat = CATEGORIES[t.category] || CATEGORIES.other;
    const rankClass = i === 0 ? 'gold' : i === 1 ? 'silver' : i === 2 ? 'bronze' : '';
    return `
      <div class="top-spend-item">
        <span class="rank ${rankClass}">${i + 1}</span>
        <div class="tx-icon" style="width:36px;height:36px;border-radius:10px;background:${cat.bg}">
          <span class="ms sm" style="color:${cat.color}">${cat.icon}</span>
        </div>
        <div class="tx-info">
          <div class="title">${t.title}</div>
          <div class="meta">${cat.name}</div>
        </div>
        <div class="tx-amount expense">${formatVND(t.amount)}</div>
      </div>
    `;
  }).join('');
}

function renderCategoryGrid() {
  const expenseCats = ['food', 'coffee', 'transport', 'shopping', 'home', 'utilities', 'entertainment', 'health', 'education'];
  const incomeCats = ['salary', 'other'];
  const cats = state.txType === 'income' ? incomeCats : expenseCats;

  $('#category-grid').innerHTML = cats.map(key => {
    const c = CATEGORIES[key];
    return `
      <button class="cat-option ${state.selectedCategory === key ? 'active' : ''}" data-cat="${key}" type="button">
        <div class="icon" style="background:${c.bg};color:${c.color}">
          <span class="ms">${c.icon}</span>
        </div>
        <span class="name">${c.name}</span>
      </button>
    `;
  }).join('');

  $$('.cat-option').forEach(btn => {
    btn.addEventListener('click', () => {
      state.selectedCategory = btn.dataset.cat;
      $$('.cat-option').forEach(b => b.classList.toggle('active', b.dataset.cat === state.selectedCategory));
    });
  });
}

function bindTxSwipe(wrap) {
  const item = $('.tx-item', wrap);
  if (!item || item._swipeBound) return;
  item._swipeBound = true;
  let startX = 0;
  let startY = 0;
  let swiping = false;
  let tracking = false;

  const down = (x, y) => {
    startX = x;
    startY = y;
    swiping = false;
    tracking = true;
  };
  const move = (x, y) => {
    if (!tracking) return;
    const dx = x - startX;
    const dy = y - startY;
    if (Math.abs(dx) > 12 && Math.abs(dx) > Math.abs(dy)) swiping = true;
  };
  const up = (x) => {
    if (!tracking) return;
    tracking = false;
    const dx = x - startX;
    if (swiping && dx < -40) {
      wrap._ignoreClick = true;
      $$('.tx-swipe-wrap.open').forEach(o => { if (o !== wrap) o.classList.remove('open'); });
      wrap.classList.add('open');
    } else if (swiping && dx > 24) {
      wrap._ignoreClick = true;
      wrap.classList.remove('open');
    }
  };

  item.addEventListener('pointerdown', e => {
    try { item.setPointerCapture(e.pointerId); } catch (_) {}
    down(e.clientX, e.clientY);
  });
  item.addEventListener('pointermove', e => move(e.clientX, e.clientY));
  item.addEventListener('pointerup', e => up(e.clientX));
  item.addEventListener('pointercancel', () => { tracking = false; });
}

function openTxDetail(id) {
  const tx = TRANSACTIONS.find(t => t.id === Number(id));
  if (!tx) return;
  state.editingTxId = tx.id;
  state.txType = tx.type;
  state.selectedCategory = tx.category;
  $('#sheet-title').textContent = 'Sửa giao dịch';
  $('#btn-save-tx').textContent = 'Lưu thay đổi';
  $('#input-amount').value = tx.amount.toLocaleString('vi-VN');
  $('#input-note').value = tx.title || tx.note || '';
  $('#input-date').value = tx.date;
  $('#input-time').value = tx.time || '12:00';
  const account = $('#input-account');
  if (account && tx.account) account.value = tx.account;
  $$('.type-btn').forEach(b => b.classList.toggle('active', b.dataset.type === tx.type));
  renderCategoryGrid();
  $('#sheet-overlay').classList.add('open');
  $('#add-sheet').classList.add('open');
}

function handleTxActivate(item) {
  if (!item) return;
  const wrap = item.closest('.tx-swipe-wrap');
  if (wrap && wrap._ignoreClick) {
    wrap._ignoreClick = false;
    return;
  }
  if (wrap && wrap.classList.contains('open')) {
    wrap.classList.remove('open');
    return;
  }
  openTxDetail(item.dataset.id);
}

/* ============================================================
   BOTTOM SHEET
   ============================================================ */
function openSheet() {
  const now = new Date();
  state.editingTxId = null;
  $('#sheet-title').textContent = 'Thêm giao dịch';
  $('#btn-save-tx').textContent = 'Lưu giao dịch';
  $('#input-date').value = '2026-08-07';
  $('#input-time').value = String(now.getHours()).padStart(2, '0') + ':' + String(now.getMinutes()).padStart(2, '0');
  $('#input-amount').value = '';
  $('#input-note').value = '';
  state.txType = 'expense';
  state.selectedCategory = 'food';
  $$('.type-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.type === 'expense');
  });
  renderCategoryGrid();
  $('#sheet-overlay').classList.add('open');
  $('#add-sheet').classList.add('open');
  setTimeout(() => $('#input-amount')?.focus(), 320);
}

function closeSheet() {
  $('#sheet-overlay').classList.remove('open');
  $('#add-sheet').classList.remove('open');
  state.editingTxId = null;
}

function saveTransaction() {
  const amountStr = $('#input-amount').value.replace(/\D/g, '');
  const amount = parseInt(amountStr, 10);
  if (!amount || amount <= 0) {
    showToast('Vui lòng nhập số tiền');
    $('#input-amount').focus();
    return;
  }
  const note = $('#input-note').value.trim();
  const title = note || (CATEGORIES[state.selectedCategory]?.name || 'Giao dịch mới');
  const payload = {
    title,
    category: state.selectedCategory,
    type: state.txType,
    amount,
    date: $('#input-date').value || '2026-08-07',
    time: $('#input-time').value || '12:00',
    note,
    account: $('#input-account').value,
  };

  if (state.editingTxId) {
    const tx = TRANSACTIONS.find(t => t.id === state.editingTxId);
    if (tx) Object.assign(tx, payload);
    state.editingTxId = null;
    closeSheet();
    renderHome();
    renderTransactions();
    renderBudget();
    showToast('Đã cập nhật giao dịch ✓');
    return;
  }

  TRANSACTIONS.unshift({ id: Date.now(), ...payload });
  closeSheet();
  renderHome();
  renderTransactions();
  showToast('Đã lưu giao dịch ✓');
}

/* ============================================================
   ONBOARDING
   ============================================================ */
function setOnboardingStep(step) {
  state.onboardingStep = step;
  $$('.onboarding-slide').forEach((s, i) => s.classList.toggle('active', i === step));
  $$('#onboarding-dots .dot').forEach((d, i) => {
    d.classList.toggle('active', i === step);
    d.setAttribute('aria-current', i === step ? 'true' : 'false');
  });
  const progress = $('#onboarding-progress');
  if (progress) progress.textContent = `${step + 1} / 3`;
  const btn = $('#btn-next-onboarding');
  btn.textContent = step === 2 ? 'Bắt đầu ngay' : 'Tiếp tục';
}

function nextOnboarding() {
  if (state.onboardingStep < 2) {
    setOnboardingStep(state.onboardingStep + 1);
  } else {
    showScreen('login');
  }
}

/* ============================================================
   DARK MODE
   ============================================================ */
function setDarkMode(on) {
  state.darkMode = on;
  document.documentElement.setAttribute('data-theme', on ? 'dark' : 'light');
  $('#toggle-dark').classList.toggle('on', on);
  $('#toggle-dark').setAttribute('aria-checked', on);
  try { localStorage.setItem('tienday-dark', on ? '1' : '0'); } catch (_) {}
}

/* ============================================================
   STATUS TIME
   ============================================================ */
function updateClock() {
  const now = new Date();
  $('#status-time').textContent =
    String(now.getHours()).padStart(2, '0') + ':' +
    String(now.getMinutes()).padStart(2, '0');
}

/* ============================================================
   AMOUNT INPUT FORMATTING
   ============================================================ */
function formatAmountInput(el) {
  const raw = el.value.replace(/\D/g, '');
  if (!raw) { el.value = ''; return; }
  el.value = parseInt(raw, 10).toLocaleString('vi-VN');
}

/* ============================================================
   EVENT BINDINGS
   ============================================================ */
function bindEvents() {
  // Bottom nav
  $$('.nav-item').forEach(item => {
    item.addEventListener('click', () => navigateMain(item.dataset.nav));
  });

  // Link buttons that navigate (exclude bottom nav items)
  $$('[data-nav]').forEach(el => {
    if (el.classList.contains('nav-item')) return;
    el.addEventListener('click', () => navigateMain(el.dataset.nav));
  });

  // FAB + quick add
  $('#fab').addEventListener('click', openSheet);
  $$('[data-action="add"]').forEach(el => el.addEventListener('click', openSheet));

  // Quick actions
  $$('[data-action="transfer"]').forEach(el => {
    el.addEventListener('click', () => showToast('Tính năng chuyển khoản — sắp ra mắt'));
  });
  $$('[data-action="budget"]').forEach(el => {
    el.addEventListener('click', () => navigateMain('budget'));
  });
  $$('[data-action="scan"]').forEach(el => {
    el.addEventListener('click', () => showToast('Quét QR — sắp ra mắt'));
  });

  // Sheet
  $('#sheet-overlay').addEventListener('click', closeSheet);
  $('#btn-close-sheet').addEventListener('click', closeSheet);
  $('#btn-save-tx').addEventListener('click', saveTransaction);

  $$('.type-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      state.txType = btn.dataset.type;
      $$('.type-btn').forEach(b => b.classList.toggle('active', b.dataset.type === state.txType));
      state.selectedCategory = state.txType === 'income' ? 'salary' : 'food';
      renderCategoryGrid();
    });
  });

  $('#input-amount').addEventListener('input', e => formatAmountInput(e.target));

  $('#btn-photo').addEventListener('click', () => showToast('Đính kèm ảnh hóa đơn ✓'));
  $('#btn-voice').addEventListener('click', () => showToast('Đang ghi âm... (demo)'));

  // Onboarding
  $('#btn-next-onboarding').addEventListener('click', nextOnboarding);
  $('#btn-skip-onboarding').addEventListener('click', () => showScreen('login'));
  $$('#onboarding-dots .dot').forEach(dot => {
    dot.addEventListener('click', () => setOnboardingStep(Number(dot.dataset.step)));
  });

  // Onboarding swipe
  const slides = $('#onboarding-slides');
  if (slides) {
    let startX = 0;
    slides.addEventListener('touchstart', e => { startX = e.changedTouches[0].screenX; }, { passive: true });
    slides.addEventListener('touchend', e => {
      const dx = e.changedTouches[0].screenX - startX;
      if (dx < -50 && state.onboardingStep < 2) setOnboardingStep(state.onboardingStep + 1);
      if (dx > 50 && state.onboardingStep > 0) setOnboardingStep(state.onboardingStep - 1);
    }, { passive: true });
  }

  // Login
  $('#btn-google').addEventListener('click', () => enterApp('Google'));
  $('#btn-apple').addEventListener('click', () => enterApp('Apple'));
  $('#btn-guest').addEventListener('click', () => enterApp('Khách'));

  // Privacy — mask salary / totals, keep spending items visible
  $('#btn-hide-balance')?.addEventListener('click', () => {
    state.balanceHidden = !state.balanceHidden;
    const btn = $('#btn-hide-balance');
    const icon = $('#eye-icon');
    btn.setAttribute('aria-pressed', state.balanceHidden);
    btn.setAttribute('aria-label', state.balanceHidden ? 'Hiện số tiền nhạy cảm' : 'Ẩn số tiền nhạy cảm');
    if (icon) icon.textContent = state.balanceHidden ? 'visibility_off' : 'visibility';
    renderHome();
    renderTransactions();
  });

  // Transaction row / amount → existing add sheet in edit mode
  const screens = $('#screens');
  screens?.addEventListener('click', e => {
    if (e.target.closest('.tx-delete')) return;
    const item = e.target.closest('.tx-item');
    if (!item) return;
    handleTxActivate(item);
  });
  screens?.addEventListener('keydown', e => {
    if (e.key !== 'Enter' && e.key !== ' ') return;
    const item = e.target.closest('.tx-item');
    if (!item) return;
    e.preventDefault();
    handleTxActivate(item);
  });

  // Quick amount chips
  $$('.quick-amt').forEach(btn => {
    btn.addEventListener('click', () => {
      const amt = btn.dataset.amt;
      $('#input-amount').value = parseInt(amt, 10).toLocaleString('vi-VN');
      $('#input-amount').focus();
    });
  });

  // Transactions filter
  $$('#tx-chips .chip').forEach(chip => {
    chip.addEventListener('click', () => {
      state.txFilter = chip.dataset.filter;
      $$('#tx-chips .chip').forEach(c => {
        c.classList.toggle('active', c === chip);
        c.setAttribute('aria-selected', c === chip ? 'true' : 'false');
      });
      renderTransactions();
    });
  });

  $('#tx-search').addEventListener('input', e => {
    state.txSearch = e.target.value;
    renderTransactions();
  });

  $('#btn-tx-filter').addEventListener('click', () => showToast('Bộ lọc nâng cao — sắp ra mắt'));

  // Period tabs
  $$('#period-tabs .period-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      state.period = tab.dataset.period;
      $$('#period-tabs .period-tab').forEach(t => {
        t.classList.toggle('active', t === tab);
        t.setAttribute('aria-selected', t === tab ? 'true' : 'false');
      });
      renderCharts();
    });
  });

  // Settings
  $('#toggle-dark').addEventListener('click', e => {
    e.stopPropagation();
    setDarkMode(!state.darkMode);
  });
  $('#toggle-notif').addEventListener('click', e => {
    e.stopPropagation();
    const on = !$('#toggle-notif').classList.contains('on');
    $('#toggle-notif').classList.toggle('on', on);
    $('#toggle-notif').setAttribute('aria-checked', on);
    showToast(on ? 'Đã bật thông báo' : 'Đã tắt thông báo');
  });

  // Keyboard support for toggles
  ['#toggle-dark', '#toggle-notif'].forEach(sel => {
    $(sel)?.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); $(sel).click(); }
    });
  });

  $$('.settings-item').forEach(item => {
    item.addEventListener('click', () => {
      const key = item.dataset.setting;
      if (key === 'darkmode' || key === 'notification') return;
      const messages = {
        currency: { title: 'Tiền tệ', msg: 'Hiện đang dùng VND (₫). Hỗ trợ thêm USD, EUR sắp tới.', icon: 'payments' },
        language: { title: 'Ngôn ngữ', msg: 'Ứng dụng đang hiển thị bằng Tiếng Việt.', icon: 'language' },
        export: { title: 'Xuất dữ liệu', msg: 'Dữ liệu sẽ được xuất ra file CSV / Excel.', icon: 'download' },
        backup: { title: 'Sao lưu', msg: 'Sao lưu đám mây giúp bạn không mất dữ liệu khi đổi máy.', icon: 'cloud_upload' },
        about: { title: 'Về Tiền Đây', msg: 'Phiên bản prototype 1.0.0 — Quản lý tài chính cá nhân hiện đại, tối giản, thân thiện.', icon: 'info' },
        biometric: { title: 'Sinh trắc học', msg: 'Bảo vệ số dư và giao dịch bằng vân tay / Face ID. Bật trong bản Flutter đầy đủ.', icon: 'fingerprint' },
      };
      const m = messages[key];
      if (m) showDialog(m);
    });
  });

  $('#profile-card')?.addEventListener('click', () => {
    showDialog({ title: 'Hồ sơ', msg: 'Minh Anh · minhanh@email.com\nChỉnh sửa ảnh đại diện và thông tin cá nhân.', icon: 'person' });
  });

  $('#btn-logout')?.addEventListener('click', () => {
    showDialog({ title: 'Đăng xuất?', msg: 'Bạn có thể tiếp tục dùng ở chế độ khách. Dữ liệu cục bộ vẫn được giữ.', icon: 'logout' });
  });

  $('#dialog-ok').addEventListener('click', closeDialog);
  $('#dialog-overlay').addEventListener('click', e => {
    if (e.target === $('#dialog-overlay')) closeDialog();
  });

  $('#btn-avatar').addEventListener('click', () => navigateMain('settings'));
  $('#btn-add-budget').addEventListener('click', () => showToast('Thêm ngân sách — sắp ra mắt'));
  $('#btn-create-goal')?.addEventListener('click', () => {
    showDialog({
      title: 'Tạo mục tiêu',
      msg: 'Đặt mục tiêu tiết kiệm và theo dõi tiến độ mỗi ngày. Thêm quỹ mới trong vài giây.',
      icon: 'savings',
    });
  });

  // Escape to close sheet/dialog
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
      closeSheet();
      closeDialog();
    }
  });
}

function enterApp(method) {
  showToast(`Đăng nhập với ${method}`);
  setTimeout(() => {
    showScreen('home');
    animateProgressBars();
    const fab = $('#fab');
    fab.classList.add('pulse');
    setTimeout(() => fab.classList.remove('pulse'), 3200);
  }, 400);
}

/* ============================================================
   BOOT
   ============================================================ */
function boot() {
  try {
    if (localStorage.getItem('tienday-dark') === '1') setDarkMode(true);
  } catch (_) {}

  updateClock();
  setInterval(updateClock, 30000);

  document.querySelector('.phone-status')?.classList.add('on-dark');

  renderHome();
  renderTransactions();
  renderBudget();
  renderCharts();
  renderCategoryGrid();
  bindEvents();
  initRipples();

  setTimeout(() => {
    showScreen('onboarding');
  }, 2200);
}

document.addEventListener('DOMContentLoaded', boot);
