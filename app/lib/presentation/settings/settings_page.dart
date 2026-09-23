import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../../application/notification_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/notifications/reminder_schedule.dart';
import '../profile/user_profile_scope.dart';
import '../profile/widgets/profile_avatar.dart';
import '../theme/app_colors.dart';
import '../theme/app_dialog.dart';
import 'app_settings_controller.dart';
import 'notification_schedule_sheet.dart';
import 'settings_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    this.onOpenFinance,
    this.onOpenProfile,
    this.onChangePin,
    this.onOpenBackupRestore,
    this.onOpenTutorial,
  });

  final VoidCallback? onOpenFinance;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onChangePin;
  final VoidCallback? onOpenBackupRestore;
  final VoidCallback? onOpenTutorial;

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScope.maybeOf(context);
    final settings = controller?.settings ?? AppSettings.defaults;
    final profile = UserProfileScope.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: AppColors.bg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 12,
          20,
          24 + bottomInset + 72,
        ),
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
          _ProfileCard(
            displayName: profile.displayName,
            email: profile.email,
            initials: profile.initials,
            avatarPath: profile.avatarPath,
            onTap: onOpenProfile,
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Tiền của tôi',
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
                key: const Key('settings-currency'),
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFFF9A825),
                iconBg: AppColors.warningContainer,
                label: 'Tiền tệ',
                value: 'VND (₫)',
                onTap: () => _currencyDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Bảo mật & dữ liệu',
            children: [
              _SettingsRow(
                key: const Key('settings-pin'),
                icon: Icons.lock_outline,
                iconColor: AppColors.dark
                    ? const Color(0xFF9FA8DA)
                    : const Color(0xFF5C6BC0),
                iconBg: AppColors.dark
                    ? const Color(0xFF1E2238)
                    : const Color(0xFFE8EAF6),
                label: 'Mật khẩu quản lý',
                onTap: onChangePin,
              ),
              _SettingsRow(
                key: const Key('settings-backup-restore'),
                icon: Icons.cloud_upload_outlined,
                iconColor: AppColors.dark
                    ? const Color(0xFFB39DDB)
                    : const Color(0xFF7E57C2),
                iconBg: AppColors.dark
                    ? const Color(0xFF2A1F3A)
                    : const Color(0xFFEDE7F6),
                label: 'Sao lưu & khôi phục',
                onTap: onOpenBackupRestore,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Thông báo',
            children: [
              _ReminderTile(
                icon: Icons.edit_note_outlined,
                title: 'Nhắc ghi giao dịch',
                subtitle: 'Nhắc bạn ghi lại giao dịch trong ngày',
                enabled: settings.transactionReminderEnabled,
                toggleKey: const Key('toggle-transaction-reminder'),
                scheduleKey: const Key('schedule-transaction-reminder'),
                scheduleLabel: 'Thời gian',
                scheduleValue: formatReminderClock(
                  settings.transactionReminderHour,
                  settings.transactionReminderMinute,
                ),
                cadence: 'Mỗi ngày',
                onChanged: (value) => _setReminder(
                  context,
                  controller,
                  controller?.setTransactionReminderEnabled(value),
                ),
                onEdit: () => _pickDailyReminder(context, controller),
              ),
              _ReminderTile(
                icon: Icons.event_note_outlined,
                title: 'Tổng kết tài chính',
                subtitle: 'Nhắc xem lại tình hình tài chính',
                enabled: settings.financialSummaryEnabled,
                toggleKey: const Key('toggle-financial-summary'),
                scheduleKey: const Key('schedule-financial-summary'),
                scheduleLabel: formatWeeklyReminder(
                  settings.financialSummaryWeekday,
                  settings.financialSummaryHour,
                  settings.financialSummaryMinute,
                ),
                cadence: 'Mỗi tuần',
                onChanged: (value) => _setReminder(
                  context,
                  controller,
                  controller?.setFinancialSummaryEnabled(value),
                ),
                onEdit: () => _pickWeeklyReminder(context, controller),
              ),
              if (controller?.notificationsNeedSystemAccess ?? false)
                _NotificationPermissionNote(
                  onOpen: () => controller?.openNotificationSettings(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Ứng dụng',
            children: [
              _SettingsRow(
                key: const Key('settings-tutorial'),
                icon: Icons.menu_book_outlined,
                iconColor: AppColors.primary,
                iconBg: AppColors.primaryContainer,
                label: 'Hướng dẫn sử dụng',
                subtitle: 'Xem lại cách sử dụng Tiền đâu nè',
                onTap: onOpenTutorial,
              ),
              _SettingsRow(
                key: const Key('settings-privacy'),
                icon: Icons.visibility_outlined,
                iconColor: AppColors.income,
                iconBg: AppColors.incomeContainer,
                label: 'Hiển thị số tiền',
                trailing: _Toggle(
                  key: const Key('toggle-privacy'),
                  on: !settings.balanceHidden,
                  onChanged: (value) => controller?.setBalanceHidden(!value),
                ),
              ),
              _SettingsRow(
                key: const Key('settings-dark'),
                icon: Icons.dark_mode_outlined,
                iconColor: AppColors.dark
                    ? const Color(0xFFB39DDB)
                    : const Color(0xFF7E57C2),
                iconBg: AppColors.dark
                    ? const Color(0xFF2A1F3A)
                    : const Color(0xFFEDE7F6),
                label: 'Giao diện tối',
                trailing: _Toggle(
                  key: const Key('toggle-dark'),
                  on: settings.darkMode,
                  onChanged: (value) => controller?.setDarkMode(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Về ứng dụng',
            children: [
              _SettingsRow(
                key: const Key('settings-version'),
                icon: Icons.info_outline,
                iconColor: AppColors.textSecondary,
                iconBg: AppColors.dark
                    ? const Color(0xFF1E2430)
                    : const Color(0xFFF0F2F5),
                label: 'Phiên bản',
                value: AppInfo.displayVersion,
                valueKey: const Key('settings-version-value'),
                showChevron: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDailyReminder(
    BuildContext context,
    AppSettingsController? controller,
  ) async {
    if (controller == null) return;
    final settings = controller.settings;
    final picked = await pickReminderTime(
      context,
      initial: TimeOfDay(
        hour: settings.transactionReminderHour,
        minute: settings.transactionReminderMinute,
      ),
    );
    if (picked == null || !context.mounted) return;
    await _setReminder(
      context,
      controller,
      controller.setTransactionReminderTime(
        hour: picked.hour,
        minute: picked.minute,
      ),
    );
  }

  Future<void> _pickWeeklyReminder(
    BuildContext context,
    AppSettingsController? controller,
  ) async {
    if (controller == null) return;
    final settings = controller.settings;
    await showWeeklyReminderSheet(
      context,
      weekday: settings.financialSummaryWeekday,
      hour: settings.financialSummaryHour,
      minute: settings.financialSummaryMinute,
      onChanged: ({required weekday, required hour, required minute}) async {
        final result = await controller.setFinancialSummarySchedule(
          weekday: weekday,
          hour: hour,
          minute: minute,
        );
        if (context.mounted) {
          _showNotificationFeedback(context, controller, result);
        }
        return result == NotificationChange.applied;
      },
    );
  }

  Future<void> _currencyDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tiền tệ'),
        content: const Text('MVP dùng VND (₫).'),
        actions: [
          AppDialog.confirm(
            key: const Key('dialog-currency-ok'),
            onPressed: () => Navigator.pop(context),
            label: 'OK',
          ),
        ],
      ),
    );
  }
}

Future<void> _setReminder(
  BuildContext context,
  AppSettingsController? controller,
  Future<NotificationChange>? change,
) async {
  final result = await change;
  if (!context.mounted || result == null || controller == null) return;
  _showNotificationFeedback(context, controller, result);
}

void _showNotificationFeedback(
  BuildContext context,
  AppSettingsController controller,
  NotificationChange result,
) {
  switch (result) {
    case NotificationChange.applied:
      return;
    case NotificationChange.permissionDenied:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          content: const Text('Chưa cấp quyền thông báo.'),
          action: SnackBarAction(
            key: const Key('notification-permission-settings'),
            label: 'Cài đặt',
            onPressed: controller.openNotificationSettings,
          ),
        ),
      );
    case NotificationChange.failed:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa đặt được thông báo. Thử lại.')),
      );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.toggleKey,
    required this.scheduleKey,
    required this.scheduleLabel,
    required this.cadence,
    required this.onChanged,
    required this.onEdit,
    this.scheduleValue,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final Key toggleKey;
  final Key scheduleKey;
  final String scheduleLabel;
  final String? scheduleValue;
  final String cadence;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFFB8C00), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _Toggle(key: toggleKey, on: enabled, onChanged: onChanged),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            InkWell(
              key: scheduleKey,
              onTap: onEdit,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.only(left: 54, right: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scheduleLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cadence,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (scheduleValue != null)
                        Text(
                          scheduleValue!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationPermissionNote extends StatelessWidget {
  const _NotificationPermissionNote({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông báo đang tắt trong hệ thống.',
            key: const Key('settings-notification-permission'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          TextButton(
            key: const Key('settings-notification-open'),
            onPressed: onOpen,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              minimumSize: const Size(48, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.displayName,
    required this.email,
    required this.initials,
    this.avatarPath,
    this.onTap,
  });

  final String displayName;
  final String email;
  final String initials;
  final String? avatarPath;
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
              ProfileAvatar(
                initials: initials,
                avatarPath: avatarPath,
                size: 64,
                fontSize: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      key: const Key('settings-profile-name'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      key: const Key('settings-profile-email'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hồ sơ',
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
    this.subtitle,
    this.value,
    this.valueKey,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final String? value;
  final Key? valueKey;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
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
              else if (showChevron)
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
