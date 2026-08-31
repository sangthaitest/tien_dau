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
  const HomeTransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.unsignedNeutralAmount = false,
  });

  final Transaction transaction;
  final VoidCallback? onTap;
  final bool unsignedNeutralAmount;

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
    final hidden = SettingsScope.hideMoney(context);
    final amountText = hidden
        ? kHiddenMoneyShort
        : unsignedNeutralAmount
        ? formatVnd(transaction.amount)
        : '${transaction.type == TransactionType.income ? '+' : '−'}${formatVnd(transaction.amount)}';
    final amountColor = unsignedNeutralAmount
        ? AppColors.text
        : transaction.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    final radius = unsignedNeutralAmount ? 20.0 : 18.0;
    final iconSize = unsignedNeutralAmount ? 44.0 : 50.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('tx-tile-${transaction.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: unsignedNeutralAmount ? 13 : 15,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(radius),
            border: unsignedNeutralAmount
                ? null
                : Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: unsignedNeutralAmount ? 8 : 12,
                offset: Offset(0, unsignedNeutralAmount ? 2 : 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: look.background,
                  borderRadius: BorderRadius.circular(
                    unsignedNeutralAmount ? 14 : 16,
                  ),
                ),
                child: Icon(
                  look.icon,
                  color: look.color,
                  size: unsignedNeutralAmount ? 22 : 24,
                ),
              ),
              SizedBox(width: unsignedNeutralAmount ? 12 : 14),
              Expanded(
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
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.42,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    amountText,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: moneyStyle(size: 15, color: amountColor),
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
