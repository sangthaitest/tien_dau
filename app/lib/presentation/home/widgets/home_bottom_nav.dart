import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum AppTab { home, transactions, statistics, settings }

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    this.onAddPressed,
    this.tab = AppTab.home,
    this.onTabSelected,
  });

  final VoidCallback? onAddPressed;
  final AppTab tab;
  final ValueChanged<AppTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: AppColors.navBar,
      elevation: 0,
      child: SizedBox(
        height: 76 + bottom,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Row(
            children: [
              _NavItem(
                key: const Key('nav-home'),
                icon: Icons.home_rounded,
                label: 'Trang chủ',
                active: tab == AppTab.home,
                onTap: () => onTabSelected?.call(AppTab.home),
              ),
              _NavItem(
                key: const Key('nav-transactions'),
                icon: Icons.receipt_long_outlined,
                label: 'Giao dịch',
                active: tab == AppTab.transactions,
                onTap: () => onTabSelected?.call(AppTab.transactions),
              ),
              Expanded(
                child: Align(
                  alignment: const Alignment(0, -0.35),
                  child: FloatingActionButton(
                    key: const Key('fab-add'),
                    onPressed: onAddPressed,
                    tooltip: 'Thêm giao dịch',
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.onYellow,
                    elevation: 6,
                    heroTag: 'home-add',
                    child: const Icon(Icons.add, size: 28),
                  ),
                ),
              ),
              _NavItem(
                key: const Key('nav-statistics'),
                icon: Icons.bar_chart_outlined,
                label: 'Thống kê',
                active: tab == AppTab.statistics,
                onTap: () => onTabSelected?.call(AppTab.statistics),
              ),
              _NavItem(
                key: const Key('nav-settings'),
                icon: Icons.settings_outlined,
                label: 'Cài đặt',
                active: tab == AppTab.settings,
                onTap: () => onTabSelected?.call(AppTab.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textTertiary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (active)
              Container(
                width: 56,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 26),
              )
            else
              Icon(icon, color: color, size: 26),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
