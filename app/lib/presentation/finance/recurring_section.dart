import 'package:flutter/material.dart';

import '../../application/finance_service.dart';
import '../../domain/amount/amount_input.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';
import '../format/money_format.dart';
import '../settings/settings_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_dialog.dart';
import '../theme/app_typography.dart';
import '../theme/category_look.dart';
import 'finance_collapsible_card.dart';
import 'finance_controller.dart';

Future<void> showRecurringManager({
  required BuildContext context,
  required FinanceController controller,
  required RecurringKind kind,
}) {
  return RecurringWorkspace(
    controller: controller,
    kind: kind,
  ).openManager(context);
}

class RecurringWorkspace {
  const RecurringWorkspace({required this.controller, required this.kind});

  final FinanceController controller;
  final RecurringKind kind;

  bool get isIncome => kind == RecurringKind.income;

  List<RecurringTransaction> get managed => isIncome
      ? controller.snapshot.managedIncome
      : controller.snapshot.managedRecurring;

  String get managerTitle =>
      isIncome ? 'Quản lý thu nhập' : 'Quản lý khoản định kỳ';

  String get editorCreateTitle =>
      isIncome ? 'Thêm thu nhập' : 'Thêm khoản định kỳ';

  String get editorEditTitle => isIncome ? 'Sửa thu nhập' : 'Sửa khoản định kỳ';

  String get nameHint => isIncome ? 'VD: Freelance' : 'VD: Thẻ tín dụng';

  Key get manageSheetKey => isIncome
      ? const Key('finance-income-manage-sheet')
      : const Key('finance-upcoming-manage-sheet');

  Key get addButtonKey => isIncome
      ? const Key('finance-income-add')
      : const Key('finance-upcoming-add');

  Key managedItemKey(String id) => isIncome
      ? Key('finance-income-managed-$id')
      : Key('finance-upcoming-managed-$id');

  Future<void> openManager(BuildContext context) {
    // Keep edit and delete on the overlay. The first save reloads Finance
    // and the page context under this sheet is gone after that.
    final host = Navigator.of(context, rootNavigator: true).overlay!.context;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _RecurringManager(
        workspace: this,
        onAdd: () => openEditor(host),
        onEdit: (rule) => openEditor(host, rule: rule),
        onDelete: (rule) => delete(host, rule),
      ),
    );
  }

  Future<void> openEditor(
    BuildContext context, {
    RecurringTransaction? rule,
  }) async {
    final draft = await showModalBottomSheet<RecurringDraft>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _RecurringEditorSheet(
        rule: rule,
        clock: controller.clock,
        lockedKind: kind,
        createTitle: editorCreateTitle,
        editTitle: editorEditTitle,
        nameHint: nameHint,
      ),
    );
    if (draft == null || !context.mounted) return;
    final result = rule == null
        ? await controller.createRecurring(draft)
        : await controller.updateRecurring(rule, draft);
    if (context.mounted && result is Err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.failure.message)));
    }
  }

  Future<void> delete(BuildContext context, RecurringTransaction rule) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text(isIncome ? 'Xóa khoản thu nhập?' : 'Xóa khoản định kỳ?'),
        content: Text('Bạn có chắc muốn xóa “${rule.name}”?'),
        actions: [
          AppDialog.cancel(onPressed: () => Navigator.pop(context, false)),
          AppDialog.confirm(
            key: const Key('finance-upcoming-confirm-delete'),
            onPressed: () => Navigator.pop(context, true),
            label: 'Xác nhận',
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await controller.deleteRecurring(rule.id);
    if (context.mounted && result is Err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.failure.message)));
    }
  }
}

class RecurringSection extends StatelessWidget {
  const RecurringSection({super.key, required this.controller});

  final FinanceController controller;

  @override
  Widget build(BuildContext context) {
    final snap = controller.snapshot;
    final items = snap.recurringItems;
    return FinanceCollapsibleCard(
      sectionKey: const Key('finance-upcoming-section'),
      summaryKey: const Key('finance-upcoming-summary'),
      icon: Icons.calendar_month_outlined,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningContainer,
      title: 'Khoản định kỳ',
      amount: snap.recurringExpenseTotal,
      amountColor: AppColors.text,
      amountKey: const Key('finance-upcoming-total'),
      viewMonth: controller.selectedMonth,
      lines: [
        for (final rule in items)
          FinanceLine(
            id: rule.id,
            name: rule.name,
            dateLabel: financeOccurrenceDate(rule, snap.month),
            amount: rule.amount,
            onTap: () => _openDetail(context, rule),
          ),
      ],
      managedCount: snap.managedRecurring.length,
      emptyMessage: 'Chưa có khoản định kỳ. Quản lý để thêm.',
      monthEmptyMessage: 'Không có khoản định kỳ trong tháng này.',
      emptyKey: const Key('finance-upcoming-empty'),
      manageLabel: 'Quản lý khoản định kỳ →',
      manageKey: const Key('finance-upcoming-manage'),
      rowKeyPrefix: 'finance-upcoming-row',
      onManage: () => RecurringWorkspace(
        controller: controller,
        kind: RecurringKind.expense,
      ).openManager(context),
    );
  }

  RecurringWorkspace get _expenses =>
      RecurringWorkspace(controller: controller, kind: RecurringKind.expense);

  Future<void> _openDetail(
    BuildContext context,
    RecurringTransaction rule,
  ) async {
    final hidden = SettingsScope.hideMoney(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final current = [
          for (final item in controller.snapshot.recurringItems)
            if (item.id == rule.id) item,
        ];
        final item = current.isEmpty ? rule : current.first;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              key: Key('finance-upcoming-detail-${item.id}'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayVnd(item.amount, hidden: hidden),
                  style: moneyStyle(size: 24, color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  item.dueLabelForMonth(controller.snapshot.month),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: Key('finance-upcoming-edit-${item.id}'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;
                            _expenses.openEditor(context, rule: item);
                          });
                        },
                        child: const Text('Sửa'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        key: Key('finance-upcoming-delete-${item.id}'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;
                            _expenses.delete(context, item);
                          });
                        },
                        child: Text(
                          'Xóa',
                          style: TextStyle(color: AppColors.expense),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecurringIcon extends StatelessWidget {
  const _RecurringIcon({required this.rule});

  final RecurringTransaction rule;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        rule.kind == RecurringKind.income
            ? Icons.payments_outlined
            : categoryLook(rule.categoryId ?? 'other').icon,
        color: AppColors.textSecondary,
        size: 22,
      ),
    );
  }
}

class _RecurringManager extends StatelessWidget {
  const _RecurringManager({
    required this.workspace,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringWorkspace workspace;
  final Future<void> Function() onAdd;
  final Future<void> Function(RecurringTransaction rule) onEdit;
  final Future<void> Function(RecurringTransaction rule) onDelete;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    final controller = workspace.controller;
    return FractionallySizedBox(
      heightFactor: 0.86,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      workspace.managerTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: workspace.addButtonKey,
                    tooltip: 'Thêm',
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final list = workspace.managed;
                  return ListView.builder(
                    key: workspace.manageSheetKey,
                    primary: false,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: list.isEmpty ? 1 : list.length,
                    itemBuilder: (context, index) {
                      if (list.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.fromLTRB(0, 20, 0, 24),
                          child: Text(
                            'Chưa có khoản. Nhấn + để thêm.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }
                      final item = list[index];
                      return Padding(
                        key: workspace.managedItemKey(item.id),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            _RecurringIcon(rule: item),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.dueLabelForMonth(controller.snapshot.month)} · ${displayVnd(item.amount, hidden: hidden)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: Key('finance-upcoming-edit-${item.id}'),
                              tooltip: 'Sửa',
                              onPressed: () => onEdit(item),
                              icon: const Icon(Icons.edit_outlined, size: 22),
                            ),
                            IconButton(
                              key: Key('finance-upcoming-delete-${item.id}'),
                              tooltip: 'Xóa',
                              onPressed: () => onDelete(item),
                              icon: Icon(
                                Icons.delete_outline,
                                size: 22,
                                color: AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringEditorSheet extends StatefulWidget {
  const _RecurringEditorSheet({
    required this.clock,
    required this.lockedKind,
    required this.createTitle,
    required this.editTitle,
    required this.nameHint,
    this.rule,
  });

  final RecurringTransaction? rule;
  final DateTime Function() clock;
  final RecurringKind lockedKind;
  final String createTitle;
  final String editTitle;
  final String nameHint;

  @override
  State<_RecurringEditorSheet> createState() => _RecurringEditorSheetState();
}

class _RecurringEditorSheetState extends State<_RecurringEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DateTime _dueDate;
  String? _categoryId;
  String? _paymentSourceId;
  late bool _isActive;
  String? _error;

  bool get _isExpense => widget.lockedKind == RecurringKind.expense;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _name = TextEditingController(text: rule?.name ?? '');
    _amount = TextEditingController(
      text: rule == null ? '' : AmountInput.formatGrouped(rule.amount),
    );
    _note = TextEditingController(text: rule?.note ?? '');
    _dueDate = dateOnly(rule?.startDate ?? widget.clock());
    _categoryId = rule?.categoryId;
    _paymentSourceId = rule?.paymentSourceId;
    _isActive = rule?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _groupAmount(String raw) {
    final formatted = AmountInput.formatGrouped(AmountInput.parse(raw));
    if (_amount.text != formatted) {
      _amount.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(_dueDate.year - 5),
      lastDate: DateTime(_dueDate.year + 1),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dueDate = dateOnly(picked);
      _error = null;
    });
  }

  void _save() {
    final title = _name.text.trim();
    final amount = AmountInput.parse(_amount.text);
    if (title.isEmpty || amount <= 0) {
      setState(() => _error = 'Nhập tên, số tiền và ngày.');
      return;
    }
    Navigator.pop(
      context,
      RecurringDraft(
        name: title,
        kind: widget.lockedKind,
        amount: amount,
        dayOfMonth: _dueDate.day,
        categoryId: _isExpense ? _categoryId : null,
        paymentSourceId: _paymentSourceId,
        note: _note.text,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.rule == null ? widget.createTitle : widget.editTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tên khoản',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              TextField(
                key: const Key('upcoming-name-input'),
                controller: _name,
                decoration: InputDecoration(hintText: widget.nameHint),
              ),
              const SizedBox(height: 12),
              const Text(
                'Số tiền (₫)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              TextField(
                key: const Key('upcoming-amount-input'),
                controller: _amount,
                keyboardType: TextInputType.number,
                onChanged: _groupAmount,
              ),
              const SizedBox(height: 12),
              const Text(
                'Ngày',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(height: 6),
              _DueDateButton(
                key: const Key('upcoming-due-input'),
                label: formatIsoDate(_dueDate),
                onTap: _pickDueDate,
                trailing: Icons.calendar_today_outlined,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('upcoming-save'),
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    textStyle: AppTypography.button(),
                  ),
                  child: const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueDateButton extends StatelessWidget {
  const _DueDateButton({
    super.key,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (trailing != null)
                  Icon(trailing, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
