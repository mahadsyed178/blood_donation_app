import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../../BloodRequestsLifeCycle/state/blood_request_providers.dart';
import '../../Co-ordinationChat/state/chat_providers.dart';

/// The acceptor's (donor / organization) commitments:
/// `GET /request-matches/mine` and the accept / eta / cancel / complete calls.
class MyMatchesNotifier extends AsyncNotifier<List<RequestMatch>> {
  @override
  Future<List<RequestMatch>> build() async {
    ref.watch(authProvider.select((s) => s.user?.id));
    final role = ref.read(currentRoleProvider);
    if (role == null || !role.canAcceptRequests) return const [];
    return ref.read(requestMatchRepositoryProvider).listMine();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(requestMatchRepositoryProvider).listMine());
  }

  List<RequestMatch> get open => (state.value ?? const []).where((m) => m.isOpen).toList();

  Future<RequestMatch> accept(
    String requestId, {
    required int units,
    required DateTime eta,
  }) async {
    final match = await ref
        .read(requestMatchRepositoryProvider)
        .accept(requestId, unitsCommitted: units, eta: eta);
    state = AsyncData([match, ...?state.value]);
    // Accepting creates a chat thread and changes the request's state.
    ref.read(nearbyRequestsProvider.notifier).removeLocally(requestId);
    ref.invalidate(chatThreadsProvider);
    return match;
  }

  Future<RequestMatch> _mutate(
    String matchId,
    Future<RequestMatch> Function() call, {
    RequestMatch Function(RequestMatch)? optimistic,
  }) async {
    final before = state.value;
    if (before != null && optimistic != null) {
      state = AsyncData(before.map((m) => m.id == matchId ? optimistic(m) : m).toList());
    }
    try {
      final updated = await call();
      state = AsyncData(
        (state.value ?? before ?? const []).map((m) => m.id == updated.id ? updated : m).toList(),
      );
      return updated;
    } catch (_) {
      if (before != null) state = AsyncData(before);
      rethrow;
    }
  }

  Future<RequestMatch> updateEta(String matchId, DateTime eta) => _mutate(
        matchId,
        () => ref.read(requestMatchRepositoryProvider).updateEta(matchId, eta),
        optimistic: (m) => m.copyWith(eta: eta),
      );

  Future<RequestMatch> cancel(String matchId, {String? reason}) async {
    final result = await _mutate(
      matchId,
      () => ref.read(requestMatchRepositoryProvider).cancel(matchId, reason: reason),
      optimistic: (m) => m.copyWith(status: MatchStatus.cancelled, cancelReason: reason),
    );
    // Cancelling reopens the request for other donors — refresh the feed.
    ref.invalidate(nearbyRequestsProvider);
    ref.invalidate(chatThreadsProvider);
    return result;
  }

  Future<RequestMatch> complete(String matchId) async {
    final result = await _mutate(
      matchId,
      () => ref.read(requestMatchRepositoryProvider).complete(matchId),
      optimistic: (m) => m.copyWith(status: MatchStatus.completed),
    );
    ref.invalidate(chatThreadsProvider);
    return result;
  }
}

final myMatchesProvider = AsyncNotifierProvider<MyMatchesNotifier, List<RequestMatch>>(
  MyMatchesNotifier.new,
);
