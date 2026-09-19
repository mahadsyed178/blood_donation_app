import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/core_providers.dart';

/// Hospital's review queue: `GET /blood-requests/hospital/pending`, with the
/// verify / reject decision applied optimistically.
class HospitalQueueNotifier extends AsyncNotifier<List<BloodRequest>> {
  @override
  Future<List<BloodRequest>> build() async {
    ref.watch(authProvider.select((s) => s.user?.id));
    if (ref.read(currentRoleProvider) != UserRole.hospital) return const [];
    return ref.read(bloodRequestRepositoryProvider).listPendingForHospital();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(bloodRequestRepositoryProvider).listPendingForHospital(),
    );
  }

  Future<BloodRequest> decide(String id, {required bool approve}) async {
    final before = state.value;
    if (before != null) state = AsyncData(before.where((r) => r.id != id).toList());
    try {
      return await ref
          .read(bloodRequestRepositoryProvider)
          .hospitalVerify(id, approve: approve);
    } catch (_) {
      if (before != null) state = AsyncData(before);
      rethrow;
    }
  }
}

final hospitalQueueProvider = AsyncNotifierProvider<HospitalQueueNotifier, List<BloodRequest>>(
  HospitalQueueNotifier.new,
);
