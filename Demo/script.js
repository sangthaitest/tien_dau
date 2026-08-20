/**
 * Tiền Đây — Version C (V3)
 * Isolated from V2. Only Add Transaction flow is redesigned.
 */

/* ============================================================
   CATEGORIES & DEFAULTS
   ============================================================ */
const INCOME_CATS_META = {
  salary:       { name: 'Lương',          icon: 'payments', color: '#00A3A1', bg: '#E0F7F5', img: 'assets/illustrations/salary.svg', type: 'income' },
  bonus:        { name: 'Thưởng',         icon: 'redeem',   color: '#26A69A', bg: '#E0F7F5', img: null, type: 'income' },
  other_income: { name: 'Thu nhập khác',  icon: 'south',    color: '#00897B', bg: '#E0F7F5', img: null, type: 'income' },
};

function defaultChiCho() {
  return [
    { id: 'breakfast', name: 'Ăn sáng',   icon: 'free_breakfast',  color: '#FF8A5B', bg: '#FFF0EA' },
    { id: 'lunch',     name: 'Ăn trưa',   icon: 'lunch_dining',    color: '#FFB020', bg: '#FFF6E5' },
    { id: 'dinner',    name: 'Ăn tối',    icon: 'dinner_dining',   color: '#FF6B9D', bg: '#FFE8F0' },
    { id: 'cafe',      name: 'Cafe',      icon: 'local_cafe',      color: '#A0785A', bg: '#F5EDE6' },
    { id: 'market',    name: 'Đi chợ',    icon: 'grocery',         color: '#00B67A', bg: '#E6F8EF' },
    { id: 'transport', name: 'Di chuyển', icon: 'directions_car',  color: '#4DA3FF', bg: '#E8F3FF' },
    { id: 'shopping',  name: 'Mua sắm',   icon: 'shopping_bag',    color: '#B57BFF', bg: '#F3EBFF' },
    { id: 'other',     name: 'Khác',      icon: 'more_horiz',      color: '#8B93A0', bg: '#EEF1F5' },
  ];
}

function defaultChiChoDetails() {
  return {
    breakfast: ['Mì Quảng', 'Bánh mì', 'Phở', 'Xôi', 'Bún', 'Khác'],
    lunch:     ['Cơm', 'Bún', 'Phở', 'Cơm tấm', 'Khác'],
    dinner:    ['Cơm', 'Lẩu', 'Nướng', 'Ăn vặt', 'Khác'],
    cafe:      ['Highlands', 'Ô Bầu', 'The Coffee House', 'Khác'],
    market:    ['Rau', 'Thịt', 'Cá', 'Trái cây', 'Đồ khô', 'Khác'],
    transport: ['Grab', 'Xăng', 'Xe buýt', 'Taxi', 'Khác'],
    shopping:  ['Quần áo', 'Đồ gia dụng', 'Mỹ phẩm', 'Khác'],
    other:     ['Khác'],
  };
}

const CHI_CHO_ICON_OPTIONS = [
  { icon: 'free_breakfast',  color: '#FF8A5B', bg: '#FFF0EA' },
  { icon: 'lunch_dining',    color: '#FFB020', bg: '#FFF6E5' },
  { icon: 'dinner_dining',   color: '#FF6B9D', bg: '#FFE8F0' },
  { icon: 'local_cafe',      color: '#A0785A', bg: '#F5EDE6' },
  { icon: 'grocery',         color: '#00B67A', bg: '#E6F8EF' },
  { icon: 'directions_car',  color: '#4DA3FF', bg: '#E8F3FF' },
  { icon: 'shopping_bag',    color: '#B57BFF', bg: '#F3EBFF' },
  { icon: 'more_horiz',      color: '#8B93A0', bg: '#EEF1F5' },
  { icon: 'home',            color: '#00B67A', bg: '#E6F8EF' },
  { icon: 'bolt',            color: '#FFB020', bg: '#FFF6E5' },
  { icon: 'movie',           color: '#FF6B9D', bg: '#FFE8F0' },
  { icon: 'favorite',        color: '#FF6B6B', bg: '#FFECEC' },
  { icon: 'school',          color: '#6B7CFF', bg: '#EEF0FF' },
  { icon: 'fitness_center',  color: '#26A69A', bg: '#E0F7F5' },
  { icon: 'pets',            color: '#A0785A', bg: '#F5EDE6' },
  { icon: 'sports_esports',  color: '#B57BFF', bg: '#F3EBFF' },
];

function defaultPayMethods() {
  return [
    { id: 'momo', name: 'MoMo', type: 'Ví điện tử' },
    { id: 'vcb',  name: 'Vietcombank', type: 'Tài khoản ngân hàng' },
    { id: 'cash', name: 'Tiền mặt', type: 'Tiền mặt' },
    { id: 'tcb',  name: 'Techcombank', type: 'Tài khoản ngân hàng' },
  ];
}

function payLabel(p) {
  if (!p) return 'Chọn';
  return p.type ? `${p.name} — ${p.type}` : p.name;
}

function migratePayType(type) {
  if (type === 'Ví') return 'Ví điện tử';
  if (type === 'Ngân hàng') return 'Tài khoản ngân hàng';
  return type || 'Tài khoản ngân hàng';
}

function getCat(key) {
  const chi = (store.chiCho || []).find(c => c.id === key);
  if (chi) return chi;
  return INCOME_CATS_META[key] || { name: 'Khác', icon: 'more_horiz', color: '#8B93A0', bg: '#EEF1F5' };
}

const STORAGE_KEYS = {
  tx: 'tienday-v3-transactions',
  budget: 'tienday-v3-budget',
  goals: 'tienday-v3-goals',
  prefs: 'tienday-v3-prefs',
  salary: 'tienday-v3-salary',
  onboard: 'tienday-v3-onboarding-done',
  chicho: 'tienday-v3-chicho',
  pay: 'tienday-v3-pay',
  details: 'tienday-v3-details',
};

/* ============================================================
   UTILITIES
   ============================================================ */
function $(sel, root = document) { return root.querySelector(sel); }
function $$(sel, root = document) { return [...root.querySelectorAll(sel)]; }

function pad2(n) { return String(n).padStart(2, '0'); }

function todayISO() {
  const d = new Date();
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
}

function nowTime() {
  const d = new Date();
  return `${pad2(d.getHours())}:${pad2(d.getMinutes())}`;
}

function monthKey(dateStr = todayISO()) {
  return dateStr.slice(0, 7);
}

function viewMonth() {
  return state.viewMonth || monthKey();
}

function prevMonthKey(mk = monthKey()) {
  const [y, m] = mk.split('-').map(Number);
  const d = new Date(y, m - 2, 1);
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}`;
}

function monthLabel(mk = monthKey()) {
  const [y, m] = mk.split('-').map(Number);
  return `Tháng ${m} · ${y}`;
}

function daysInMonth(mk) {
  const [y, m] = mk.split('-').map(Number);
  return new Date(y, m, 0).getDate();
}

function inMonth(dateStr, mk) {
  return dateStr && dateStr.startsWith(mk);
}

function formatVND(n, short = false) {
  const abs = Math.abs(n);
  if (short) {
    if (abs >= 1_000_000) return (n / 1_000_000).toFixed(1).replace(/\.0$/, '') + 'tr';
    if (abs >= 1_000) return Math.round(n / 1_000) + 'k';
  }
  return abs.toLocaleString('vi-VN') + ' ₫';
}

function moveIndex(list, from, to) {
  if (from === to || from < 0 || to < 0 || from >= list.length || to >= list.length) return list;
  const next = list.slice();
  const [item] = next.splice(from, 1);
  next.splice(to, 0, item);
  return next;
}

function moveButtonsHtml(index, length) {
  const upOff = index === 0 ? 'true' : 'false';
  const downOff = index === length - 1 ? 'true' : 'false';
  return `
    <span class="manage-move">
      <span class="btn-icon" role="button" tabindex="0" data-move="-1" data-index="${index}" aria-disabled="${upOff}" aria-label="Lên">
        <span class="ms">expand_less</span>
      </span>
      <span class="btn-icon" role="button" tabindex="0" data-move="1" data-index="${index}" aria-disabled="${downOff}" aria-label="Xuống">
        <span class="ms">expand_more</span>
      </span>
    </span>`;
}

function bindMoveButtons(root, onMove) {
  $$('[data-move]', root).forEach(btn => {
    btn.addEventListener('click', e => {
      e.stopPropagation();
      if (btn.getAttribute('aria-disabled') === 'true') return;
      const from = Number(btn.dataset.index);
      onMove(from, from + Number(btn.dataset.move));
    });
  });
}

function parseAmountInput(str) {
  const raw = String(str || '').replace(/\D/g, '');
  return raw ? parseInt(raw, 10) : 0;
}

function formatAmountInput(el) {
  const n = parseAmountInput(el.value);
  el.value = n ? n.toLocaleString('vi-VN') : '';
  syncQuickAmountChips();
}

function syncQuickAmountChips() {
  const n = parseAmountInput($('#input-amount')?.value);
  $$('#quick-amounts .quick-amt').forEach(btn => {
    btn.classList.toggle('active', n > 0 && Number(btn.dataset.amt) === n);
  });
}

function formatDateLabel(dateStr) {
  const d = new Date(dateStr + 'T00:00:00');
  const t = new Date(todayISO() + 'T00:00:00');
  const y = new Date(t);
  y.setDate(y.getDate() - 1);
  if (d.getTime() === t.getTime()) return 'Hôm nay';
  if (d.getTime() === y.getTime()) return 'Hôm qua';
  const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  return `${days[d.getDay()]}, ${d.getDate()}/${d.getMonth() + 1}`;
}

function groupByDate(txs) {
  const map = {};
  txs.forEach(t => {
    if (!map[t.date]) map[t.date] = [];
    map[t.date].push(t);
  });
  return Object.entries(map).sort((a, b) => b[0].localeCompare(a[0]));
}

function showToast(msg, ms = 2200) {
  const el = $('#toast');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(el._timer);
  el._timer = setTimeout(() => el.classList.remove('show'), ms);
}

let dialogCallback = null;

function showDialog({ title, msg, icon = 'check_circle', confirm = false, onConfirm = null }) {
  $('#dialog-icon').textContent = icon;
  $('#dialog-title').textContent = title;
  $('#dialog-msg').textContent = msg;
  dialogCallback = onConfirm;
  const cancel = $('#dialog-cancel');
  if (confirm) {
    cancel.classList.remove('hidden');
    $('#dialog-ok').textContent = 'Xác nhận';
  } else {
    cancel.classList.add('hidden');
    $('#dialog-ok').textContent = 'OK';
    dialogCallback = null;
  }
  $('#dialog-overlay').classList.add('open');
}

function closeDialog() {
  $('#dialog-overlay').classList.remove('open');
  dialogCallback = null;
}

function maskMoney(text, short = false) {
  if (!store.prefs.balanceHidden) return text;
  return short ? '••••' : '••••••••';
}

function toggleShowAmounts() {
  store.prefs.balanceHidden = !store.prefs.balanceHidden;
  persistPrefs();
  applyPrivacyUI();
  renderHome();
  renderBudget();
}

/* ============================================================
   SEED DATA
   ============================================================ */
function seedTransactions() {
  const mk = monthKey();
  const [y, m] = mk.split('-').map(Number);
  const d = (day, monthKeyStr = mk) => {
    const [yy, mm] = monthKeyStr.split('-').map(Number);
    return `${yy}-${pad2(mm)}-${pad2(Math.min(day, daysInMonth(monthKeyStr)))}`;
  };
  const prev = prevMonthKey(mk);
  return [
    { id: 2, title: 'Highlands', category: 'cafe', type: 'expense', amount: 45000, date: d(Math.min(7, daysInMonth(mk))), time: '08:15', note: '', account: 'MoMo', detail: 'Highlands' },
    { id: 3, title: 'Grab Bike', category: 'transport', type: 'expense', amount: 42000, date: d(Math.min(7, daysInMonth(mk))), time: '08:40', note: '', account: 'MoMo', detail: 'Grab' },
    { id: 4, title: 'Rau', category: 'market', type: 'expense', amount: 85000, date: d(Math.min(6, daysInMonth(mk))), time: '12:30', note: '', account: 'Vietcombank', detail: 'Rau' },
    { id: 5, title: 'Shopee', category: 'shopping', type: 'expense', amount: 289000, date: d(Math.min(5, daysInMonth(mk))), time: '21:00', note: 'Flash sale', account: 'Techcombank', detail: '' },
    { id: 6, title: 'Bánh mì', category: 'breakfast', type: 'expense', amount: 25000, date: d(4), time: '07:20', note: '', account: 'Tiền mặt', detail: 'Bánh mì' },
    { id: 8, title: 'Ô Bầu', category: 'cafe', type: 'expense', amount: 55000, date: d(12, prev), time: '09:10', note: '', account: 'MoMo', detail: 'Ô Bầu' },
    { id: 9, title: 'Đi chợ', category: 'market', type: 'expense', amount: 220000, date: d(18, prev), time: '17:00', note: '', account: 'Vietcombank', detail: 'Rau' },
    { id: 10, title: 'Grab', category: 'transport', type: 'expense', amount: 38000, date: d(20, prev), time: '08:30', note: '', account: 'MoMo', detail: 'Grab' },
  ];
}

function seedBudget() {
  return { month: monthKey(), totalLimit: 10000000 };
}

function seedGoals() {
  return [
    { id: 1, name: 'Quỹ khẩn cấp', targetAmount: 50000000, currentAmount: 31000000 },
  ];
}

const DEMO_UPCOMING_CASH = 20000000;
const DEMO_UPCOMING_SPENT = 4626157;

function seedUpcomingPayments() {
  return [
    { id: 'card', title: 'Thẻ tín dụng', amount: 5000000, dueLabel: 'Hạn 25/08', icon: 'credit_card' },
    { id: 'transfer', title: 'Chuyển cho Minh', amount: 2000000, dueLabel: 'Hạn 28/08', icon: 'person' },
    { id: 'utility', title: 'Điện nước', amount: 500000, dueLabel: 'Hạn 30/08', icon: 'bolt' },
  ];
}

function defaultPrefs() {
  return {
    darkMode: false,
    balanceHidden: false,
    notificationsEnabled: true,
    currency: 'VND',
    viewMonth: null,
    financePin: '1234',
  };
}

function defaultSalary() {
  return { monthlyAmount: 18500000 };
}

/* ============================================================
   STORE / PERSISTENCE
   ============================================================ */
const store = {
  transactions: [],
  budget: null,
  goals: [],
  salary: null,
  prefs: defaultPrefs(),
  chiCho: defaultChiCho(),
  payMethods: defaultPayMethods(),
  chiChoDetails: defaultChiChoDetails(),
};

function loadJSON(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw);
  } catch (_) {
    return fallback;
  }
}

function saveJSON(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch (_) {}
}

function hasStorageKey(key) {
  try { return localStorage.getItem(key) !== null; } catch (_) { return false; }
}

function loadStore() {
  const firstRun = !hasStorageKey(STORAGE_KEYS.tx);

  if (firstRun) {
    store.transactions = seedTransactions();
    store.budget = seedBudget();
    store.goals = seedGoals();
    store.salary = defaultSalary();
    store.prefs = defaultPrefs();
    store.chiCho = defaultChiCho();
    store.payMethods = defaultPayMethods();
    store.chiChoDetails = defaultChiChoDetails();
    persistAll();
    return;
  }

  const txs = loadJSON(STORAGE_KEYS.tx, []);
  store.transactions = Array.isArray(txs) ? txs : [];

  let budget = loadJSON(STORAGE_KEYS.budget, null);
  if (!budget || typeof budget.totalLimit !== 'number') budget = seedBudget();
  if (budget.month !== monthKey()) {
    budget = { month: monthKey(), totalLimit: budget.totalLimit || 10000000 };
  }
  store.budget = budget;

  const goals = loadJSON(STORAGE_KEYS.goals, []);
  store.goals = Array.isArray(goals) ? goals : [];

  const prefs = loadJSON(STORAGE_KEYS.prefs, null);
  store.prefs = { ...defaultPrefs(), ...(prefs || {}) };

  store.salary = loadJSON(STORAGE_KEYS.salary, defaultSalary());
  if (typeof store.salary.monthlyAmount !== 'number') store.salary = defaultSalary();

  const chi = loadJSON(STORAGE_KEYS.chicho, null);
  store.chiCho = Array.isArray(chi) && chi.length ? chi : defaultChiCho();

  const pay = loadJSON(STORAGE_KEYS.pay, null);
  store.payMethods = Array.isArray(pay) && pay.length ? pay : defaultPayMethods();
  store.payMethods.forEach(p => { p.type = migratePayType(p.type); });

  const details = loadJSON(STORAGE_KEYS.details, null);
  store.chiChoDetails = details && typeof details === 'object' ? details : defaultChiChoDetails();
  sanitizeChiCho();
  const expenseOnly = store.transactions.filter(t => t.type !== 'income');
  if (expenseOnly.length !== store.transactions.length) {
    store.transactions = expenseOnly;
    saveJSON(STORAGE_KEYS.tx, store.transactions);
  }
}

function persistAll() {
  saveJSON(STORAGE_KEYS.tx, store.transactions);
  saveJSON(STORAGE_KEYS.budget, store.budget);
  saveJSON(STORAGE_KEYS.goals, store.goals);
  saveJSON(STORAGE_KEYS.salary, store.salary);
  saveJSON(STORAGE_KEYS.prefs, store.prefs);
  saveJSON(STORAGE_KEYS.chicho, store.chiCho);
  saveJSON(STORAGE_KEYS.pay, store.payMethods);
  saveJSON(STORAGE_KEYS.details, store.chiChoDetails);
}

function persistPrefs() {
  saveJSON(STORAGE_KEYS.prefs, store.prefs);
}

function normalizeChiChoName(name) {
  return String(name || '')
    .trim()
    .toLowerCase()
    .replace(/о/g, 'o')
    .replace(/а/g, 'a')
    .replace(/\s+/g, '');
}

function isJunkChiCho(c) {
  const n = normalizeChiChoName(c && c.name);
  if (!n) return true;
  return /^cao+o+$/.test(n);
}

function sanitizeChiCho() {
  const list = Array.isArray(store.chiCho) ? store.chiCho : [];
  const next = list.filter(c => !isJunkChiCho(c));
  if (next.length !== list.length) {
    store.chiCho = next.length ? next : defaultChiCho();
    saveJSON(STORAGE_KEYS.chicho, store.chiCho);
    if (typeof state !== 'undefined' && !store.chiCho.find(c => c.id === state.selectedCategory) && store.chiCho[0]) {
      state.selectedCategory = store.chiCho[0].id;
    }
  }
}

function isOnboardingDone() {
  try { return localStorage.getItem(STORAGE_KEYS.onboard) === '1'; } catch (_) { return false; }
}

function setOnboardingDone() {
  try { localStorage.setItem(STORAGE_KEYS.onboard, '1'); } catch (_) {}
}

/* ============================================================
   CALCULATIONS
   ============================================================ */
function calcBalance() {
  return store.transactions.reduce((s, t) => s + (t.type === 'income' ? t.amount : -t.amount), 0);
}

function txsInMonth(mk = monthKey()) {
  return store.transactions.filter(t => inMonth(t.date, mk));
}

function sumByType(list, type) {
  return list.filter(t => t.type === type).reduce((s, t) => s + t.amount, 0);
}

function monthExpense(mk = monthKey()) {
  return sumByType(txsInMonth(mk), 'expense');
}

function monthIncome(mk = monthKey()) {
  return sumByType(txsInMonth(mk), 'income');
}

function budgetUsed(mk = monthKey()) {
  return monthExpense(mk);
}

function budgetRemaining(mk = monthKey()) {
  return (store.budget?.totalLimit || 0) - budgetUsed(mk);
}

function categorySpending(mk = monthKey()) {
  const map = {};
  txsInMonth(mk).filter(t => t.type === 'expense').forEach(t => {
    map[t.category] = (map[t.category] || 0) + t.amount;
  });
  return Object.entries(map)
    .map(([key, amount]) => ({ key, amount }))
    .sort((a, b) => b.amount - a.amount);
}

function sortedTransactions() {
  return [...store.transactions].sort((a, b) => {
    const c = b.date.localeCompare(a.date);
    if (c !== 0) return c;
    return (b.time || '').localeCompare(a.time || '');
  });
}

/* ============================================================
   UI STATE
   ============================================================ */
const state = {
  currentScreen: 'splash',
  onboardingStep: 0,
  onboardingMax: 1,
  txCatFilter: 'all',
  txDateFilter: 'thisMonth',
  txDateFrom: '',
  txDateTo: '',
  sheetMode: 'add', // add | edit
  editingTxId: null,
  detailTxId: null,
  goalMode: 'create', // create | edit | addMoney
  editingGoalId: null,
  selectedCategory: 'cafe',
  selectedDetail: '',
  selectedPayId: 'momo',
  payEditId: null,
  chiChoEditId: null,
  selectedChiChoIcon: 'more_horiz',
  detailEditIndex: null,
  viewMonth: null,
  txType: 'expense',
  budgetReturnTo: 'settings',
  financeUnlocked: false,
  financePendingAction: null,
  financePendingFrom: 'settings',
  upcomingItems: seedUpcomingPayments(),
  upcomingPaidIds: [],
  upcomingNextId: 1,
  upcomingDetailId: null,
  upcomingEditId: null,
  mainScreens: ['home', 'transactions', 'budget', 'statistics', 'settings'],
};

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

  const lightStatus = name === 'splash' || name === 'home';
  document.querySelector('.phone-status')?.classList.toggle('on-dark', lightStatus);

  $$('.nav-item').forEach(item => {
    const nav = item.dataset.nav;
    item.classList.toggle('active', nav === name || (name === 'budget' && nav === 'settings'));
  });

  if (isMain) refreshScreen(name);
}

function getFinancePin() {
  return String(store.prefs.financePin || '1234');
}

function runFinanceAction(action, from = 'settings') {
  if (action === 'budget') {
    state.budgetReturnTo = from;
    showScreen('budget');
  } else if (action === 'change-pin') {
    openFinancePinChangeSheet();
  }
}

function requireFinanceAccess(action, from = 'settings') {
  if (state.financeUnlocked) {
    runFinanceAction(action, from);
    return;
  }
  state.financePendingAction = action;
  state.financePendingFrom = from;
  $('#input-finance-pin').value = '';
  const hint = $('#finance-pin-hint');
  if (hint) {
    hint.textContent = action === 'change-pin'
      ? 'Nhập mật khẩu hiện tại để đổi.'
      : 'Nhập mật khẩu 4 số để xem Tài chính.';
  }
  openOverlay();
  $('#finance-pin-sheet').classList.add('open');
  setTimeout(() => $('#input-finance-pin')?.focus(), 200);
}

function verifyFinancePin() {
  const pin = ($('#input-finance-pin')?.value || '').trim();
  if (pin !== getFinancePin()) {
    showToast('Mật khẩu không đúng');
    return;
  }
  state.financeUnlocked = true;
  closeAllSheets();
  const action = state.financePendingAction;
  const from = state.financePendingFrom || 'settings';
  state.financePendingAction = null;
  if (action) runFinanceAction(action, from);
}

function navigateMain(name) {
  if (!state.mainScreens.includes(name)) return;
  showScreen(name);
}

function openBudgetScreen(from = 'settings') {
  requireFinanceAccess('budget', from);
}

function refreshAll() {
  renderHome();
  renderTransactions();
  renderBudget();
  renderStatistics();
  applyPrivacyUI();
}

function refreshScreen(name) {
  if (name === 'home') renderHome();
  if (name === 'transactions') renderTransactions();
  if (name === 'budget') renderBudget();
  if (name === 'statistics') renderStatistics();
  if (name === 'settings') renderSettings();
}

/* ============================================================
   RENDER HELPERS
   ============================================================ */
function renderTxItem(tx, { swipeable = false, compact = false } = {}) {
  const cat = getCat(tx.category);
  const sign = tx.type === 'income' ? '+' : '−';
  const iconHtml = cat.img
    ? `<img src="${cat.img}" alt="" />`
    : `<span class="ms" style="color:${cat.color}">${cat.icon}</span>`;
  const amountHtml = compact
    ? maskMoney(`${sign}${formatVND(tx.amount)}`, true)
    : `${sign}${formatVND(tx.amount)}`;

  const inner = `
    <div class="tx-item ${swipeable ? 'swipeable' : ''}" data-id="${tx.id}" role="button" tabindex="0">
      <div class="tx-icon" style="background:${cat.bg}">${iconHtml}</div>
      <div class="tx-info">
        <div class="title">${tx.title}</div>
        <div class="meta">${cat.name}${tx.account ? ' · ' + tx.account : ''}</div>
      </div>
      <div class="tx-amount ${tx.type}">${amountHtml}</div>
    </div>
  `;

  if (!swipeable) return inner;
  return `
    <div class="tx-swipe-wrap" data-id="${tx.id}">
      <div class="tx-swipe-actions">
        <button type="button" class="tx-delete" data-delete="${tx.id}" aria-label="Xóa">
          <span class="ms">delete</span> Xóa
        </button>
      </div>
      ${inner}
    </div>
  `;
}

function goalProgress(g) {
  if (!g.targetAmount || g.targetAmount <= 0) return 0;
  return Math.min(100, Math.round((g.currentAmount / g.targetAmount) * 100));
}

function renderGoalCard(g, { home = false } = {}) {
  const pct = goalProgress(g);
  const cur = maskMoney(formatVND(g.currentAmount));
  const left = maskMoney(formatVND(Math.max(0, g.targetAmount - g.currentAmount)));
  const target = maskMoney(formatVND(g.targetAmount));
  const meta = `Mục tiêu ${target} · ${pct}%`;
  const actions = home ? '' : `
    <div class="goal-actions">
      <button type="button" class="btn btn-sm btn-secondary" data-goal-add="${g.id}">Thêm tiền</button>
      <button type="button" class="btn-icon" data-goal-edit="${g.id}" aria-label="Sửa"><span class="ms">edit</span></button>
      <button type="button" class="btn-icon" data-goal-del="${g.id}" aria-label="Xóa"><span class="ms">delete</span></button>
    </div>`;
  return `
    <div class="goal-card" data-goal-id="${g.id}">
      <div class="goal-icon"><img src="assets/illustrations/piggy-bank.svg" alt="" /></div>
      <div class="goal-body">
        <div class="title">${g.name}</div>
        <div class="meta">${meta}</div>
        <div class="progress-bar"><div class="progress-fill" data-pct="${pct}" style="width:${pct}%"></div></div>
        <div class="goal-amounts">
          <span class="amount income" style="font-size:12px">${cur}</span>
          <span class="tiny">còn ${left}</span>
        </div>
        ${actions}
      </div>
    </div>`;
}

/* ============================================================
   HOME
   ============================================================ */
function stripHomeExtraCards() {
  const home = $('#screen-home');
  if (!home) return;
  home.querySelector('.balance-label')?.remove();
  home.querySelector('#balance-row')?.remove();
  home.querySelector('#current-balance')?.closest('.balance-row')?.remove();
  home.querySelector('.home-goal-section')?.remove();
  const goal = home.querySelector('#home-goal');
  if (goal) {
    const wrap = goal.closest('.home-goal-section') || (goal.parentElement?.classList.contains('section') ? goal.parentElement : null);
    if (wrap && wrap.id !== 'screen-home') wrap.remove();
    else goal.remove();
  }
}

function renderHome() {
  stripHomeExtraCards();
  const hour = new Date().getHours();
  const greet = hour < 12 ? 'Chào buổi sáng' : hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối';
  $('#home-greeting-text').textContent = greet;
  $('#home-month-label').textContent = monthLabel(viewMonth());

  const spend = monthExpense(viewMonth());
  const spendEl = $('#home-month-spend');
  if (spendEl) spendEl.textContent = maskMoney(formatVND(spend));

  const recent = sortedTransactions().filter(t => inMonth(t.date, viewMonth())).slice(0, 5);
  $('#home-tx-list').innerHTML = recent.length
    ? recent.map(t => renderTxItem(t, { compact: true })).join('')
    : `<p class="caption">Chưa có giao dịch. Nhấn + để thêm.</p>`;

  $$('#home-tx-list .tx-item').forEach(el => {
    el.addEventListener('click', () => openDetail(Number(el.dataset.id)));
  });

  applyPrivacyUI();
}

function applyEyeIcon() {
  const icon = $('#eye-icon');
  const btn = $('#btn-hide-balance');
  const hidden = store.prefs.balanceHidden;
  if (icon) icon.textContent = hidden ? 'visibility_off' : 'visibility';
  if (btn) {
    btn.setAttribute('aria-pressed', hidden);
    btn.setAttribute('aria-label', hidden ? 'Hiện số dư' : 'Ẩn số dư');
  }
  $('#balance-row')?.classList.toggle('balance-hidden', hidden);
}

function applyPrivacyUI() {
  applyEyeIcon();
  const pv = $('#privacy-value');
  if (pv) pv.textContent = store.prefs.balanceHidden ? 'Ẩn số' : 'Hiện số';
}

/* ============================================================
   TRANSACTIONS
   ============================================================ */
function getFilteredTransactions() {
  let list = [...store.transactions].filter(t => t.type !== 'income');
  const mk = viewMonth();
  const pmk = prevMonthKey(mk);

  if (state.txDateFilter === 'thisMonth') {
    list = list.filter(t => inMonth(t.date, mk));
  } else if (state.txDateFilter === 'lastMonth') {
    list = list.filter(t => inMonth(t.date, pmk));
  } else if (state.txDateFilter === 'custom') {
    const from = state.txDateFrom || '0000-01-01';
    const to = state.txDateTo || '9999-12-31';
    list = list.filter(t => t.date >= from && t.date <= to);
  }

  if (state.txCatFilter !== 'all') {
    list = list.filter(t => t.category === state.txCatFilter);
  }

  return list.sort((a, b) => {
    const c = b.date.localeCompare(a.date);
    return c !== 0 ? c : (b.time || '').localeCompare(a.time || '');
  });
}

function renderCategoryFilterChips() {
  const wrap = $('#tx-cat-chips');
  if (!wrap) return;
  const keys = [...(store.chiCho || []).map(c => c.id)];
  const chips = [
    `<button class="chip ${state.txCatFilter === 'all' ? 'active' : ''}" data-cat-filter="all">Tất cả</button>`,
    ...keys.map(key => {
      const c = getCat(key);
      return `<button class="chip ${state.txCatFilter === key ? 'active' : ''}" data-cat-filter="${key}">${c.name}</button>`;
    }),
  ];
  wrap.innerHTML = chips.join('');
  $$('[data-cat-filter]', wrap).forEach(btn => {
    btn.addEventListener('click', () => {
      state.txCatFilter = btn.dataset.catFilter;
      renderTransactions();
    });
  });
}

function renderTransactions() {
  renderCategoryFilterChips();
  const list = getFilteredTransactions();
  const expenseSum = sumByType(list, 'expense');
  $('#tx-sum-expense').textContent = '−' + formatVND(expenseSum, true);

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
    const dayNet = txs.reduce((s, t) => s + (t.type === 'income' ? t.amount : -t.amount), 0);
    const dayLabel = (dayNet >= 0 ? '+' : '−') + formatVND(Math.abs(dayNet), true);
    return `
      <div class="date-group">
        <div class="date-label-row">
          <div class="date-label">${formatDateLabel(date)}</div>
          <div class="day-total">${dayLabel}</div>
        </div>
        <div class="tx-list">
          ${txs.map(t => renderTxItem(t, { swipeable: true })).join('')}
        </div>
      </div>`;
  }).join('');

  $$('.tx-swipe-wrap', container).forEach(wrap => {
    const item = $('.tx-item', wrap);
    item.addEventListener('click', e => {
      if (e.target.closest('.tx-delete')) return;
      openDetail(Number(wrap.dataset.id));
    });
    item.addEventListener('dblclick', e => {
      e.preventDefault();
      const wasOpen = wrap.classList.contains('open');
      $$('.tx-swipe-wrap.open').forEach(o => o.classList.remove('open'));
      if (!wasOpen) wrap.classList.add('open');
    });
  });

  $$('[data-delete]', container).forEach(btn => {
    btn.addEventListener('click', e => {
      e.stopPropagation();
      confirmDeleteTx(Number(btn.dataset.delete));
    });
  });
}

/* ============================================================
   BUDGET + GOALS
   ============================================================ */
function renderBudget() {
  const mk = viewMonth();
  const limit = store.budget.totalLimit || 0;
  const used = budgetUsed(mk);
  const rem = limit - used;
  const pct = limit > 0 ? Math.min(100, Math.round((used / limit) * 100)) : 0;

  const salaryAmt = store.salary?.monthlyAmount || 0;
  const salaryLabel = $('#salary-month-label');
  const salaryAmountEl = $('#salary-amount');
  if (salaryLabel) salaryLabel.textContent = `Lương ${monthLabel(mk)}`;
  if (salaryAmountEl) salaryAmountEl.textContent = maskMoney(formatVND(salaryAmt));

  if ($('#budget-month-label')) $('#budget-month-label').textContent = 'Ngân sách tháng';
  const limitEl = $('#budget-limit-amount');
  const usedEl = $('#budget-used-amount');
  const remainingEl = $('#budget-remaining-amount');
  if (limitEl) limitEl.textContent = maskMoney(formatVND(limit));
  if (usedEl) usedEl.textContent = maskMoney(formatVND(used));
  if (remainingEl) remainingEl.textContent = maskMoney(formatVND(rem));
  const bar = $('#budget-total-bar');
  if (bar) {
    bar.style.width = pct + '%';
    bar.classList.toggle('danger', pct >= 90);
    bar.classList.toggle('warning', pct >= 75 && pct < 90);
  }

  const goalsList = $('#goals-list');
  const goalsEmpty = $('#goals-empty');
  if (!store.goals.length) {
    goalsList.innerHTML = '';
    goalsEmpty.classList.remove('hidden');
  } else {
    goalsEmpty.classList.add('hidden');
    goalsList.innerHTML = store.goals.map(g => renderGoalCard(g)).join('');
    bindGoalActions();
  }
  renderUpcoming();
}

function bindGoalActions() {
  $$('[data-goal-add]').forEach(btn => {
    btn.addEventListener('click', () => openGoalSheet('addMoney', Number(btn.dataset.goalAdd)));
  });
  $$('[data-goal-edit]').forEach(btn => {
    btn.addEventListener('click', () => openGoalSheet('edit', Number(btn.dataset.goalEdit)));
  });
  $$('[data-goal-del]').forEach(btn => {
    btn.addEventListener('click', () => {
      const id = Number(btn.dataset.goalDel);
      showDialog({
        title: 'Xóa mục tiêu?',
        msg: 'Bạn có chắc muốn xóa mục tiêu này?',
        icon: 'delete',
        confirm: true,
        onConfirm: () => {
          store.goals = store.goals.filter(g => g.id !== id);
          persistAll();
          refreshAll();
          showToast('Đã xóa mục tiêu');
          closeDialog();
        },
      });
    });
  });
}

/* ============================================================
   STATISTICS (MONTH ONLY)
   ============================================================ */
function renderStatistics() {
  const mk = viewMonth();
  const pmk = prevMonthKey(mk);
  const expense = monthExpense(mk);
  const prevExp = monthExpense(pmk);

  $('#stats-month-label').textContent = `Chi tiêu ${monthLabel(mk)}`;
  $('#stats-expense-total').textContent = formatVND(expense);

  let deltaPct = 0;
  if (prevExp > 0) deltaPct = Math.round(((expense - prevExp) / prevExp) * 100);
  else if (expense > 0) deltaPct = 100;

  const badge = $('#trend-badge');
  const icon = $('#trend-icon');
  const text = $('#trend-text');
  badge.classList.remove('up', 'down');
  if (deltaPct < 0) {
    badge.classList.add('down');
    icon.textContent = 'trending_down';
    text.textContent = `${deltaPct}%`;
  } else if (deltaPct > 0) {
    badge.classList.add('up');
    icon.textContent = 'trending_up';
    text.textContent = `+${deltaPct}%`;
  } else {
    icon.textContent = 'trending_flat';
    text.textContent = '0%';
  }

  const cats = categorySpending(mk);
  const total = expense || 1;
  if (!cats.length) {
    $('#pie-chart').style.background = 'var(--surface-variant)';
    $('#pie-legend').innerHTML = '<p class="caption">Chưa có chi tiêu tháng này.</p>';
    $('#pie-total').textContent = '0';
    $('#top-spending').innerHTML = '<p class="caption" style="padding:12px">Chưa có dữ liệu.</p>';
    return;
  }

  let acc = 0;
  const stops = cats.map(c => {
    const cat = getCat(c.key);
    const pct = (c.amount / total) * 100;
    const start = acc;
    acc += pct;
    return `${cat.color} ${start}% ${acc}%`;
  }).join(', ');
  $('#pie-chart').style.background = `conic-gradient(${stops})`;
  $('#pie-total').textContent = formatVND(expense, true);
  $('#pie-legend').innerHTML = cats.map(c => {
    const cat = getCat(c.key);
    const pct = Math.round((c.amount / total) * 100);
    return `
      <div class="legend-item">
        <span class="legend-dot" style="background:${cat.color}"></span>
        <div class="legend-copy">
          <div class="legend-head">
            <span class="name">${cat.name}</span>
            <span class="val">${pct}%</span>
          </div>
          <span class="amt">${formatVND(c.amount, true)}</span>
        </div>
      </div>`;
  }).join('');

  $('#top-spending').innerHTML = cats.slice(0, 5).map((c, i) => {
    const cat = getCat(c.key);
    const rankClass = i === 0 ? 'gold' : i === 1 ? 'silver' : i === 2 ? 'bronze' : '';
    return `
      <div class="top-spend-item">
        <span class="rank ${rankClass}">${i + 1}</span>
        <div class="tx-icon" style="width:36px;height:36px;border-radius:10px;background:${cat.bg}">
          <span class="ms sm" style="color:${cat.color}">${cat.icon}</span>
        </div>
        <div class="tx-info">
          <div class="title">${cat.name}</div>
          <div class="meta">${Math.round((c.amount / total) * 100)}% chi tiêu</div>
        </div>
        <div class="tx-amount expense">${formatVND(c.amount)}</div>
      </div>`;
  }).join('');
}

function renderSettings() {
  $('#toggle-dark').classList.toggle('on', store.prefs.darkMode);
  $('#toggle-dark').setAttribute('aria-checked', store.prefs.darkMode);
  $('#toggle-notif').classList.toggle('on', store.prefs.notificationsEnabled);
  $('#toggle-notif').setAttribute('aria-checked', store.prefs.notificationsEnabled);
  applyPrivacyUI();
}

/* ============================================================
   SHEETS — TRANSACTION
   ============================================================ */
function closeNestedSheets() {
  ['#pay-edit-sheet', '#chicho-sheet', '#chicho-edit-sheet', '#detail-manage-sheet', '#detail-edit-sheet', '#month-sheet', '#upcoming-manage-sheet', '#upcoming-edit-sheet'].forEach(sel => {
    $(sel)?.classList.remove('open');
  });
}

function closeAllSheets() {
  closeNestedSheets();
  $('#sheet-overlay').classList.remove('open');
  $('#pay-menu')?.classList.add('hidden');
  ['#add-sheet', '#detail-sheet', '#budget-sheet', '#goal-sheet', '#month-sheet', '#finance-pin-sheet', '#finance-pin-change-sheet', '#salary-sheet', '#upcoming-all-sheet', '#upcoming-detail-sheet', '#upcoming-manage-sheet', '#upcoming-edit-sheet'].forEach(sel => {
    $(sel)?.classList.remove('open');
  });
}

function openOverlay() {
  $('#sheet-overlay').classList.add('open');
}

function currentPay() {
  return store.payMethods.find(p => p.id === state.selectedPayId) || store.payMethods[0];
}

function renderCategoryGrid() {
  sanitizeChiCho();
  const cats = (store.chiCho || []).filter(c => !isJunkChiCho(c));
  if (!cats.find(c => c.id === state.selectedCategory) && cats[0]) {
    state.selectedCategory = cats[0].id;
  }
  $('#category-grid').innerHTML = cats.map(c => `
      <button class="cat-option ${state.selectedCategory === c.id ? 'active' : ''}" data-cat="${c.id}" type="button">
        <div class="icon" style="background:${c.bg};color:${c.color}">
          <span class="ms">${c.icon}</span>
        </div>
        <span class="name">${c.name}</span>
      </button>`).join('');
  $$('.cat-option').forEach(btn => {
    btn.addEventListener('click', () => {
      state.selectedCategory = btn.dataset.cat;
      state.selectedDetail = '';
      $$('.cat-option').forEach(b => b.classList.toggle('active', b.dataset.cat === state.selectedCategory));
      renderDetailChips();
    });
  });
  renderDetailChips();
}

function renderDetailChips() {
  const wrap = $('#detail-chips');
  const group = $('#detail-group');
  if (!wrap || !group) return;
  const items = (store.chiChoDetails && store.chiChoDetails[state.selectedCategory]) || ['Khác'];
  wrap.innerHTML = items.map(name => `
    <button type="button" class="chip ${state.selectedDetail === name ? 'active' : ''}" data-detail="${name}">${name}</button>
  `).join('');
  $$('[data-detail]', wrap).forEach(btn => {
    btn.addEventListener('click', () => {
      state.selectedDetail = state.selectedDetail === btn.dataset.detail ? '' : btn.dataset.detail;
      renderDetailChips();
    });
  });
}

function renderPaySelect() {
  const pay = currentPay();
  $('#pay-select-label').textContent = payLabel(pay);
}

function renderPayMenu() {
  const menu = $('#pay-menu');
  menu.innerHTML = store.payMethods.map((p, i) => `
    <button type="button" class="pay-option" data-pay="${p.id}">
      <span class="ms check">${p.id === state.selectedPayId ? 'check' : ''}</span>
      <span class="pay-meta">
        <span>${p.name}</span>
        <span class="pay-type">${p.type || ''}</span>
      </span>
      ${moveButtonsHtml(i, store.payMethods.length)}
      <span class="pay-edit ms" data-pay-edit="${p.id}" role="button">edit</span>
    </button>
  `).join('') + `
    <button type="button" class="pay-option pay-option-add" id="btn-add-pay">＋ Thêm phương thức</button>
  `;
  $$('[data-pay]', menu).forEach(btn => {
    btn.addEventListener('click', e => {
      if (e.target.closest('[data-pay-edit]') || e.target.closest('[data-move]')) return;
      state.selectedPayId = btn.dataset.pay;
      renderPaySelect();
      menu.classList.add('hidden');
      $('#pay-select').setAttribute('aria-expanded', 'false');
    });
  });
  bindMoveButtons(menu, (from, to) => {
    store.payMethods = moveIndex(store.payMethods, from, to);
    persistAll();
    renderPaySelect();
    renderPayMenu();
  });
  $$('[data-pay-edit]', menu).forEach(btn => {
    btn.addEventListener('click', e => {
      e.stopPropagation();
      openPayEdit(btn.dataset.payEdit);
    });
  });
  $('#btn-add-pay')?.addEventListener('click', () => openPayEdit(null));
}

function openPayEdit(id) {
  state.payEditId = id;
  const isEdit = !!id;
  $('#pay-edit-title').textContent = isEdit ? 'Sửa phương thức' : 'Thêm phương thức';
  const p = store.payMethods.find(x => x.id === id);
  $('#input-pay-name').value = p ? p.name : '';
  $('#input-pay-type').value = p ? migratePayType(p.type) : 'Tài khoản ngân hàng';
  $('#btn-delete-pay').classList.toggle('hidden', !isEdit);
  $('#pay-menu').classList.add('hidden');
  $('#pay-edit-sheet').classList.add('open');
}

function savePayMethod() {
  const name = $('#input-pay-name').value.trim();
  if (!name) {
    showToast('Nhập tên phương thức');
    return;
  }
  const type = $('#input-pay-type').value;
  if (state.payEditId) {
    const p = store.payMethods.find(x => x.id === state.payEditId);
    if (p) { p.name = name; p.type = type; }
    showToast('Đã cập nhật phương thức');
  } else {
    const id = 'pay-' + Date.now();
    store.payMethods.push({ id, name, type });
    state.selectedPayId = id;
    showToast('Đã thêm phương thức');
  }
  persistAll();
  $('#pay-edit-sheet').classList.remove('open');
  renderPaySelect();
  renderPayMenu();
}

function deletePayMethod() {
  const id = state.payEditId;
  showDialog({
    title: 'Xóa phương thức?',
    msg: 'Phương thức này sẽ bị xóa khỏi danh sách.',
    icon: 'delete',
    confirm: true,
    onConfirm: () => {
      store.payMethods = store.payMethods.filter(p => p.id !== id);
      if (state.selectedPayId === id && store.payMethods[0]) {
        state.selectedPayId = store.payMethods[0].id;
      }
      persistAll();
      $('#pay-edit-sheet').classList.remove('open');
      renderPaySelect();
      renderPayMenu();
      showToast('Đã xóa phương thức');
      closeDialog();
    },
  });
}

function renderChiChoManage() {
  $('#chicho-manage-list').innerHTML = store.chiCho.map((c, i) => `
    <div class="manage-row">
      <span class="manage-row-left">
        <span class="ms" style="color:${c.color}">${c.icon}</span>
        <span>${c.name}</span>
      </span>
      <span class="manage-row-actions">
        ${moveButtonsHtml(i, store.chiCho.length)}
        <button type="button" class="btn-icon" data-chicho-edit="${c.id}" aria-label="Sửa">
          <span class="ms">edit</span>
        </button>
      </span>
    </div>
  `).join('');
  $$('[data-chicho-edit]').forEach(btn => {
    btn.addEventListener('click', () => openChiChoEdit(btn.dataset.chichoEdit));
  });
  bindMoveButtons($('#chicho-manage-list'), (from, to) => {
    store.chiCho = moveIndex(store.chiCho, from, to);
    persistAll();
    renderChiChoManage();
    renderCategoryGrid();
  });
}

function renderChiChoIconPicker(selectedIcon) {
  const wrap = $('#chicho-icon-picker');
  if (!wrap) return;
  wrap.innerHTML = CHI_CHO_ICON_OPTIONS.map(opt => `
    <button type="button" class="icon-pick ${opt.icon === selectedIcon ? 'active' : ''}" data-icon="${opt.icon}" style="background:${opt.bg};color:${opt.color}">
      <span class="ms">${opt.icon}</span>
    </button>
  `).join('');
  $$('.icon-pick', wrap).forEach(btn => {
    btn.addEventListener('click', () => {
      state.selectedChiChoIcon = btn.dataset.icon;
      renderChiChoIconPicker(state.selectedChiChoIcon);
    });
  });
}

function iconOption(icon) {
  return CHI_CHO_ICON_OPTIONS.find(o => o.icon === icon) || CHI_CHO_ICON_OPTIONS[7];
}

function openChiChoManage() {
  renderChiChoManage();
  $('#chicho-sheet').classList.add('open');
}

function openChiChoEdit(id) {
  state.chiChoEditId = id;
  const isEdit = !!id;
  $('#chicho-edit-title').textContent = isEdit ? 'Sửa khoản chi' : 'Thêm khoản mới';
  const c = store.chiCho.find(x => x.id === id);
  $('#input-chicho-name').value = c ? c.name : '';
  state.selectedChiChoIcon = c ? c.icon : 'more_horiz';
  renderChiChoIconPicker(state.selectedChiChoIcon);
  $('#btn-delete-chicho').classList.toggle('hidden', !isEdit);
  $('#chicho-edit-sheet').classList.add('open');
}

function saveChiCho() {
  const name = $('#input-chicho-name').value.trim();
  if (!name) {
    showToast('Nhập tên khoản chi');
    return;
  }
  const opt = iconOption(state.selectedChiChoIcon);
  if (state.chiChoEditId) {
    const c = store.chiCho.find(x => x.id === state.chiChoEditId);
    if (c) {
      c.name = name;
      c.icon = opt.icon;
      c.color = opt.color;
      c.bg = opt.bg;
    }
    showToast('Đã cập nhật khoản chi');
  } else {
    const id = 'chi-' + Date.now();
    store.chiCho.push({
      id,
      name,
      icon: opt.icon,
      color: opt.color,
      bg: opt.bg,
    });
    if (!store.chiChoDetails[id]) store.chiChoDetails[id] = ['Khác'];
    showToast('Đã thêm khoản chi');
  }
  persistAll();
  $('#chicho-edit-sheet').classList.remove('open');
  renderChiChoManage();
  renderCategoryGrid();
}

function deleteChiCho() {
  const id = state.chiChoEditId;
  showDialog({
    title: 'Xóa khoản chi?',
    msg: 'Khoản này sẽ bị xóa khỏi lưới Chi cho.',
    icon: 'delete',
    confirm: true,
    onConfirm: () => {
      store.chiCho = store.chiCho.filter(c => c.id !== id);
      delete store.chiChoDetails[id];
      if (state.selectedCategory === id && store.chiCho[0]) {
        state.selectedCategory = store.chiCho[0].id;
        state.selectedDetail = '';
      }
      persistAll();
      $('#chicho-edit-sheet').classList.remove('open');
      renderChiChoManage();
      renderCategoryGrid();
      showToast('Đã xóa khoản chi');
      closeDialog();
    },
  });
}

function detailsFor(catId) {
  if (!store.chiChoDetails[catId]) store.chiChoDetails[catId] = ['Khác'];
  return store.chiChoDetails[catId];
}

function renderDetailManage() {
  const cat = getCat(state.selectedCategory);
  $('#detail-manage-cat').innerHTML = `
    <span class="detail-manage-icon" style="background:${cat.bg};color:${cat.color}">
      <span class="ms">${cat.icon}</span>
    </span>
    <span class="detail-manage-name">${cat.name || ''}</span>
  `;
  const items = detailsFor(state.selectedCategory);
  $('#detail-manage-list').innerHTML = items.map((name, i) => `
    <div class="manage-row">
      <span>${name}</span>
      <span class="manage-row-actions">
        ${moveButtonsHtml(i, items.length)}
        <button type="button" class="btn-icon" data-detail-edit="${i}" aria-label="Sửa">
          <span class="ms">edit</span>
        </button>
      </span>
    </div>
  `).join('');
  $$('[data-detail-edit]').forEach(btn => {
    btn.addEventListener('click', () => openDetailEdit(Number(btn.dataset.detailEdit)));
  });
  bindMoveButtons($('#detail-manage-list'), (from, to) => {
    store.chiChoDetails[state.selectedCategory] = moveIndex(items, from, to);
    persistAll();
    renderDetailManage();
    renderDetailChips();
  });
}

function openDetailManage() {
  renderDetailManage();
  $('#detail-manage-sheet').classList.add('open');
}

function openDetailEdit(index) {
  state.detailEditIndex = index;
  const isEdit = index !== null && index !== undefined;
  $('#detail-edit-title').textContent = isEdit ? 'Sửa chi tiết' : 'Thêm chi tiết';
  const items = detailsFor(state.selectedCategory);
  $('#input-detail-name').value = isEdit ? (items[index] || '') : '';
  $('#btn-delete-detail').classList.toggle('hidden', !isEdit);
  $('#detail-edit-sheet').classList.add('open');
}

function saveDetailItem() {
  const name = $('#input-detail-name').value.trim();
  if (!name) {
    showToast('Nhập tên chi tiết');
    return;
  }
  const items = detailsFor(state.selectedCategory);
  if (state.detailEditIndex !== null && state.detailEditIndex !== undefined) {
    const old = items[state.detailEditIndex];
    items[state.detailEditIndex] = name;
    if (state.selectedDetail === old) state.selectedDetail = name;
    showToast('Đã cập nhật chi tiết');
  } else {
    items.push(name);
    showToast('Đã thêm chi tiết');
  }
  persistAll();
  $('#detail-edit-sheet').classList.remove('open');
  renderDetailManage();
  renderDetailChips();
}

function deleteDetailItem() {
  const idx = state.detailEditIndex;
  showDialog({
    title: 'Xóa chi tiết?',
    msg: 'Chi tiết này sẽ bị xóa khỏi danh mục đang chọn.',
    icon: 'delete',
    confirm: true,
    onConfirm: () => {
      const items = detailsFor(state.selectedCategory);
      const removed = items[idx];
      items.splice(idx, 1);
      if (state.selectedDetail === removed) state.selectedDetail = '';
      persistAll();
      $('#detail-edit-sheet').classList.remove('open');
      renderDetailManage();
      renderDetailChips();
      showToast('Đã xóa chi tiết');
      closeDialog();
    },
  });
}

function openMonthPicker() {
  const list = $('#month-picker-list');
  const current = viewMonth();
  const now = new Date();
  const months = [];
  for (let i = 0; i < 12; i++) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    months.push(`${d.getFullYear()}-${pad2(d.getMonth() + 1)}`);
  }
  list.innerHTML = months.map(mk => `
    <button type="button" class="month-pick ${mk === current ? 'active' : ''}" data-month="${mk}">
      <span>${monthLabel(mk)}</span>
      <span class="ms">${mk === current ? 'check' : ''}</span>
    </button>
  `).join('');
  $$('[data-month]', list).forEach(btn => {
    btn.addEventListener('click', () => {
      state.viewMonth = btn.dataset.month;
      store.prefs.viewMonth = state.viewMonth;
      persistPrefs();
      $('#month-sheet').classList.remove('open');
      $('#sheet-overlay').classList.remove('open');
      refreshAll();
    });
  });
  openOverlay();
  $('#month-sheet').classList.add('open');
}

function openAddSheet() {
  state.sheetMode = 'add';
  state.editingTxId = null;
  state.txType = 'expense';
  state.selectedCategory = (store.chiCho.find(c => c.id === 'cafe') || store.chiCho[0] || {}).id;
  state.selectedDetail = '';
  state.selectedPayId = (store.payMethods.find(p => p.id === 'momo') || store.payMethods[0] || {}).id;
  $('#sheet-title').textContent = 'Thêm giao dịch';
  $('#btn-save-tx').textContent = 'Lưu giao dịch';
  $('#input-amount').value = '';
  $('#input-note').value = '';
  $('#input-date').value = todayISO();
  $('#input-time').value = nowTime();
  $('#pay-menu').classList.add('hidden');
  syncQuickAmountChips();
  renderCategoryGrid();
  renderPaySelect();
  renderPayMenu();
  openOverlay();
  $('#add-sheet').classList.add('open');
  setTimeout(() => $('#input-amount')?.focus(), 280);
}

function openEditSheet(tx) {
  state.sheetMode = 'edit';
  state.editingTxId = tx.id;
  state.txType = tx.type === 'income' ? 'income' : 'expense';
  state.selectedCategory = tx.category;
  state.selectedDetail = tx.detail || '';
  const byName = store.payMethods.find(p => payLabel(p) === tx.account || p.name === tx.account);
  state.selectedPayId = byName ? byName.id : (store.payMethods[0] || {}).id;
  $('#sheet-title').textContent = 'Sửa giao dịch';
  $('#btn-save-tx').textContent = 'Cập nhật';
  $('#input-amount').value = tx.amount.toLocaleString('vi-VN');
  syncQuickAmountChips();
  $('#input-note').value = tx.note || '';
  $('#input-date').value = tx.date;
  $('#input-time').value = tx.time || nowTime();
  closeNestedSheets();
  renderCategoryGrid();
  renderPaySelect();
  renderPayMenu();
  closeAllSheets();
  openOverlay();
  $('#add-sheet').classList.add('open');
}

function saveTransaction() {
  const amount = parseAmountInput($('#input-amount').value);
  if (!amount || amount <= 0) {
    showToast('Vui lòng nhập số tiền');
    $('#input-amount').focus();
    return;
  }
  const note = $('#input-note').value.trim();
  const cat = getCat(state.selectedCategory);
  const pay = currentPay();
  const detail = state.selectedDetail || '';
  const title = detail || note || cat.name || 'Giao dịch';
  const payload = {
    title,
    category: state.selectedCategory,
    type: state.sheetMode === 'edit' ? state.txType : 'expense',
    amount,
    date: $('#input-date').value || todayISO(),
    time: $('#input-time').value || nowTime(),
    note,
    account: pay ? payLabel(pay) : '',
    detail,
  };

  if (state.sheetMode === 'edit' && state.editingTxId != null) {
    const idx = store.transactions.findIndex(t => t.id === state.editingTxId);
    if (idx >= 0) {
      store.transactions[idx] = { ...store.transactions[idx], ...payload };
    }
    showToast('Đã cập nhật giao dịch');
  } else {
    store.transactions.unshift({ id: Date.now(), ...payload });
    showToast('Đã lưu giao dịch ✓');
  }

  persistAll();
  closeAllSheets();
  refreshAll();
}

function openDetail(id) {
  const tx = store.transactions.find(t => t.id === id);
  if (!tx) return;
  state.detailTxId = id;
  const cat = getCat(tx.category);
  const sign = tx.type === 'income' ? '+' : '−';
  $('#detail-body').innerHTML = `
    <div class="detail-amount ${tx.type}">${sign}${formatVND(tx.amount)}</div>
    <div class="detail-title">${tx.title}</div>
    <div class="detail-rows">
      <div class="detail-row"><span>Chi cho</span><strong>${cat.name}</strong></div>
      <div class="detail-row"><span>Chi tiết</span><strong>${tx.detail || '—'}</strong></div>
      <div class="detail-row"><span>Thanh toán</span><strong>${tx.account || '—'}</strong></div>
      <div class="detail-row"><span>Ngày</span><strong>${tx.date} · ${tx.time || ''}</strong></div>
      <div class="detail-row"><span>Ghi chú</span><strong>${tx.note || '—'}</strong></div>
    </div>`;
  openOverlay();
  $('#detail-sheet').classList.add('open');
}

function confirmDeleteTx(id) {
  showDialog({
    title: 'Xóa giao dịch?',
    msg: 'Thao tác này không thể hoàn tác.',
    icon: 'delete',
    confirm: true,
    onConfirm: () => {
      store.transactions = store.transactions.filter(t => t.id !== id);
      persistAll();
      closeAllSheets();
      refreshAll();
      showToast('Đã xóa giao dịch');
      closeDialog();
    },
  });
}

/* ============================================================
   UPCOMING PAYMENTS (prototype demo, in-memory only)
   ============================================================ */
function normalizeUpcomingDue(raw) {
  const trimmed = String(raw || '').trim();
  if (!trimmed) return '';
  const lower = trimmed.toLowerCase();
  if (lower.startsWith('hạn ') || lower === 'hạn') return trimmed;
  return `Hạn ${trimmed}`;
}

function isUpcomingPaid(id) {
  return state.upcomingPaidIds.includes(id);
}

function unpaidUpcoming() {
  return state.upcomingItems.filter(item => !isUpcomingPaid(item.id));
}

function upcomingRowHtml(item) {
  const paid = isUpcomingPaid(item.id);
  return `
    <div class="upcoming-row" data-upcoming-id="${item.id}" role="button" tabindex="0">
      <div class="upcoming-icon"><span class="ms">${item.icon}</span></div>
      <div class="upcoming-info">
        <div class="title">${item.title}</div>
        <div class="meta${paid ? ' paid' : ''}">${paid ? 'Đã thanh toán' : item.dueLabel}</div>
      </div>
      <div class="upcoming-amount">${maskMoney(formatVND(item.amount))}</div>
    </div>`;
}

function bindUpcomingRows(root) {
  $$('[data-upcoming-id]', root).forEach(row => {
    row.addEventListener('click', () => openUpcomingDetail(row.dataset.upcomingId));
  });
}

function renderUpcoming() {
  const list = $('#upcoming-list');
  if (!list) return;
  const items = state.upcomingItems;
  const rows = items.length
    ? items.map(upcomingRowHtml).join('')
    : '<div class="upcoming-empty">Chưa có khoản sắp trả. Quản lý để thêm.</div>';
  list.innerHTML = `
    ${rows}
    <div class="upcoming-see-all" id="btn-upcoming-see-all" role="button" tabindex="0">Xem tất cả →</div>
  `;
  bindUpcomingRows(list);
  $('#btn-upcoming-see-all')?.addEventListener('click', openUpcomingAll);
}

function openUpcomingAll() {
  const unpaid = unpaidUpcoming();
  const total = unpaid.reduce((sum, item) => sum + item.amount, 0);
  const expected = DEMO_UPCOMING_CASH - DEMO_UPCOMING_SPENT - total;
  const body = $('#upcoming-all-body');
  const rows = state.upcomingItems.length
    ? state.upcomingItems.map(upcomingRowHtml).join('')
    : '<p class="caption">Chưa có khoản sắp trả.</p>';
  body.innerHTML = `
    ${rows}
    <div class="upcoming-summary">
      <span class="label">Tổng sắp trả</span>
      <span class="val">${maskMoney(formatVND(total))}</span>
    </div>
    <div class="upcoming-summary emphasize">
      <span class="label">Còn lại dự kiến</span>
      <span class="val">${maskMoney(formatVND(expected))}</span>
    </div>
    <p class="upcoming-hint">Sau khi trừ các khoản đã chi và khoản sắp trả</p>
  `;
  bindUpcomingRows(body);
  openOverlay();
  $('#upcoming-all-sheet').classList.add('open');
}

function openUpcomingManage() {
  renderUpcomingManage();
  openOverlay();
  $('#upcoming-manage-sheet').classList.add('open');
}

function renderUpcomingManage() {
  const list = $('#upcoming-manage-list');
  if (!list) return;
  list.innerHTML = state.upcomingItems.map((item, i) => `
    <div class="manage-row">
      <span class="manage-row-left">
        <span class="ms">${item.icon}</span>
        <span>${item.title}</span>
      </span>
      <span class="manage-row-actions">
        ${moveButtonsHtml(i, state.upcomingItems.length)}
        <button type="button" class="btn-icon" data-upcoming-edit="${item.id}" aria-label="Sửa">
          <span class="ms">edit</span>
        </button>
      </span>
    </div>
  `).join('');
  $$('[data-upcoming-edit]').forEach(btn => {
    btn.addEventListener('click', () => openUpcomingEdit(btn.dataset.upcomingEdit, true));
  });
  bindMoveButtons(list, (from, to) => {
    state.upcomingItems = moveIndex(state.upcomingItems, from, to);
    renderUpcoming();
    renderUpcomingManage();
  });
}

function openUpcomingDetail(id) {
  const item = state.upcomingItems.find(x => x.id === id);
  if (!item) return;
  state.upcomingDetailId = id;
  const paid = isUpcomingPaid(id);
  $('#upcoming-detail-title').textContent = item.title;
  $('#upcoming-detail-body').innerHTML = `
    <div class="upcoming-detail-amount">${maskMoney(formatVND(item.amount))}</div>
    <p class="caption">${item.dueLabel}</p>
    <p class="caption" style="margin-top:8px;font-weight:600;color:${paid ? 'var(--income)' : 'var(--text)'}">
      Trạng thái: ${paid ? 'Đã thanh toán' : 'Chưa thanh toán'}
    </p>
  `;
  $('#btn-upcoming-mark-paid').classList.toggle('hidden', paid);
  closeAllSheets();
  openOverlay();
  $('#upcoming-detail-sheet').classList.add('open');
}

function openUpcomingEdit(id = null, nested = false) {
  state.upcomingEditId = id;
  const item = id ? state.upcomingItems.find(x => x.id === id) : null;
  $('#upcoming-edit-title').textContent = item ? 'Sửa khoản sắp trả' : 'Thêm khoản sắp trả';
  $('#input-upcoming-name').value = item ? item.title : '';
  $('#input-upcoming-amount').value = item ? item.amount.toLocaleString('vi-VN') : '';
  const due = item?.dueLabel || '';
  $('#input-upcoming-due').value = due.toLowerCase().startsWith('hạn ') ? due.slice(4) : due;
  $('#btn-delete-upcoming')?.classList.toggle('hidden', !item);
  if (!nested) {
    closeAllSheets();
    openOverlay();
  }
  $('#upcoming-edit-sheet').classList.add('open');
}

function saveUpcoming() {
  const title = $('#input-upcoming-name').value.trim();
  const amount = parseAmountInput($('#input-upcoming-amount').value);
  const dueLabel = normalizeUpcomingDue($('#input-upcoming-due').value);
  if (!title || amount <= 0 || !dueLabel) {
    showToast('Nhập tên, số tiền và hạn.');
    return;
  }
  if (state.upcomingEditId) {
    state.upcomingItems = state.upcomingItems.map(item => (
      item.id === state.upcomingEditId
        ? { ...item, title, amount, dueLabel }
        : item
    ));
  } else {
    state.upcomingItems = [
      ...state.upcomingItems,
      {
        id: `custom-${state.upcomingNextId}`,
        title,
        amount,
        dueLabel,
        icon: 'payments',
      },
    ];
    state.upcomingNextId += 1;
  }
  $('#upcoming-edit-sheet').classList.remove('open');
  if (!$('#upcoming-manage-sheet')?.classList.contains('open')) closeAllSheets();
  renderUpcoming();
  renderUpcomingManage();
  showToast('Đã lưu khoản sắp trả');
}

function confirmDeleteUpcoming() {
  const id = state.upcomingEditId || state.upcomingDetailId;
  const item = state.upcomingItems.find(x => x.id === id);
  if (!item) return;
  showDialog({
    title: 'Xóa khoản sắp trả?',
    msg: `Bạn có chắc muốn xóa “${item.title}”?`,
    icon: 'delete',
    confirm: true,
    onConfirm: () => {
      state.upcomingItems = state.upcomingItems.filter(x => x.id !== item.id);
      state.upcomingPaidIds = state.upcomingPaidIds.filter(paidId => paidId !== item.id);
      $('#upcoming-edit-sheet').classList.remove('open');
      if (!$('#upcoming-manage-sheet')?.classList.contains('open')) closeAllSheets();
      renderUpcoming();
      renderUpcomingManage();
      showToast('Đã xóa khoản sắp trả');
      closeDialog();
    },
  });
}

function markUpcomingPaid() {
  const id = state.upcomingDetailId;
  if (!id || isUpcomingPaid(id)) return;
  state.upcomingPaidIds = [...state.upcomingPaidIds, id];
  closeAllSheets();
  renderUpcoming();
  showToast('Đã đánh dấu đã trả');
}

/* ============================================================
   BUDGET SHEET
   ============================================================ */
function openBudgetSheet() {
  $('#input-budget-limit').value = (store.budget.totalLimit || 0).toLocaleString('vi-VN');
  openOverlay();
  $('#budget-sheet').classList.add('open');
}

function saveBudget() {
  const n = parseAmountInput($('#input-budget-limit').value);
  if (!n || n <= 0) {
    showToast('Nhập hạn mức hợp lệ');
    return;
  }
  store.budget = { month: monthKey(), totalLimit: n };
  persistAll();
  closeAllSheets();
  refreshAll();
  showToast('Đã lưu ngân sách');
}

/* ============================================================
   FINANCE PIN & SALARY
   ============================================================ */
function openFinancePinChangeSheet() {
  $('#input-finance-pin-old').value = '';
  $('#input-finance-pin-new').value = '';
  openOverlay();
  $('#finance-pin-change-sheet').classList.add('open');
}

function saveFinancePin() {
  const oldPin = ($('#input-finance-pin-old')?.value || '').trim();
  const newPin = ($('#input-finance-pin-new')?.value || '').trim();
  if (oldPin !== getFinancePin()) {
    showToast('Mật khẩu hiện tại không đúng');
    return;
  }
  if (!/^\d{4}$/.test(newPin)) {
    showToast('Mật khẩu mới phải có 4 số');
    return;
  }
  store.prefs.financePin = newPin;
  persistPrefs();
  closeAllSheets();
  showToast('Đã đổi mật khẩu');
}

function openSalarySheet() {
  const amt = store.salary?.monthlyAmount || 0;
  $('#input-salary-amount').value = amt ? amt.toLocaleString('vi-VN') : '';
  openOverlay();
  $('#salary-sheet').classList.add('open');
}

function saveSalary() {
  const n = parseAmountInput($('#input-salary-amount').value);
  if (!n || n <= 0) {
    showToast('Nhập số lương hợp lệ');
    return;
  }
  store.salary = { monthlyAmount: n };
  saveJSON(STORAGE_KEYS.salary, store.salary);
  closeAllSheets();
  renderBudget();
  showToast('Đã lưu lương');
}

/* ============================================================
   GOAL SHEET
   ============================================================ */
function openGoalSheet(mode, id = null) {
  state.goalMode = mode;
  state.editingGoalId = id;
  const nameG = $('#goal-name-group');
  const targetG = $('#goal-target-group');
  const currentG = $('#goal-current-group');
  const hint = $('#goal-hint');

  $('#input-goal-name').value = '';
  $('#input-goal-target').value = '';
  $('#input-goal-current').value = '';

  if (mode === 'create') {
    $('#goal-sheet-title').textContent = 'Tạo mục tiêu';
    $('#goal-current-label').textContent = 'Số hiện có (₫)';
    nameG.classList.remove('hidden');
    targetG.classList.remove('hidden');
    currentG.classList.remove('hidden');
    hint.classList.remove('hidden');
  } else if (mode === 'edit') {
    const g = store.goals.find(x => x.id === id);
    if (!g) return;
    $('#goal-sheet-title').textContent = 'Sửa mục tiêu';
    $('#goal-current-label').textContent = 'Số hiện có (₫)';
    $('#input-goal-name').value = g.name;
    $('#input-goal-target').value = g.targetAmount.toLocaleString('vi-VN');
    $('#input-goal-current').value = g.currentAmount.toLocaleString('vi-VN');
    nameG.classList.remove('hidden');
    targetG.classList.remove('hidden');
    currentG.classList.remove('hidden');
    hint.classList.remove('hidden');
  } else if (mode === 'addMoney') {
    const g = store.goals.find(x => x.id === id);
    if (!g) return;
    $('#goal-sheet-title').textContent = `Thêm tiền · ${g.name}`;
    $('#goal-current-label').textContent = 'Số tiền thêm (₫)';
    nameG.classList.add('hidden');
    targetG.classList.add('hidden');
    currentG.classList.remove('hidden');
    hint.classList.remove('hidden');
  }

  openOverlay();
  $('#goal-sheet').classList.add('open');
}

function saveGoal() {
  if (state.goalMode === 'addMoney') {
    const add = parseAmountInput($('#input-goal-current').value);
    if (!add || add <= 0) {
      showToast('Nhập số tiền hợp lệ');
      return;
    }
    const g = store.goals.find(x => x.id === state.editingGoalId);
    if (g) g.currentAmount += add;
    persistAll();
    closeAllSheets();
    refreshAll();
    showToast('Đã thêm vào mục tiêu');
    return;
  }

  const name = $('#input-goal-name').value.trim();
  const target = parseAmountInput($('#input-goal-target').value);
  const current = parseAmountInput($('#input-goal-current').value);
  if (!name) {
    showToast('Nhập tên mục tiêu');
    return;
  }
  if (!target || target <= 0) {
    showToast('Nhập mục tiêu hợp lệ');
    return;
  }

  if (state.goalMode === 'edit') {
    const g = store.goals.find(x => x.id === state.editingGoalId);
    if (g) {
      g.name = name;
      g.targetAmount = target;
      g.currentAmount = current;
    }
    showToast('Đã cập nhật mục tiêu');
  } else {
    store.goals.push({
      id: Date.now(),
      name,
      targetAmount: target,
      currentAmount: current || 0,
    });
    showToast('Đã tạo mục tiêu');
  }
  persistAll();
  closeAllSheets();
  refreshAll();
}

/* ============================================================
   THEME / ONBOARDING
   ============================================================ */
function setDarkMode(on) {
  store.prefs.darkMode = on;
  document.documentElement.setAttribute('data-theme', on ? 'dark' : 'light');
  $('#toggle-dark')?.classList.toggle('on', on);
  $('#toggle-dark')?.setAttribute('aria-checked', on);
  persistPrefs();
}

function setOnboardingStep(step) {
  state.onboardingStep = step;
  $$('.onboarding-slide').forEach((s, i) => s.classList.toggle('active', i === step));
  $$('#onboarding-dots .dot').forEach((d, i) => {
    d.classList.toggle('active', i === step);
    d.setAttribute('aria-current', i === step ? 'true' : 'false');
  });
  $('#onboarding-progress').textContent = `${step + 1} / ${state.onboardingMax + 1}`;
  $('#btn-next-onboarding').textContent = step === state.onboardingMax ? 'Bắt đầu ngay' : 'Tiếp tục';
}

function nextOnboarding() {
  if (state.onboardingStep < state.onboardingMax) {
    setOnboardingStep(state.onboardingStep + 1);
  } else {
    showScreen('login');
  }
}

function enterApp(method) {
  setOnboardingDone();
  showToast(method ? `Đăng nhập với ${method}` : 'Chào mừng!');
  setTimeout(() => {
    showScreen('home');
    const fab = $('#fab');
    if (fab) {
      fab.classList.add('pulse');
      setTimeout(() => fab.classList.remove('pulse'), 2400);
    }
  }, 350);
}

function updateClock() {
  const now = new Date();
  $('#status-time').textContent = `${pad2(now.getHours())}:${pad2(now.getMinutes())}`;
}

/* ============================================================
   EVENTS
   ============================================================ */
function bindEvents() {
  $$('.nav-item').forEach(item => {
    item.addEventListener('click', () => navigateMain(item.dataset.nav));
  });
  $$('[data-nav]').forEach(el => {
    if (el.classList.contains('nav-item')) return;
    el.addEventListener('click', () => navigateMain(el.dataset.nav));
  });

  $('#fab').addEventListener('click', openAddSheet);
  $$('[data-action="add"]').forEach(el => el.addEventListener('click', openAddSheet));

  $('#sheet-overlay').addEventListener('click', () => {
    if ($('#upcoming-edit-sheet')?.classList.contains('open')) {
      $('#upcoming-edit-sheet').classList.remove('open');
      return;
    }
    if ($('#upcoming-manage-sheet')?.classList.contains('open')) {
      $('#upcoming-manage-sheet').classList.remove('open');
      $('#sheet-overlay').classList.remove('open');
      return;
    }
    if ($('#detail-edit-sheet')?.classList.contains('open')) {
      $('#detail-edit-sheet').classList.remove('open');
      return;
    }
    if ($('#detail-manage-sheet')?.classList.contains('open')) {
      $('#detail-manage-sheet').classList.remove('open');
      return;
    }
    if ($('#chicho-edit-sheet')?.classList.contains('open')) {
      $('#chicho-edit-sheet').classList.remove('open');
      return;
    }
    if ($('#pay-edit-sheet')?.classList.contains('open')) {
      $('#pay-edit-sheet').classList.remove('open');
      return;
    }
    if ($('#chicho-sheet')?.classList.contains('open')) {
      $('#chicho-sheet').classList.remove('open');
      return;
    }
    if ($('#month-sheet')?.classList.contains('open')) {
      $('#month-sheet').classList.remove('open');
      $('#sheet-overlay').classList.remove('open');
      return;
    }
    closeAllSheets();
  });
  $('#btn-close-sheet').addEventListener('click', closeAllSheets);
  $('#btn-close-detail').addEventListener('click', closeAllSheets);
  $('#btn-close-budget-sheet').addEventListener('click', closeAllSheets);
  $('#btn-close-goal-sheet').addEventListener('click', closeAllSheets);
  $('#btn-close-finance-pin')?.addEventListener('click', closeAllSheets);
  $('#btn-close-finance-pin-change')?.addEventListener('click', closeAllSheets);
  $('#btn-close-salary-sheet')?.addEventListener('click', closeAllSheets);
  $('#btn-close-upcoming-all')?.addEventListener('click', closeAllSheets);
  $('#btn-close-upcoming-detail')?.addEventListener('click', closeAllSheets);
  $('#btn-close-upcoming-edit')?.addEventListener('click', () => {
    $('#upcoming-edit-sheet').classList.remove('open');
    if (!$('#upcoming-manage-sheet')?.classList.contains('open')) closeAllSheets();
  });
  $('#btn-close-upcoming-manage')?.addEventListener('click', closeAllSheets);
  $('#btn-manage-upcoming')?.addEventListener('click', openUpcomingManage);
  $('#btn-add-upcoming')?.addEventListener('click', () => openUpcomingEdit(null, true));
  $('#btn-save-upcoming')?.addEventListener('click', saveUpcoming);
  $('#input-upcoming-amount')?.addEventListener('input', e => formatAmountInput(e.target));
  $('#btn-delete-upcoming')?.addEventListener('click', confirmDeleteUpcoming);
  $('#btn-upcoming-mark-paid')?.addEventListener('click', markUpcomingPaid);
  $('#btn-submit-finance-pin')?.addEventListener('click', verifyFinancePin);
  $('#input-finance-pin')?.addEventListener('keydown', e => {
    if (e.key === 'Enter') verifyFinancePin();
  });
  $('#btn-save-finance-pin')?.addEventListener('click', saveFinancePin);
  $('#btn-save-salary')?.addEventListener('click', saveSalary);
  $('#input-salary-amount')?.addEventListener('input', e => formatAmountInput(e.target));
  $('#btn-close-pay-edit')?.addEventListener('click', () => $('#pay-edit-sheet').classList.remove('open'));
  $('#btn-close-chicho')?.addEventListener('click', () => $('#chicho-sheet').classList.remove('open'));
  $('#btn-close-chicho-edit')?.addEventListener('click', () => $('#chicho-edit-sheet').classList.remove('open'));
  $('#btn-close-detail-manage')?.addEventListener('click', () => $('#detail-manage-sheet').classList.remove('open'));
  $('#btn-close-detail-edit')?.addEventListener('click', () => $('#detail-edit-sheet').classList.remove('open'));
  $('#btn-close-month')?.addEventListener('click', () => {
    $('#month-sheet').classList.remove('open');
    $('#sheet-overlay').classList.remove('open');
  });

  $('#btn-save-tx').addEventListener('click', saveTransaction);
  $('#input-amount').addEventListener('input', e => formatAmountInput(e.target));
  $$('#quick-amounts .quick-amt').forEach(btn => {
    btn.addEventListener('click', () => {
      const amt = parseInt(btn.dataset.amt, 10);
      $('#input-amount').value = amt.toLocaleString('vi-VN');
      syncQuickAmountChips();
    });
  });

  $('#pay-select')?.addEventListener('click', () => {
    const menu = $('#pay-menu');
    const open = menu.classList.contains('hidden');
    menu.classList.toggle('hidden', !open);
    $('#pay-select').setAttribute('aria-expanded', open ? 'true' : 'false');
    if (open) renderPayMenu();
  });
  $('#btn-save-pay')?.addEventListener('click', savePayMethod);
  $('#btn-delete-pay')?.addEventListener('click', deletePayMethod);

  $('#btn-manage-chicho')?.addEventListener('click', openChiChoManage);
  $('#btn-add-chicho')?.addEventListener('click', () => openChiChoEdit(null));
  $('#btn-save-chicho')?.addEventListener('click', saveChiCho);
  $('#btn-delete-chicho')?.addEventListener('click', deleteChiCho);
  $('#btn-manage-details')?.addEventListener('click', openDetailManage);
  $('#btn-add-detail')?.addEventListener('click', () => openDetailEdit(null));
  $('#btn-save-detail')?.addEventListener('click', saveDetailItem);
  $('#btn-delete-detail')?.addEventListener('click', deleteDetailItem);
  $('#btn-home-month')?.addEventListener('click', openMonthPicker);

  $('#btn-detail-edit').addEventListener('click', () => {
    const tx = store.transactions.find(t => t.id === state.detailTxId);
    if (tx) openEditSheet(tx);
  });
  $('#btn-detail-delete').addEventListener('click', () => {
    if (state.detailTxId != null) confirmDeleteTx(state.detailTxId);
  });

  $('#btn-edit-budget').addEventListener('click', openBudgetSheet);
  $('#btn-save-budget').addEventListener('click', saveBudget);
  $('#input-budget-limit').addEventListener('input', e => formatAmountInput(e.target));

  $('#btn-create-goal').addEventListener('click', () => openGoalSheet('create'));
  $('#btn-save-goal').addEventListener('click', saveGoal);
  $('#input-goal-target').addEventListener('input', e => formatAmountInput(e.target));
  $('#input-goal-current').addEventListener('input', e => formatAmountInput(e.target));

  $('#btn-budget-back')?.addEventListener('click', () => {
    showScreen(state.budgetReturnTo === 'home' ? 'home' : 'settings');
  });

  $('#btn-edit-salary')?.addEventListener('click', openSalarySheet);

  $$('#tx-date-chips .chip').forEach(chip => {
    chip.addEventListener('click', () => {
      state.txDateFilter = chip.dataset.dateFilter;
      $$('#tx-date-chips .chip').forEach(c => c.classList.toggle('active', c === chip));
      $('#custom-date-row').classList.toggle('hidden', state.txDateFilter !== 'custom');
      renderTransactions();
    });
  });
  $('#tx-date-from')?.addEventListener('change', e => {
    state.txDateFrom = e.target.value;
    renderTransactions();
  });
  $('#tx-date-to')?.addEventListener('change', e => {
    state.txDateTo = e.target.value;
    renderTransactions();
  });

  // Privacy
  $('#btn-hide-balance')?.addEventListener('click', toggleShowAmounts);

  // Onboarding
  $('#btn-next-onboarding').addEventListener('click', nextOnboarding);
  $('#btn-skip-onboarding').addEventListener('click', () => showScreen('login'));
  $$('#onboarding-dots .dot').forEach(dot => {
    dot.addEventListener('click', () => setOnboardingStep(Number(dot.dataset.step)));
  });
  const slides = $('#onboarding-slides');
  if (slides) {
    let startX = 0;
    slides.addEventListener('touchstart', e => { startX = e.changedTouches[0].screenX; }, { passive: true });
    slides.addEventListener('touchend', e => {
      const dx = e.changedTouches[0].screenX - startX;
      if (dx < -50 && state.onboardingStep < state.onboardingMax) setOnboardingStep(state.onboardingStep + 1);
      if (dx > 50 && state.onboardingStep > 0) setOnboardingStep(state.onboardingStep - 1);
    }, { passive: true });
  }

  $('#btn-google').addEventListener('click', () => enterApp('Google'));
  $('#btn-apple').addEventListener('click', () => enterApp('Apple'));
  $('#btn-guest').addEventListener('click', () => enterApp('Khách'));

  // Settings
  $('#toggle-dark').addEventListener('click', e => {
    e.stopPropagation();
    setDarkMode(!store.prefs.darkMode);
  });
  $('#toggle-notif').addEventListener('click', e => {
    e.stopPropagation();
    store.prefs.notificationsEnabled = !store.prefs.notificationsEnabled;
    persistPrefs();
    renderSettings();
    showToast(store.prefs.notificationsEnabled ? 'Đã bật thông báo' : 'Đã tắt thông báo');
  });
  ['#toggle-dark', '#toggle-notif'].forEach(sel => {
    $(sel)?.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); $(sel).click(); }
    });
  });

  $$('.settings-item').forEach(item => {
    item.addEventListener('click', () => {
      const key = item.dataset.setting;
      if (key === 'darkmode' || key === 'notification') return;
      if (key === 'currency') {
        showDialog({ title: 'Tiền tệ', msg: 'MVP dùng VND (₫).', icon: 'payments' });
      } else if (key === 'privacy') {
        toggleShowAmounts();
      } else if (key === 'budget') {
        openBudgetScreen('settings');
      } else if (key === 'finance-pin') {
        if (state.financeUnlocked) openFinancePinChangeSheet();
        else requireFinanceAccess('change-pin');
      }
    });
  });

  $('#profile-card').addEventListener('click', () => {
    showDialog({ title: 'Hồ sơ', msg: 'Minh Khuê · minhkhue@email.com\n(UI prototype — không có backend)', icon: 'person' });
  });

  $('#btn-logout').addEventListener('click', () => {
    showDialog({
      title: 'Đăng xuất?',
      msg: 'Dữ liệu cục bộ vẫn được giữ trên thiết bị.',
      icon: 'logout',
      confirm: true,
      onConfirm: () => {
        closeDialog();
        state.financeUnlocked = false;
        showScreen('login');
      },
    });
  });

  $('#btn-avatar').addEventListener('click', () => navigateMain('settings'));

  $('#dialog-ok').addEventListener('click', () => {
    if (dialogCallback) dialogCallback();
    else closeDialog();
  });
  $('#dialog-cancel').addEventListener('click', closeDialog);
  $('#dialog-overlay').addEventListener('click', e => {
    if (e.target === $('#dialog-overlay')) closeDialog();
  });

  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
      closeAllSheets();
      closeDialog();
    }
  });
}

/* ============================================================
   BOOT
   ============================================================ */
function boot() {
  stripHomeExtraCards();
  loadStore();
  state.viewMonth = store.prefs.viewMonth || monthKey();
  setDarkMode(store.prefs.darkMode);
  updateClock();
  setInterval(updateClock, 30000);
  document.querySelector('.phone-status')?.classList.add('on-dark');

  refreshAll();
  bindEvents();

  setTimeout(() => {
    showScreen('home');
  }, 450);
}

document.addEventListener('DOMContentLoaded', boot);
