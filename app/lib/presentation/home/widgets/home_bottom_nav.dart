import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

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
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SizedBox(
          height: 78 + bottom,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Row(
              children: [
                _NavItem(
                  key: const Key('nav-home'),
                  icon: Icons.home_outlined,
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
                      splashColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      tooltip: 'Thêm giao dịch',
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.onYellow,
                      elevation: 2,
                      highlightElevation: 1,
                      heroTag: 'home-add',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (active)
              Container(
                width: 50,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 25),
              )
            else
              SizedBox(
                width: 50,
                height: 32,
                child: Icon(icon, color: color, size: 25),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active
                    ? AppTypography.titleWeight
                    : AppTypography.metadataWeight,
                color: color,
                letterSpacing: -0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
