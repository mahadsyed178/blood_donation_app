import '../models/blood_request.dart';
import '../models/enums.dart';
import '../network/api_client.dart';

/// `/blood-requests/*`
class BloodRequestRepository {
  final ApiClient _api;
  const BloodRequestRepository(this._api);

  static List<BloodRequest> _list(List<dynamic> raw) =>
      raw.map((e) => BloodRequest.fromJson(e as Map<String, dynamic>)).toList();

  Future<BloodRequest> create(BloodRequestCreate data) async => BloodRequest.fromJson(
        await _api.post<Map<String, dynamic>>('/blood-requests', body: data.toJson()),
      );

  Future<BloodRequest> getById(String id) async =>
      BloodRequest.fromJson(await _api.get<Map<String, dynamic>>('/blood-requests/$id'));

  /// Donor only. Blood-type compatible, in-radius, open requests with `distance_km`.
  Future<List<BloodRequest>> listNearbyForMe() async =>
      _list(await _api.get<List<dynamic>>('/blood-requests/nearby/for-me'));

  /// Hospital only: requests naming this hospital that await verification.
  Future<List<BloodRequest>> listPendingForHospital() async =>
      _list(await _api.get<List<dynamic>>('/blood-requests/hospital/pending'));

  /// Requestor / organization: their own posts, newest first.
  Future<List<BloodRequest>> listMine({
    List<RequestStatus>? statuses,
    int limit = 50,
    int offset = 0,
  }) async =>
      _list(await _api.get<List<dynamic>>('/blood-requests/mine', query: {
        if (statuses != null && statuses.isNotEmpty)
          'status': statuses.map((s) => s.apiValue).toList(),
        'limit': limit,
        'offset': offset,
      }));

  Future<List<RequestMatch>> listMatches(String requestId) async {
    final raw = await _api.get<List<dynamic>>('/blood-requests/$requestId/matches');
    return raw.map((e) => RequestMatch.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BloodRequest> hospitalVerify(String id, {required bool approve}) async =>
      BloodRequest.fromJson(await _api.patch<Map<String, dynamic>>(
        '/blood-requests/$id/hospital-verify',
        query: {'approve': approve},
      ));

  Future<BloodRequest> cancel(String id, {String? reason}) async =>
      BloodRequest.fromJson(await _api.patch<Map<String, dynamic>>(
        '/blood-requests/$id/cancel',
        body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      ));

  /// Omit [toRadiusKm] for the standard widen step.
  Future<BloodRequest> widenRadius(String id, {double? toRadiusKm}) async =>
      BloodRequest.fromJson(await _api.patch<Map<String, dynamic>>(
        '/blood-requests/$id/widen-radius',
        body: {if (toRadiusKm != null) 'to_radius_km': toRadiusKm},
      ));

  Future<BloodRequest> reactivate(String id) async => BloodRequest.fromJson(
        await _api.patch<Map<String, dynamic>>('/blood-requests/$id/reactivate'),
      );

  Future<BloodRequest> closeAsPoster(String id) async => BloodRequest.fromJson(
        await _api.post<Map<String, dynamic>>('/blood-requests/poster/close/$id'),
      );

  Future<BloodRequest> closeAsHospital(String id) async => BloodRequest.fromJson(
        await _api.post<Map<String, dynamic>>('/blood-requests/hospital/close/$id'),
      );
}

/// `/request-matches/*`
class RequestMatchRepository {
  final ApiClient _api;
  const RequestMatchRepository(this._api);

  Future<RequestMatch> accept(
    String requestId, {
    required int unitsCommitted,
    required DateTime eta,
  }) async =>
      RequestMatch.fromJson(await _api.post<Map<String, dynamic>>(
        '/request-matches/$requestId/accept',
        body: {
          'units_committed': unitsCommitted,
          'eta': eta.toUtc().toIso8601String(),
        },
      ));

  Future<List<RequestMatch>> listMine() async {
    final raw = await _api.get<List<dynamic>>('/request-matches/mine');
    return raw.map((e) => RequestMatch.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RequestMatch> updateEta(String matchId, DateTime eta) async =>
      RequestMatch.fromJson(await _api.patch<Map<String, dynamic>>(
        '/request-matches/$matchId/eta',
        body: {'eta': eta.toUtc().toIso8601String()},
      ));

  Future<RequestMatch> cancel(String matchId, {String? reason}) async =>
      RequestMatch.fromJson(await _api.patch<Map<String, dynamic>>(
        '/request-matches/$matchId/cancel',
        body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      ));

  Future<RequestMatch> complete(String matchId) async => RequestMatch.fromJson(
        await _api.patch<Map<String, dynamic>>('/request-matches/$matchId/complete'),
      );
}
