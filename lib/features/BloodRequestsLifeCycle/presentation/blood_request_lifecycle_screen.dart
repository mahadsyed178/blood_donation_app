import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/skeleton.dart';
import '../../Commitments/state/match_providers.dart';
import '../../DonorMatching/presentation/donor_matching_screen.dart';
import '../state/blood_request_providers.dart';
import '../state/matching_rank.dart';
import 'accept_request_sheet.dart';
import 'request_matches_sheet.dart';

/// Donors see the nearby feed (`/blood-requests/nearby/for-me`); requestors
/// and organizations see their own posts (`/blood-requests/mine`). The card
/// actions differ accordingly.
class BloodRequestsLifecycleScreen extends ConsumerStatefulWidget {
  const BloodRequestsLifecycleScreen({super.key});

  @override
  ConsumerState<BloodRequestsLifecycleScreen> createState() =>
      _BloodRequestsLifecycleScreenState();
}

enum _Filter { all, critical, open, matched, pending, fulfilled, closed }

class _BloodRequestsLifecycleScreenState extends ConsumerState<BloodRequestsLifecycleScreen> {
  _Filter _selectedFilter = _Filter.all;

  static const _donorFilters = [_Filter.all, _Filter.critical, _Filter.open, _Filter.matched];
  static const _posterFilters = [
    _Filter.all,
    _Filter.critical,
    _Filter.open,
    _Filter.matched,
    _Filter.pending,
    _Filter.fulfilled,
    _Filter.closed,
  ];

  String _filterLabel(_Filter f) => switch (f) {
        _Filter.all => 'All',
        _Filter.critical => 'Critical',
        _Filter.open => 'Active',
        _Filter.matched => 'Matched',
        _Filter.pending => 'Pending Verification',
        _Filter.fulfilled => 'Fulfilled',
        _Filter.closed => 'Closed',
      };

  bool _matches(BloodRequest r, _Filter f) => switch (f) {
        _Filter.all => true,
        _Filter.critical => r.urgencyLevel == UrgencyLevel.critical,
        _Filter.open => r.status == RequestStatus.active,
        _Filter.matched =>
          r.status == RequestStatus.partiallyMatched || r.status == RequestStatus.fullyMatched,
        _Filter.pending => r.status == RequestStatus.pendingVerification,
        _Filter.fulfilled => r.status == RequestStatus.fulfilled,
        _Filter.closed => r.status.isTerminal && r.status != RequestStatus.fulfilled ||
            r.status == RequestStatus.expired,
      };

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoleProvider);
    if (role == null) return const SizedBox.shrink();
    final isDonor = role == UserRole.donor;
    final donor = ref.watch(currentUserProvider)?.donor;

    final asyncList = isDonor ? ref.watch(nearbyRequestsProvider) : ref.watch(myRequestsProvider);
    final filters = isDonor ? _donorFilters : _posterFilters;
    if (!filters.contains(_selectedFilter)) _selectedFilter = _Filter.all;

    Future<void> refresh() => isDonor
        ? ref.read(nearbyRequestsProvider.notifier).refresh()
        : ref.read(myRequestsProvider.notifier).refresh();

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      floatingActionButton: role.canPostRequests
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryRed,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Request',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => context.push(AppRoutes.createRequest),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightPink,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primaryRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isDonor
                          ? (donor?.hasLocation ?? false)
                              ? 'Requests compatible with your ${donor!.bloodType.label} blood, within each request’s search radius of ${donor.areaLabel}.'
                              : 'Set your location to see requests near you.'
                          : 'Multi-unit requests stay active until all units are fulfilled. Partial donations are tracked live.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textDark),
                    ),
                  ),
                  if (isDonor && !(donor?.hasLocation ?? false))
                    TextButton(
                      onPressed: () => context.push(AppRoutes.locationPicker,
                          extra: LocationPickerMode.donorLocation),
                      child: const Text('Set'),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryRed : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected ? AppColors.primaryRed : AppColors.borderGrey),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _filterLabel(filter),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textGrey,
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryRed,
              onRefresh: refresh,
              child: AsyncView<List<BloodRequest>>(
                value: asyncList,
                onRetry: refresh,
                loadingBuilder: () => const SkeletonList(),
                isEmpty: (list) => list.where((r) => _matches(r, _selectedFilter)).isEmpty,
                emptyBuilder: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.bloodtype_outlined,
                      title: (asyncList.value?.isEmpty ?? true)
                          ? (isDonor ? 'No requests near you' : 'No requests yet')
                          : 'No requests match this filter',
                      subtitle: (asyncList.value?.isEmpty ?? true)
                          ? (isDonor
                              ? 'Pull to refresh. New compatible requests appear here automatically.'
                              : 'Tap “Create Request” to post one.')
                          : 'Try a different filter.',
                    ),
                  ],
                ),
                builder: (list) {
                  var requests = list.where((r) => _matches(r, _selectedFilter)).toList();
                  // PRD ranking for donors: compatibility → distance → recency.
                  if (isDonor && donor != null) requests = rankRequestsForDonor(requests, donor.bloodType);
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: ListView.builder(
                      key: ValueKey('${_selectedFilter.name}-${requests.length}'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: requests.length,
                      itemBuilder: (context, index) => RequestCard(
                        key: ValueKey(requests[index].id),
                        request: requests[index],
                        viewerRole: role,
                      ),
                    ),
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

/// One request, with the actions its viewer is allowed to take.
class RequestCard extends ConsumerWidget {
  final BloodRequest request;
  final UserRole viewerRole;
  const RequestCard({super.key, required this.request, required this.viewerRole});

  Color _statusColor(RequestStatus s) => switch (s) {
        RequestStatus.active => AppColors.successGreen,
        RequestStatus.partiallyMatched || RequestStatus.fullyMatched => AppColors.amber,
        RequestStatus.fulfilled => AppColors.successGreen,
        RequestStatus.pendingVerification => AppColors.orange,
        RequestStatus.draft => AppColors.textGrey,
        _ => AppColors.textGrey,
      };

  IconData _statusIcon(RequestStatus s) => switch (s) {
        RequestStatus.active => Icons.radio_button_checked_rounded,
        RequestStatus.partiallyMatched || RequestStatus.fullyMatched => Icons.hourglass_bottom_rounded,
        RequestStatus.fulfilled => Icons.check_circle_rounded,
        RequestStatus.pendingVerification => Icons.pending_rounded,
        RequestStatus.expired => Icons.timer_off_rounded,
        _ => Icons.cancel_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = request;
    final isDonor = viewerRole == UserRole.donor;
    final isPoster = viewerRole.canPostRequests;
    final progress = data.progress;
    final isFulfilled = data.status == RequestStatus.fulfilled;
    final statusColor = _statusColor(data.status);
    final urgencyColor = AppColors.urgency(data.urgencyLevel.apiValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.urgencyLevel == UrgencyLevel.critical
              ? urgencyColor.withValues(alpha: 0.3)
              : AppColors.borderGrey,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.requestDetailPath(data.id), extra: data),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  child: Text(
                    data.bloodTypeNeeded.label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.placeLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (isPoster) 'Patient: ${data.patientName}',
                          timeAgo(data.createdAt),
                          if (data.distanceKm != null) '${formatKm(data.distanceKm!)} away',
                        ].join(' · '),
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                Chip2(
                    label: data.urgencyLevel.label,
                    color: urgencyColor,
                    icon: Icons.priority_high_rounded),
                Chip2(label: data.status.label, color: statusColor, icon: _statusIcon(data.status)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    data.isHospitalBacked ? 'Hospital-backed' : 'Self-posted',
                    style: const TextStyle(
                        color: AppColors.primaryRed, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Chip2(
                  label: 'Needed ${untilLabel(data.requiredBy)}',
                  color: AppColors.textGrey,
                  icon: Icons.schedule_rounded,
                ),
                if (isPoster)
                  Chip2(
                    label: 'Radius ${data.currentRadiusKm.toStringAsFixed(0)} km',
                    color: AppColors.blue,
                    icon: Icons.radar_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Units: ${data.unitsSecured} / ${data.unitsNeeded} secured',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isFulfilled ? AppColors.successGreen : AppColors.primaryRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.borderGrey,
                color: isFulfilled ? AppColors.successGreen : AppColors.primaryRed,
                minHeight: 6,
              ),
            ),
            if (data.cancellationReason != null && data.cancellationReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Reason: ${data.cancellationReason}',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            if (isFulfilled)
              _FulfilledBanner()
            else if (isDonor)
              _DonorActions(request: data)
            else if (isPoster)
              _PosterActions(request: data),
          ],
        ),
      ),
      ),
    );
  }
}

class _FulfilledBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 16),
            SizedBox(width: 6),
            Text(
              'Request fulfilled — thank you to all donors',
              style: TextStyle(
                  color: AppColors.successGreen, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

class _DonorActions extends ConsumerWidget {
  final BloodRequest request;
  const _DonorActions({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donor = ref.watch(currentUserProvider)?.donor;
    final canAccept = request.status.isOpen && (donor?.isAvailable ?? false);
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.requestDetailPath(request.id), extra: request),
          icon: const Icon(Icons.map_outlined, size: 16),
          label: const Text('Details'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textDark,
            side: const BorderSide(color: AppColors.borderGrey),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.volunteer_activism, size: 16),
            label: Text(canAccept
                ? 'I Can Donate'
                : (donor?.isAvailable ?? true) ? 'Not open' : 'You are unavailable'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
              side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: canAccept
                ? () async {
                    final match = await showAcceptRequestSheet(context, request);
                    if (match != null && context.mounted) {
                      showSnack(context, 'Accepted! Chat with ${match.posterName ?? 'the requester'} is open.');
                      context.push(AppRoutes.chatThreadPath(match.id));
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class _PosterActions extends ConsumerStatefulWidget {
  final BloodRequest request;
  const _PosterActions({required this.request});

  @override
  ConsumerState<_PosterActions> createState() => _PosterActionsState();
}

class _PosterActionsState extends ConsumerState<_PosterActions> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && success != null) showSnack(context, success);
      // Matches may have changed with the request.
      ref.invalidate(myMatchesProvider);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final notifier = ref.read(myRequestsProvider.notifier);
    final s = r.status;

    final actions = <Widget>[
      if (s.isOpen || s == RequestStatus.fullyMatched || s == RequestStatus.expired)
        _btn(
          Icons.groups_rounded,
          'Responders (${r.unitsSecured > 0 ? 'active' : 'none yet'})',
          () => showRequestMatchesSheet(context, r),
          primary: true,
        ),
      if (s.isOpen)
        _btn(Icons.radar_rounded, 'Widen radius', () async {
          final ok = await confirmDialog(context,
              title: 'Widen search radius?',
              message:
                  'Currently ${r.currentRadiusKm.toStringAsFixed(0)} km. More donors will be notified.',
              confirmLabel: 'Widen');
          if (ok) await _run(() => notifier.widen(r.id), success: 'Radius widened');
        }),
      if (s == RequestStatus.expired)
        _btn(Icons.replay_rounded, 'Reactivate', () async {
          await _run(() => notifier.reactivate(r.id), success: 'Request reactivated');
        }),
      if (!s.isTerminal && s != RequestStatus.draft)
        _btn(Icons.cancel_outlined, 'Cancel', () async {
          final reason = await promptText(context,
              title: 'Cancel this request?',
              hint: 'Reason (optional)',
              confirmLabel: 'Cancel request');
          if (reason == null) return;
          await _run(() => notifier.cancel(r.id, reason: reason), success: 'Request cancelled');
        }, danger: true),
      if (s == RequestStatus.fullyMatched || s == RequestStatus.partiallyMatched)
        _btn(Icons.task_alt_rounded, 'Close', () async {
          final ok = await confirmDialog(context,
              title: 'Close this request?',
              message: 'Use this when the need has been met outside the app.',
              confirmLabel: 'Close');
          if (ok) await _run(() => notifier.close(r.id), success: 'Request closed');
        }),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();
    return Opacity(
      opacity: _busy ? 0.5 : 1,
      child: IgnorePointer(
        ignoring: _busy,
        child: Wrap(spacing: 8, runSpacing: 8, children: actions),
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap,
      {bool primary = false, bool danger = false}) {
    final color = danger ? AppColors.textGrey : AppColors.primaryRed;
    return primary
        ? ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 16, color: Colors.white),
            label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        : OutlinedButton.icon(
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
}
