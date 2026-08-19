import 'package:flutter/material.dart';

import '../../domain/entities/app_settings.dart';
import '../theme/app_colors.dart';
import 'settings_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    this.onOpenFinance,
    this.onChangePin,
    this.onLogout,
  });

  final VoidCallback? onOpenFinance;
  final VoidCallback? onChangePin;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScope.maybeOf(context);
    final settings = controller?.settings ?? AppSettings.defaults;
    return ColoredBox(
      color: AppColors.bg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 24),
        children: [
          Text(
            'Cài đặt',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          _ProfileCard(onTap: () => _profileDialog(context)),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Quản lý tài chính',
            children: [
              _SettingsRow(
                key: const Key('settings-finance'),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.primary,
                iconBg: AppColors.primaryContainer,
                label: 'Tài chính',
                onTap: onOpenFinance,
              ),
              _SettingsRow(
                key: const Key('settings-pin'),
                icon: Icons.lock_outline,
                iconColor: AppColors.dark ? const Color(0xFF9FA8DA) : const Color(0xFF5C6BC0),
                iconBg: AppColors.dark ? const Color(0xFF1E2238) : const Color(0xFFE8EAF6),
                label: 'Mật khẩu quản lý',
                onTap: onChangePin,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Tùy chọn',
            children: [
              _SettingsRow(
                key: const Key('settings-currency'),
                icon: Icons.payments_outlined,
                iconColor: AppColors.primary,
                iconBg: AppColors.primaryContainer,
                label: 'Tiền tệ',
                value: 'VND (₫)',
                onTap: () => _currencyDialog(context),
              ),
              _SettingsRow(
                key: const Key('settings-notifications'),
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFFFB8C00),
                iconBg: AppColors.warningContainer,
                label: 'Thông báo',
                trailing: _Toggle(
                  key: const Key('toggle-notif'),
                  on: settings.notificationsEnabled,
                  onChanged: (value) async {
                    await controller?.setNotificationsEnabled(value);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'Đã bật thông báo' : 'Đã tắt thông báo',
                        ),
                      ),
                    );
                  },
                ),
              ),
              _SettingsRow(
                key: const Key('settings-privacy'),
                icon: Icons.visibility_outlined,
                iconColor: AppColors.income,
                iconBg: AppColors.incomeContainer,
                label: 'Riêng tư',
                value: settings.balanceHidden ? 'Ẩn số' : 'Hiện số',
                valueKey: const Key('privacy-value'),
                onTap: () => controller?.toggleBalanceHidden(),
              ),
              _SettingsRow(
                key: const Key('settings-dark'),
                icon: Icons.dark_mode_outlined,
                iconColor: AppColors.dark ? const Color(0xFFB39DDB) : const Color(0xFF7E57C2),
                iconBg: AppColors.dark ? const Color(0xFF2A1F3A) : const Color(0xFFEDE7F6),
                label: 'Giao diện tối',
                trailing: _Toggle(
                  key: const Key('toggle-dark'),
                  on: settings.darkMode,
                  onChanged: (value) => controller?.setDarkMode(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              key: const Key('settings-logout'),
              onPressed: () => _logoutDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.expense,
                backgroundColor: AppColors.expenseContainer,
                side: BorderSide(color: AppColors.expenseContainer, width: 1.5),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              child: const Text('Đăng xuất (prototype)'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _profileDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hồ sơ'),
        content: const Text(
          'Minh Khuê · minhanh@email.com\n(UI prototype — không có backend)',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _currencyDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tiền tệ'),
        content: const Text('MVP dùng VND (₫).'),
        actions: [
          TextButton(
            key: const Key('dialog-currency-ok'),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutDialog(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Dữ liệu cục bộ vẫn được giữ trên thiết bị.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            key: const Key('dialog-logout-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok == true) onLogout?.call();
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: const Key('settings-profile'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'MK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minh Khuê',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'minhanh@email.com',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hồ sơ (UI)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.7,
              ),
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.value,
    this.valueKey,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? value;
  final Key? valueKey;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value!,
                    key: valueKey,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (trailing != null)
                trailing!
              else
                Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({super.key, required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: on ? AppColors.primary : AppColors.divider,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: const Cubic(0.34, 1.45, 0.64, 1),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
