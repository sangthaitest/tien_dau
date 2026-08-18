import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/security/sensitive_access_port.dart';
import '../theme/app_colors.dart';

enum PinSheetMode { setup, unlock, change }

class PinSheet extends StatefulWidget {
  const PinSheet({
    super.key,
    required this.access,
    required this.mode,
  });

  final SensitiveAccessPort access;
  final PinSheetMode mode;

  static Future<bool> show(
    BuildContext context, {
    required SensitiveAccessPort access,
    required PinSheetMode mode,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: PinSheet(access: access, mode: mode),
      ),
    );
    return result == true;
  }

  @override
  State<PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<PinSheet> {
  final _pin = TextEditingController();
  final _current = TextEditingController();
  final _next = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pin.dispose();
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  String get _title => switch (widget.mode) {
        PinSheetMode.setup => 'Tạo mật khẩu',
        PinSheetMode.unlock => 'Mật khẩu quản lý tài chính',
        PinSheetMode.change => 'Đổi mật khẩu',
      };

  String get _hint => switch (widget.mode) {
        PinSheetMode.setup => 'Tạo mật khẩu 4 số để bảo vệ Tài chính.',
        PinSheetMode.unlock => 'Nhập mật khẩu 4 số để xem Tài chính.',
        PinSheetMode.change => 'Nhập mật khẩu hiện tại để đổi.',
      };

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = switch (widget.mode) {
      PinSheetMode.setup => await widget.access.setupPin(_pin.text.trim()),
      PinSheetMode.unlock => await widget.access.unlock(_pin.text.trim()),
      PinSheetMode.change => await widget.access.changePin(
          current: _current.text.trim(),
          next: _next.text.trim(),
        ),
    };
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = ok ? null : (widget.access.lastError ?? 'Mật khẩu không đúng');
    });
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _hint,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.mode == PinSheetMode.change) ...[
            _PinField(controller: _current, label: 'Mật khẩu hiện tại'),
            const SizedBox(height: 12),
            _PinField(controller: _next, label: 'Mật khẩu mới'),
          ] else
            _PinField(
              controller: _pin,
              label: 'Mật khẩu',
              key: const Key('input-finance-pin'),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              key: const Key('pin-error'),
              style: const TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              key: const Key('btn-submit-pin'),
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(
                widget.mode == PinSheetMode.setup ? 'Lưu mật khẩu' : 'Xác nhận',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••',
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
