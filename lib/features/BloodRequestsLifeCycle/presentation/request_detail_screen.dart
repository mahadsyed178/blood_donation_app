import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/geo/geo_utils.dart';
import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/map/approximate_location_map.dart';
import '../../../core/widgets/skeleton.dart';
import '../state/blood_request_providers.dart';
import 'accept_request_sheet.dart';
import 'request_matches_sheet.dart';

/// `GET /blood-requests/{id}` — what a notification opens into. Donors see
/// the approximate area (shaded circle); the poster, the verifying hospital
/// and admins see the exact pin.
class RequestDetailScreen extends ConsumerWidget {
  final String requestId;

  /// Optional pre-loaded copy (from a list) so the screen paints instantly
  /// while the fresh copy loads.
  final BloodRequest? initial;

  const RequestDetailScreen({super.key, required this.requestId, this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bloodRequestByIdProvider(requestId));
    final request = async.value ?? initial;
    final role = ref.watch(currentRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request details'),
        actions: [
          AppIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(bloodRequestByIdProvider(requestId)),
          ),
        ],
      ),
      body: request == null
          ? (async.hasError
              ? ErrorState(
                  error: async.error!,
                  onRetry: () async => ref.invalidate(bloodRequestByIdProvider(requestId)),
                )
              : const SkeletonList(count: 2, cardHeight: 220))
          : _Body(request: request, role: role ?? UserRole.donor, stale: async.hasError),
    );
  }
}

class _Body extends ConsumerWidget {
  final BloodRequest request;
  final UserRole role;
  final bool stale;
  const _Body({required this.request, required this.role, required this.stale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final point = r.displayPoint;
    final urgencyColor = AppColors.urgency(r.urgencyLevel.apiValue);
    final isDonor = role == UserRole.donor;
    final canSeeResponders = role.canPostRequests || role == UserRole.hospital || role == UserRole.admin;
    final donor = ref.watch(currentUserProvider)?.donor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        if (stale)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _Notice(
              icon: Icons.cloud_off_rounded,
              text: 'Showing the last copy we have — couldn’t refresh from the server.',
            ),
          ),
        Card(
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: AppRadius.mdAll),
                      child: Text(r.bloodTypeNeeded.label,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.placeLabel, style: AppText.h2, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (!isDonor) 'Patient: ${r.patientName}',
                              'Posted ${timeAgo(r.createdAt)}',
                              if (r.distanceKm != null) '${GeoUtils.formatDistance(r.distanceKm!)} away',
                            ].join(' · '),
                            style: AppText.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    Chip2(label: r.urgencyLevel.label, color: urgencyColor, icon: Icons.priority_high_rounded),
                    Chip2(label: r.status.label, color: _statusColor(r.status), icon: _statusIcon(r.status)),
                    Chip2(
                      label: r.isHospitalBacked ? 'Hospital-backed' : 'Self-posted',
                      color: r.isHospitalBacked ? AppColors.blue : AppColors.textGrey,
                      icon: r.isHospitalBacked ? Icons.verified_rounded : Icons.person_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _Progress(request: r),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Location
        Text(isDonor ? 'Where to go' : 'Location', style: AppText.h3),
        const SizedBox(height: AppSpacing.sm),
        if (point != null)
          ApproximateLocationMap(
            point: point,
            exact: r.isExactLocation,
            height: 190,
            caption: r.areaLabel,
          )
        else
          _Notice(icon: Icons.map_outlined, text: 'Location unavailable for this request.'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          r.isExactLocation
              ? 'You posted this request, so the pin is exact. Donors only ever see the shaded area.'
              : 'Only the approximate area is shown to protect the patient’s privacy. The exact address is shared by the requester over chat or phone once you commit.',
          style: AppText.caption,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Facts
        Card(
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              children: [
                _Fact(Icons.water_drop_rounded, 'Units needed', '${r.unitsNeeded} (${r.unitsRemaining} still open)'),
                _Fact(Icons.event_rounded, 'Needed by', '${formatDateTime(r.requiredBy)} (${untilLabel(r.requiredBy)})'),
                _Fact(Icons.radar_rounded, 'Search radius', '${r.currentRadiusKm.toStringAsFixed(0)} km'),
                if (r.hospitalNameText != null) _Fact(Icons.local_hospital_outlined, 'Hospital', r.hospitalNameText!),
                if (!isDonor) _Fact(Icons.phone_outlined, 'Contact', r.contactPhone),
                if (r.cancellationReason?.isNotEmpty ?? false)
                  _Fact(Icons.info_outline_rounded, 'Reason', r.cancellationReason!),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        if (isDonor && r.status.isOpen)
          AppButton(
            label: (donor?.isAvailable ?? true) ? 'I can donate' : 'You are marked unavailable',
            icon: Icons.volunteer_activism_rounded,
            enabled: donor?.isAvailable ?? false,
            onPressed: () async {
              final match = await showAcceptRequestSheet(context, r);
              if (match != null && context.mounted) {
                showSnack(context, 'Accepted! Chat with ${match.posterName ?? 'the requester'} is open.');
                context.pushReplacement(AppRoutes.chatThreadPath(match.id));
              }
            },
          ),
        if (canSeeResponders)
          AppButton(
            label: 'See responders',
            icon: Icons.groups_rounded,
            variant: AppButtonVariant.outline,
            onPressed: () => showRequestMatchesSheet(context, r),
          ),
      ],
    );
  }

  Color _statusColor(RequestStatus s) => switch (s) {
        RequestStatus.active || RequestStatus.fulfilled => AppColors.successGreen,
        RequestStatus.partiallyMatched || RequestStatus.fullyMatched => AppColors.amber,
        RequestStatus.pendingVerification => AppColors.orange,
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
}

class _Progress extends StatelessWidget {
  final BloodRequest request;
  const _Progress({required this.request});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final done = r.status == RequestStatus.fulfilled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Units: ${r.unitsSecured} / ${r.unitsNeeded} secured', style: AppText.label),
            Text('${(r.progress * 100).toInt()}%',
                style: AppText.label.copyWith(color: done ? AppColors.successGreen : AppColors.primaryRed)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: r.progress),
            duration: AppDurations.slow,
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              backgroundColor: AppColors.borderGrey,
              color: done ? AppColors.successGreen : AppColors.primaryRed,
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Fact(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.textGrey),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(width: 110, child: Text(label, style: AppText.bodySmall)),
            Expanded(child: Text(value, style: AppText.label)),
          ],
        ),
      );
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Notice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgGrey,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textGrey, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text, style: AppText.bodySmall)),
          ],
        ),
      );
}
