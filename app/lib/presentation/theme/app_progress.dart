import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Shared loading and progress chrome for the whole app.
abstract final class AppProgress {
  static const double strokeWidth = 3;
  static const double size = 32;
  static const double compactSize = 24;
  static const double busySize = 40;
  static const double linearHeight = 8;
}

class AppCircularProgress extends StatelessWidget {
  const AppCircularProgress({
    super.key,
    this.size = AppProgress.size,
    this.strokeWidth = AppProgress.strokeWidth,
  });

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        constraints: BoxConstraints.tight(Size.square(size)),
      ),
    );
  }
}

class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({
    super.key,
    this.value,
    this.color,
    this.trackColor,
    this.height = AppProgress.linearHeight,
  });

  final double? value;
  final Color? color;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return ClipRRect(
      borderRadius: radius,
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        color: color ?? AppColors.primary,
        backgroundColor: trackColor ?? AppColors.surfaceVariant,
        borderRadius: radius,
        trackGap: 0,
        stopIndicatorColor: Colors.transparent,
        stopIndicatorRadius: 0,
      ),
    );
  }
}

class AppBusyDialog extends StatelessWidget {
  const AppBusyDialog({super.key, required this.message});

  final String message;

  static Future<void> show(BuildContext context, {required String message}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x59000000),
      builder: (context) =>
          PopScope(canPop: false, child: AppBusyDialog(message: message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('app-busy-dialog'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 72),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 168),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppCircularProgress(size: AppProgress.busySize),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: AppTypography.metadataWeight,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
