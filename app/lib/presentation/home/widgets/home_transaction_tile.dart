import 'package:flutter/material.dart';

import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/transaction_type.dart';
import '../../../domain/transaction_display.dart';
import '../../format/money_format.dart';
import '../../settings/settings_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/category_look.dart';

class HomeTransactionTile extends StatelessWidget {
  const HomeTransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(transaction.categoryId);
    final title = transactionTitle(transaction);
    final sign = transaction.type == TransactionType.income ? '+' : '−';
    final hidden = SettingsScope.hideMoney(context);
    final amountText = hidden ? kHiddenMoneyShort : '$sign${formatVnd(transaction.amount)}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('tx-tile-${transaction.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0D1A1D26)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A1D26),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: look.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(look.icon, color: look.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${look.name} · ${transaction.paymentSourceName}',
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
          Text(
            amountText,
            style: moneyStyle(size: 14, color: AppColors.expense, weight: FontWeight.w700),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
