class AuthSession {
  final String token, name, userType;
  final int? id;
  const AuthSession({required this.token, required this.name, required this.userType, this.id});

  bool get isProvider => userType.toLowerCase() == 'provider';
  String get firstName => name.trim().isEmpty ? '' : name.trim().split(' ').first;

  static dynamic _pick(Map m, String key) {
    for (final e in m.entries) {
      if (e.key.toString().toLowerCase() == key) return e.value;
    }
    return null;
  }

  /// Login response keys are capitalised inconsistently (Token, Full_name…).
  factory AuthSession.fromLogin(Map m) {
    final token = _pick(m, 'token')?.toString();
    if (token == null || token.isEmpty) throw const FormatException('Login response did not include a token');
    return AuthSession(
      token: token,
      name: (_pick(m, 'full_name') ?? _pick(m, 'username') ?? '').toString(),
      userType: (_pick(m, 'user_type') ?? 'customer').toString().toLowerCase(),
      id: int.tryParse('${_pick(m, 'id')}'),
    );
  }
}
