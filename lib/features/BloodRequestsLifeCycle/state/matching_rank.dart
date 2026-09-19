import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';

/// PRD ranking: compatibility → distance → recency.
///
/// Everything in the nearby feed is already compatible (the backend filters
/// by `COMPATIBLE_DONORS_FOR_RECIPIENT`), so "compatibility" here means an
/// exact blood-type match ranks above a merely compatible one, and critical
/// urgency ranks above the rest within the same tier.
List<BloodRequest> rankRequestsForDonor(List<BloodRequest> requests, BloodType donorType) {
  int tier(BloodRequest r) {
    final exact = r.bloodTypeNeeded == donorType ? 0 : 1;
    return exact * 3 + r.urgencyLevel.index;
  }

  final sorted = [...requests];
  sorted.sort((a, b) {
    final t = tier(a).compareTo(tier(b));
    if (t != 0) return t;
    final d = (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity);
    if (d != 0) return d;
    return b.createdAt.compareTo(a.createdAt);
  });
  return sorted;
}

/// Candidate list for a poster: open commitments first, then nearest, then
/// most recent.
List<RequestMatch> rankMatchesForPoster(List<RequestMatch> matches) {
  final sorted = [...matches];
  sorted.sort((a, b) {
    final s = (a.isOpen ? 0 : 1).compareTo(b.isOpen ? 0 : 1);
    if (s != 0) return s;
    final d = (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity);
    if (d != 0) return d;
    return b.acceptedAt.compareTo(a.acceptedAt);
  });
  return sorted;
}
