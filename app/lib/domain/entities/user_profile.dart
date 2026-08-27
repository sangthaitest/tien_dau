class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.email,
    this.avatarPath,
  });

  final String displayName;
  final String email;

  /// Local file path for a future avatar image. Null means initials only.
  final String? avatarPath;

  static const defaults = UserProfile(
    displayName: 'Minh Khuê',
    email: 'minhkhue@email.com',
  );

  /// Initials derived from [displayName] (not persisted separately).
  ///
  /// - Multiple words → first letter of first + last word (`Nguyễn Văn An` → `NA`)
  /// - Single word → up to two leading letters (`Minh` → `MI`)
  /// - Empty / whitespace → `?`
  String get initials => initialsFromDisplayName(displayName);

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? avatarPath,
    bool clearAvatarPath = false,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfile &&
        other.displayName == displayName &&
        other.email == email &&
        other.avatarPath == avatarPath;
  }

  @override
  int get hashCode => Object.hash(displayName, email, avatarPath);
}

String initialsFromDisplayName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final word = parts.first;
    final runes = word.runes.toList();
    if (runes.isEmpty) return '?';
    if (runes.length == 1) {
      return String.fromCharCode(runes.first).toUpperCase();
    }
    return String.fromCharCodes(runes.take(2)).toUpperCase();
  }
  final first = String.fromCharCode(parts.first.runes.first);
  final last = String.fromCharCode(parts.last.runes.first);
  return '$first$last'.toUpperCase();
}
