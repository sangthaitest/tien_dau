import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/finance_service.dart';
import '../../domain/amount/amount_input.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/failures/result.dart';
import '../format/money_format.dart';
import '../settings/settings_scope.dart';
import '../theme/app_colors.dart';
import '../theme/category_look.dart';
import 'finance_controller.dart';

String _dueFieldText(int day, DateTime month) {
  final dd = day.toString().padLeft(2, '0');
  final mm = month.month.toString().padLeft(2, '0');
  return '$dd/$mm';
}

int? _parseDueDay(String raw) {
  final match = RegExp(r'(\d{1,2})').firstMatch(raw.trim());
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  if (day < 1 || day > 31) return null;
  return day;
}

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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _RecurringManager(
        workspace: this,
        onAdd: () => openEditor(context),
        onEdit: (rule) => openEditor(context, rule: rule),
        onDelete: (rule) => delete(context, rule),
      ),
    );
  }

  Future<void> openEditor(
    BuildContext context, {
    RecurringTransaction? rule,
  }) async {
    final draft = await showModalBottomSheet<RecurringDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _RecurringEditorSheet(
        rule: rule,
        month: controller.snapshot.month,
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
      builder: (context) => AlertDialog(
        title: Text(isIncome ? 'Xóa khoản thu nhập?' : 'Xóa khoản định kỳ?'),
        content: Text('Bạn có chắc muốn xóa “${rule.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            key: const Key('finance-upcoming-confirm-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
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
    return Column(
      key: const Key('finance-upcoming-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        size: 22,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Khoản định kỳ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('finance-upcoming-manage'),
                      onPressed: () => RecurringWorkspace(
                        controller: controller,
                        kind: RecurringKind.expense,
                      ).openManager(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Quản lý →',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (snap.managedRecurring.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  child: Text(
                    'Chưa có khoản định kỳ. Quản lý để thêm.',
                    key: const Key('finance-upcoming-empty'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  child: Text(
                    'Không có khoản định kỳ trong tháng này.',
                    key: const Key('finance-upcoming-empty'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppColors.divider),
                  _RecurringRow(
                    rule: items[i],
                    month: snap.month,
                    onTap: () => _openDetail(context, items[i]),
                  ),
                ],
              if (items.isNotEmpty) ...[
                Divider(height: 1, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tổng định kỳ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            displayVnd(
                              snap.recurringExpenseTotal,
                              hidden: SettingsScope.hideMoney(context),
                            ),
                            key: const Key('finance-upcoming-total'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: moneyStyle(size: 16, color: AppColors.text),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${items.where((item) => item.kind == RecurringKind.expense).length} khoản',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
                          _expenses.openEditor(context, rule: item);
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
                          _expenses.delete(context, item);
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

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.rule,
    required this.month,
    required this.onTap,
  });

  final RecurringTransaction rule;
  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    return InkWell(
      key: Key('finance-upcoming-row-${rule.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            _RecurringIcon(rule: rule),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rule.dueLabelForMonth(month),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayVnd(rule.amount, hidden: hidden),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: moneyStyle(size: 15, color: AppColors.text),
            ),
          ],
        ),
      ),
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
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Text(
                        'Chưa có khoản. Nhấn + để thêm.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }
                  return ListView.builder(
                    key: workspace.manageSheetKey,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return ListTile(
                        key: workspace.managedItemKey(item.id),
                        contentPadding: EdgeInsets.zero,
                        leading: _RecurringIcon(rule: item),
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.dueLabelForMonth(controller.snapshot.month)} · ${displayVnd(item.amount, hidden: hidden)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: Key('finance-upcoming-edit-${item.id}'),
                              tooltip: 'Sửa',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => onEdit(item),
                              icon: const Icon(Icons.edit_outlined, size: 20),
                            ),
                            IconButton(
                              key: Key('finance-upcoming-delete-${item.id}'),
                              tooltip: 'Xóa',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => onDelete(item),
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
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
    required this.month,
    required this.lockedKind,
    required this.createTitle,
    required this.editTitle,
    required this.nameHint,
    this.rule,
  });

  final RecurringTransaction? rule;
  final DateTime month;
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
  late final TextEditingController _due;
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
    _due = TextEditingController(
      text: rule == null ? '' : _dueFieldText(rule.dayOfMonth, widget.month),
    );
    _categoryId = rule?.categoryId;
    _paymentSourceId = rule?.paymentSourceId;
    _isActive = rule?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    _due.dispose();
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

  void _save() {
    final title = _name.text.trim();
    final amount = AmountInput.parse(_amount.text);
    final day = _parseDueDay(_due.text);
    if (title.isEmpty || amount <= 0 || day == null) {
      setState(() => _error = 'Nhập tên, số tiền và ngày.');
      return;
    }
    Navigator.pop(
      context,
      RecurringDraft(
        name: title,
        kind: widget.lockedKind,
        amount: amount,
        dayOfMonth: day,
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
                  fontSize: 17,
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _groupAmount,
              ),
              const SizedBox(height: 12),
              const Text(
                'Ngày',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              TextField(
                key: const Key('upcoming-due-input'),
                controller: _due,
                decoration: const InputDecoration(hintText: 'VD: 25/08'),
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
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
