import 'package:dio/dio.dart';

import '../models/accounts.dart';
import '../network/api_client.dart';

/// `/donors/me*`
class DonorRepository {
  final ApiClient _api;
  const DonorRepository(this._api);

  Future<Donor> getMe() async =>
      Donor.fromJson(await _api.get<Map<String, dynamic>>('/donors/me'));

  Future<Donor> updateProfile(DonorProfileUpdate data) async => Donor.fromJson(
        await _api.patch<Map<String, dynamic>>('/donors/me', body: data.toJson()),
      );

  Future<Donor> updateLocation({
    required double latitude,
    required double longitude,
    required String areaLabel,
  }) async =>
      Donor.fromJson(await _api.patch<Map<String, dynamic>>(
        '/donors/me/location',
        body: {'latitude': latitude, 'longitude': longitude, 'area_label': areaLabel},
      ));

  Future<Donor> updateAvailability(bool isAvailable) async =>
      Donor.fromJson(await _api.patch<Map<String, dynamic>>(
        '/donors/me/availability',
        body: {'is_available': isAvailable},
      ));

  /// `null` unregisters the device (logout, token rotation).
  Future<Donor> updateDeviceToken(String? token) async =>
      Donor.fromJson(await _api.patch<Map<String, dynamic>>(
        '/donors/me/device-token',
        body: {'device_token': token},
      ));

  Future<Donor> uploadProfilePic(String filePath) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    return Donor.fromJson(
      await _api.post<Map<String, dynamic>>('/donors/me/profile-pic', body: form),
    );
  }

  Future<Donor> removeProfilePic() async =>
      Donor.fromJson(await _api.delete<Map<String, dynamic>>('/donors/me/profile-pic'));

  Future<void> deleteAccount() => _api.delete<dynamic>('/donors/me');
}

/// `/requestors/me*`
class RequestorRepository {
  final ApiClient _api;
  const RequestorRepository(this._api);

  Future<Requestor> getMe() async =>
      Requestor.fromJson(await _api.get<Map<String, dynamic>>('/requestors/me'));

  Future<Requestor> updateProfile(RequestorProfileUpdate data) async =>
      Requestor.fromJson(
        await _api.patch<Map<String, dynamic>>('/requestors/me', body: data.toJson()),
      );

  Future<Requestor> uploadProfilePic(String filePath) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    return Requestor.fromJson(
      await _api.post<Map<String, dynamic>>('/requestors/me/profile-pic', body: form),
    );
  }

  Future<Requestor> removeProfilePic() async => Requestor.fromJson(
        await _api.delete<Map<String, dynamic>>('/requestors/me/profile-pic'),
      );

  Future<void> deleteAccount() => _api.delete<dynamic>('/requestors/me');
}

/// `/hospitals/me*` and `/organizations/me*` — same shape, different prefix.
class InstitutionRepository {
  final ApiClient _api;
  final String _prefix;
  const InstitutionRepository._(this._api, this._prefix);

  const InstitutionRepository.hospital(ApiClient api) : this._(api, '/hospitals');
  const InstitutionRepository.organization(ApiClient api)
      : this._(api, '/organizations');

  Future<Institution> getMe() async =>
      Institution.fromJson(await _api.get<Map<String, dynamic>>('$_prefix/me'));

  Future<Institution> uploadLogo(String filePath) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    return Institution.fromJson(
      await _api.post<Map<String, dynamic>>('$_prefix/me/logo', body: form),
    );
  }
}

/// `/admin/*` plus the admin-only sweep triggers under `/blood-requests/admin/*`.
class AdminRepository {
  final ApiClient _api;
  const AdminRepository(this._api);

  Future<List<Institution>> listPendingHospitals() async {
    final list = await _api.get<List<dynamic>>('/admin/hospitals/pending');
    return list.map((e) => Institution.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Institution>> listPendingOrganizations() async {
    final list = await _api.get<List<dynamic>>('/admin/organizations/pending');
    return list.map((e) => Institution.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Institution> decideHospital(String id, {required bool approve}) async =>
      Institution.fromJson(await _api.patch<Map<String, dynamic>>(
        '/admin/hospitals/$id/decision',
        body: {'approve': approve},
      ));

  Future<Institution> decideOrganization(String id, {required bool approve}) async =>
      Institution.fromJson(await _api.patch<Map<String, dynamic>>(
        '/admin/organizations/$id/decision',
        body: {'approve': approve},
      ));

  Future<int> expireOverdue() async {
    final json = await _api.post<Map<String, dynamic>>('/blood-requests/admin/expire-overdue');
    return (json['expired_count'] as num).toInt();
  }

  Future<int> autoWiden() async {
    final json = await _api.post<Map<String, dynamic>>('/blood-requests/admin/auto-widen');
    return (json['widened_count'] as num).toInt();
  }
}
