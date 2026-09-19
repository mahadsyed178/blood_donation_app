import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/chat.dart';
import '../../../core/models/enums.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/skeleton.dart';
import '../state/chat_providers.dart';

/// `GET /chat/threads` — one row per match this account is part of.
class CoordinationChatScreen extends ConsumerWidget {
  const CoordinationChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(chatThreadsProvider);
    Future<void> refresh() => ref.read(chatThreadsProvider.notifier).refresh();

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: refresh,
        child: AsyncView<List<ChatThreadSummary>>(
          value: threads,
          onRetry: refresh,
          loadingBuilder: () => const SkeletonList(cardHeight: 92, padding: EdgeInsets.all(16)),
          isEmpty: (l) => l.isEmpty,
          emptyBuilder: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 80),
              EmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'No conversations yet',
                subtitle: 'A private chat opens automatically for every commitment.',
              ),
            ],
          ),
          builder: (list) => ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ThreadTile(thread: list[i]),
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThreadSummary thread;
  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final t = thread;
    final closed = t.matchStatus != MatchStatus.accepted;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(AppRoutes.chatThreadPath(t.matchId), extra: t),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.lightPink,
                  child: Text(
                    t.bloodTypeNeeded.label,
                    style: const TextStyle(
                        color: AppColors.primaryRed, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: closed ? AppColors.textGrey : AppColors.successGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.counterpartyName ?? 'Participant',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                      Text(
                        t.lastMessageAt != null ? timeAgo(t.lastMessageAt!) : timeAgo(t.createdAt),
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.counterpartyRole?.label ?? ''} · ${t.hospitalName ?? t.areaLabel ?? ''} · ${t.urgencyLevel.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.lastMessagePreview ?? 'Say hello to coordinate the donation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.lastMessagePreview == null ? AppColors.hintGrey : AppColors.textDark,
                      fontSize: 12.5,
                      fontStyle: t.lastMessagePreview == null ? FontStyle.italic : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
