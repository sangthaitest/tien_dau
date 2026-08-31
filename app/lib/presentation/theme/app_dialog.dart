import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Shared dialog actions: primary is filled, secondary stays a text button.
abstract final class AppDialog {
  static Widget cancel({
    required VoidCallback onPressed,
    String label = 'Hủy',
    Key? key,
  }) {
    return TextButton(key: key, onPressed: onPressed, child: Text(label));
  }

  static Widget confirm({
    required VoidCallback onPressed,
    required String label,
    Key? key,
  }) {
    return FilledButton(
      key: key,
      onPressed: onPressed,
      child: Text(label, style: AppTypography.button()),
    );
  }
}
