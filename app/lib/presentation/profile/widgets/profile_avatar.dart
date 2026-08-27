import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Circular initials avatar used on Home, Settings, and Profile.
/// [avatarPath] is reserved for a future image-backed avatar.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.avatarPath,
    this.size = 40,
    this.fontSize = 14,
  });

  final String initials;
  final String? avatarPath;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // Image-backed avatar can use [avatarPath] when upload lands.
    final hasImage = avatarPath != null && avatarPath!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
        color: hasImage ? AppColors.primary : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
