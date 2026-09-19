import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/accounts.dart';
import '../models/enums.dart';
import '../network/api_exception.dart';
import '../storage/token_storage.dart';
import 'core_providers.dart';

/// Where the session stands. [unknown] only exists between app start and
/// the first secure-storage read; the router waits on it.
enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;

  const AuthState._(this.status, this.user);
  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);
  const AuthState.authenticated(AuthUser user) : this._(AuthStatus.authenticated, user);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  UserRole? get role => user?.role;
}

/// Owns the session: restores it on start, performs login/signup/logout, and
/// is the single place a 401 turns into "you're logged out".
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // A 401 on any authenticated call clears the session. The router reacts
    // to the state change and sends the user to /login.
    ref.read(apiClientProvider).onUnauthorized = () => _clearSession();
    Future.microtask(restoreSession);
    return const AuthState.unknown();
  }

  TokenStorage get _storage => ref.read(tokenStorageProvider);

  /// Auto-login on app start. A dead token, or an unreachable server, both
  /// land on unauthenticated — the login screen will explain the latter.
  Future<void> restoreSession() async {
    final stored = await _storage.read();
    if (stored == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final user = await ref.read(authRepositoryProvider).fetchMe(stored.role);
      state = AuthState.authenticated(user);
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized || e.kind == ApiErrorKind.forbidden) {
        await _storage.clear();
      }
      state = const AuthState.unauthenticated();
    } catch (e) {
      debugPrint('[auth] restore failed: $e');
      state = const AuthState.unauthenticated();
    }
  }

  Future<AuthUser> login(UserRole role, String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    final token = await repo.login(role, email, password);
    await _storage.write(StoredSession(token: token.accessToken, role: role));
    try {
      final user = await repo.fetchMe(role, adminEmail: email);
      state = AuthState.authenticated(user);
      return user;
    } catch (_) {
      await _storage.clear();
      rethrow;
    }
  }

  Future<AuthUser> signupDonor(DonorSignupRequest data) async {
    await ref.read(authRepositoryProvider).signupDonor(data);
    return login(UserRole.donor, data.email, data.password);
  }

  Future<AuthUser> signupRequestor(RequestorSignupRequest data) async {
    await ref.read(authRepositoryProvider).signupRequestor(data);
    return login(UserRole.requestor, data.email, data.password);
  }

  Future<void> logout() async {
    final user = state.user;
    if (user?.role == UserRole.donor) {
      // Best effort: stop the backend targeting this device for pushes.
      try {
        await ref.read(donorRepositoryProvider).updateDeviceToken(null);
      } catch (_) {}
    }
    await _clearSession();
  }

  Future<void> _clearSession() async {
    await _storage.clear();
    if (state.status != AuthStatus.unauthenticated) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Re-reads `/me` after a profile/location/availability change.
  Future<void> refreshUser() async {
    final role = state.role;
    if (role == null) return;
    try {
      final user = await ref.read(authRepositoryProvider).fetchMe(role, adminEmail: state.user?.email);
      state = AuthState.authenticated(user);
    } on ApiException catch (e) {
      if (!e.isAuthError) rethrow;
    }
  }

  /// `PATCH /donors/me/availability`, applied optimistically to the session.
  Future<void> setDonorAvailability(bool isAvailable) async {
    final donor = state.user?.donor;
    if (donor == null) return;
    state = AuthState.authenticated(AuthUser.donor(donor.copyWith(isAvailable: isAvailable)));
    try {
      final updated = await ref.read(donorRepositoryProvider).updateAvailability(isAvailable);
      state = AuthState.authenticated(AuthUser.donor(updated));
    } catch (_) {
      state = AuthState.authenticated(AuthUser.donor(donor));
      rethrow;
    }
  }

  /// `PATCH /donors/me/location`.
  Future<Donor> setDonorLocation({
    required double latitude,
    required double longitude,
    required String areaLabel,
  }) async {
    final updated = await ref.read(donorRepositoryProvider).updateLocation(
          latitude: latitude,
          longitude: longitude,
          areaLabel: areaLabel,
        );
    state = AuthState.authenticated(AuthUser.donor(updated));
    return updated;
  }

  /// Push an already-fetched donor into the session without a round trip.
  void updateDonor(Donor donor) {
    if (state.role != UserRole.donor) return;
    state = AuthState.authenticated(AuthUser.donor(donor));
  }

  void updateRequestor(Requestor requestor) {
    if (state.role != UserRole.requestor) return;
    state = AuthState.authenticated(AuthUser.requestor(requestor));
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience selectors.
final currentUserProvider = Provider<AuthUser?>((ref) => ref.watch(authProvider).user);
final currentRoleProvider = Provider<UserRole?>((ref) => ref.watch(authProvider).role);
