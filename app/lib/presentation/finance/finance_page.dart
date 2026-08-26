import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/finance_service.dart';
import '../../domain/amount/amount_input.dart';
import '../../domain/entities/finance.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/failures/result.dart';
import '../format/money_format.dart';
import '../settings/settings_scope.dart';
import '../theme/app_colors.dart';
import 'finance_controller.dart';
import 'recurring_section.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final FinanceController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final snap = controller.snapshot;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  8,
                  MediaQuery.paddingOf(context).top + 4,
                  8,
                  8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('finance-back'),
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: Text(
                        'Tài chính',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('btn-edit-budget'),
                      onPressed: () => _editBudget(context),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: controller.loading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                        children: [
                          if (controller.error != null)
                            Text(
                              controller.error!,
                              style: TextStyle(color: AppColors.expense),
                            ),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Thu nhập',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const Key('finance-income-manage'),
                                onPressed: () => showRecurringManager(
                                  context: context,
                                  controller: controller,
                                  kind: RecurringKind.income,
                                ),
                                child: Text(
                                  'Quản lý →',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Lương · Tháng ${snap.month.month}/${snap.month.year}',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      key: const Key('btn-edit-salary'),
                                      onTap: () => _editSalary(context),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          10,
                                          4,
                                          10,
                                        ),
                                        child: Text(
                                          'Sửa',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  displayVnd(
                                    snap.salary,
                                    hidden: SettingsScope.hideMoney(context),
                                  ),
                                  key: const Key('salary-amount'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: moneyStyle(
                                    size: 22,
                                    color: AppColors.income,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BudgetCard(snapshot: snap),
                          const SizedBox(height: 20),
                          RecurringSection(controller: controller),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Mục tiêu tiết kiệm',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const Key('btn-create-goal'),
                                onPressed: () =>
                                    _goalSheet(context, mode: _GoalMode.create),
                                child: Text(
                                  'Quản lý →',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (snap.goals.isEmpty)
                            Text(
                              'Chưa có mục tiêu. Tạo một mục tiêu nhỏ để bắt đầu.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            )
                          else
                            for (final goal in snap.goals)
                              _GoalCard(
                                goal: goal,
                                onAdd: () => _goalSheet(
                                  context,
                                  mode: _GoalMode.addMoney,
                                  goal: goal,
                                ),
                                onEdit: () => _goalSheet(
                                  context,
                                  mode: _GoalMode.edit,
                                  goal: goal,
                                ),
                                onDelete: () => _deleteGoal(context, goal),
                              ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editSalary(BuildContext context) async {
    final amount = await _amountDialog(
      context,
      title: 'Lương tháng',
      label: 'Số tiền lương (₫)',
      initial: controller.snapshot.salary,
    );
    if (amount == null) return;
    final result = await controller.saveSalary(amount);
    if (context.mounted && result is Err) {
      _toast(context, result.failure.message);
    }
  }

  Future<void> _editBudget(BuildContext context) async {
    final amount = await _amountDialog(
      context,
      title: 'Đặt ngân sách tháng',
      label: 'Hạn mức tháng (₫)',
      initial: controller.snapshot.budgetLimit,
    );
    if (amount == null) return;
    final result = await controller.saveBudget(amount);
    if (context.mounted && result is Err) {
      _toast(context, result.failure.message);
    }
  }

  Future<void> _deleteGoal(BuildContext context, SavingsGoal goal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa mục tiêu?'),
        content: const Text('Bạn có chắc muốn xóa mục tiêu này?'),
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
    if (ok == true) await controller.deleteGoal(goal.id);
  }

  Future<void> _goalSheet(
    BuildContext context, {
    required _GoalMode mode,
    SavingsGoal? goal,
  }) async {
    final result = await showModalBottomSheet<_GoalDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _GoalSheet(mode: mode, goal: goal),
    );
    if (result == null) return;
    final save = switch (mode) {
      _GoalMode.create => controller.createGoal(
        name: result.name,
        targetAmount: result.target,
        currentAmount: result.current,
      ),
      _GoalMode.edit => controller.updateGoal(
        goal!.copyWith(
          name: result.name,
          targetAmount: result.target,
          currentAmount: result.current,
        ),
      ),
      _GoalMode.addMoney => controller.addToGoal(goal!, result.current),
    };
    final saved = await save;
    if (context.mounted && saved is Err) {
      _toast(context, saved.failure.message);
    }
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _groupAmountField(TextEditingController field, String raw) {
  final formatted = AmountInput.formatGrouped(AmountInput.parse(raw));
  if (field.text != formatted) {
    field.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Future<int?> _amountDialog(
  BuildContext context, {
  required String title,
  required String label,
  required int initial,
}) {
  final field = TextEditingController(text: AmountInput.formatGrouped(initial));
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final inset = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('finance-amount-input'),
                  controller: field,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (raw) => _groupAmountField(field, raw),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    key: const Key('finance-amount-save'),
                    onPressed: () =>
                        Navigator.pop(context, AmountInput.parse(field.text)),
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
    },
  );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.snapshot});
  final FinanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final pct = snapshot.percentUsed;
    Color fill = Colors.white;
    if (pct >= 90) {
      fill = AppColors.expense;
    } else if (pct >= 75) {
      fill = AppColors.warning;
    }
    final remainingPct = snapshot.budgetLimit <= 0
        ? 0
        : ((snapshot.remaining / snapshot.budgetLimit) * 100).round().clamp(
            0,
            100,
          );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B67A), Color(0xFF009963)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ngân sách tháng',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayVnd(
              snapshot.budgetLimit,
              hidden: SettingsScope.hideMoney(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: moneyStyle(size: 24),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: snapshot.budgetLimit <= 0 ? 0 : (pct / 100).clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.white24,
              color: fill,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.budgetLimit > 0 ? 'Đã dùng · $pct%' : 'Đã dùng',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      displayVnd(
                        snapshot.used,
                        hidden: SettingsScope.hideMoney(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: moneyStyle(size: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      snapshot.budgetLimit > 0
                          ? 'Còn lại · $remainingPct%'
                          : 'Còn lại',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      displayVnd(
                        snapshot.remaining,
                        hidden: SettingsScope.hideMoney(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: moneyStyle(size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _GoalMode { create, edit, addMoney }

class _GoalDraft {
  const _GoalDraft({
    required this.name,
    required this.target,
    required this.current,
  });
  final String name;
  final int target;
  final int current;
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({required this.mode, this.goal});
  final _GoalMode mode;
  final SavingsGoal? goal;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final TextEditingController name;
  late final TextEditingController target;
  late final TextEditingController current;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    name = TextEditingController(text: g?.name ?? '');
    target = TextEditingController(
      text: AmountInput.formatGrouped(g?.targetAmount ?? 0),
    );
    current = TextEditingController(
      text: widget.mode == _GoalMode.addMoney
          ? ''
          : AmountInput.formatGrouped(g?.currentAmount ?? 0),
    );
  }

  @override
  void dispose() {
    name.dispose();
    target.dispose();
    current.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final title = switch (widget.mode) {
      _GoalMode.create => 'Tạo mục tiêu',
      _GoalMode.edit => 'Sửa mục tiêu',
      _GoalMode.addMoney => 'Thêm tiền',
    };
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
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.mode != _GoalMode.addMoney) ...[
                const SizedBox(height: 12),
                const Text(
                  'Tên mục tiêu',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                TextField(
                  key: const Key('goal-name-input'),
                  controller: name,
                  decoration: const InputDecoration(
                    hintText: 'VD: Quỹ khẩn cấp',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mục tiêu (₫)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                TextField(
                  key: const Key('goal-target-input'),
                  controller: target,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (raw) => _groupAmountField(target, raw),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                widget.mode == _GoalMode.addMoney
                    ? 'Số tiền thêm (₫)'
                    : 'Số hiện có (₫)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              TextField(
                key: const Key('goal-current-input'),
                controller: current,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (raw) => _groupAmountField(current, raw),
              ),
              if (widget.mode != _GoalMode.addMoney)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Không trừ vào số dư — chỉ theo dõi tiến độ.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('goal-save'),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _GoalDraft(
                        name: name.text,
                        target: AmountInput.parse(target.text),
                        current: AmountInput.parse(current.text),
                      ),
                    );
                  },
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

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Mục tiêu ${displayVnd(goal.targetAmount, hidden: hidden)} · ${goal.progressPercent}%',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: goal.progressPercent / 100,
            minHeight: 8,
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceVariant,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                displayVnd(goal.currentAmount, hidden: hidden),
                style: moneyStyle(size: 12, color: AppColors.income),
              ),
              const Spacer(),
              Text(
                'còn ${displayVnd(goal.remaining, hidden: hidden)}',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: onAdd, child: const Text('Thêm tiền')),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
