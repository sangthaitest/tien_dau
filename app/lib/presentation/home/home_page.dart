import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format/money_format.dart';
import '../theme/app_colors.dart';
import 'home_controller.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/home_transaction_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
    this.userName = 'Minh Khuê',
    this.userInitials = 'MK',
  });

  final HomeController controller;
  final String userName;
  final String userInitials;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _Header(controller: c, page: widget)),
                      SliverToBoxAdapter(child: _Recent(controller: c)),
                    ],
                  ),
                ),
                HomeBottomNav(
                  onAddPressed: () {
                    // Add Transaction is Phase 04. FAB is the V3 primary control.
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.page});

  final HomeController controller;
  final HomePage page;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final snapshot = controller.snapshot;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00B67A),
            Color(0xFF009963),
            Color(0xFF00855A),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: _Blob(size: 180, opacity: 0.10),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: _Blob(size: 120, opacity: 0.07),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greetingFor(DateTime.now()),
                          style: const TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          page.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x38FFFFFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x73FFFFFF), width: 2),
                    ),
                    child: Text(
                      page.userInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month, size: 15, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      monthLabel(snapshot.month.year == 1970
                          ? DateTime.now()
                          : snapshot.month),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0x29FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi tiêu tháng này',
                      style: TextStyle(
                        color: Color(0xC7FFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.loading ? '…' : formatVnd(snapshot.monthExpense),
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

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final recent = controller.snapshot.recent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gần đây',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (controller.error != null)
            Text(
              controller.error!,
              style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600),
            )
          else if (controller.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (recent.isEmpty)
            const Text(
              'Chưa có giao dịch. Nhấn + để thêm.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...recent.map(
              (tx) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: HomeTransactionTile(transaction: tx),
              ),
            ),
        ],
      ),
    );
  }
}
