import 'package:flutter/material.dart';

enum _RequestStatus { active, matched, fulfilled }

class BloodRequestsLifecycleScreen extends StatefulWidget {
  const BloodRequestsLifecycleScreen({super.key});

  @override
  State<BloodRequestsLifecycleScreen> createState() =>
      _BloodRequestsLifecycleScreenState();
}

class _BloodRequestsLifecycleScreenState
    extends State<BloodRequestsLifecycleScreen> {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color bgGrey = Color(0xFFF8FAFC);

  String _selectedFilter = 'All';
  static const List<String> _filters = [
    'All',
    'Critical',
    'Active',
    'Matched',
    'Fulfilled',
  ];

  // Placeholder data — wire to RequestRepository.getRequests() later
  final List<_RequestData> _requests = [
    _RequestData(
      bloodGroup: 'B+',
      hospital: 'Civil Hospital, Karachi',
      unitsRequired: 4,
      unitsFulfilled: 2,
      trustLabel: 'Institution-backed',
      status: _RequestStatus.matched,
      urgency: 'Critical',
      timeAgo: '15 mins ago',
    ),
    _RequestData(
      bloodGroup: 'O-',
      hospital: 'Liaquat National Hospital',
      unitsRequired: 1,
      unitsFulfilled: 0,
      trustLabel: 'Self-verified',
      status: _RequestStatus.active,
      urgency: 'High',
      timeAgo: '42 mins ago',
    ),
    _RequestData(
      bloodGroup: 'A+',
      hospital: 'Indus Hospital',
      unitsRequired: 2,
      unitsFulfilled: 2,
      trustLabel: 'Partner fulfillment (Alkhidmat)',
      status: _RequestStatus.fulfilled,
      urgency: 'Medium',
      timeAgo: '2 hours ago',
    ),
  ];

  List<_RequestData> get _filteredRequests {
    switch (_selectedFilter) {
      case 'Critical':
        return _requests.where((r) => r.urgency == 'Critical').toList();
      case 'Active':
        return _requests
            .where((r) => r.status == _RequestStatus.active)
            .toList();
      case 'Matched':
        return _requests
            .where((r) => r.status == _RequestStatus.matched)
            .toList();
      case 'Fulfilled':
        return _requests
            .where((r) => r.status == _RequestStatus.fulfilled)
            .toList();
      default:
        return _requests;
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = _filteredRequests;

    return Scaffold(
      backgroundColor: bgGrey,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Opening Request Creation Form...')),
          );
        },
      ),
      body: Column(
        children: [
          // --- Emergency info notice ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: primaryRed),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Multi-unit requests stay active until all units are fulfilled. Partial donations are tracked live.',
                      style: TextStyle(fontSize: 12.5, color: textDark),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Filter chips ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryRed : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primaryRed : borderGrey,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textGrey,
                          fontSize: 12.5,
                          fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // --- Request list ---
          Expanded(
            child: requests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              itemCount: requests.length,
              itemBuilder: (context, index) =>
                  _buildRequestCard(context, requests[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bloodtype_outlined,
                size: 56, color: textGrey.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text(
              'No requests here',
              style: TextStyle(fontWeight: FontWeight.w800, color: textDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different filter, or create a new request.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey.withOpacity(0.8), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'Critical':
        return const Color(0xFFDC2626);
      case 'High':
        return const Color(0xFFF97316);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return textGrey;
    }
  }

  Color _statusColor(_RequestStatus status) {
    switch (status) {
      case _RequestStatus.active:
        return const Color(0xFF16A34A);
      case _RequestStatus.matched:
        return const Color(0xFFF59E0B);
      case _RequestStatus.fulfilled:
        return const Color(0xFF16A34A);
    }
  }

  String _statusLabel(_RequestStatus status) {
    switch (status) {
      case _RequestStatus.active:
        return 'Active (Matching)';
      case _RequestStatus.matched:
        return 'Matched / In Progress';
      case _RequestStatus.fulfilled:
        return 'Fulfilled';
    }
  }

  Widget _buildRequestCard(BuildContext context, _RequestData data) {
    final double progress = data.unitsFulfilled / data.unitsRequired;
    final bool isFulfilled = data.status == _RequestStatus.fulfilled;
    final Color statusColor = _statusColor(data.status);
    final Color urgencyColor = _urgencyColor(data.urgency);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.urgency == 'Critical'
              ? urgencyColor.withOpacity(0.3)
              : borderGrey,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data.bloodGroup,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.hospital,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(data.timeAgo,
                          style:
                          const TextStyle(color: textGrey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- Urgency + status badges row (urgency now actually shown) ---
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.priority_high_rounded,
                          size: 12, color: urgencyColor),
                      const SizedBox(width: 2),
                      Text(
                        data.urgency,
                        style: TextStyle(
                          color: urgencyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(data.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryRed.withOpacity(0.2)),
                  ),
                  child: Text(
                    data.trustLabel,
                    style: const TextStyle(
                      color: primaryRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Units: ${data.unitsFulfilled} / ${data.unitsRequired} fulfilled',
                  style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isFulfilled ? const Color(0xFF16A34A) : primaryRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: borderGrey,
                color: isFulfilled ? const Color(0xFF16A34A) : primaryRed,
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 14),

            // --- Actions: hidden once fulfilled, since donating no longer applies ---
            if (isFulfilled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF16A34A), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Request fulfilled — thank you to all donors',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.volunteer_activism, size: 16),
                      label: const Text('I Can Donate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryRed,
                        side: BorderSide(color: primaryRed.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Accepted! Marked as Matched & Chat Unlocked.')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: primaryRed.withOpacity(0.1),
                      foregroundColor: primaryRed,
                    ),
                    icon: const Icon(Icons.chat_outlined),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text('Opening private coordination chat...')),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestData {
  final String bloodGroup;
  final String hospital;
  final int unitsRequired;
  final int unitsFulfilled;
  final String trustLabel;
  final _RequestStatus status;
  final String urgency;
  final String timeAgo;

  _RequestData({
    required this.bloodGroup,
    required this.hospital,
    required this.unitsRequired,
    required this.unitsFulfilled,
    required this.trustLabel,
    required this.status,
    required this.urgency,
    required this.timeAgo,
  });
}