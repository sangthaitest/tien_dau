import 'package:flutter/material.dart';

import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/transaction_type.dart';
import '../../../domain/transaction_display.dart';
import '../../format/money_format.dart';
import '../../settings/settings_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/category_look.dart';
import '../../catalog/transaction_catalog_scope.dart';

class HomeTransactionTile extends StatelessWidget {
  const HomeTransactionTile({super.key, required this.transaction, this.onTap});

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final category = TransactionCatalogScope.maybeOf(
      context,
    )?.categoryById(transaction.categoryId);
    final look = categoryLook(
      transaction.categoryId,
      name: category?.name,
      visualKey: category?.visualKey,
    );
    final title = transactionTitle(transaction, categoryName: category?.name);
    final sign = transaction.type == TransactionType.income ? '+' : '−';
    final hidden = SettingsScope.hideMoney(context);
    final amountText = hidden
        ? kHiddenMoneyShort
        : '$sign${formatVnd(transaction.amount)}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('tx-tile-${transaction.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: look.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(look.icon, color: look.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: AppTypography.titleWeight,
                        fontSize: 14,
                        height: 1.3,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${look.name} · ${transaction.paymentSourceName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: AppTypography.metadataWeight,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    amountText,
                    maxLines: 1,
                    style: moneyStyle(
                      size: 15,
                      color: transaction.type == TransactionType.income
                          ? AppColors.income
                          : AppColors.expense,
                    ),
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
