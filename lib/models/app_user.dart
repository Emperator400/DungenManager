class AppUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? avatarUrl;

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.avatarUrl,
  });

  String get initials {
    final name = displayName ?? email ?? '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
