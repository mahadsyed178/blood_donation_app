import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/accounts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/feedback.dart';
import '../state/admin_providers.dart';

/// Hospital / organization approval queues:
/// `GET /admin/{hospitals|organizations}/pending` and
/// `PATCH /admin/{hospitals|organizations}/{id}/decision`.
class AdminSafetyConsoleScreen extends ConsumerStatefulWidget {
  const AdminSafetyConsoleScreen({super.key});

  @override
  ConsumerState<AdminSafetyConsoleScreen> createState() => _AdminSafetyConsoleScreenState();
}

class _AdminSafetyConsoleScreenState extends ConsumerState<AdminSafetyConsoleScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Institution i) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return i.name.toLowerCase().contains(q) ||
        i.email.toLowerCase().contains(q) ||
        i.address.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final hospitals = ref.watch(pendingHospitalsProvider);
    final orgs = ref.watch(pendingOrganizationsProvider);

    Future<void> refresh() => Future.wait([
          ref.read(pendingHospitalsProvider.notifier).refresh(),
          ref.read(pendingOrganizationsProvider.notifier).refresh(),
        ]);

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: appInputDecoration(
                hint: 'Search by name, e-mail or address',
                icon: Icons.search_rounded,
                suffix: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Hospitals awaiting approval',
              icon: Icons.local_hospital_rounded,
              value: hospitals,
              filter: _matches,
              onRetry: () => ref.read(pendingHospitalsProvider.notifier).refresh(),
              onDecide: (id, approve) =>
                  ref.read(pendingHospitalsProvider.notifier).decide(id, approve: approve),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Organizations awaiting approval',
              icon: Icons.inventory_2_rounded,
              value: orgs,
              filter: _matches,
              onRetry: () => ref.read(pendingOrganizationsProvider.notifier).refresh(),
              onDecide: (id, approve) =>
                  ref.read(pendingOrganizationsProvider.notifier).decide(id, approve: approve),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final AsyncValue<List<Institution>> value;
  final bool Function(Institution) filter;
  final Future<void> Function() onRetry;
  final Future<Institution> Function(String id, bool approve) onDecide;

  const _Section({
    required this.title,
    required this.icon,
    required this.value,
    required this.filter,
    required this.onRetry,
    required this.onDecide,
  });

  @override
  Widget build(BuildContext context) {
    final count = value.value?.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryRed, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
            ),
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$count pending',
                    style: const TextStyle(
                        color: AppColors.primaryRed, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (value.hasError)
          ErrorState(error: value.error!, onRetry: onRetry)
        else if (!value.hasValue)
          const Padding(padding: EdgeInsets.all(24), child: LoadingState())
        else ...[
          if (value.value!.where(filter).isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: AppColors.successGreen),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Nothing pending',
                        style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                  ),
                ],
              ),
            )
          else
            ...value.value!.where(filter).map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InstitutionCard(institution: i, onDecide: onDecide),
                )),
        ],
      ],
    );
  }
}

class _InstitutionCard extends StatefulWidget {
  final Institution institution;
  final Future<Institution> Function(String id, bool approve) onDecide;
  const _InstitutionCard({required this.institution, required this.onDecide});

  @override
  State<_InstitutionCard> createState() => _InstitutionCardState();
}

class _InstitutionCardState extends State<_InstitutionCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final i = widget.institution;
    if (!approve) {
      final ok = await confirmDialog(context,
          title: 'Reject ${i.name}?',
          message: 'They will not be able to log in. This cannot be undone from the app.',
          confirmLabel: 'Reject',
          destructive: true);
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      await widget.onDecide(i.id, approve);
      if (mounted) {
        showSnack(context, approve ? '${i.name} approved — they can now log in' : '${i.name} rejected',
            isError: !approve);
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.institution;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(i.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          const SizedBox(height: 4),
          Text(i.email, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          Text(i.phone, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(i.address,
                    style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Registered ${timeAgo(i.createdAt)}',
              style: const TextStyle(color: AppColors.hintGrey, fontSize: 11)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _decide(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                    side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _decide(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Approve', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
