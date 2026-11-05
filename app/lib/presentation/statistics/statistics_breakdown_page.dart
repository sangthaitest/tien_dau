import 'package:flutter/material.dart';

import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/time/clock_format.dart';
import '../catalog/transaction_catalog_controller.dart';
import '../format/money_format.dart';
import '../home/widgets/home_transaction_tile.dart';
import '../theme/app_colors.dart';
import '../theme/app_progress.dart';
import '../theme/app_typography.dart';
import '../transactions/transaction_detail_sheet.dart';
import 'statistics_breakdown_controller.dart';

class StatisticsBreakdownPage extends StatefulWidget {
  const StatisticsBreakdownPage({
    super.key,
    required this.title,
    required this.month,
    required this.filter,
    required this.service,
    required this.catalogController,
    required this.clock,
    required this.onBack,
    required this.onChanged,
  });

  final String title;
  final DateTime month;
  final StatisticsBreakdownFilter filter;
  final TransactionService service;
  final TransactionCatalogController catalogController;
  final DateTime Function() clock;
  final VoidCallback onBack;
  final VoidCallback onChanged;

  @override
  State<StatisticsBreakdownPage> createState() =>
      _StatisticsBreakdownPageState();
}

class _StatisticsBreakdownPageState extends State<StatisticsBreakdownPage> {
  late final StatisticsBreakdownController _controller;
  var _openingDetail = false;

  @override
  void initState() {
    super.initState();
    _controller = StatisticsBreakdownController(
      service: widget.service,
      month: widget.month,
      filter: widget.filter,
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _itemDate(Transaction transaction) {
    final date = transaction.occurredOn;
    return '${formatWeekdayShort(date)}, ${formatDayMonth(date)}';
  }

  Future<void> _openDetail(String id) async {
    if (_openingDetail) return;
    _openingDetail = true;
    try {
      final changed = await TransactionDetailSheet.show(
        context: context,
        transactionService: widget.service,
        catalogController: widget.catalogController,
        clock: widget.clock,
        transactionId: id,
      );
      if (!mounted || changed != true) return;
      widget.onChanged();
      await _controller.load();
    } finally {
      _openingDetail = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('stats-breakdown-page'),
      color: AppColors.bg,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final transactions = _controller.transactions;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  8,
                  MediaQuery.paddingOf(context).top,
                  8,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('stats-breakdown-back'),
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Quay lại',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        key: const Key('stats-breakdown-title'),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  children: [
                    Text(
                      monthLabel(widget.month),
                      key: const Key('stats-breakdown-month'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!_controller.loading && _controller.error == null) ...[
                      const SizedBox(height: 2),
                      Text(
                        formatVnd(_controller.total),
                        key: const Key('stats-breakdown-total'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _controller.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _controller.error!,
                            key: const Key('stats-breakdown-error'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.expense,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : _controller.loading
                    ? const Center(child: AppCircularProgress())
                    : transactions.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có giao dịch tháng này',
                          key: const Key('stats-breakdown-empty'),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 16,
                            fontWeight: AppTypography.titleWeight,
                            color: AppColors.text,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          for (final transaction in transactions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: HomeTransactionTile(
                                transaction: transaction,
                                dateLabel: _itemDate(transaction),
                                onTap: () => _openDetail(transaction.id),
                              ),
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
}
