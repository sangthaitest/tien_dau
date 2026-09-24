import 'package:flutter/material.dart';

import '../../application/backup_service.dart';
import '../../application/finance_service.dart';
import '../../application/restore_service.dart';
import '../../application/statistics_query.dart';
import '../../application/transaction_service.dart';
import '../../data/backup/backup_ports.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/security/sensitive_access_port.dart';
import '../add_transaction/add_transaction_controller.dart';
import '../add_transaction/add_transaction_page.dart';
import '../backup/backup_restore_page.dart';
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
import '../tutorial/tutorial_overlay.dart';
import '../tutorial/tutorial_steps.dart';
import '../tutorial/tutorial_targets.dart';
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
  bool _showBackupRestore = false;
  bool _showAdd = false;
  bool _openingAdd = false;
  bool _openingSensitive = false;
  bool _openingDetail = false;
  bool _paintWarm = true;
  bool _tutorialActive = false;
  bool _tutorialBusy = false;
  TutorialTrack _tutorialTrack = TutorialTrack.firstLaunch;
  TutorialStep _tutorialStep = TutorialStep.welcome;
  late final TransactionListController _listController;
  late final FinanceController _financeController;
  late final StatisticsController _statsController;
  late final AddTransactionController _addController;
  late final Map<AppTab, GlobalKey> _tabKeys;
  final GlobalKey _addKey = GlobalKey();
  final TutorialTargets _tutorialTargets = TutorialTargets();

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
      clock: widget.clock,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeStartFirstLaunchTutorial();
      });
    }
  }

  void _maybeStartFirstLaunchTutorial() {
    _maybeStartTrack(TutorialTrack.firstLaunch);
  }

  bool _isTrackCompleted(TutorialTrack track) {
    final settings = SettingsScope.maybeOf(context)?.settings;
    if (settings == null) return true;
    return switch (track) {
      TutorialTrack.firstLaunch => settings.hasCompletedTutorial,
      TutorialTrack.add => settings.hasCompletedAddTutorial,
      TutorialTrack.finance => settings.hasCompletedFinanceTutorial,
      TutorialTrack.backup => settings.hasCompletedBackupTutorial,
      TutorialTrack.transactions => settings.hasCompletedTransactionsTutorial,
      TutorialTrack.statistics => settings.hasCompletedStatisticsTutorial,
      TutorialTrack.full => false,
    };
  }

  Future<void> _maybeStartTrack(TutorialTrack track) async {
    if (!mounted || _tutorialActive || _tutorialBusy) return;
    if (_isTrackCompleted(track)) return;
    await _startTutorial(track);
  }

  Future<void> _startTutorial(TutorialTrack track) async {
    if (_tutorialActive || _tutorialBusy) return;
    _tutorialBusy = true;
    try {
      final first = track.steps.first;
      setState(() {
        _tutorialTrack = track;
        _tutorialStep = first;
        _tutorialActive = true;
        if (track.resetsShell) {
          _showAdd = false;
          _showProfile = false;
          _showBackupRestore = false;
          _showFinance = false;
          _tab = AppTab.home;
        }
      });
      await _prepareTutorialStep(first);
    } finally {
      _tutorialBusy = false;
    }
  }

  Future<void> _prepareTutorialStep(TutorialStep step) async {
    if (step.usesFinance) {
      if (!_showFinance) {
        await _financeController.load();
        if (!mounted) return;
        setState(() {
          _showAdd = false;
          _showProfile = false;
          _showBackupRestore = false;
          _showFinance = true;
        });
      }
    } else if (step.usesAdd) {
      _addController.reset(now: widget.clock());
      if (!_showAdd || _showFinance || _showBackupRestore) {
        setState(() {
          _showFinance = false;
          _showProfile = false;
          _showBackupRestore = false;
          _showAdd = true;
        });
      }
    } else if (step.usesBackup) {
      if (!_showBackupRestore) {
        setState(() {
          _showAdd = false;
          _showProfile = false;
          _showFinance = false;
          _showBackupRestore = true;
          _tab = AppTab.settings;
        });
      }
    } else if (step.usesTransactions) {
      await _listController.load();
      if (!mounted) return;
      if (_showAdd ||
          _showFinance ||
          _showBackupRestore ||
          _tab != AppTab.transactions) {
        setState(() {
          _showAdd = false;
          _showFinance = false;
          _showProfile = false;
          _showBackupRestore = false;
          _tab = AppTab.transactions;
        });
      }
    } else if (step.usesStatistics) {
      await _statsController.load();
      if (!mounted) return;
      if (_showAdd ||
          _showFinance ||
          _showBackupRestore ||
          _tab != AppTab.statistics) {
        setState(() {
          _showAdd = false;
          _showFinance = false;
          _showProfile = false;
          _showBackupRestore = false;
          _tab = AppTab.statistics;
        });
      }
    } else {
      if (_showAdd ||
          _showFinance ||
          _showBackupRestore ||
          _tab != AppTab.home) {
        setState(() {
          _showAdd = false;
          _showFinance = false;
          _showProfile = false;
          _showBackupRestore = false;
          _tab = AppTab.home;
        });
      }
    }
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final target = _tutorialTargets.keyFor(step).currentContext;
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 280),
        alignment: 0.2,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _onTutorialContinue() async {
    if (_tutorialBusy) return;
    final next = _tutorialStep.nextIn(_tutorialTrack);
    if (next == null) {
      await _finishTutorial(completed: true);
      return;
    }
    _tutorialBusy = true;
    try {
      await _prepareTutorialStep(next);
      if (!mounted) return;
      setState(() => _tutorialStep = next);
    } finally {
      _tutorialBusy = false;
    }
  }

  Future<void> _finishTutorial({required bool completed}) async {
    if (!_tutorialActive) return;
    final track = _tutorialTrack;
    final stayOnFinance = track == TutorialTrack.finance;
    final stayOnBackup = track == TutorialTrack.backup;
    final stayOnTransactions = track == TutorialTrack.transactions;
    final stayOnStatistics = track == TutorialTrack.statistics;
    final stayOnAdd = track == TutorialTrack.add;
    setState(() {
      _tutorialActive = false;
      if (!stayOnAdd) _showAdd = false;
      if (!stayOnFinance) _showFinance = false;
      if (!stayOnBackup) _showBackupRestore = false;
      if (track.returnsToSettings) {
        _tab = AppTab.settings;
      } else if (stayOnFinance || stayOnBackup || stayOnAdd) {
        // Keep the screen that was just introduced.
      } else if (stayOnTransactions) {
        _tab = AppTab.transactions;
      } else if (stayOnStatistics) {
        _tab = AppTab.statistics;
      } else {
        _tab = AppTab.home;
      }
    });
    if (completed && mounted) {
      final settings = SettingsScope.maybeOf(context);
      if (settings == null) return;
      switch (track) {
        case TutorialTrack.firstLaunch:
          await settings.setTutorialCompleted(true);
        case TutorialTrack.add:
          await settings.setAddTutorialCompleted(true);
        case TutorialTrack.finance:
          await settings.setFinanceTutorialCompleted(true);
        case TutorialTrack.backup:
          await settings.setBackupTutorialCompleted(true);
        case TutorialTrack.transactions:
          await settings.setTransactionsTutorialCompleted(true);
        case TutorialTrack.statistics:
          await settings.setStatisticsTutorialCompleted(true);
        case TutorialTrack.full:
          await settings.completeAllTutorials();
      }
    }
  }

  void _onViewMonthChanged() {
    _refresh();
  }

  AppTab get _tutorialNavTab {
    if (_tutorialStep.usesFinance || _tutorialStep.usesBackup) {
      return AppTab.settings;
    }
    if (_tutorialStep.usesTransactions) return AppTab.transactions;
    if (_tutorialStep.usesStatistics) return AppTab.statistics;
    return AppTab.home;
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
    if (_tutorialActive || _openingAdd || _showAdd) return;
    _openingAdd = true;
    traceInteraction('openAdd.start');
    _addController.reset(now: widget.clock());
    setState(() => _showAdd = true);
    _openingAdd = false;
    _maybeStartTrack(TutorialTrack.add);
  }

  Future<void> _onAddFinished(bool saved) async {
    if (_tutorialActive || !_showAdd) return;
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

  void _selectTab(AppTab tab) {
    if (_tutorialActive) return;
    if (_tab == tab && !_showFinance && !_showProfile && !_showBackupRestore) {
      return;
    }
    setState(() {
      _tab = tab;
      if (tab != AppTab.settings) {
        _showFinance = false;
        _showProfile = false;
        _showBackupRestore = false;
      }
    });
    switch (tab) {
      case AppTab.transactions:
        _maybeStartTrack(TutorialTrack.transactions);
      case AppTab.statistics:
        _maybeStartTrack(TutorialTrack.statistics);
      case AppTab.home:
      case AppTab.settings:
        break;
    }
  }

  Future<bool> _ensureUnlocked() async {
    if (await widget.sensitiveAccess.isUnlocked()) return true;
    final hasPin = await widget.sensitiveAccess.hasPin();
    final mode = hasPin ? PinSheetMode.unlock : PinSheetMode.setup;
    if (!mounted) return false;
    return PinSheet.show(context, access: widget.sensitiveAccess, mode: mode);
  }

  Future<void> _openFinance() async {
    if (_tutorialActive || _openingSensitive) return;
    _openingSensitive = true;
    try {
      final ok = await _ensureUnlocked();
      if (!ok || !mounted) return;
      await _financeController.load();
      setState(() {
        _tab = AppTab.settings;
        _showProfile = false;
        _showBackupRestore = false;
        _showFinance = true;
      });
      await _maybeStartTrack(TutorialTrack.finance);
    } finally {
      _openingSensitive = false;
    }
  }

  void _openProfile() {
    setState(() {
      _tab = AppTab.settings;
      _showFinance = false;
      _showBackupRestore = false;
      _showProfile = true;
    });
  }

  void _openBackupRestore() {
    if (_tutorialActive) return;
    setState(() {
      _tab = AppTab.settings;
      _showFinance = false;
      _showProfile = false;
      _showBackupRestore = true;
    });
    _maybeStartTrack(TutorialTrack.backup);
  }

  Future<void> _onBackupRestored() async {
    await widget.sensitiveAccess.lock();
    await widget.catalogController.load();
    await widget.viewMonthController.load();
    if (!mounted) return;
    final settings = SettingsScope.maybeOf(context);
    final profile = UserProfileScope.maybeOf(context);
    await settings?.load();
    await profile?.load();
    await _financeController.load();
    await _refresh();
    if (!mounted) return;
    setState(() {
      _showFinance = false;
      _showProfile = false;
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

  @override
  Widget build(BuildContext context) {
    SettingsScope.maybeOf(context);
    UserProfileScope.maybeOf(context);
    return PopScope(
      canPop: !_showAdd && !_tutorialActive,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_tutorialActive) {
          _finishTutorial(completed: false);
          return;
        }
        if (!_showAdd) return;
        _onAddFinished(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Expanded(
                  child: _showFinance
                      ? FinancePage(
                          controller: _financeController,
                          onBack: () {
                            if (_tutorialActive) return;
                            setState(() => _showFinance = false);
                          },
                          onOpenTransactions: () =>
                              _selectTab(AppTab.transactions),
                          incomeTargetKey: _tutorialTargets.income,
                          recurringTargetKey: _tutorialTargets.recurring,
                          spendingTargetKey: _tutorialTargets.spending,
                        )
                      : _showProfile
                      ? ProfilePage(
                          onBack: () => setState(() => _showProfile = false),
                        )
                      : _showBackupRestore
                      ? BackupRestorePage(
                          onBack: () {
                            if (_tutorialActive) return;
                            setState(() => _showBackupRestore = false);
                          },
                          onRestored: _onBackupRestored,
                          backupService: widget.backupService,
                          restoreService: widget.restoreService,
                          backupShare: widget.backupShare,
                          backupPicker: widget.backupPicker,
                          backupTargetKey: _tutorialTargets.backup,
                          restoreTargetKey: _tutorialTargets.restore,
                        )
                      : _tabHost(),
                ),
                HomeBottomNav(
                  tab: _tutorialActive
                      ? _tutorialNavTab
                      : _tab == AppTab.settings ||
                            _showFinance ||
                            _showProfile ||
                            _showBackupRestore
                      ? AppTab.settings
                      : _tab,
                  onAddPressed: _openAdd,
                  onTabSelected: _selectTab,
                  addTargetKey: _tutorialTargets.addButton,
                ),
              ],
            ),
            _PaintWarmSlot(
              visible: _showAdd,
              paintWarm: _paintWarm,
              child: AddTransactionPage(
                key: _addKey,
                controller: _addController,
                autofocusAmount: _showAdd && !_tutorialActive,
                onFinished: _onAddFinished,
                amountTargetKey: _tutorialTargets.amount,
                categoryTargetKey: _tutorialTargets.category,
                saveTargetKey: _tutorialTargets.save,
              ),
            ),
            if (_tutorialActive)
              TutorialOverlay(
                key: const Key('tutorial-overlay'),
                step: _tutorialStep,
                isLast: _tutorialStep.isLastIn(_tutorialTrack),
                targetKey: _tutorialTargets.keyFor(_tutorialStep),
                onContinue: _onTutorialContinue,
                onSkip: () => _finishTutorial(completed: false),
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
        overviewTargetKey: _tutorialTargets.overview,
      ),
      AppTab.transactions => TransactionListPage(
        controller: _listController,
        embedNavigation: false,
        onAddPressed: _openAdd,
        onTransactionTap: _openDetail,
        summaryTargetKey: _tutorialTargets.txList,
        filtersTargetKey: _tutorialTargets.txFilters,
      ),
      AppTab.statistics => StatisticsPage(
        controller: _statsController,
        insightTargetKey: _tutorialTargets.statsMonth,
        chartTargetKey: _tutorialTargets.statsCategories,
      ),
      AppTab.settings => SettingsPage(
        onOpenFinance: _openFinance,
        onOpenProfile: _openProfile,
        onChangePin: _changePin,
        onOpenBackupRestore: _openBackupRestore,
        onOpenTutorial: () => _startTutorial(TutorialTrack.full),
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
