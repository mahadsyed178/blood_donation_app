import 'package:blood_donation_app/features/AdminSafetyConsole/presentation/admin_safety_console_screen.dart';
import 'package:blood_donation_app/features/BloodRequestsLifeCycle/presentation/blood_request_lifecycle_screen.dart';
import 'package:blood_donation_app/features/Co-ordinationChat/presenatation/co-ordination_chat_screen.dart';
import 'package:blood_donation_app/features/DonorMatching/presentation/donor_matching_screen.dart';
import 'package:blood_donation_app/features/HospitalVerification/presentation/hospital_verification_screen.dart';
import 'package:flutter/material.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentTabIndex = 0;
  String _activeRole = 'Donor';

  static const Color primaryRed = Color(0xFFE53935);
  static const Color deepRed = Color(0xFFB71C1C);
  static const Color lightPink = Color(0xFFFFF5F5);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color bgGrey = Color(0xFFF8FAFC);
  static const Color borderGrey = Color(0xFFE2E8F0);

  static const List<_RoleOption> _roles = [
    _RoleOption(
      label: 'Donor',
      subtitle: 'O+ · Available to donate',
      icon: Icons.volunteer_activism_rounded,
    ),
    _RoleOption(
      label: 'Requester',
      subtitle: 'Create and track blood requests',
      icon: Icons.bloodtype_rounded,
    ),
    _RoleOption(
      label: 'Hospital Staff',
      subtitle: 'Verify requests tied to your facility',
      icon: Icons.local_hospital_rounded,
    ),
    _RoleOption(
      label: 'Partner Org',
      subtitle: 'Alkhidmat · fulfill & declare stock',
      icon: Icons.inventory_2_rounded,
    ),
    _RoleOption(
      label: 'Admin',
      subtitle: 'System Admin · safety & metrics',
      icon: Icons.admin_panel_settings_rounded,
    ),
  ];

  late final List<Widget> _screens = [
    _HomeOverviewTab(
      activeRole: _activeRole,
      onSeeRequests: () => setState(() => _currentTabIndex = 1),
      onSeeMap: () => setState(() => _currentTabIndex = 2),
    ),
    const BloodRequestsLifecycleScreen(),
    const DonorMatchingScreen(),
    const HospitalVerificationScreen(),
    const CoordinationChatScreen(),
    const AdminSafetyConsoleScreen(),
  ];

  static const List<String> _titles = [
    'HEMALINK',
    'Emergency Blood Requests',
    'Nearby Donor Map',
    'Hospital Review Queue',
    'Coordination Chats',
    'Admin Safety Console',
  ];

  _RoleOption get _activeRoleOption =>
      _roles.firstWhere((r) => r.label == _activeRole);

  @override
  Widget build(BuildContext context) {
    final bool isHome = _currentTabIndex == 0;

    return Scaffold(
      backgroundColor: bgGrey,
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
                color: lightPink,
                border: Border.all(color: primaryRed.withOpacity(0.25)),
              ),
              child: const Icon(Icons.bloodtype_rounded,
                  color: primaryRed, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'HEMALINK',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        )
            : Text(
          _titles[_currentTabIndex],
          style: const TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: textDark),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Push Notification: 1 urgent B+ request nearby!'),
                    ),
                  );
                },
              ),
              Positioned(
                right: 10,
                top: 12,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(
                    color: primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildAppDrawer(),
      body: IndexedStack(
        index: _currentTabIndex,
        children: _screens,
      ),
      floatingActionButton: isHome
          ? FloatingActionButton.extended(
        backgroundColor: primaryRed,
        onPressed: () => setState(() => _currentTabIndex = 1),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Request',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) => setState(() => _currentTabIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryRed,
          unselectedItemColor: textGrey,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bloodtype_outlined),
              activeIcon: Icon(Icons.bloodtype),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Live Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined),
              activeIcon: Icon(Icons.local_hospital),
              label: 'Hospital',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // --- Profile header ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryRed, deepRed],
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
                      border: Border.all(
                          color: Colors.white.withOpacity(0.6), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: primaryRed, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Muhammad Ali',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_activeRoleOption.icon,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                _activeRole,
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
                  // --- Role switcher: tap-to-select cards ---
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'SWITCH ROLE.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  ..._roles.map((role) => _buildRoleTile(role)),

                  const SizedBox(height: 12),
                  const Divider(color: borderGrey, height: 1),
                  const SizedBox(height: 12),

                  // --- Other actions ---
                  _buildActionTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Partner Stock Claim',
                    subtitle: 'Declare welfare stock fulfillment (FR-30)',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentTabIndex = 1);
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.medical_services_outlined,
                    title: 'Emergency Disclaimer',
                    subtitle: 'Logistical tool only (Sec 6.1)',
                    onTap: () {
                      Navigator.pop(context);
                      _showDisclaimerModal();
                    },
                  ),
                ],
              ),
            ),

            const Divider(color: borderGrey, height: 1),
            _buildActionTile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              titleColor: primaryRed,
              iconColor: primaryRed,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTile(_RoleOption role) {
    final bool isActive = _activeRole == role.label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (!isActive) {
            setState(() => _activeRole = role.label);
          }
          Navigator.pop(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? lightPink : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? primaryRed : borderGrey,
              width: isActive ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: isActive ? primaryRed : bgGrey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role.icon,
                  color: isActive ? Colors.white : textGrey,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: TextStyle(
                        color: isActive ? primaryRed : textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.subtitle,
                      style: TextStyle(
                        color: isActive
                            ? primaryRed.withOpacity(0.75)
                            : textGrey,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(Icons.check_circle_rounded,
                    color: primaryRed, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? textDark, size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: textGrey, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisclaimerModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: primaryRed),
            SizedBox(width: 8),
            Text('Medical Disclaimer'),
          ],
        ),
        content: const Text(
          'HEMALINK is a logistical matching platform. It does NOT provide clinical advice. Final donor suitability and transfusion safety remain the sole responsibility of the attending hospital and blood bank.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood')),
        ],
      ),
    );
  }
}

class _RoleOption {
  final String label;
  final String subtitle;
  final IconData icon;

  const _RoleOption({
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

/// --- Home Overview Tab ---
/// The dashboard's landing screen: greeting, quick stats, urgent alerts,
/// and quick-action shortcuts into the other tabs. Gives the user immediate
/// orientation instead of dropping them straight into a raw request list.
class _HomeOverviewTab extends StatelessWidget {
  const _HomeOverviewTab({
    required this.activeRole,
    required this.onSeeRequests,
    required this.onSeeMap,
  });

  final String activeRole;
  final VoidCallback onSeeRequests;
  final VoidCallback onSeeMap;

  static const Color primaryRed = Color(0xFFE53935);
  static const Color deepRed = Color(0xFFB71C1C);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final bool isDonor = activeRole == 'Donor';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Greeting + role-aware hero card ---
          // Container(
          //   padding: const EdgeInsets.all(20),
          //   decoration: BoxDecoration(
          //     gradient: const LinearGradient(
          //       colors: [primaryRed, deepRed],
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //     ),
          //     borderRadius: BorderRadius.circular(20),
          //     boxShadow: [
          //       BoxShadow(
          //         color: primaryRed.withOpacity(0.3),
          //         blurRadius: 16,
          //         offset: const Offset(0, 8),
          //       ),
          //     ],
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         isDonor ? '' : 'Welcome back',
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 18,
          //           fontWeight: FontWeight.w800,
          //         ),
          //       ),
          //       const SizedBox(height: 6),
          //       Text(
          //         isDonor
          //             ? 'Your last donation was 3 months ago. You are eligible to donate again.'
          //             : 'Track your active requests and see donor responses in real time.',
          //         style: TextStyle(
          //           color: Colors.white.withOpacity(0.9),
          //           fontSize: 13,
          //           height: 1.4,
          //         ),
          //       ),
          //       const SizedBox(height: 16),
          //       Row(
          //         children: [
          //           Container(
          //             padding: const EdgeInsets.symmetric(
          //                 horizontal: 12, vertical: 6),
          //             decoration: BoxDecoration(
          //               color: Colors.white.withOpacity(0.15),
          //               borderRadius: BorderRadius.circular(10),
          //             ),
          //             child: Row(
          //               mainAxisSize: MainAxisSize.min,
          //               children: const [
          //                 Icon(Icons.bloodtype_rounded,
          //                     color: Colors.white, size: 14),
          //                 SizedBox(width: 4),
          //                 Text(
          //                   'O+ Blood Group',
          //                   style: TextStyle(
          //                     color: Colors.white,
          //                     fontSize: 12,
          //                     fontWeight: FontWeight.w700,
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //           const SizedBox(width: 8),
          //           Container(
          //             padding: const EdgeInsets.symmetric(
          //                 horizontal: 12, vertical: 6),
          //             decoration: BoxDecoration(
          //               color: Colors.white.withOpacity(0.15),
          //               borderRadius: BorderRadius.circular(10),
          //             ),
          //             child: const Text(
          //               'Available',
          //               style: TextStyle(
          //                 color: Colors.white,
          //                 fontSize: 12,
          //                 fontWeight: FontWeight.w700,
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
// --- Greeting + role-aware hero card ---
          GestureDetector(
            onTap: isDonor ? onSeeRequests : null,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryRed, deepRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryRed.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDonor ? 'Welcome back, hero 🩸' : 'Welcome back',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // --- Next-action description ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.priority_high_rounded,
                          color: Colors.white, size: 15),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isDonor
                              ? 'B+ needed 2.4 km away at Aga Khan Hospital — you could be the match.'
                              : 'Your O- request has 2 donors nearby. Check their responses now.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.bloodtype_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'O+ Blood Group',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isDonor ? 'Respond now' : 'View responses',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Stat cards row ---
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.bloodtype_rounded,
                  iconColor: primaryRed,
                  value: '12',
                  label: 'Active\nRequests',
                  onTap: onSeeRequests,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFF16A34A),
                  value: '48',
                  label: 'Nearby\nDonors',
                  onTap: onSeeMap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFF2563EB),
                  value: '3',
                  label: 'Lives\nHelped',
                  onTap: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Urgent alert banner ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryRed.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: primaryRed.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high_rounded,
                      color: primaryRed, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Critical request nearby',
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'B+ needed at Aga Khan Hospital · 2.4 km away',
                        style: TextStyle(color: textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded,
                      color: primaryRed, size: 16),
                  onPressed: onSeeRequests,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Quick actions ---
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'New Request',
                  onTap: onSeeRequests,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.location_searching_rounded,
                  label: 'Find Donors',
                  onTap: onSeeMap,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Recent activity ---
          const Text(
            'Recent Activity',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _ActivityTile(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF16A34A),
            title: 'Donation confirmed',
            subtitle: 'You helped fulfill a request at Liaquat National',
            time: '2h ago',
          ),
          const SizedBox(height: 10),
          _ActivityTile(
            icon: Icons.chat_bubble_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'New message',
            subtitle: 'Requester sent you a coordination message',
            time: '5h ago',
          ),
          const SizedBox(height: 10),
          _ActivityTile(
            icon: Icons.verified_rounded,
            iconColor: primaryRed,
            title: 'Request verified',
            subtitle: 'Aga Khan Hospital verified your request',
            time: '1d ago',
          ),
        ],
      ),
    );
  }
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

  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);

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
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textGrey,
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
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color primaryRed = Color(0xFFE53935);
  static const Color lightPink = Color(0xFFFFF5F5);
  static const Color textDark = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: lightPink,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryRed.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryRed, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: textDark,
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

  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: textGrey, fontSize: 11.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}