import 'package:flutter/material.dart';

class HospitalVerificationScreen extends StatefulWidget {
  const HospitalVerificationScreen({super.key});

  @override
  State<HospitalVerificationScreen> createState() =>
      _HospitalVerificationScreenState();
}

class _HospitalVerificationScreenState
    extends State<HospitalVerificationScreen> {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color bgGrey = Color(0xFFF8FAFC);
  static const Color successGreen = Color(0xFF16A34A);

  // Placeholder queue — wire to HospitalRepository.getPendingVerifications() later
  final List<_VerificationRequest> _queue = [
    _VerificationRequest(
      patientName: 'Ahmed Raza',
      mrn: 'MRN #9021',
      bloodGroup: 'AB+',
      units: 2,
      ward: 'Emergency Trauma Ward 3',
      timeAgo: '10 mins ago',
      isCritical: true,
    ),
    _VerificationRequest(
      patientName: 'Fatima Bibi',
      mrn: 'MRN #4412',
      bloodGroup: 'O+',
      units: 1,
      ward: 'Gynae OT 2',
      timeAgo: '25 mins ago',
      isCritical: false,
    ),
  ];

  void _verifyRequest(_VerificationRequest request) {
    setState(() => _queue.remove(request));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${request.patientName}\'s request is now ACTIVE and visible to donors.'),
        backgroundColor: successGreen,
      ),
    );
  }

  void _rejectRequest(_VerificationRequest request, String reason) {
    setState(() => _queue.remove(request));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Marked Not Verified — returned to requester with reason: "$reason"'),
        backgroundColor: primaryRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Info banner ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_hospital_rounded, color: primaryRed, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Verify incoming blood requests originating at your facility before they become active to donors.',
                    style: TextStyle(fontSize: 12.5, color: textDark),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Queue header with pending count ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pending Verification',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_queue.length} pending',
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

          if (_queue.isEmpty)
            _buildEmptyState()
          else
            ..._queue.map((request) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildVerificationCard(context, request),
            )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, color: successGreen.withOpacity(0.7), size: 44),
          const SizedBox(height: 10),
          const Text(
            'Queue is clear',
            style: TextStyle(fontWeight: FontWeight.w800, color: textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'No requests are waiting for verification right now',
            style: TextStyle(color: textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(
      BuildContext context, _VerificationRequest request) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: request.isCritical
              ? primaryRed.withOpacity(0.3)
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (request.isCritical) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryRed.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CRITICAL',
                                style: TextStyle(
                                  color: primaryRed,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.mrn,
                        style: const TextStyle(color: textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${request.bloodGroup} · ${request.units} Units',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: borderGrey),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 15, color: textGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request.ward,
                    style: const TextStyle(color: textGrey, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 15, color: textGrey),
                const SizedBox(width: 6),
                Text(
                  'Submitted ${request.timeAgo}',
                  style: const TextStyle(color: textGrey, fontSize: 12.5),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryRed,
                      side: BorderSide(color: primaryRed.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _showRejectDialog(context, request),
                    child: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white),
                    onPressed: () => _verifyRequest(request),
                    label: const Text(
                      'Verify',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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

  void _showRejectDialog(BuildContext context, _VerificationRequest request) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.close_rounded, color: primaryRed),
            SizedBox(width: 8),
            Text('Reason for Non-Verification'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This reason will be shown to ${request.patientName.split(' ').first}\'s requester.',
                style: const TextStyle(fontSize: 12.5, color: textGrey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                autofocus: true,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'e.g. Patient not found, incorrect blood group',
                  hintStyle:
                  const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
                  filled: true,
                  fillColor: bgGrey,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryRed, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: textGrey),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              _rejectRequest(request, reason);
            },
            child: const Text(
              'Submit Reason',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationRequest {
  final String patientName;
  final String mrn;
  final String bloodGroup;
  final int units;
  final String ward;
  final String timeAgo;
  final bool isCritical;

  _VerificationRequest({
    required this.patientName,
    required this.mrn,
    required this.bloodGroup,
    required this.units,
    required this.ward,
    required this.timeAgo,
    required this.isCritical,
  });
}