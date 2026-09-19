import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/accounts.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../AdminSafetyConsole/presentation/admin_safety_console_screen.dart';
import '../../AdminSafetyConsole/state/admin_providers.dart';
import '../../BloodRequestsLifeCycle/presentation/blood_request_lifecycle_screen.dart';
import '../../BloodRequestsLifeCycle/state/blood_request_providers.dart';
import '../../Co-ordinationChat/presenatation/coordination_chat_screen.dart';
import '../../Commitments/presentation/commitments_screen.dart';
import '../../DonorMatching/presentation/donor_matching_screen.dart';
import '../../HospitalVerification/presentation/hospital_verification_screen.dart';
import '../../HospitalVerification/state/hospital_providers.dart';
import 'home_tab.dart';

/// One tab definition: what the bottom bar shows and what it opens.
class DashboardTab {
  final String title;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  const DashboardTab({
    required this.title,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}

/// Shell around the role-specific tabs. The role comes from the session —
/// there is no in-app role switching, because each role is a separate
/// backend account.
class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  ConsumerState<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  int _currentTabIndex = 0;

  /// Tabs that have been opened at least once. IndexedStack builds every
  /// child up front, which would start the map's GPS lookup (and its system
  /// prompt) while the user is still on Home; other tabs stay alive once
  /// visited so their state persists across switches.
  final Set<int> _visited = {0};

  List<DashboardTab> _tabsFor(UserRole role) {
    final home = DashboardTab(
      title: 'BLOOD-BRIDGE',
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      screen: HomeTab(onSwitchTab: _switchTab),
    );
    switch (role) {
      case UserRole.donor:
        return [
          home,
          const DashboardTab(
            title: 'Nearby Requests',
            label: 'Nearby',
            icon: Icons.bloodtype_outlined,
            activeIcon: Icons.bloodtype,
            screen: BloodRequestsLifecycleScreen(),
          ),
          const DashboardTab(
            title: 'My Commitments',
            label: 'Commitments',
            icon: Icons.volunteer_activism_outlined,
            activeIcon: Icons.volunteer_activism,
            screen: CommitmentsScreen(),
          ),
          const DashboardTab(
            title: 'My Location',
            label: 'Location',
            icon: Icons.map_outlined,
            activeIcon: Icons.map,
            screen: DonorMatchingScreen(mode: LocationPickerMode.donorLocation, embedded: true),
          ),
          const DashboardTab(
            title: 'Coordination Chats',
            label: 'Chats',
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            screen: CoordinationChatScreen(),
          ),
        ];
      case UserRole.requestor:
        return [
          home,
          const DashboardTab(
            title: 'My Blood Requests',
            label: 'Requests',
            icon: Icons.bloodtype_outlined,
            activeIcon: Icons.bloodtype,
            screen: BloodRequestsLifecycleScreen(),
          ),
          const DashboardTab(
            title: 'Coordination Chats',
            label: 'Chats',
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            screen: CoordinationChatScreen(),
          ),
        ];
      case UserRole.organization:
        return [
          home,
          const DashboardTab(
            title: 'Our Blood Requests',
            label: 'Requests',
            icon: Icons.bloodtype_outlined,
            activeIcon: Icons.bloodtype,
            screen: BloodRequestsLifecycleScreen(),
          ),
          const DashboardTab(
            title: 'Our Commitments',
            label: 'Commitments',
            icon: Icons.volunteer_activism_outlined,
            activeIcon: Icons.volunteer_activism,
            screen: CommitmentsScreen(),
          ),
          const DashboardTab(
            title: 'Coordination Chats',
            label: 'Chats',
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            screen: CoordinationChatScreen(),
          ),
        ];
      case UserRole.hospital:
        return [
          home,
          const DashboardTab(
            title: 'Hospital Review Queue',
            label: 'Review Queue',
            icon: Icons.local_hospital_outlined,
            activeIcon: Icons.local_hospital,
            screen: HospitalVerificationScreen(),
          ),
        ];
      case UserRole.admin:
        return [
          home,
          const DashboardTab(
            title: 'Admin Console',
            label: 'Approvals',
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings,
            screen: AdminSafetyConsoleScreen(),
          ),
        ];
    }
  }

  void _switchTab(int index) => setState(() {
        _currentTabIndex = index;
        _visited.add(index);
      });

  /// Items that deserve the user's attention right now, for the bell badge.
  int _attentionCount(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return (ref.watch(nearbyRequestsProvider).value ?? const [])
            .where((r) => r.urgencyLevel == UrgencyLevel.critical)
            .length;
      case UserRole.requestor:
      case UserRole.organization:
        return (ref.watch(myRequestsProvider).value ?? const [])
            .where((r) => r.status.isOpen || r.status == RequestStatus.fullyMatched)
            .length;
      case UserRole.hospital:
        return (ref.watch(hospitalQueueProvider).value ?? const []).length;
      case UserRole.admin:
        return (ref.watch(pendingHospitalsProvider).value ?? const []).length +
            (ref.watch(pendingOrganizationsProvider).value ?? const []).length;
    }
  }

  String _attentionMessage(UserRole role, int count) => switch (role) {
        UserRole.donor => '$count critical request${count == 1 ? '' : 's'} near you',
        UserRole.requestor || UserRole.organization =>
          '$count open request${count == 1 ? '' : 's'} being matched',
        UserRole.hospital => '$count request${count == 1 ? '' : 's'} awaiting your verification',
        UserRole.admin => '$count account${count == 1 ? '' : 's'} awaiting approval',
      };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      // The router redirects on logout; render nothing in the meantime.
      return const Scaffold(body: SizedBox.shrink());
    }
    final tabs = _tabsFor(user.role);
    if (_currentTabIndex >= tabs.length) _currentTabIndex = 0;
    final bool isHome = _currentTabIndex == 0;
    final attention = _attentionCount(user.role);

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: isHome ? 20 : 16,
        title: isHome
            ? Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.lightPink,
                      border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.bloodtype_rounded, color: AppColors.primaryRed, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'BLOOD-BRIDGE',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            : Text(
                tabs[_currentTabIndex].title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark),
                onPressed: () {
                  if (attention == 0) {
                    showSnack(context, 'Nothing needs your attention right now');
                  } else {
                    showSnack(context, _attentionMessage(user.role, attention));
                    _switchTab(1);
                  }
                },
              ),
              if (attention > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$attention',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _AppDrawer(user: user),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _visited.contains(i) ? tabs[i].screen : const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: isHome && user.role.canPostRequests
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryRed,
              onPressed: () => context.push(AppRoutes.createRequest),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'New Request',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _switchTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryRed,
          unselectedItemColor: AppColors.textGrey,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    activeIcon: Icon(t.activeIcon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  final AuthUser user;
  const _AppDrawer({required this.user});

  static const _roleIcons = {
    UserRole.donor: Icons.volunteer_activism_rounded,
    UserRole.requestor: Icons.bloodtype_rounded,
    UserRole.hospital: Icons.local_hospital_rounded,
    UserRole.organization: Icons.inventory_2_rounded,
    UserRole.admin: Icons.admin_panel_settings_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donor = user.donor;
    final institution = user.hospital ?? user.organization;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryRed, AppColors.deepRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                    ),
                    child: donor != null
                        ? Center(
                            child: Text(
                              donor.bloodType.label,
                              style: const TextStyle(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : Icon(_roleIcons[user.role], color: AppColors.primaryRed, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_roleIcons[user.role], color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                institution != null
                                    ? '${user.role.label} · ${institution.approvalStatus.label}'
                                    : user.role.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (donor != null) _AvailabilityTile(donor: donor),
                  if (user.role == UserRole.donor || user.role == UserRole.requestor)
                    _ActionTile(
                      icon: Icons.person_outline_rounded,
                      title: 'My Profile',
                      subtitle: 'Update your contact details',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.profile);
                      },
                    ),
                  if (user.role == UserRole.donor)
                    _ActionTile(
                      icon: Icons.my_location_rounded,
                      title: 'Update My Location',
                      subtitle: donor?.areaLabel ?? 'Not set — required to receive requests',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.locationPicker,
                            extra: LocationPickerMode.donorLocation);
                      },
                    ),
                  _ActionTile(
                    icon: Icons.medical_services_outlined,
                    title: 'Emergency Disclaimer',
                    subtitle: 'Logistical tool only',
                    onTap: () {
                      Navigator.pop(context);
                      _showDisclaimerModal(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderGrey, height: 1),
            _ActionTile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              titleColor: AppColors.primaryRed,
              iconColor: AppColors.primaryRed,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDisclaimerModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.primaryRed),
            SizedBox(width: 8),
            Text('Medical Disclaimer'),
          ],
        ),
        content: const Text(
          'BloodBridge is a logistical matching platform. It does NOT provide clinical advice. Final donor suitability and transfusion safety remain the sole responsibility of the attending hospital and blood bank.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
        ],
      ),
    );
  }
}

/// `PATCH /donors/me/availability` from the drawer.
class _AvailabilityTile extends ConsumerStatefulWidget {
  final Donor donor;
  const _AvailabilityTile({required this.donor});

  @override
  ConsumerState<_AvailabilityTile> createState() => _AvailabilityTileState();
}

class _AvailabilityTileState extends ConsumerState<_AvailabilityTile> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).setDonorAvailability(value);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.donor.isAvailable;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: available ? AppColors.successBg : AppColors.bgGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: available ? AppColors.successGreen : AppColors.borderGrey),
        ),
        child: Row(
          children: [
            Icon(
              available ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded,
              color: available ? AppColors.successGreen : AppColors.textGrey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    available ? 'Available to donate' : 'Unavailable',
                    style: const TextStyle(
                        color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  Text(
                    available
                        ? 'You will be notified about nearby requests'
                        : 'You will not be matched to new requests',
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                  ),
                ],
              ),
            ),
            _busy
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Switch(
                    value: available,
                    activeThumbColor: AppColors.successGreen,
                    onChanged: _toggle,
                  ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color titleColor;
  final Color iconColor;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor = AppColors.textDark,
    this.iconColor = AppColors.textGrey,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(title,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5))
            : null,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}
