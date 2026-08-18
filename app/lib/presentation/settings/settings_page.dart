import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    this.onOpenFinance,
    this.onChangePin,
  });

  final VoidCallback? onOpenFinance;
  final VoidCallback? onChangePin;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 24),
        children: [
          const Text(
            'Cài đặt',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Text('MK', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Minh Khuê', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('Hồ sơ (UI)', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'QUẢN LÝ TÀI CHÍNH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _Item(
            key: const Key('settings-finance'),
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.primary,
            label: 'Tài chính',
            onTap: onOpenFinance,
          ),
          _Item(
            key: const Key('settings-pin'),
            icon: Icons.lock_outline,
            color: const Color(0xFF5C6BC0),
            label: 'Mật khẩu quản lý',
            onTap: onChangePin,
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
