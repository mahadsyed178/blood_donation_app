import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/blood_request.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../Commitments/state/match_providers.dart';

/// Collects `units_committed` and `eta`, then `POST /request-matches/{id}/accept`.
/// Resolves with the new match, or null if dismissed.
Future<RequestMatch?> showAcceptRequestSheet(BuildContext context, BloodRequest request) {
  return showModalBottomSheet<RequestMatch>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _AcceptSheet(request: request),
  );
}

class _AcceptSheet extends ConsumerStatefulWidget {
  final BloodRequest request;
  const _AcceptSheet({required this.request});

  @override
  ConsumerState<_AcceptSheet> createState() => _AcceptSheetState();
}

class _AcceptSheetState extends ConsumerState<_AcceptSheet> {
  late int _units = 1;
  Duration _etaIn = const Duration(minutes: 30);
  bool _busy = false;

  static const _etaOptions = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 12),
  ];

  String _etaLabel(Duration d) => d.inMinutes < 60 ? '${d.inMinutes} min' : '${d.inHours} h';

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final match = await ref.read(myMatchesProvider.notifier).accept(
            widget.request.id,
            units: _units,
            eta: DateTime.now().add(_etaIn),
          );
      if (mounted) Navigator.pop(context, match);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final maxUnits = r.unitsRemaining.clamp(1, 20);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                    const Text('Commit to donate',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      '${r.placeLabel} · ${r.unitsRemaining} unit(s) still needed',
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Units you can give',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _units > 1 ? () => setState(() => _units--) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text('$_units',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _units < maxUnits ? () => setState(() => _units++) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('I can arrive in',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _etaOptions
                .map((d) => ChoiceChip(
                      label: Text(_etaLabel(d)),
                      selected: _etaIn == d,
                      selectedColor: AppColors.primaryRed,
                      labelStyle: TextStyle(
                        color: _etaIn == d ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _etaIn = d),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Needed by ${formatDateTime(r.requiredBy)} (${untilLabel(r.requiredBy)}).',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.volunteer_activism, color: Colors.white),
              label: Text(
                _busy ? 'Committing…' : 'Confirm commitment',
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
