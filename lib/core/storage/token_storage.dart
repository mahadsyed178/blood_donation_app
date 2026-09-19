import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/enums.dart';

/// The persisted session: the bearer token plus which role's `/me` it belongs
/// to. Tokens never touch SharedPreferences.
class StoredSession {
  final String token;
  final UserRole role;

  const StoredSession({required this.token, required this.role});
}

class TokenStorage {
  static const _tokenKey = 'auth.access_token';
  static const _roleKey = 'auth.role';

  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      // v10+ always uses EncryptedSharedPreferences on Android.
      : _storage = storage ?? const FlutterSecureStorage();

  Future<StoredSession?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final roleRaw = await _storage.read(key: _roleKey);
    if (token == null || token.isEmpty || roleRaw == null) return null;
    final role = UserRole.tryParse(roleRaw);
    if (role == null) return null;
    return StoredSession(token: token, role: role);
  }

  Future<void> write(StoredSession session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _roleKey, value: session.role.apiValue);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
  }
}
