import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/map/approximate_location_map.dart';
import '../../../core/widgets/skeleton.dart';
import '../state/blood_request_providers.dart';
import '../state/matching_rank.dart';

/// `GET /blood-requests/{id}/matches` — who has committed, with contact
/// details, for the poster (or hospital / admin).
Future<void> showRequestMatchesSheet(BuildContext context, BloodRequest request) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _MatchesSheet(request: request),
  );
}

class _MatchesSheet extends ConsumerWidget {
  final BloodRequest request;
  const _MatchesSheet({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(requestMatchesProvider(request.id));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.borderGrey, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Responders',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      Text(
                        '${request.bloodTypeNeeded.label} for ${request.patientName} · ${request.unitsSecured}/${request.unitsNeeded} units secured',
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref.invalidate(requestMatchesProvider(request.id)),
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<List<RequestMatch>>(
              value: matches,
              onRetry: () async => ref.invalidate(requestMatchesProvider(request.id)),
              loadingBuilder: () => const SkeletonList(count: 2, cardHeight: 120, padding: EdgeInsets.all(20)),
              isEmpty: (l) => l.isEmpty,
              emptyBuilder: () => const EmptyState(
                icon: Icons.hourglass_empty_rounded,
                title: 'No one has committed yet',
                subtitle: 'Nearby compatible donors have been notified. Widening the radius reaches more of them.',
              ),
              builder: (list) {
                final ranked = rankMatchesForPoster(list);
                return ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: ranked.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _MatchTile(match: ranked[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final RequestMatch match;
  const _MatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final color = switch (m.status) {
      MatchStatus.accepted => AppColors.amber,
      MatchStatus.completed => AppColors.successGreen,
      MatchStatus.cancelled => AppColors.textGrey,
    };
    final isOrg = m.organizationId != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(isOrg ? Icons.inventory_2_rounded : Icons.person_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.acceptorName ?? (isOrg ? 'Organization' : 'Donor'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(
                      '${m.unitsCommitted} unit(s) · ${m.status.label}'
                      '${m.distanceKm != null ? ' · ${formatKm(m.distanceKm!)} away' : ''}',
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Chip2(label: m.status.label, color: color, icon: switch (m.status) { MatchStatus.accepted => Icons.hourglass_bottom_rounded, MatchStatus.completed => Icons.check_circle_rounded, MatchStatus.cancelled => Icons.cancel_rounded }),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(
                m.eta != null ? 'ETA ${formatDateTime(m.eta!)} (${untilLabel(m.eta!)})' : 'No ETA given',
                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
              ),
              const Spacer(),
              if (m.acceptorPhone != null) ...[
                const Icon(Icons.phone_rounded, size: 14, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text(m.acceptorPhone!, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
          if (m.isOpen && m.acceptorApproxPoint != null) ...[
            const SizedBox(height: 10),
            ApproximateLocationMap(
              point: m.acceptorApproxPoint!,
              height: 110,
              caption: m.distanceKm != null ? '${formatKm(m.distanceKm!)} from the patient' : null,
            ),
          ],
          if (m.cancelReason != null && m.cancelReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Cancelled: ${m.cancelReason}',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          ],
          if (m.isOpen) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.chatThreadPath(m.id));
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Open chat'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primaryRed),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
