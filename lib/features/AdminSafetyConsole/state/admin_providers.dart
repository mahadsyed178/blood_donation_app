import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/accounts.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/core_providers.dart';

/// Pending hospital / organization approvals, one notifier each, sharing the
/// optimistic-remove-then-decide behaviour.
abstract class _PendingInstitutionsNotifier extends AsyncNotifier<List<Institution>> {
  Future<List<Institution>> fetch();
  Future<Institution> decideRemote(String id, bool approve);

  @override
  Future<List<Institution>> build() async {
    ref.watch(authProvider.select((s) => s.user?.id));
    if (ref.read(currentRoleProvider) != UserRole.admin) return const [];
    return fetch();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(fetch);
  }

  Future<Institution> decide(String id, {required bool approve}) async {
    final before = state.value;
    if (before != null) state = AsyncData(before.where((i) => i.id != id).toList());
    try {
      return await decideRemote(id, approve);
    } catch (_) {
      if (before != null) state = AsyncData(before);
      rethrow;
    }
  }
}

class PendingHospitalsNotifier extends _PendingInstitutionsNotifier {
  @override
  Future<List<Institution>> fetch() => ref.read(adminRepositoryProvider).listPendingHospitals();
  @override
  Future<Institution> decideRemote(String id, bool approve) =>
      ref.read(adminRepositoryProvider).decideHospital(id, approve: approve);
}

class PendingOrganizationsNotifier extends _PendingInstitutionsNotifier {
  @override
  Future<List<Institution>> fetch() =>
      ref.read(adminRepositoryProvider).listPendingOrganizations();
  @override
  Future<Institution> decideRemote(String id, bool approve) =>
      ref.read(adminRepositoryProvider).decideOrganization(id, approve: approve);
}

final pendingHospitalsProvider =
    AsyncNotifierProvider<PendingHospitalsNotifier, List<Institution>>(
  PendingHospitalsNotifier.new,
);

final pendingOrganizationsProvider =
    AsyncNotifierProvider<PendingOrganizationsNotifier, List<Institution>>(
  PendingOrganizationsNotifier.new,
);
