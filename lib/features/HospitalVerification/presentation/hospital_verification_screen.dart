import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/map/approximate_location_map.dart';
import '../../../core/widgets/skeleton.dart';
import '../state/hospital_providers.dart';

/// `GET /blood-requests/hospital/pending` +
/// `PATCH /blood-requests/{id}/hospital-verify?approve=`.
///
/// The backend takes no rejection reason, so rejecting is a plain confirm.
class HospitalVerificationScreen extends ConsumerWidget {
  const HospitalVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(hospitalQueueProvider);
    Future<void> refresh() => ref.read(hospitalQueueProvider.notifier).refresh();

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: refresh,
        child: AsyncView<List<BloodRequest>>(
          value: queue,
          onRetry: refresh,
          loadingBuilder: () => const SkeletonList(padding: EdgeInsets.all(16)),
          builder: (list) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_hospital_rounded, color: AppColors.primaryRed, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Verify incoming blood requests that name your facility before they become visible to donors.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pending Verification',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${list.length} pending',
                      style: const TextStyle(
                          color: AppColors.primaryRed, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const EmptyState(
                  icon: Icons.verified_outlined,
                  title: 'Queue is clear',
                  subtitle: 'New requests naming your hospital will appear here.',
                )
              else
                ...list.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _VerificationCard(request: r),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationCard extends ConsumerStatefulWidget {
  final BloodRequest request;
  const _VerificationCard({required this.request});

  @override
  ConsumerState<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends ConsumerState<_VerificationCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final r = widget.request;
    if (!approve) {
      final ok = await confirmDialog(context,
          title: 'Mark as not verified?',
          message:
              'The request for ${r.patientName} will be rejected and the requester informed. This cannot be undone.',
          confirmLabel: 'Reject',
          destructive: true);
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(hospitalQueueProvider.notifier).decide(r.id, approve: approve);
      if (!mounted) return;
      showSnack(
        context,
        approve
            ? '${r.patientName}’s request is now ACTIVE and visible to donors.'
            : 'Marked not verified — returned to the requester.',
        isError: !approve,
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final isCritical = r.urgencyLevel == UrgencyLevel.critical;
    final urgencyColor = AppColors.urgency(r.urgencyLevel.apiValue);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCritical ? urgencyColor.withValues(alpha: 0.35) : AppColors.borderGrey),
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
                      Text(r.patientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${r.unitsNeeded} unit(s) · submitted ${timeAgo(r.createdAt)}',
                          style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                Chip2(
                    label: r.urgencyLevel.label,
                    color: urgencyColor,
                    icon: Icons.priority_high_rounded),
              ],
            ),
            if (r.displayPoint != null) ...[
              const SizedBox(height: 12),
              ApproximateLocationMap(point: r.displayPoint!, exact: r.isExactLocation, height: 130, caption: r.areaLabel),
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
                  _row(Icons.place_outlined, 'Area', r.areaLabel ?? '—'),
                  const SizedBox(height: 6),
                  _row(Icons.event_rounded, 'Needed by',
                      '${formatDateTime(r.requiredBy)} (${untilLabel(r.requiredBy)})'),
                  const SizedBox(height: 6),
                  _row(Icons.phone_outlined, 'Contact', r.contactPhone),
                  const SizedBox(height: 6),
                  _row(Icons.radar_rounded, 'Initial radius', '${r.currentRadiusKm.toStringAsFixed(0)} km'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _decide(false),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Not Verified'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _decide(true),
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                    label: const Text('Verify & Activate', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
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
