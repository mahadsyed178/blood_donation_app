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
import '../state/match_providers.dart';

/// `GET /request-matches/mine` — every request this donor / organization
/// committed to, with ETA update, cancel and complete.
class CommitmentsScreen extends ConsumerStatefulWidget {
  const CommitmentsScreen({super.key});

  @override
  ConsumerState<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends ConsumerState<CommitmentsScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(myMatchesProvider);
    Future<void> refresh() => ref.read(myMatchesProvider.notifier).refresh();

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Active'), icon: Icon(Icons.bolt_rounded, size: 16)),
                ButtonSegment(value: true, label: Text('History'), icon: Icon(Icons.history_rounded, size: 16)),
              ],
              selected: {_showHistory},
              onSelectionChanged: (s) => setState(() => _showHistory = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primaryRed,
                selectedForegroundColor: Colors.white,
                foregroundColor: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryRed,
              onRefresh: refresh,
              child: AsyncView<List<RequestMatch>>(
                value: matches,
                onRetry: refresh,
                loadingBuilder: () => const SkeletonList(),
                isEmpty: (list) => list.where((m) => m.isOpen != _showHistory).isEmpty,
                emptyBuilder: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.volunteer_activism_outlined,
                      title: _showHistory ? 'No past commitments' : 'No active commitments',
                      subtitle: _showHistory
                          ? 'Completed and cancelled commitments appear here.'
                          : 'Accept a nearby request and it will show up here.',
                    ),
                  ],
                ),
                builder: (list) {
                  final items = list.where((m) => m.isOpen != _showHistory).toList();
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _CommitmentCard(match: items[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentCard extends ConsumerStatefulWidget {
  final RequestMatch match;
  const _CommitmentCard({required this.match});

  @override
  ConsumerState<_CommitmentCard> createState() => _CommitmentCardState();
}

class _CommitmentCardState extends ConsumerState<_CommitmentCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showSnack(context, success);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateEta() async {
    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.match.eta ?? now.add(const Duration(minutes: 30))),
      helpText: 'New arrival time (today)',
    );
    if (time == null) return;
    var eta = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!eta.isAfter(now)) eta = eta.add(const Duration(days: 1));
    await _run(
      () => ref.read(myMatchesProvider.notifier).updateEta(widget.match.id, eta),
      'ETA updated to ${formatDateTime(eta)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final r = m.bloodRequest;
    final statusColor = switch (m.status) {
      MatchStatus.accepted => AppColors.amber,
      MatchStatus.completed => AppColors.successGreen,
      MatchStatus.cancelled => AppColors.textGrey,
    };
    final notifier = ref.read(myMatchesProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(r.bloodTypeNeeded.label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.placeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        'Patient: ${r.patientName} · accepted ${timeAgo(m.acceptedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip2(label: m.status.label, color: statusColor, icon: switch (m.status) { MatchStatus.accepted => Icons.hourglass_bottom_rounded, MatchStatus.completed => Icons.check_circle_rounded, MatchStatus.cancelled => Icons.cancel_rounded }),
                Chip2(
                    label: r.urgencyLevel.label,
                    color: AppColors.urgency(r.urgencyLevel.apiValue),
                    icon: Icons.priority_high_rounded),
                Chip2(label: '${m.unitsCommitted} unit(s)', color: AppColors.blue, icon: Icons.water_drop_rounded),
                if (m.distanceKm != null)
                  Chip2(label: formatKm(m.distanceKm!), color: AppColors.textGrey, icon: Icons.near_me_rounded),
                Chip2(label: 'Request ${r.status.label}', color: AppColors.textGrey),
              ],
            ),
            if (m.isOpen && r.approxPoint != null) ...[
              const SizedBox(height: 12),
              ApproximateLocationMap(point: r.approxPoint!, height: 130, caption: r.areaLabel),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Requester',
                    value: '${m.posterName ?? 'Requester'} · ${m.posterPhone}',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Your ETA',
                    value: m.eta != null
                        ? '${formatDateTime(m.eta!)} (${untilLabel(m.eta!)})'
                        : 'Not set',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.event_rounded,
                    label: 'Needed by',
                    value: '${formatDateTime(r.requiredBy)} (${untilLabel(r.requiredBy)})',
                  ),
                  if (m.cancelReason != null && m.cancelReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _InfoRow(icon: Icons.info_outline_rounded, label: 'Reason', value: m.cancelReason!),
                  ],
                ],
              ),
            ),
            if (m.isOpen) ...[
              const SizedBox(height: 14),
              Opacity(
                opacity: _busy ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: _busy,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.chatThreadPath(m.id)),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                        label: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      _outlined(Icons.schedule_rounded, 'Update ETA', _updateEta),
                      _outlined(Icons.task_alt_rounded, 'Mark donated', () async {
                        final ok = await confirmDialog(context,
                            title: 'Mark as donated?',
                            message: 'Confirm that you delivered ${m.unitsCommitted} unit(s).',
                            confirmLabel: 'Yes, donated');
                        if (ok) {
                          await _run(() => notifier.complete(m.id), 'Thank you — donation recorded');
                        }
                      }, color: AppColors.successGreen),
                      _outlined(Icons.cancel_outlined, 'Cancel', () async {
                        final reason = await promptText(context,
                            title: 'Cancel your commitment?',
                            hint: 'Reason (optional)',
                            confirmLabel: 'Cancel commitment');
                        if (reason == null) return;
                        await _run(
                          () => notifier.cancel(m.id, reason: reason),
                          'Commitment cancelled — the request is open again',
                        );
                      }, color: AppColors.textGrey),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _outlined(IconData icon, String label, VoidCallback onTap,
          {Color color = AppColors.primaryRed}) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}
