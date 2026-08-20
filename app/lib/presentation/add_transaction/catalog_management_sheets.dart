import 'package:flutter/material.dart';

import '../../domain/catalog/chi_cho_catalog.dart';
import '../../domain/catalog/payment_option_catalog.dart';
import '../../domain/entities/payment_method_kind.dart';
import '../../domain/failures/result.dart';
import '../catalog/transaction_catalog_controller.dart';
import '../theme/app_colors.dart';
import '../theme/category_look.dart';

Future<void> showCategoryManager(
  BuildContext context,
  TransactionCatalogController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _CategoryManager(controller: controller),
  );
}

Future<void> showDetailManager(
  BuildContext context,
  TransactionCatalogController controller, {
  required String categoryId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _DetailManager(controller: controller, categoryId: categoryId),
  );
}

Future<void> showPaymentManager(
  BuildContext context,
  TransactionCatalogController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PaymentManager(controller: controller),
  );
}

class _CategoryManager extends StatelessWidget {
  const _CategoryManager({required this.controller});

  final TransactionCatalogController controller;

  Future<void> _edit(BuildContext context, [ChiChoCategory? category]) async {
    final value = await _showCategoryEditor(context, category);
    if (value == null || !context.mounted) return;
    final result = category == null
        ? await controller.addCategory(
            name: value.name,
            visualKey: value.visualKey,
          )
        : await controller.updateCategory(
            id: category.id,
            name: value.name,
            visualKey: value.visualKey,
          );
    if (context.mounted) _showResultError(context, result);
  }

  Future<void> _delete(BuildContext context, ChiChoCategory category) async {
    if (!await _confirmDelete(context, category.name) || !context.mounted) {
      return;
    }
    final result = await controller.archiveCategory(category.id);
    if (context.mounted) _showResultError(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return _ManagerShell(
      title: 'Quản lý khoản chi',
      addKey: const Key('add-category'),
      onAdd: () => _edit(context),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final categories = controller.categories;
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            buildDefaultDragHandles: false,
            itemCount: categories.length,
            onReorder: controller.reorderCategories,
            itemBuilder: (context, index) {
              final category = categories[index];
              final look = categoryLook(
                category.id,
                name: category.name,
                visualKey: category.visualKey,
              );
              return ListTile(
                key: Key('managed-category-${category.id}'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 84,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DragHandle(index: index),
                    const SizedBox(width: 4),
                    _LookIcon(look: look),
                  ],
                ),
                title: Text(category.name),
                subtitle: Text('${category.details.length} chi tiết'),
                trailing: _RowActions(
                  editKey: Key('edit-category-${category.id}'),
                  deleteKey: Key('delete-category-${category.id}'),
                  onEdit: () => _edit(context, category),
                  onDelete: () => _delete(context, category),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailManager extends StatelessWidget {
  const _DetailManager({required this.controller, required this.categoryId});

  final TransactionCatalogController controller;
  final String categoryId;

  Future<void> _edit(BuildContext context, [String? current]) async {
    final value = await _showNameEditor(
      context,
      title: current == null ? 'Thêm chi tiết' : 'Sửa chi tiết',
      initialValue: current ?? '',
      inputKey: const Key('detail-name-input'),
    );
    if (value == null || !context.mounted) return;
    final result = current == null
        ? await controller.addDetail(categoryId: categoryId, name: value)
        : await controller.updateDetail(
            categoryId: categoryId,
            oldName: current,
            newName: value,
          );
    if (context.mounted) _showResultError(context, result);
  }

  Future<void> _delete(BuildContext context, String detail) async {
    if (!await _confirmDelete(context, detail) || !context.mounted) return;
    final result = await controller.deleteDetail(
      categoryId: categoryId,
      name: detail,
    );
    if (context.mounted) _showResultError(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final category = controller.categoryById(categoryId);
        return _ManagerShell(
          title: 'Chi tiết · ${category?.name ?? ''}',
          addKey: const Key('add-detail'),
          onAdd: () => _edit(context),
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            buildDefaultDragHandles: false,
            itemCount: category?.details.length ?? 0,
            onReorder: (oldIndex, newIndex) {
              controller.reorderDetails(
                categoryId: categoryId,
                oldIndex: oldIndex,
                newIndex: newIndex,
              );
            },
            itemBuilder: (context, index) {
              final detail = category!.details[index];
              return ListTile(
                key: Key('managed-detail-$detail'),
                contentPadding: EdgeInsets.zero,
                leading: _DragHandle(index: index),
                title: Text(detail),
                trailing: _RowActions(
                  editKey: Key('edit-detail-$detail'),
                  deleteKey: Key('delete-detail-$detail'),
                  onEdit: () => _edit(context, detail),
                  onDelete: () => _delete(context, detail),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PaymentManager extends StatelessWidget {
  const _PaymentManager({required this.controller});

  final TransactionCatalogController controller;

  Future<void> _edit(BuildContext context, [PaymentOption? payment]) async {
    final value = await _showPaymentEditor(context, payment);
    if (value == null || !context.mounted) return;
    final result = payment == null
        ? await controller.addPayment(
            name: value.name,
            method: value.method,
            typeLabel: paymentTypeLabel(value.method),
          )
        : await controller.updatePayment(
            id: payment.source.id,
            name: value.name,
            method: value.method,
            typeLabel: paymentTypeLabel(value.method),
          );
    if (context.mounted) _showResultError(context, result);
  }

  Future<void> _delete(BuildContext context, PaymentOption payment) async {
    if (!await _confirmDelete(context, payment.source.name) ||
        !context.mounted) {
      return;
    }
    final result = await controller.archivePayment(payment.source.id);
    if (context.mounted) _showResultError(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return _ManagerShell(
      title: 'Phương thức thanh toán',
      addKey: const Key('add-payment'),
      onAdd: () => _edit(context),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final payments = controller.payments;
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            buildDefaultDragHandles: false,
            itemCount: payments.length,
            onReorder: controller.reorderPayments,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return ListTile(
                key: Key('managed-payment-${payment.source.id}'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 84,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DragHandle(index: index),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.primary,
                      child: Icon(_paymentIcon(payment.source.method), size: 20),
                    ),
                  ],
                ),
                title: Text(payment.source.name),
                subtitle: Text(payment.typeLabel),
                trailing: _RowActions(
                  editKey: Key('edit-payment-${payment.source.id}'),
                  deleteKey: Key('delete-payment-${payment.source.id}'),
                  onEdit: () => _edit(context, payment),
                  onDelete: () => _delete(context, payment),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ManagerShell extends StatelessWidget {
  const _ManagerShell({
    required this.title,
    required this.addKey,
    required this.onAdd,
    required this.child,
  });

  final String title;
  final Key addKey;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: addKey,
                    tooltip: 'Thêm',
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.divider),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(Icons.drag_handle, color: AppColors.textTertiary),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.editKey,
    required this.deleteKey,
    required this.onEdit,
    required this.onDelete,
  });

  final Key editKey;
  final Key deleteKey;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: editKey,
          tooltip: 'Sửa',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 20),
        ),
        IconButton(
          key: deleteKey,
          tooltip: 'Xóa',
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, size: 20, color: AppColors.expense),
        ),
      ],
    );
  }
}

class _LookIcon extends StatelessWidget {
  const _LookIcon({required this.look});
  final CategoryLook look;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: look.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(look.icon, color: look.color, size: 22),
    );
  }
}

typedef _CategoryEditorValue = ({String name, String visualKey});
typedef _PaymentEditorValue = ({String name, PaymentMethodKind method});

Future<_CategoryEditorValue?> _showCategoryEditor(
  BuildContext context,
  ChiChoCategory? category,
) {
  var name = category?.name ?? '';
  var visualKey = category?.visualKey ?? categoryVisualKeys.first;
  return showModalBottomSheet<_CategoryEditorValue>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => _EditorBody(
        title: category == null ? 'Thêm khoản chi' : 'Sửa khoản chi',
        children: [
          TextFormField(
            key: const Key('category-name-input'),
            initialValue: name,
            onChanged: (value) => name = value,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Tên khoản chi'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Biểu tượng',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final key in categoryVisualKeys)
                _VisualChoice(
                  visualKey: key,
                  selected: visualKey == key,
                  onTap: () => setState(() => visualKey = key),
                ),
            ],
          ),
        ],
        onSave: () {
          Navigator.pop(context, (name: name, visualKey: visualKey));
        },
      ),
    ),
  );
}

Future<String?> _showNameEditor(
  BuildContext context, {
  required String title,
  required String initialValue,
  required Key inputKey,
}) {
  var name = initialValue;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _EditorBody(
      title: title,
      children: [
        TextFormField(
          key: inputKey,
          initialValue: name,
          onChanged: (value) => name = value,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Tên chi tiết'),
        ),
      ],
      onSave: () => Navigator.pop(context, name),
    ),
  );
}

Future<_PaymentEditorValue?> _showPaymentEditor(
  BuildContext context,
  PaymentOption? payment,
) {
  var name = payment?.source.name ?? '';
  var method = payment?.source.method ?? PaymentMethodKind.cash;
  return showModalBottomSheet<_PaymentEditorValue>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => _EditorBody(
        title: payment == null ? 'Thêm phương thức' : 'Sửa phương thức',
        children: [
          TextFormField(
            key: const Key('payment-name-input'),
            initialValue: name,
            onChanged: (value) => name = value,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Tên phương thức'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<PaymentMethodKind>(
            key: const Key('payment-type-input'),
            initialValue: method,
            decoration: const InputDecoration(labelText: 'Loại'),
            items: [
              for (final value in PaymentMethodKind.values)
                DropdownMenuItem(
                  value: value,
                  child: Text(paymentTypeLabel(value)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => method = value);
            },
          ),
        ],
        onSave: () {
          Navigator.pop(context, (name: name, method: method));
        },
      ),
    ),
  );
}

class _EditorBody extends StatelessWidget {
  const _EditorBody({
    required this.title,
    required this.children,
    required this.onSave,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              ...children,
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('save-catalog-item'),
                onPressed: onSave,
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisualChoice extends StatelessWidget {
  const _VisualChoice({
    required this.visualKey,
    required this.selected,
    required this.onTap,
  });

  final String visualKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(visualKey);
    return Material(
      color: selected ? AppColors.primaryContainer : look.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('visual-$visualKey'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(look.icon, color: look.color),
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xóa mục này?'),
      content: Text(
        '“$name” sẽ không còn xuất hiện khi thêm giao dịch mới. '
        'Các giao dịch đã lưu vẫn được giữ nguyên.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

void _showResultError(BuildContext context, Result<void> result) {
  if (result case Err(:final failure)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }
}

String paymentTypeLabel(PaymentMethodKind method) {
  return switch (method) {
    PaymentMethodKind.cash => 'Tiền mặt',
    PaymentMethodKind.bankAccount => 'Tài khoản ngân hàng',
    PaymentMethodKind.eWallet => 'Ví điện tử',
    PaymentMethodKind.creditCard => 'Thẻ tín dụng',
    PaymentMethodKind.debitCard => 'Thẻ ghi nợ',
    PaymentMethodKind.other => 'Khác',
  };
}

IconData _paymentIcon(PaymentMethodKind method) {
  return switch (method) {
    PaymentMethodKind.cash => Icons.payments_outlined,
    PaymentMethodKind.bankAccount => Icons.account_balance_outlined,
    PaymentMethodKind.eWallet => Icons.account_balance_wallet_outlined,
    PaymentMethodKind.creditCard ||
    PaymentMethodKind.debitCard => Icons.credit_card_outlined,
    PaymentMethodKind.other => Icons.more_horiz,
  };
}
