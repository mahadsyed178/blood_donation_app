import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/core_providers.dart';

/// Every list notifier keys itself on the signed-in account, so switching
/// users (or logging out) rebuilds it instead of showing stale rows.
String? _sessionKey(Ref ref) => ref.watch(authProvider.select((s) => s.user?.id));

/// Donor's nearby feed: `GET /blood-requests/nearby/for-me`.
class NearbyRequestsNotifier extends AsyncNotifier<List<BloodRequest>> {
  @override
  Future<List<BloodRequest>> build() async {
    _sessionKey(ref);
    if (ref.read(currentRoleProvider) != UserRole.donor) return const [];
    return ref.read(bloodRequestRepositoryProvider).listNearbyForMe();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(bloodRequestRepositoryProvider).listNearbyForMe(),
    );
  }

  /// After accepting, the request is no longer "open to me" in the same way;
  /// drop it locally so the feed reflects the commitment immediately.
  void removeLocally(String requestId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.where((r) => r.id != requestId).toList());
  }
}

final nearbyRequestsProvider =
    AsyncNotifierProvider<NearbyRequestsNotifier, List<BloodRequest>>(
  NearbyRequestsNotifier.new,
);

/// Poster's own requests: `GET /blood-requests/mine` plus every mutation a
/// poster can perform, applied optimistically with rollback.
class MyRequestsNotifier extends AsyncNotifier<List<BloodRequest>> {
  @override
  Future<List<BloodRequest>> build() async {
    _sessionKey(ref);
    final role = ref.read(currentRoleProvider);
    if (role == null || !role.canPostRequests) return const [];
    return ref.read(bloodRequestRepositoryProvider).listMine(limit: 100);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(bloodRequestRepositoryProvider).listMine(limit: 100),
    );
  }

  Future<BloodRequest> create(BloodRequestCreate data) async {
    final created = await ref.read(bloodRequestRepositoryProvider).create(data);
    state = AsyncData([created, ...?state.value]);
    return created;
  }

  Future<BloodRequest> _mutate(
    String id,
    Future<BloodRequest> Function() call, {
    RequestStatus? optimisticStatus,
  }) async {
    final before = state.value;
    if (before != null && optimisticStatus != null) {
      state = AsyncData(_replaceStatus(before, id, optimisticStatus));
    }
    try {
      final updated = await call();
      state = AsyncData(_replace(state.value ?? before ?? const [], updated));
      return updated;
    } catch (_) {
      if (before != null) state = AsyncData(before);
      rethrow;
    }
  }

  Future<BloodRequest> cancel(String id, {String? reason}) => _mutate(
        id,
        () => ref.read(bloodRequestRepositoryProvider).cancel(id, reason: reason),
        optimisticStatus: RequestStatus.cancelled,
      );

  Future<BloodRequest> close(String id) => _mutate(
        id,
        () => ref.read(bloodRequestRepositoryProvider).closeAsPoster(id),
        optimisticStatus: RequestStatus.closed,
      );

  Future<BloodRequest> reactivate(String id) => _mutate(
        id,
        () => ref.read(bloodRequestRepositoryProvider).reactivate(id),
        optimisticStatus: RequestStatus.active,
      );

  // Radius is server-computed, so no optimistic value — just replace on return.
  Future<BloodRequest> widen(String id, {double? toRadiusKm}) => _mutate(
        id,
        () => ref.read(bloodRequestRepositoryProvider).widenRadius(id, toRadiusKm: toRadiusKm),
      );

  static List<BloodRequest> _replace(List<BloodRequest> list, BloodRequest updated) =>
      list.map((r) => r.id == updated.id ? updated : r).toList();

  static List<BloodRequest> _replaceStatus(
    List<BloodRequest> list,
    String id,
    RequestStatus status,
  ) =>
      list.map((r) {
        if (r.id != id) return r;
        return BloodRequest(
          id: r.id,
          requestorId: r.requestorId,
          organizationId: r.organizationId,
          patientName: r.patientName,
          bloodTypeNeeded: r.bloodTypeNeeded,
          unitsNeeded: r.unitsNeeded,
          unitsSecured: r.unitsSecured,
          urgencyLevel: r.urgencyLevel,
          requiredBy: r.requiredBy,
          hospitalNameText: r.hospitalNameText,
          hospitalId: r.hospitalId,
          isHospitalBacked: r.isHospitalBacked,
          status: status,
          currentRadiusKm: r.currentRadiusKm,
          contactPhone: r.contactPhone,
          areaLabel: r.areaLabel,
          cancellationReason: r.cancellationReason,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
          distanceKm: r.distanceKm,
        );
      }).toList();
}

final myRequestsProvider = AsyncNotifierProvider<MyRequestsNotifier, List<BloodRequest>>(
  MyRequestsNotifier.new,
);

/// Who committed to one request: `GET /blood-requests/{id}/matches`.
/// Poster / hospital / admin only — donors get a 404 by design.
final requestMatchesProvider =
    FutureProvider.autoDispose.family<List<RequestMatch>, String>((ref, requestId) {
  return ref.read(bloodRequestRepositoryProvider).listMatches(requestId);
});

/// One request's detail (chat header, detail sheet).
final bloodRequestByIdProvider =
    FutureProvider.autoDispose.family<BloodRequest, String>((ref, id) {
  return ref.read(bloodRequestRepositoryProvider).getById(id);
});
