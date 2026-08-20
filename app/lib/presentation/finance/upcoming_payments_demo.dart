import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/amount/amount_input.dart';
import '../../domain/catalog/list_order.dart';
import '../format/money_format.dart';
import '../settings/settings_scope.dart';
import '../theme/app_colors.dart';

/// In-memory UX prototype only. Not persisted and not part of finance domain.
const demoCashOnHand = 20000000;
const demoSpentThisMonth = 4626157;

class DemoUpcomingPayment {
  const DemoUpcomingPayment({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueLabel,
    required this.icon,
  });

  final String id;
  final String title;
  final int amount;
  final String dueLabel;
  final IconData icon;

  DemoUpcomingPayment copyWith({
    String? title,
    int? amount,
    String? dueLabel,
    IconData? icon,
  }) {
    return DemoUpcomingPayment(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueLabel: dueLabel ?? this.dueLabel,
      icon: icon ?? this.icon,
    );
  }
}

List<DemoUpcomingPayment> seedDemoUpcomingPayments() => [
      const DemoUpcomingPayment(
        id: 'card',
        title: 'Thẻ tín dụng',
        amount: 5000000,
        dueLabel: 'Ngày 25/08',
        icon: Icons.credit_card,
      ),
      const DemoUpcomingPayment(
        id: 'transfer',
        title: 'Chuyển cho Minh',
        amount: 2000000,
        dueLabel: 'Ngày 28/08',
        icon: Icons.person_outline,
      ),
      const DemoUpcomingPayment(
        id: 'utility',
        title: 'Điện nước',
        amount: 500000,
        dueLabel: 'Ngày 30/08',
        icon: Icons.bolt_outlined,
      ),
    ];

int demoUpcomingTotal(Iterable<DemoUpcomingPayment> items) {
  return items.fold<int>(0, (sum, item) => sum + item.amount);
}

int demoExpectedRemaining(int upcomingTotal) {
  return demoCashOnHand - demoSpentThisMonth - upcomingTotal;
}

String stripDuePrefix(String raw) {
  final trimmed = raw.trim();
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('ngày ')) return trimmed.substring(5);
  if (lower.startsWith('hạn ')) return trimmed.substring(4);
  return trimmed;
}

String normalizeDueLabel(String raw) {
  final rest = stripDuePrefix(raw).trim();
  if (rest.isEmpty) return '';
  return 'Ngày $rest';
}

class UpcomingPaymentsDemoSection extends StatefulWidget {
  const UpcomingPaymentsDemoSection({super.key});

  @override
  State<UpcomingPaymentsDemoSection> createState() =>
      _UpcomingPaymentsDemoSectionState();
}

class _UpcomingListenable extends ChangeNotifier {
  void tick() => notifyListeners();
}

class _UpcomingPaymentsDemoSectionState
    extends State<UpcomingPaymentsDemoSection> {
  late List<DemoUpcomingPayment> _items;
  final Set<String> _paidIds = {};
  final _tick = _UpcomingListenable();
  var _nextId = 1;

  @override
  void initState() {
    super.initState();
    _items = seedDemoUpcomingPayments();
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  void _notify() {
    setState(() {});
    _tick.tick();
  }

  bool _isPaid(String id) => _paidIds.contains(id);

  List<DemoUpcomingPayment> get _unpaid {
    return [
      for (final item in _items)
        if (!_isPaid(item.id)) item,
    ];
  }

  void _markPaid(String id) {
    _paidIds.add(id);
    _notify();
  }

  Future<void> _create(BuildContext context) async {
    final draft = await _openEditor(context);
    if (draft == null || !mounted) return;
    _items = [
      ..._items,
      DemoUpcomingPayment(
        id: 'custom-$_nextId',
        title: draft.title,
        amount: draft.amount,
        dueLabel: draft.dueLabel,
        icon: Icons.payments_outlined,
      ),
    ];
    _nextId += 1;
    _notify();
  }

  Future<void> _edit(BuildContext context, DemoUpcomingPayment item) async {
    final draft = await _openEditor(context, item: item);
    if (draft == null || !mounted) return;
    _items = [
      for (final current in _items)
        if (current.id == item.id)
          current.copyWith(
            title: draft.title,
            amount: draft.amount,
            dueLabel: draft.dueLabel,
          )
        else
          current,
    ];
    _notify();
  }

  Future<void> _delete(BuildContext context, DemoUpcomingPayment item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khoản định kỳ?'),
        content: Text('Bạn có chắc muốn xóa “${item.title}”?'),
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
    if (ok != true || !mounted) return;
    _items = [for (final current in _items) if (current.id != item.id) current];
    _paidIds.remove(item.id);
    _notify();
  }

  void _reorder(int oldIndex, int newIndex) {
    _items = moveAt(_items, oldIndex, adjustedReorderIndex(oldIndex, newIndex));
    _notify();
  }

  Future<void> _openManage(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _UpcomingManager(
        listenable: _tick,
        items: () => _items,
        onAdd: () => _create(context),
        onEdit: (item) => _edit(context, item),
        onDelete: (item) => _delete(context, item),
        onReorder: _reorder,
      ),
    );
  }

  Future<_UpcomingDraft?> _openEditor(
    BuildContext context, {
    DemoUpcomingPayment? item,
  }) {
    return showModalBottomSheet<_UpcomingDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _UpcomingEditorSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('finance-upcoming-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Khoản định kỳ',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            TextButton(
              key: const Key('finance-upcoming-manage'),
              onPressed: () => _openManage(context),
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
              if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
              else
                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppColors.divider),
                  _UpcomingRow(
                    item: _items[i],
                    paid: _isPaid(_items[i].id),
                    onTap: () => _openDetail(context, _items[i]),
                  ),
                ],
              if (_items.isNotEmpty) ...[
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
                              demoUpcomingTotal(_items),
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
                        '${_items.length} khoản',
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
        const SizedBox(height: 12),
        _ExpectedRemainingCard(
          amount: demoExpectedRemaining(demoUpcomingTotal(_unpaid)),
        ),
      ],
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    DemoUpcomingPayment item,
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
        final matches = [
          for (final row in _items)
            if (row.id == item.id) row,
        ];
        final current = matches.isEmpty ? item : matches.first;
        final paid = _isPaid(current.id);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              key: Key('finance-upcoming-detail-${current.id}'),
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
                  current.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayVnd(current.amount, hidden: hidden),
                  style: moneyStyle(size: 24, color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  current.dueLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  paid
                      ? 'Trạng thái: Đã thanh toán'
                      : 'Trạng thái: Chưa thanh toán',
                  key: const Key('finance-upcoming-status'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: paid ? AppColors.income : AppColors.text,
                  ),
                ),
                if (!paid) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      key: const Key('finance-upcoming-mark-paid'),
                      onPressed: () {
                        _markPaid(current.id);
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Đánh dấu đã trả',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }
}

class _UpcomingManager extends StatelessWidget {
  const _UpcomingManager({
    required this.listenable,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  final Listenable listenable;
  final List<DemoUpcomingPayment> Function() items;
  final Future<void> Function() onAdd;
  final Future<void> Function(DemoUpcomingPayment item) onEdit;
  final Future<void> Function(DemoUpcomingPayment item) onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
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
                  const Expanded(
                    child: Text(
                      'Quản lý khoản định kỳ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('finance-upcoming-add'),
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
                listenable: listenable,
                builder: (context, _) {
                  final list = items();
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Text(
                        'Chưa có khoản. Nhấn + để thêm.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }
                  return ReorderableListView.builder(
                    key: const Key('finance-upcoming-manage-sheet'),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    buildDefaultDragHandles: false,
                    itemCount: list.length,
                    onReorder: onReorder,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return ListTile(
                        key: Key('finance-upcoming-managed-${item.id}'),
                        contentPadding: EdgeInsets.zero,
                        minLeadingWidth: 84,
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                color: AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.dueLabel} · ${displayVnd(item.amount, hidden: hidden)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: Key('finance-upcoming-edit-${item.id}'),
                              tooltip: 'Sửa',
                              onPressed: () => onEdit(item),
                              icon: const Icon(Icons.edit_outlined, size: 20),
                            ),
                            IconButton(
                              key: Key('finance-upcoming-delete-${item.id}'),
                              tooltip: 'Xóa',
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

class _UpcomingDraft {
  const _UpcomingDraft({
    required this.title,
    required this.amount,
    required this.dueLabel,
  });

  final String title;
  final int amount;
  final String dueLabel;
}

class _UpcomingEditorSheet extends StatefulWidget {
  const _UpcomingEditorSheet({this.item});

  final DemoUpcomingPayment? item;

  @override
  State<_UpcomingEditorSheet> createState() => _UpcomingEditorSheetState();
}

class _UpcomingEditorSheetState extends State<_UpcomingEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _due;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.title ?? '');
    _amount = TextEditingController(
      text: AmountInput.formatGrouped(item?.amount ?? 0),
    );
    final due = item?.dueLabel ?? '';
    _due = TextEditingController(text: stripDuePrefix(due));
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
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
    final dueLabel = normalizeDueLabel(_due.text);
    if (title.isEmpty || amount <= 0 || dueLabel.isEmpty) {
      setState(() => _error = 'Nhập tên, số tiền và ngày.');
      return;
    }
    Navigator.pop(
      context,
      _UpcomingDraft(title: title, amount: amount, dueLabel: dueLabel),
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
                widget.item == null ? 'Thêm khoản định kỳ' : 'Sửa khoản định kỳ',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tên khoản',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              TextField(
                key: const Key('upcoming-name-input'),
                controller: _name,
                decoration: const InputDecoration(hintText: 'VD: Thẻ tín dụng'),
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
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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

class _ExpectedRemainingCard extends StatelessWidget {
  const _ExpectedRemainingCard({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Còn lại dự kiến',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sau khi trừ khoản đã dùng\nvà khoản định kỳ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            displayVnd(amount, hidden: hidden),
            key: const Key('finance-upcoming-expected'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: moneyStyle(size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.item,
    required this.paid,
    required this.onTap,
  });

  final DemoUpcomingPayment item;
  final bool paid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    return InkWell(
      key: Key('finance-upcoming-row-${item.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    paid ? 'Đã thanh toán' : item.dueLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: paid ? AppColors.income : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayVnd(item.amount, hidden: hidden),
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
