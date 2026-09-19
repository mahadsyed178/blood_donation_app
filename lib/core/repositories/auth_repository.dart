import '../models/accounts.dart';
import '../models/enums.dart';
import '../network/api_client.dart';

/// Login, signup and password reset for every role, plus the `/me` lookup
/// that turns a stored token back into an [AuthUser].
class AuthRepository {
  final ApiClient _api;
  const AuthRepository(this._api);

  Future<TokenResponse> login(UserRole role, String email, String password) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/${role.pathSegment}/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    return TokenResponse.fromJson(json);
  }

  Future<Donor> signupDonor(DonorSignupRequest data) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/donors/signup',
      body: data.toJson(),
      auth: false,
    );
    return Donor.fromJson(json);
  }

  Future<Requestor> signupRequestor(RequestorSignupRequest data) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/requestors/signup',
      body: data.toJson(),
      auth: false,
    );
    return Requestor.fromJson(json);
  }

  /// Resolves the current account for [role]. Admin has no `/me`; its
  /// identity is just the email that logged in.
  Future<AuthUser> fetchMe(UserRole role, {String? adminEmail}) async {
    switch (role) {
      case UserRole.donor:
        final json = await _api.get<Map<String, dynamic>>('/donors/me');
        return AuthUser.donor(Donor.fromJson(json));
      case UserRole.requestor:
        final json = await _api.get<Map<String, dynamic>>('/requestors/me');
        return AuthUser.requestor(Requestor.fromJson(json));
      case UserRole.hospital:
        final json = await _api.get<Map<String, dynamic>>('/hospitals/me');
        return AuthUser.hospital(Institution.fromJson(json));
      case UserRole.organization:
        final json = await _api.get<Map<String, dynamic>>('/organizations/me');
        return AuthUser.organization(Institution.fromJson(json));
      case UserRole.admin:
        // Cheapest authenticated admin call, to prove the token still works.
        await _api.get<List<dynamic>>('/admin/hospitals/pending');
        return AuthUser.admin(adminEmail ?? 'admin');
    }
  }

  /// Only donors and requestors have forgot/reset endpoints.
  static bool supportsPasswordReset(UserRole role) =>
      role == UserRole.donor || role == UserRole.requestor;

  Future<String> forgotPassword(UserRole role, String email) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/${role.pathSegment}/forgot-password',
      body: {'email': email},
      auth: false,
    );
    return json['message'] as String? ?? 'If that email exists, a reset link has been sent';
  }

  Future<String> resetPassword(UserRole role, String token, String newPassword) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/${role.pathSegment}/reset-password',
      body: {'token': token, 'new_password': newPassword},
      auth: false,
    );
    return json['message'] as String? ?? 'Password reset successfully';
  }

  Future<String> resendVerification(UserRole role, String email) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/${role.pathSegment}/resend-verification',
      body: {'email': email},
      auth: false,
    );
    return json['message'] as String? ?? 'Sent';
  }
}
