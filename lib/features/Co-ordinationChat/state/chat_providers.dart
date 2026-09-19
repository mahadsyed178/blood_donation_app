import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/core_providers.dart';

/// `GET /chat/threads` — the caller's conversations, most recent first.
class ChatThreadsNotifier extends AsyncNotifier<List<ChatThreadSummary>> {
  @override
  Future<List<ChatThreadSummary>> build() async {
    ref.watch(authProvider.select((s) => s.user?.id));
    final role = ref.read(currentRoleProvider);
    if (role == null || !role.canChat) return const [];
    return ref.read(chatRepositoryProvider).listThreads(limit: 100);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(chatRepositoryProvider).listThreads(limit: 100));
  }
}

final chatThreadsProvider =
    AsyncNotifierProvider<ChatThreadsNotifier, List<ChatThreadSummary>>(
  ChatThreadsNotifier.new,
);

/// History for one match: `GET /chat/{match_id}/messages`. The live socket
/// appends to this in the detail screen.
final chatMessagesProvider =
    FutureProvider.autoDispose.family<List<ChatMessage>, String>((ref, matchId) {
  return ref.read(chatRepositoryProvider).listMessages(matchId);
});
