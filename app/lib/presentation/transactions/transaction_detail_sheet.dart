import 'package:flutter/material.dart';

import '../../application/add_transaction_draft.dart';
import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';
import '../../domain/transaction_display.dart';
import '../add_transaction/add_transaction_controller.dart';
import '../add_transaction/add_transaction_page.dart';
import '../format/money_format.dart';
import '../theme/app_colors.dart';
import '../theme/category_look.dart';
import 'transaction_detail_controller.dart';

class TransactionDetailSheet extends StatefulWidget {
  const TransactionDetailSheet({
    super.key,
    required this.controller,
    required this.transactionService,
    required this.clock,
    this.transactionId,
  });

  final TransactionDetailController controller;
  final TransactionService transactionService;
  final DateTime Function() clock;
  final String? transactionId;

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  @override
  void initState() {
    super.initState();
    final id = widget.transactionId;
    if (id != null) {
      widget.controller.load(id);
    }
  }

  Future<void> _delete() async {
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
    if (confirmed != true || !mounted) return;
    final result = await widget.controller.delete();
    if (!mounted) return;
    if (result is Ok) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _edit(Transaction tx) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddTransactionPage(
          controller: AddTransactionController(
            service: widget.transactionService,
            clock: widget.clock,
            existing: tx,
            draft: AddTransactionDraft.fromTransaction(tx),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Chi tiết',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('btn-close-detail'),
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (c.loading)
                  Expanded(
                    child: Center(
                      child: SizedBox.square(
                        dimension: 32,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  )
                else if (c.error != null && c.transaction == null)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          c.error!,
                          key: const Key('detail-error'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.expense,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (c.transaction != null) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _BodyContent(
                        transaction: c.transaction!,
                        error: c.error,
                      ),
                    ),
                  ),
                  _ActionFooter(
                    onDelete: _delete,
                    onEdit: () => _edit(c.transaction!),
                  ),
                ],
              ],
            ),
        );
      },
    );
  }
}

class _BodyContent extends StatelessWidget {
  const _BodyContent({
    required this.transaction,
    this.error,
  });

  final Transaction transaction;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(transaction.categoryId);
    final date = formatIsoDate(transaction.occurredOn);
    final time = transaction.occurredTime ?? '';
    return Column(
      children: [
        Text(
          '−${formatVnd(transaction.amount)}',
          style: moneyStyle(size: 32, color: AppColors.expense),
        ),
        const SizedBox(height: 4),
        Text(
          transactionTitle(transaction),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 20),
        _Row(label: 'Chi cho', value: look.name),
        _Row(label: 'Chi tiết', value: _orDash(transaction.detail)),
        _Row(label: 'Thanh toán', value: _orDash(transaction.paymentSourceName)),
        _Row(label: 'Ngày', value: time.isEmpty ? date : '$date · $time'),
        _Row(label: 'Ghi chú', value: _orDash(transaction.note)),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: TextStyle(color: AppColors.expense)),
        ],
      ],
    );
  }

  String _orDash(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '—';
    return trimmed;
  }
}

class _ActionFooter extends StatelessWidget {
  const _ActionFooter({
    required this.onDelete,
    required this.onEdit,
  });

  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('btn-detail-delete'),
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: BorderSide(color: AppColors.divider),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              key: const Key('btn-detail-edit'),
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: const Text('Sửa', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
