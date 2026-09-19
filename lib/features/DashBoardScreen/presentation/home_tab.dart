import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/accounts.dart';
import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../AdminSafetyConsole/state/admin_providers.dart';
import '../../BloodRequestsLifeCycle/state/blood_request_providers.dart';
import '../../Commitments/state/match_providers.dart';
import '../../DonorMatching/presentation/donor_matching_screen.dart';
import '../../HospitalVerification/state/hospital_providers.dart';

/// The overview tab. Every number here is derived from the same providers
/// the detail tabs use, so it never disagrees with them.
class HomeTab extends ConsumerWidget {
  final ValueChanged<int> onSwitchTab;
  const HomeTab({super.key, required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final body = switch (user.role) {
      UserRole.donor => _DonorHome(user: user, onSwitchTab: onSwitchTab),
      UserRole.requestor || UserRole.organization =>
        _PosterHome(user: user, onSwitchTab: onSwitchTab),
      UserRole.hospital => _HospitalHome(user: user, onSwitchTab: onSwitchTab),
      UserRole.admin => _AdminHome(user: user, onSwitchTab: onSwitchTab),
    };

    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () => _refreshFor(ref, user.role),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: body,
      ),
    );
  }

  Future<void> _refreshFor(WidgetRef ref, UserRole role) async {
    final futures = <Future<void>>[ref.read(authProvider.notifier).refreshUser()];
    switch (role) {
      case UserRole.donor:
        futures.add(ref.read(nearbyRequestsProvider.notifier).refresh());
        futures.add(ref.read(myMatchesProvider.notifier).refresh());
      case UserRole.requestor:
        futures.add(ref.read(myRequestsProvider.notifier).refresh());
      case UserRole.organization:
        futures.add(ref.read(myRequestsProvider.notifier).refresh());
        futures.add(ref.read(myMatchesProvider.notifier).refresh());
      case UserRole.hospital:
        futures.add(ref.read(hospitalQueueProvider.notifier).refresh());
      case UserRole.admin:
        futures.add(ref.read(pendingHospitalsProvider.notifier).refresh());
        futures.add(ref.read(pendingOrganizationsProvider.notifier).refresh());
    }
    await Future.wait(futures);
  }
}

// --- Donor -----------------------------------------------------------------

class _DonorHome extends ConsumerWidget {
  final AuthUser user;
  final ValueChanged<int> onSwitchTab;
  const _DonorHome({required this.user, required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donor = user.donor!;
    final nearby = ref.watch(nearbyRequestsProvider);
    final matches = ref.watch(myMatchesProvider);

    final nearbyList = nearby.value ?? const <BloodRequest>[];
    final matchList = matches.value ?? const <RequestMatch>[];
    final openCommitments = matchList.where((m) => m.isOpen).length;
    final completed = matchList.where((m) => m.status == MatchStatus.completed).length;

    BloodRequest? spotlight;
    if (nearbyList.isNotEmpty) {
      final sorted = [...nearbyList]..sort((a, b) {
          final u = a.urgencyLevel.index.compareTo(b.urgencyLevel.index);
          return u != 0 ? u : (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0);
        });
      spotlight = sorted.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeCard(
          title: 'Welcome back, ${_firstName(user.displayName)} 🩸',
          message: !donor.hasLocation
              ? 'Set your location to start receiving requests that match your ${donor.bloodType.label} blood.'
              : spotlight != null
                  ? '${spotlight.bloodTypeNeeded.label} needed ${formatKm(spotlight.distanceKm ?? 0)} away at ${spotlight.placeLabel} — you could be the match.'
                  : 'No compatible requests within ${donor.areaLabel} right now. We’ll surface them here as they come in.',
          chipLabel: '${donor.bloodType.label} Blood Group',
          actionLabel: !donor.hasLocation ? 'Set location' : 'Respond now',
          onAction: () => !donor.hasLocation
              ? context.push(AppRoutes.locationPicker, extra: LocationPickerMode.donorLocation)
              : onSwitchTab(1),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.bloodtype_rounded,
                iconColor: AppColors.primaryRed,
                value: nearby.hasValue ? '${nearbyList.length}' : '–',
                label: 'Nearby\nRequests',
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.volunteer_activism_rounded,
                iconColor: AppColors.amber,
                value: matches.hasValue ? '$openCommitments' : '–',
                label: 'Active\nCommitments',
                onTap: () => onSwitchTab(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.blue,
                value: matches.hasValue ? '$completed' : '–',
                label: 'Donations\nCompleted',
                onTap: () => onSwitchTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _AvailabilityBanner(donor: donor),
        if (spotlight != null && spotlight.urgencyLevel == UrgencyLevel.critical) ...[
          const SizedBox(height: 20),
          _AlertCard(
            title: 'Critical request nearby',
            subtitle:
                '${spotlight.bloodTypeNeeded.label} · ${spotlight.unitsRemaining} unit(s) at ${spotlight.placeLabel} · ${formatKm(spotlight.distanceKm ?? 0)} away',
            onTap: () => onSwitchTab(1),
          ),
        ],
        const SizedBox(height: 24),
        const _SectionTitle('Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.search_rounded,
                label: 'Browse Requests',
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.my_location_rounded,
                label: donor.hasLocation ? 'Update Location' : 'Set Location',
                onTap: () => onSwitchTab(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Recent Activity'),
        const SizedBox(height: 12),
        if (matches.hasError)
          ErrorState(error: matches.error!, onRetry: () => ref.read(myMatchesProvider.notifier).refresh())
        else if (!matches.hasValue)
          const Padding(padding: EdgeInsets.all(24), child: LoadingState())
        else if (matchList.isEmpty)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'No activity yet',
            subtitle: 'Commitments you make will show up here.',
          )
        else
          ...matchList.take(4).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityTile(
                  icon: switch (m.status) {
                    MatchStatus.completed => Icons.check_circle_rounded,
                    MatchStatus.cancelled => Icons.cancel_rounded,
                    MatchStatus.accepted => Icons.volunteer_activism_rounded,
                  },
                  iconColor: switch (m.status) {
                    MatchStatus.completed => AppColors.successGreen,
                    MatchStatus.cancelled => AppColors.textGrey,
                    MatchStatus.accepted => AppColors.amber,
                  },
                  title: switch (m.status) {
                    MatchStatus.completed => 'Donation completed',
                    MatchStatus.cancelled => 'Commitment cancelled',
                    MatchStatus.accepted => 'Committed ${m.unitsCommitted} unit(s)',
                  },
                  subtitle:
                      '${m.bloodRequest.bloodTypeNeeded.label} for ${m.bloodRequest.patientName} at ${m.bloodRequest.placeLabel}',
                  time: timeAgo(m.completedAt ?? m.acceptedAt),
                ),
              )),
      ],
    );
  }
}

class _AvailabilityBanner extends ConsumerWidget {
  final Donor donor;
  const _AvailabilityBanner({required this.donor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = donor.isAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: available ? AppColors.successBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: available ? AppColors.successGreen.withValues(alpha: 0.4) : AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Icon(available ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded,
              color: available ? AppColors.successGreen : AppColors.textGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              available
                  ? 'You are marked available${donor.areaLabel != null ? ' near ${donor.areaLabel}' : ''}'
                  : 'You are marked unavailable — new requests won’t reach you',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: available,
            activeThumbColor: AppColors.successGreen,
            onChanged: (v) async {
              try {
                await ref.read(authProvider.notifier).setDonorAvailability(v);
              } catch (e) {
                if (context.mounted) showApiError(context, e);
              }
            },
          ),
        ],
      ),
    );
  }
}

// --- Requester / Organization ----------------------------------------------

class _PosterHome extends ConsumerWidget {
  final AuthUser user;
  final ValueChanged<int> onSwitchTab;
  const _PosterHome({required this.user, required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(myRequestsProvider);
    final list = requests.value ?? const <BloodRequest>[];
    final open = list.where((r) => r.status.isOpen || r.status == RequestStatus.fullyMatched).toList();
    final pending = list.where((r) => r.status == RequestStatus.pendingVerification).length;
    final fulfilled = list.where((r) => r.status == RequestStatus.fulfilled).length;
    final unitsSecured = open.fold<int>(0, (sum, r) => sum + r.unitsSecured);
    final unitsNeeded = open.fold<int>(0, (sum, r) => sum + r.unitsNeeded);

    final isOrg = user.role == UserRole.organization;
    final matches = isOrg ? ref.watch(myMatchesProvider) : null;
    final openCommitments = (matches?.value ?? const <RequestMatch>[]).where((m) => m.isOpen).length;

    final mostUrgent = open.isEmpty
        ? null
        : ([...open]..sort((a, b) => a.urgencyLevel.index.compareTo(b.urgencyLevel.index))).first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeCard(
          title: 'Welcome back, ${_firstName(user.displayName)}',
          message: mostUrgent != null
              ? 'Your ${mostUrgent.bloodTypeNeeded.label} request for ${mostUrgent.patientName} has ${mostUrgent.unitsSecured}/${mostUrgent.unitsNeeded} units secured.'
              : pending > 0
                  ? '$pending request(s) are waiting for hospital verification before donors are notified.'
                  : 'No open requests. Post one and nearby compatible donors are notified immediately.',
          chipLabel: '${open.length} open',
          actionLabel: mostUrgent != null ? 'View responses' : 'New request',
          onAction: () => mostUrgent != null ? onSwitchTab(1) : context.push(AppRoutes.createRequest),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.bloodtype_rounded,
                iconColor: AppColors.primaryRed,
                value: requests.hasValue ? '${open.length}' : '–',
                label: 'Active\nRequests',
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.water_drop_rounded,
                iconColor: AppColors.amber,
                value: requests.hasValue ? '$unitsSecured/$unitsNeeded' : '–',
                label: 'Units\nSecured',
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.blue,
                value: requests.hasValue ? '$fulfilled' : '–',
                label: 'Requests\nFulfilled',
                onTap: () => onSwitchTab(1),
              ),
            ),
          ],
        ),
        if (isOrg) ...[
          const SizedBox(height: 12),
          _AlertCard(
            title: '$openCommitments open commitment(s) as a donor organization',
            subtitle: 'Track ETAs and mark deliveries complete',
            icon: Icons.inventory_2_rounded,
            color: AppColors.blue,
            onTap: () => onSwitchTab(2),
          ),
        ],
        if (pending > 0) ...[
          const SizedBox(height: 20),
          _AlertCard(
            title: '$pending request(s) pending hospital verification',
            subtitle: 'Donors are notified once the hospital approves',
            icon: Icons.hourglass_top_rounded,
            color: AppColors.amber,
            onTap: () => onSwitchTab(1),
          ),
        ],
        const SizedBox(height: 24),
        const _SectionTitle('Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.add_circle_outline_rounded,
                label: 'New Request',
                onTap: () => context.push(AppRoutes.createRequest),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Open Chats',
                onTap: () => onSwitchTab(isOrg ? 3 : 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Recent Requests'),
        const SizedBox(height: 12),
        if (requests.hasError)
          ErrorState(error: requests.error!, onRetry: () => ref.read(myRequestsProvider.notifier).refresh())
        else if (!requests.hasValue)
          const Padding(padding: EdgeInsets.all(24), child: LoadingState())
        else if (list.isEmpty)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'No requests yet',
            subtitle: 'Tap “New Request” to post your first one.',
          )
        else
          ...list.take(4).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityTile(
                  icon: switch (r.status) {
                    RequestStatus.fulfilled => Icons.check_circle_rounded,
                    RequestStatus.pendingVerification => Icons.hourglass_top_rounded,
                    RequestStatus.cancelled ||
                    RequestStatus.closed ||
                    RequestStatus.rejected ||
                    RequestStatus.expired =>
                      Icons.cancel_rounded,
                    _ => Icons.bloodtype_rounded,
                  },
                  iconColor: switch (r.status) {
                    RequestStatus.fulfilled => AppColors.successGreen,
                    RequestStatus.pendingVerification => AppColors.amber,
                    RequestStatus.cancelled ||
                    RequestStatus.closed ||
                    RequestStatus.rejected ||
                    RequestStatus.expired =>
                      AppColors.textGrey,
                    _ => AppColors.primaryRed,
                  },
                  title: '${r.bloodTypeNeeded.label} · ${r.patientName} · ${r.status.label}',
                  subtitle: '${r.unitsSecured}/${r.unitsNeeded} units · ${r.placeLabel}',
                  time: timeAgo(r.updatedAt),
                ),
              )),
      ],
    );
  }
}

// --- Hospital ----------------------------------------------------------------

class _HospitalHome extends ConsumerWidget {
  final AuthUser user;
  final ValueChanged<int> onSwitchTab;
  const _HospitalHome({required this.user, required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(hospitalQueueProvider);
    final list = queue.value ?? const <BloodRequest>[];
    final critical = list.where((r) => r.urgencyLevel == UrgencyLevel.critical).length;
    final hospital = user.hospital!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeCard(
          title: hospital.name,
          message: list.isEmpty
              ? 'No requests are waiting for verification. Requests that name your hospital appear here first.'
              : '${list.length} request(s) name your hospital and need verification before donors are notified.',
          chipLabel: hospital.address,
          actionLabel: 'Open review queue',
          onAction: () => onSwitchTab(1),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.pending_actions_rounded,
                iconColor: AppColors.amber,
                value: queue.hasValue ? '${list.length}' : '–',
                label: 'Awaiting\nVerification',
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.priority_high_rounded,
                iconColor: AppColors.critical,
                value: queue.hasValue ? '$critical' : '–',
                label: 'Critical\nUrgency',
                onTap: () => onSwitchTab(1),
              ),
            ),
          ],
        ),
        if (queue.hasError) ...[
          const SizedBox(height: 20),
          ErrorState(error: queue.error!, onRetry: () => ref.read(hospitalQueueProvider.notifier).refresh()),
        ],
      ],
    );
  }
}

// --- Admin ------------------------------------------------------------------

class _AdminHome extends ConsumerStatefulWidget {
  final AuthUser user;
  final ValueChanged<int> onSwitchTab;
  const _AdminHome({required this.user, required this.onSwitchTab});

  @override
  ConsumerState<_AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends ConsumerState<_AdminHome> {
  bool _sweeping = false;

  Future<void> _runSweeps() async {
    setState(() => _sweeping = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final expired = await repo.expireOverdue();
      final widened = await repo.autoWiden();
      if (mounted) showSnack(context, 'Sweep done: $expired expired, $widened widened');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _sweeping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitals = ref.watch(pendingHospitalsProvider);
    final orgs = ref.watch(pendingOrganizationsProvider);
    final h = hospitals.value?.length;
    final o = orgs.value?.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeCard(
          title: 'Administrator',
          message: (h ?? 0) + (o ?? 0) == 0
              ? 'No hospitals or organizations are waiting for approval.'
              : '${h ?? 0} hospital(s) and ${o ?? 0} organization(s) are waiting for approval before they can log in.',
          chipLabel: widget.user.email,
          actionLabel: 'Review approvals',
          onAction: () => widget.onSwitchTab(1),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_hospital_rounded,
                iconColor: AppColors.primaryRed,
                value: h?.toString() ?? '–',
                label: 'Hospitals\nPending',
                onTap: () => widget.onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.inventory_2_rounded,
                iconColor: AppColors.blue,
                value: o?.toString() ?? '–',
                label: 'Organizations\nPending',
                onTap: () => widget.onSwitchTab(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Maintenance'),
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: _sweeping ? Icons.hourglass_top_rounded : Icons.cleaning_services_rounded,
          label: _sweeping ? 'Running sweeps…' : 'Run expiry & auto-widen sweeps now',
          onTap: _sweeping ? () {} : _runSweeps,
        ),
        const SizedBox(height: 8),
        const Text(
          'Sweeps also run automatically inside the API every few minutes.',
          style: TextStyle(color: AppColors.textGrey, fontSize: 11.5),
        ),
      ],
    );
  }
}

// --- Shared pieces ----------------------------------------------------------

String _firstName(String full) => full.trim().split(RegExp(r'\s+')).first;

class _WelcomeCard extends StatelessWidget {
  final String title;
  final String message;
  final String chipLabel;
  final String actionLabel;
  final VoidCallback onAction;

  const _WelcomeCard({
    required this.title,
    required this.message,
    required this.chipLabel,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryRed, AppColors.deepRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4)),
            const SizedBox(height: 14),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(chipLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(actionLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      );
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  const _AlertCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.warning_amber_rounded,
    this.color = AppColors.primaryRed,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w800),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.lightPink,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryRed, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time,
              style: const TextStyle(
                  color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
