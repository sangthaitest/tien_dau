import 'package:flutter/material.dart';

import '../../application/backup_service.dart';
import '../../application/finance_service.dart';
import '../../application/restore_service.dart';
import '../../application/statistics_query.dart';
import '../../application/transaction_service.dart';
import '../../data/backup/backup_ports.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/result.dart';
import '../../domain/security/sensitive_access_port.dart';
import '../add_transaction/add_transaction_controller.dart';
import '../add_transaction/add_transaction_page.dart';
import '../catalog/transaction_catalog_controller.dart';
import '../debug/interaction_trace.dart';
import '../finance/finance_controller.dart';
import '../finance/finance_page.dart';
import '../finance/pin_sheet.dart';
import '../home/home_controller.dart';
import '../home/home_page.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../profile/profile_page.dart';
import '../profile/user_profile_scope.dart';
import '../settings/settings_page.dart';
import '../settings/settings_scope.dart';
import '../statistics/statistics_controller.dart';
import '../statistics/statistics_page.dart';
import '../theme/app_colors.dart';
import '../transactions/transaction_detail_sheet.dart';
import '../transactions/transaction_list_controller.dart';
import '../transactions/transaction_list_page.dart';
import '../view_month/view_month_controller.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.transactionService,
    required this.homeController,
    required this.financeService,
    required this.sensitiveAccess,
    required this.catalogController,
    required this.viewMonthController,
    this.backupService,
    this.restoreService,
    this.backupShare,
    this.backupPicker,
    this.clock = DateTime.now,
  });

  final TransactionService transactionService;
  final HomeController homeController;
  final FinanceService financeService;
  final SensitiveAccessPort sensitiveAccess;
  final TransactionCatalogController catalogController;
  final ViewMonthController viewMonthController;
  final BackupService? backupService;
  final RestoreService? restoreService;
  final BackupSharePort? backupShare;
  final BackupPickPort? backupPicker;
  final DateTime Function() clock;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab _tab = AppTab.home;
  bool _showFinance = false;
  bool _showProfile = false;
  bool _showAdd = false;
  bool _openingAdd = false;
  bool _openingSensitive = false;
  bool _openingDetail = false;
  bool _paintWarm = true;
  late final TransactionListController _listController;
  late final FinanceController _financeController;
  late final StatisticsController _statsController;
  late final AddTransactionController _addController;
  late final Map<AppTab, GlobalKey> _tabKeys;
  final GlobalKey _addKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabKeys = {for (final tab in AppTab.values) tab: GlobalKey()};
    _listController = TransactionListController(
      widget.transactionService,
      clock: widget.clock,
      viewMonth: () => widget.viewMonthController.month,
    );
    _financeController = FinanceController(
      widget.financeService,
      month: () => widget.viewMonthController.month,
    );
    _statsController = StatisticsController(
      StatisticsQuery(
        widget.transactionService,
        clock: () => widget.viewMonthController.month,
      ),
      clock: () => widget.viewMonthController.month,
    );
    _addController = AddTransactionController(
      service: widget.transactionService,
      catalogController: widget.catalogController,
      clock: widget.clock,
    );
    widget.viewMonthController.addListener(_onViewMonthChanged);
    _statsController.load();
    WidgetsBinding.instance.addPostFrameCallback(_onPaintWarmFrame);
  }

  @override
  void dispose() {
    widget.viewMonthController.removeListener(_onViewMonthChanged);
    _addController.dispose();
    _listController.dispose();
    _financeController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  void _onPaintWarmFrame(Duration _) {
    if (!mounted) return;
    if (_paintWarm) {
      setState(() => _paintWarm = false);
    }
  }

  void _onViewMonthChanged() {
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.homeController.load(month: widget.viewMonthController.month),
      _listController.load(),
      if (_showFinance) _financeController.load(),
      _statsController.load(),
    ]);
  }

  void _openAdd() {
    if (_openingAdd || _showAdd) return;
    _openingAdd = true;
    traceInteraction('openAdd.start');
    _addController.reset(now: widget.clock());
    setState(() => _showAdd = true);
    _openingAdd = false;
  }

  Future<void> _onAddFinished(bool saved) async {
    if (!_showAdd) return;
    setState(() => _showAdd = false);
    _addController.reset(now: widget.clock());
    if (saved && mounted) await _refresh();
  }

  Future<void> _openDetail(Transaction tx) async {
    if (_openingDetail) return;
    _openingDetail = true;
    try {
      final changed = await TransactionDetailSheet.show(
        context: context,
        transactionService: widget.transactionService,
        catalogController: widget.catalogController,
        clock: widget.clock,
        transactionId: tx.id,
      );
      if (changed == true && mounted) await _refresh();
    } finally {
      _openingDetail = false;
    }
  }

  Future<bool> _deleteTransaction(Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: const Text('Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    final result = await widget.transactionService.remove(tx.id);
    if (result is Ok && mounted) {
      await _refresh();
    }
    return false;
  }

  void _selectTab(AppTab tab) {
    if (_tab == tab && !_showFinance && !_showProfile) return;
    setState(() {
      _tab = tab;
      if (tab != AppTab.settings) {
        _showFinance = false;
        _showProfile = false;
      }
    });
  }

  Future<bool> _ensureUnlocked() async {
    if (await widget.sensitiveAccess.isUnlocked()) return true;
    final hasPin = await widget.sensitiveAccess.hasPin();
    final mode = hasPin ? PinSheetMode.unlock : PinSheetMode.setup;
    if (!mounted) return false;
    return PinSheet.show(context, access: widget.sensitiveAccess, mode: mode);
  }

  Future<void> _openFinance() async {
    if (_openingSensitive) return;
    _openingSensitive = true;
    try {
      final ok = await _ensureUnlocked();
      if (!ok || !mounted) return;
      await _financeController.load();
      setState(() {
        _tab = AppTab.settings;
        _showProfile = false;
        _showFinance = true;
      });
    } finally {
      _openingSensitive = false;
    }
  }

  void _openProfile() {
    setState(() {
      _tab = AppTab.settings;
      _showFinance = false;
      _showProfile = true;
    });
  }

  Future<void> _changePin() async {
    if (_openingSensitive) return;
    _openingSensitive = true;
    try {
      final unlocked = await _ensureUnlocked();
      if (!unlocked || !mounted) return;
      final hasPin = await widget.sensitiveAccess.hasPin();
      if (!mounted) return;
      await PinSheet.show(
        context,
        access: widget.sensitiveAccess,
        mode: hasPin ? PinSheetMode.change : PinSheetMode.setup,
      );
    } finally {
      _openingSensitive = false;
    }
  }

  bool _backupBusy = false;

  Future<void> _backup() async {
    final service = widget.backupService;
    final share = widget.backupShare;
    if (service == null || share == null || _backupBusy) return;
    _backupBusy = true;
    try {
      _showBusyDialog('Đang sao lưu…');
      final result = await service.export();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      switch (result) {
        case Err(:final failure):
          if (mounted) _toast(failure.message);
        case Ok(:final value):
          await share.share(value);
          if (mounted) _toast('Đã tạo bản sao lưu.');
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        _toast('Không thể tạo bản sao lưu.');
      }
    } finally {
      _backupBusy = false;
    }
  }

  Future<void> _restore() async {
    final service = widget.restoreService;
    final picker = widget.backupPicker;
    if (service == null || picker == null || _backupBusy) return;
    _backupBusy = true;
    try {
      final path = await picker.pickBackup();
      if (path == null || !mounted) return;
      _showBusyDialog('Đang kiểm tra bản sao lưu…');
      final inspected = await service.inspect(path);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      switch (inspected) {
        case Err(:final failure):
          if (mounted) _toast(failure.message);
          return;
        case Ok():
          break;
      }
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Khôi phục dữ liệu?'),
          content: const Text(
            'Khôi phục dữ liệu sẽ thay thế dữ liệu hiện tại trên thiết bị này.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              key: const Key('dialog-restore-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Khôi phục'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final settings = SettingsScope.maybeOf(context);
      final profile = UserProfileScope.maybeOf(context);
      _showBusyDialog('Đang khôi phục…');
      final restored = await service.restore(path);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      switch (restored) {
        case Err(:final failure):
          if (mounted) _toast(failure.message);
        case Ok():
          await widget.sensitiveAccess.lock();
          await widget.catalogController.load();
          await widget.viewMonthController.load();
          await settings?.load();
          await profile?.load();
          await _refresh();
          if (mounted) {
            setState(() {
              _showFinance = false;
              _showProfile = false;
            });
            _toast('Đã khôi phục dữ liệu.');
          }
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        _toast('Không thể khôi phục dữ liệu.');
      }
    } finally {
      _backupBusy = false;
    }
  }

  void _showBusyDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    SettingsScope.maybeOf(context);
    UserProfileScope.maybeOf(context);
    return PopScope(
      canPop: !_showAdd,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_showAdd) return;
        _onAddFinished(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _showFinance
                      ? FinancePage(
                          controller: _financeController,
                          onBack: () => setState(() => _showFinance = false),
                          onOpenTransactions: () =>
                              _selectTab(AppTab.transactions),
                        )
                      : _showProfile
                      ? ProfilePage(
                          onBack: () => setState(() => _showProfile = false),
                        )
                      : _tabHost(),
                ),
                HomeBottomNav(
                  tab: _tab == AppTab.settings || _showFinance || _showProfile
                      ? AppTab.settings
                      : _tab,
                  onAddPressed: _openAdd,
                  onTabSelected: _selectTab,
                ),
              ],
            ),
            _PaintWarmSlot(
              visible: _showAdd,
              paintWarm: _paintWarm,
              child: AddTransactionPage(
                key: _addKey,
                controller: _addController,
                autofocusAmount: _showAdd,
                onFinished: _onAddFinished,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabHost() {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final tab in AppTab.values)
          _PaintWarmSlot(
            visible: _tab == tab,
            paintWarm: _paintWarm,
            child: KeyedSubtree(key: _tabKeys[tab]!, child: _pageFor(tab)),
          ),
      ],
    );
  }

  Widget _pageFor(AppTab tab) {
    return switch (tab) {
      AppTab.home => HomePage(
        controller: widget.homeController,
        transactionService: widget.transactionService,
        catalogController: widget.catalogController,
        viewMonthController: widget.viewMonthController,
        clock: widget.clock,
        embedNavigation: false,
        onSeeAll: () => _selectTab(AppTab.transactions),
        onTransactionTap: _openDetail,
        onAvatarTap: () => _selectTab(AppTab.settings),
      ),
      AppTab.transactions => TransactionListPage(
        controller: _listController,
        clock: widget.clock,
        embedNavigation: false,
        onAddPressed: _openAdd,
        onTransactionTap: _openDetail,
        onDelete: _deleteTransaction,
      ),
      AppTab.statistics => StatisticsPage(controller: _statsController),
      AppTab.settings => SettingsPage(
        onOpenFinance: _openFinance,
        onOpenProfile: _openProfile,
        onChangePin: _changePin,
        onBackup: _backup,
        onRestore: _restore,
      ),
    };
  }
}

class _PaintWarmSlot extends StatelessWidget {
  const _PaintWarmSlot({
    required this.visible,
    required this.paintWarm,
    required this.child,
  });

  final bool visible;
  final bool paintWarm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (visible) {
      return TickerMode(enabled: true, child: child);
    }
    if (paintWarm) {
      final size = MediaQuery.sizeOf(context);
      return IgnorePointer(
        child: ExcludeSemantics(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 2,
              height: 2,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: size.width,
                  maxWidth: size.width,
                  minHeight: size.height,
                  maxHeight: size.height,
                  child: Opacity(opacity: 0.01, child: child),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Offstage(
      offstage: true,
      child: TickerMode(enabled: false, child: child),
    );
  }
}
