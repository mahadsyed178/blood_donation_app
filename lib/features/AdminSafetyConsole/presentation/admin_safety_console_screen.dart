import 'package:flutter/material.dart';

class AdminSafetyConsoleScreen extends StatefulWidget {
  const AdminSafetyConsoleScreen({super.key});

  @override
  State<AdminSafetyConsoleScreen> createState() =>
      _AdminSafetyConsoleScreenState();
}

class _AdminSafetyConsoleScreenState extends State<AdminSafetyConsoleScreen> {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color bgGrey = Color(0xFFF8FAFC);

  final _searchController = TextEditingController();

  // Placeholder flag queue — wire to AdminRepository.getFlags() later
  final List<_FlagItem> _flags = [
    _FlagItem(
      id: '#912',
      type: 'Chat Message',
      reason:
      'User reported suspicious payment solicitation in coordination chat.',
      reportedBy: 'Requester · Ayesha K.',
      timeAgo: '12 min ago',
      severity: _Severity.high,
    ),
    _FlagItem(
      id: '#907',
      type: 'Request Content',
      reason: 'Request note contains a phone number outside the app flow.',
      reportedBy: 'System · Auto-flag',
      timeAgo: '1h ago',
      severity: _Severity.medium,
    ),
    _FlagItem(
      id: '#899',
      type: 'User Profile',
      reason: 'Duplicate account suspected — same NID as user #4021.',
      reportedBy: 'Hospital · Aga Khan',
      timeAgo: '3h ago',
      severity: _Severity.low,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _dismissFlag(_FlagItem flag) {
    setState(() => _flags.remove(flag));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Flag ${flag.id} dismissed')),
    );
  }

  void _deactivateUser(_FlagItem flag) {
    setState(() => _flags.remove(flag));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User account linked to ${flag.id} deactivated'),
        backgroundColor: primaryRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // --- Search bar: users/requests (FR-31) ---
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users, requests, or NID...',
              hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: textGrey),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: borderGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: borderGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryRed, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- KPI section ---
          const _SectionHeader(
            title: 'Real-Time Operational KPIs',

          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _MetricCard(
                title: 'Active Requests',
                value: '18',
                icon: Icons.bloodtype_rounded,
                trend: '+3 today',
                trendUp: true,
              ),
              _MetricCard(
                title: 'Match Rate',
                value: '94.2%',
                icon: Icons.check_circle_rounded,
                trend: '+1.8%',
                trendUp: true,
              ),
              _MetricCard(
                title: 'Avg Response Time',
                value: '3.4 min',
                icon: Icons.timer_rounded,
                trend: '-0.6 min',
                trendUp: true,
              ),
              _MetricCard(
                title: 'Fulfillment Rate',
                value: '88.5%',
                icon: Icons.volunteer_activism_rounded,
                trend: '-2.1%',
                trendUp: false,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // --- Notification outcome mini-summary (FR-32) ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderGrey),
            ),
            child: Row(
              children: [
                _NotificationOutcomeChip(
                  label: 'Delivered',
                  count: '142',
                  color: const Color(0xFF16A34A),
                ),
                _verticalDivider(),
                _NotificationOutcomeChip(
                  label: 'Failed',
                  count: '6',
                  color: primaryRed,
                ),
                _verticalDivider(),
                _NotificationOutcomeChip(
                  label: 'Unknown',
                  count: '23',
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // --- Flags section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(
                title: 'Safety Flags & Moderation',
                subtitle: 'FR-31',
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_flags.length} pending',
                  style: const TextStyle(
                    color: primaryRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_flags.isEmpty)
            _buildEmptyFlagsState()
          else
            ..._flags.map((flag) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FlagCard(
                flag: flag,
                onDismiss: () => _dismissFlag(flag),
                onDeactivate: () => _deactivateUser(flag),
              ),
            )),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 32,
      width: 1,
      color: borderGrey,
    );
  }

  Widget _buildEmptyFlagsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 40),
          SizedBox(height: 10),
          Text(
            'All clear',
            style: TextStyle(fontWeight: FontWeight.w800, color: textDark),
          ),
          SizedBox(height: 4),
          Text(
            'No pending safety flags to review',
            style: TextStyle(color: textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// --- Data model for a flag item ---
enum _Severity { low, medium, high }

class _FlagItem {
  final String id;
  final String type;
  final String reason;
  final String reportedBy;
  final String timeAgo;
  final _Severity severity;

  _FlagItem({
    required this.id,
    required this.type,
    required this.reason,
    required this.reportedBy,
    required this.timeAgo,
    required this.severity,
  });
}

// --- Section header ---
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: textDark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text(
            '($subtitle)',
            style: const TextStyle(fontSize: 11, color: textGrey),
          ),
        ],
      ],
    );
  }
}

// --- Metric card with trend indicator ---
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final bool trendUp;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
    required this.trendUp,
  });

  static const Color primaryRed = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryRed, size: 18),
              ),
              Row(
                children: [
                  Icon(
                    trendUp
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color: trendUp
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trend,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: trendUp
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: textGrey, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// --- Notification outcome mini chip ---
class _NotificationOutcomeChip extends StatelessWidget {
  const _NotificationOutcomeChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final String count;
  final Color color;

  static const Color textGrey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: textGrey, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

// --- Flag review card ---
class _FlagCard extends StatelessWidget {
  const _FlagCard({
    required this.flag,
    required this.onDismiss,
    required this.onDeactivate,
  });

  final _FlagItem flag;
  final VoidCallback onDismiss;
  final VoidCallback onDeactivate;

  static const Color primaryRed = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  Color get _severityColor {
    switch (flag.severity) {
      case _Severity.high:
        return const Color(0xFFDC2626);
      case _Severity.medium:
        return const Color(0xFFF59E0B);
      case _Severity.low:
        return const Color(0xFF64748B);
    }
  }

  String get _severityLabel {
    switch (flag.severity) {
      case _Severity.high:
        return 'High';
      case _Severity.medium:
        return 'Medium';
      case _Severity.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _severityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _severityLabel,
                    style: TextStyle(
                      color: _severityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${flag.type} · ${flag.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  flag.timeAgo,
                  style: const TextStyle(fontSize: 11, color: textGrey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              flag.reason,
              style: const TextStyle(fontSize: 13, color: textDark, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              'Reported by ${flag.reportedBy}',
              style: const TextStyle(fontSize: 11.5, color: textGrey),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textDark,
                      side: const BorderSide(color: borderGrey),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDeactivate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Deactivate User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
}