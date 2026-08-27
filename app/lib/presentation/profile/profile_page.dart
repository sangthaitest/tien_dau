import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'user_profile_controller.dart';
import 'user_profile_scope.dart';
import 'widgets/profile_avatar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final controller = UserProfileScope.maybeOf(context);
    final profile = UserProfileScope.of(context);
    return ColoredBox(
      color: AppColors.bg,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              MediaQuery.paddingOf(context).top + 4,
              8,
              8,
            ),
            child: Row(
              children: [
                IconButton(
                  key: const Key('profile-back'),
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Text(
                    'Hồ sơ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
              children: [
                Center(
                  child: ProfileAvatar(
                    key: const Key('profile-avatar'),
                    initials: profile.initials,
                    avatarPath: profile.avatarPath,
                    size: 88,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.displayName,
                  key: const Key('profile-display-name'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  key: const Key('profile-email'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                _ProfileGroup(
                  title: 'Thông tin cá nhân',
                  children: [
                    _ProfileFieldRow(
                      key: const Key('profile-edit-name'),
                      label: 'Tên hiển thị',
                      value: profile.displayName,
                      editable: true,
                      onTap: controller == null
                          ? null
                          : () => _editDisplayName(context, controller),
                    ),
                    _ProfileFieldRow(
                      key: const Key('profile-edit-email'),
                      label: 'Email',
                      value: profile.email,
                      editable: true,
                      onTap: controller == null
                          ? null
                          : () => _editEmail(context, controller),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Email chỉ lưu trên máy bạn để hiển thị trong app, '
                  'không dùng để thu thập thông tin cá nhân.',
                  key: const Key('profile-email-note'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (controller?.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller!.error!,
                    style: TextStyle(color: AppColors.expense),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editDisplayName(
    BuildContext context,
    UserProfileController controller,
  ) async {
    final next = await showDialog<String>(
      context: context,
      builder: (context) => _ProfileTextDialog(
        title: 'Tên hiển thị',
        fieldKey: const Key('profile-name-field'),
        saveKey: const Key('profile-name-save'),
        initialValue: controller.profile.displayName,
        hintText: 'Nhập tên hiển thị',
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
      ),
    );
    if (next == null) return;
    await controller.setDisplayName(next);
  }

  Future<void> _editEmail(
    BuildContext context,
    UserProfileController controller,
  ) async {
    final next = await showDialog<String>(
      context: context,
      builder: (context) => _ProfileTextDialog(
        title: 'Email',
        fieldKey: const Key('profile-email-field'),
        saveKey: const Key('profile-email-save'),
        initialValue: controller.profile.email,
        hintText: 'Nhập email',
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        helperText:
            'Chỉ lưu trên máy bạn — không dùng để thu thập thông tin cá nhân.',
      ),
    );
    if (next == null) return;
    await controller.setEmail(next);
  }
}

class _ProfileTextDialog extends StatefulWidget {
  const _ProfileTextDialog({
    required this.title,
    required this.fieldKey,
    required this.saveKey,
    required this.initialValue,
    required this.hintText,
    required this.keyboardType,
    required this.textCapitalization,
    this.helperText,
  });

  final String title;
  final Key fieldKey;
  final Key saveKey;
  final String initialValue;
  final String hintText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? helperText;

  @override
  State<_ProfileTextDialog> createState() => _ProfileTextDialogState();
}

class _ProfileTextDialogState extends State<_ProfileTextDialog> {
  late final TextEditingController _field;

  @override
  void initState() {
    super.initState();
    _field = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _field,
        autofocus: true,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        decoration: InputDecoration(
          hintText: widget.hintText,
          helperText: widget.helperText,
          helperMaxLines: 3,
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          key: widget.saveKey,
          onPressed: () => Navigator.pop(context, _field.text),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _ProfileGroup extends StatelessWidget {
  const _ProfileGroup({required this.title, required this.children});

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

class _ProfileFieldRow extends StatelessWidget {
  const _ProfileFieldRow({
    super.key,
    required this.label,
    required this.value,
    required this.editable,
    this.onTap,
  });

  final String label;
  final String value;
  final bool editable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
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
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (editable)
                Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
