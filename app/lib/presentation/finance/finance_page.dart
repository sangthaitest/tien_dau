import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/amount/amount_input.dart';
import '../../domain/entities/finance.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/failures/result.dart';
import '../format/money_format.dart';
import '../settings/settings_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_dialog.dart';
import '../theme/app_progress.dart';
import '../theme/app_typography.dart';
import 'finance_controller.dart';
import 'recurring_section.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({
    super.key,
    required this.controller,
    required this.onBack,
    this.onOpenTransactions,
  });

  final FinanceController controller;
  final VoidCallback onBack;
  final VoidCallback? onOpenTransactions;

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
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: controller.loading
                    ? const Center(child: AppCircularProgress())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                        children: [
                          if (controller.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                controller.error!,
                                style: TextStyle(color: AppColors.expense),
                              ),
                            ),
                          _IncomeCard(
                            month: snap.month,
                            amount: snap.recurringIncomeTotal,
                            onManage: () => showRecurringManager(
                              context: context,
                              controller: controller,
                              kind: RecurringKind.income,
                            ),
                          ),
                          const _FlowConnector(
                            symbol: '−',
                            label: 'Trừ khoản định kỳ',
                          ),
                          RecurringSection(controller: controller),
                          const _FlowConnector(symbol: '='),
                          _SpendableCard(amount: snap.spendableAmount),
                          const _FlowConnector(
                            symbol: '−',
                            label: 'Trừ chi tiêu',
                          ),
                          _SpentCard(
                            amount: snap.used,
                            onTap: onOpenTransactions,
                          ),
                          const _FlowConnector(symbol: '='),
                          _RemainingCard(amount: snap.projectedRemaining),
                          const SizedBox(height: 28),
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

  Future<void> _deleteGoal(BuildContext context, SavingsGoal goal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa mục tiêu?'),
        content: const Text('Bạn có chắc muốn xóa mục tiêu này?'),
        actions: [
          AppDialog.cancel(onPressed: () => Navigator.pop(context, false)),
          AppDialog.confirm(
            onPressed: () => Navigator.pop(context, true),
            label: 'Xác nhận',
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

class _FlowConnector extends StatelessWidget {
  const _FlowConnector({required this.symbol, this.label});

  final String symbol;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Column(
            children: [
              Container(width: 2, height: 10, color: AppColors.divider),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    height: 1,
                  ),
                ),
              ),
              Container(width: 2, height: 10, color: AppColors.divider),
            ],
          ),
          if (label != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FinanceBadge extends StatelessWidget {
  const _FinanceBadge({
    required this.icon,
    required this.foreground,
    required this.background,
    this.outlined = false,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: outlined
            ? Border.all(color: foreground.withValues(alpha: 0.35))
            : null,
      ),
      child: Icon(icon, size: 22, color: foreground),
    );
  }
}

class _ManageLink extends StatelessWidget {
  const _ManageLink({required this.onPressed, this.keyId});

  final VoidCallback onPressed;
  final Key? keyId;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: keyId,
      onPressed: onPressed,
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
    );
  }
}

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({
    required this.month,
    required this.amount,
    required this.onManage,
  });

  final DateTime month;
  final int amount;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('finance-income-card'),
        onTap: onManage,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FinanceBadge(
                    icon: Icons.account_balance_wallet_outlined,
                    foreground: AppColors.income,
                    background: AppColors.incomeContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thu nhập',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tháng ${month.month}/${month.year}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ManageLink(
                    keyId: const Key('finance-income-manage'),
                    onPressed: onManage,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Text(
                  displayVnd(amount, hidden: hidden),
                  key: const Key('salary-amount'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: moneyStyle(
                    size: 24,
                    color: AppColors.income,
                    weight: FontWeight.w800,
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

class _SpendableCard extends StatelessWidget {
  const _SpendableCard({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    return Container(
      key: const Key('finance-spendable-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FinanceBadge(
                icon: Icons.credit_card,
                foreground: AppColors.primary,
                background: AppColors.card,
                outlined: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiền có thể chi',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '(Thu nhập - Khoản định kỳ)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Text(
              displayVnd(amount, hidden: hidden),
              key: const Key('finance-spendable-amount'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: moneyStyle(
                size: 24,
                color: AppColors.primary,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpentCard extends StatelessWidget {
  const _SpentCard({required this.amount, this.onTap});

  final int amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    const basket = Color(0xFF3B6FE8);
    const basketBg = Color(0xFFE8EEFF);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('finance-spent-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
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
          child: Row(
            children: [
              const _FinanceBadge(
                icon: Icons.shopping_basket_outlined,
                foreground: basket,
                background: basketBg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đã chi tiêu',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Trong tháng',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                displayVnd(amount, hidden: hidden),
                key: const Key('finance-spent-amount'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: moneyStyle(
                  size: 18,
                  color: AppColors.text,
                  weight: FontWeight.w800,
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemainingCard extends StatelessWidget {
  const _RemainingCard({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    final positive = amount >= 0;
    final accent = positive ? AppColors.warning : AppColors.expense;
    final bg = positive
        ? AppColors.warningContainer
        : AppColors.expenseContainer;
    return Container(
      key: const Key('finance-remaining-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FinanceBadge(
                icon: Icons.savings_outlined,
                foreground: accent,
                background: AppColors.card,
                outlined: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Còn lại',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '(Tiền có thể chi - Đã chi tiêu)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Text(
              displayVnd(amount, hidden: hidden),
              key: const Key('finance-remaining-amount'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: moneyStyle(
                size: 24,
                color: accent,
                weight: FontWeight.w800,
              ),
            ),
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
                  fontSize: 18,
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
          AppLinearProgress(value: goal.progressPercent / 100),
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
