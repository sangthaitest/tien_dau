import 'package:flutter/material.dart';

import '../../application/backup_service.dart';
import '../../application/restore_service.dart';
import '../../data/backup/backup_ports.dart';
import '../../domain/backup/backup_manifest.dart';
import '../../domain/failures/result.dart';
import '../theme/app_colors.dart';
import '../theme/app_dialog.dart';
import '../theme/app_progress.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({
    super.key,
    required this.onBack,
    required this.onRestored,
    this.backupService,
    this.restoreService,
    this.backupShare,
    this.backupPicker,
  });

  final VoidCallback onBack;
  final Future<void> Function() onRestored;
  final BackupService? backupService;
  final RestoreService? restoreService;
  final BackupSharePort? backupShare;
  final BackupPickPort? backupPicker;

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  DateTime? _lastBackupAt;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    final at = await widget.backupService?.lastBackupAt();
    if (!mounted) return;
    setState(() => _lastBackupAt = at);
  }

  @override
  Widget build(BuildContext context) {
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
                  key: const Key('backup-back'),
                  onPressed: _busy ? null : widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Text(
                    'Sao lưu & khôi phục',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
              children: [
                Container(
                  key: const Key('backup-last-card'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lần sao lưu gần nhất',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _lastBackupAt == null
                            ? 'Chưa có bản sao lưu'
                            : _formatStamp(_lastBackupAt!),
                        key: const Key('backup-last-value'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ActionCard(
                  keyId: const Key('backup-export'),
                  icon: Icons.file_upload_outlined,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primaryContainer,
                  title: 'Sao lưu dữ liệu',
                  subtitle: 'Tạo file .tdn — bạn chọn nơi lưu (Files/Drive/…)',
                  onTap: _busy ? null : _export,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  keyId: const Key('backup-import'),
                  icon: Icons.file_download_outlined,
                  iconColor: AppColors.income,
                  iconBg: AppColors.incomeContainer,
                  title: 'Khôi phục dữ liệu',
                  subtitle: 'Thay thế dữ liệu hiện tại bằng bản sao lưu',
                  onTap: _busy ? null : _restoreFlow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    final service = widget.backupService;
    final share = widget.backupShare;
    if (service == null || share == null || _busy) return;
    setState(() => _busy = true);
    try {
      AppBusyDialog.show(context, message: 'Đang sao lưu…');
      final result = await service.export();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      switch (result) {
        case Err(:final failure):
          if (mounted)
            await _showNotice(
              title: 'Không sao lưu được',
              body: failure.message,
            );
        case Ok(:final value):
          final delivered = await share.deliver(value);
          if (!mounted) return;
          if (delivered) {
            await service.markLastBackup();
            await _loadLastBackup();
            if (!mounted) return;
            await _showNotice(
              title: 'Đã lưu bản sao lưu',
              body:
                  'File .tdn đã được lưu/chia sẻ. Hãy nhớ vị trí bạn vừa chọn.',
              key: const Key('dialog-backup-saved'),
            );
          } else {
            await _showNotice(
              title: 'Chưa lưu ra ngoài',
              body:
                  'Bạn đã đóng hộp thoại mà chưa chọn nơi lưu. '
                  'Bản sao lưu chưa được lưu ra ngoài máy.',
              key: const Key('dialog-backup-cancelled'),
            );
          }
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        await _showNotice(
          title: 'Không sao lưu được',
          body: 'Không thể tạo bản sao lưu.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFlow() async {
    final service = widget.restoreService;
    final picker = widget.backupPicker;
    if (service == null || picker == null || _busy) return;
    setState(() => _busy = true);
    try {
      while (mounted) {
        final path = await picker.pickBackup();
        if (path == null || !mounted) return;

        AppBusyDialog.show(context, message: 'Đang kiểm tra bản sao lưu…');
        final inspected = await service.inspect(path);
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        switch (inspected) {
          case Err(:final failure):
            final retry = await _showRestoreError(
              title: failure.message.contains('không được hỗ trợ')
                  ? 'Bản sao lưu không tương thích'
                  : 'Không thể khôi phục',
              message: failure.message.contains('không được hỗ trợ')
                  ? 'File này được tạo bởi phiên bản Tiền đâu nè không được hỗ trợ.'
                  : 'File không phải bản sao lưu hợp lệ của Tiền đâu nè hoặc file đã bị hỏng.',
            );
            if (retry == true) continue;
            return;
          case Ok(:final value):
            final previewOk = await _showPreview(value);
            if (previewOk != true || !mounted) return;

            final confirmed = await _showConfirm();
            if (confirmed != true || !mounted) return;

            AppBusyDialog.show(context, message: 'Đang khôi phục…');
            final restored = await service.restore(path);
            if (mounted) Navigator.of(context, rootNavigator: true).pop();

            switch (restored) {
              case Err(:final failure):
                final retry = await _showRestoreError(
                  title: 'Không thể khôi phục',
                  message: failure.message,
                );
                if (retry == true) continue;
                return;
              case Ok():
                await widget.onRestored();
                if (!mounted) return;
                await _showSuccess();
                if (mounted) widget.onBack();
                return;
            }
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        _toast('Không thể khôi phục dữ liệu.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _showPreview(BackupPreview preview) {
    final summary = preview.summary;
    final appVersion = preview.appVersion.split('+').first;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bản sao lưu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreviewLine(
              label: 'Thời gian',
              value: _formatStamp(preview.createdAt.toLocal()),
            ),
            _PreviewLine(label: 'Phiên bản app', value: appVersion),
            _PreviewLine(
              label: 'Giao dịch',
              value: '${summary.transactionCount}',
            ),
            _PreviewLine(label: 'Danh mục', value: '${summary.categoryCount}'),
            _PreviewLine(label: 'Thu nhập', value: '${summary.incomeCount}'),
            _PreviewLine(
              label: 'Khoản định kỳ',
              value: '${summary.recurringCount}',
            ),
            const _PreviewLine(label: 'Tài chính', value: 'Đã bao gồm'),
          ],
        ),
        actions: [
          AppDialog.cancel(onPressed: () => Navigator.pop(context, false)),
          AppDialog.confirm(
            key: const Key('dialog-restore-continue'),
            onPressed: () => Navigator.pop(context, true),
            label: 'Tiếp tục',
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirm() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục dữ liệu?'),
        content: const Text(
          'Dữ liệu hiện tại trên thiết bị sẽ được thay thế bằng dữ liệu trong bản sao lưu.',
        ),
        actions: [
          AppDialog.cancel(onPressed: () => Navigator.pop(context, false)),
          AppDialog.confirm(
            key: const Key('dialog-restore-confirm'),
            onPressed: () => Navigator.pop(context, true),
            label: 'Khôi phục',
          ),
        ],
      ),
    );
  }

  Future<bool?> _showRestoreError({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          AppDialog.cancel(
            onPressed: () => Navigator.pop(context, false),
            label: 'Quay lại',
          ),
          AppDialog.confirm(
            key: const Key('dialog-restore-pick-other'),
            onPressed: () => Navigator.pop(context, true),
            label: 'Chọn file khác',
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccess() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✓ Khôi phục thành công'),
        content: const Text('Dữ liệu của bạn đã được khôi phục.'),
        actions: [
          AppDialog.confirm(
            key: const Key('dialog-restore-success-ok'),
            onPressed: () => Navigator.pop(context),
            label: 'OK',
          ),
        ],
      ),
    );
  }

  Future<void> _showNotice({
    required String title,
    required String body,
    Key? key,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: key,
        title: Text(title),
        content: Text(body),
        actions: [
          AppDialog.confirm(
            key: const Key('dialog-backup-notice-ok'),
            onPressed: () => Navigator.pop(context),
            label: 'OK',
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatStamp(DateTime local) {
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString().padLeft(4, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y · $hh:$mm';
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.keyId,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final Key keyId;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: keyId,
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
              Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
