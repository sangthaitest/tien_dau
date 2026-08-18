import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, this.onAddPressed});

  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: const Color(0xEBFFFFFF),
      elevation: 0,
      child: SizedBox(
        height: 76 + bottom,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Trang chủ', active: true),
              const _NavItem(icon: Icons.receipt_long_outlined, label: 'Giao dịch'),
              Expanded(
                child: Align(
                  alignment: const Alignment(0, -0.35),
                  child: FloatingActionButton(
                    key: const Key('fab-add'),
                    onPressed: onAddPressed,
                    tooltip: 'Thêm giao dịch',
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 6,
                    heroTag: 'home-add',
                    child: const Icon(Icons.add, size: 28),
                  ),
                ),
              ),
              const _NavItem(icon: Icons.bar_chart_outlined, label: 'Thống kê'),
              const _NavItem(icon: Icons.settings_outlined, label: 'Cài đặt'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textTertiary;
    return Expanded(
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
    );
  }
}
