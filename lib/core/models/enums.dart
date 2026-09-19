// Dart twins of `src/utils/enums.py`. `apiValue` is the exact wire string.

enum UserRole {
  donor('donor', 'Donor'),
  requestor('requestor', 'Requester'),
  hospital('hospital', 'Hospital'),
  organization('organization', 'Organization'),
  admin('admin', 'Admin');

  final String apiValue;
  final String label;
  const UserRole(this.apiValue, this.label);

  /// URL prefix of this role's account endpoints (`/donors/login`, …).
  String get pathSegment => switch (this) {
        UserRole.donor => 'donors',
        UserRole.requestor => 'requestors',
        UserRole.hospital => 'hospitals',
        UserRole.organization => 'organizations',
        UserRole.admin => 'admin',
      };

  /// Requestors and organizations create blood requests.
  bool get canPostRequests =>
      this == UserRole.requestor || this == UserRole.organization;

  /// Donors and organizations commit to requests.
  bool get canAcceptRequests =>
      this == UserRole.donor || this == UserRole.organization;

  bool get canChat => this != UserRole.hospital && this != UserRole.admin;

  static UserRole? tryParse(String? value) {
    for (final r in UserRole.values) {
      if (r.apiValue == value) return r;
    }
    return null;
  }

  static UserRole parse(String value) =>
      tryParse(value) ?? (throw FormatException('Unknown role: $value'));
}

enum BloodType {
  oPos('O+'),
  oNeg('O-'),
  aPos('A+'),
  aNeg('A-'),
  bPos('B+'),
  bNeg('B-'),
  abPos('AB+'),
  abNeg('AB-');

  final String apiValue;
  const BloodType(this.apiValue);
  String get label => apiValue;

  static BloodType parse(String value) => values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => throw FormatException('Unknown blood type: $value'),
      );
}

enum UrgencyLevel {
  critical('critical', 'Critical'),
  urgent('urgent', 'Urgent'),
  routine('routine', 'Routine');

  final String apiValue;
  final String label;
  const UrgencyLevel(this.apiValue, this.label);

  static UrgencyLevel parse(String value) => values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => throw FormatException('Unknown urgency: $value'),
      );
}

enum RequestStatus {
  draft('draft', 'Draft'),
  pendingVerification('pending_verification', 'Pending Verification'),
  active('active', 'Active (Matching)'),
  partiallyMatched('partially_matched', 'Partially Matched'),
  fullyMatched('fully_matched', 'Fully Matched'),
  fulfilled('fulfilled', 'Fulfilled'),
  closed('closed', 'Closed'),
  rejected('rejected', 'Rejected'),
  expired('expired', 'Expired'),
  cancelled('cancelled', 'Cancelled');

  final String apiValue;
  final String label;
  const RequestStatus(this.apiValue, this.label);

  /// Mirrors `constants.OPEN_STATUSES`: still visible to donors.
  bool get isOpen => this == active || this == partiallyMatched;

  /// Mirrors `constants.TERMINAL_STATUSES`.
  bool get isTerminal =>
      this == fulfilled || this == closed || this == cancelled || this == rejected;

  /// Mirrors `constants.REACTIVATABLE_STATUSES`.
  bool get isReactivatable =>
      this == active || this == partiallyMatched || this == fullyMatched || this == expired;

  static RequestStatus parse(String value) => values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => throw FormatException('Unknown request status: $value'),
      );
}

enum MatchStatus {
  accepted('accepted', 'Accepted'),
  cancelled('cancelled', 'Cancelled'),
  completed('completed', 'Completed');

  final String apiValue;
  final String label;
  const MatchStatus(this.apiValue, this.label);

  static MatchStatus parse(String value) => values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => throw FormatException('Unknown match status: $value'),
      );
}

enum ApprovalStatus {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected');

  final String apiValue;
  final String label;
  const ApprovalStatus(this.apiValue, this.label);

  static ApprovalStatus parse(String value) => values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => throw FormatException('Unknown approval status: $value'),
      );
}

enum SenderType {
  donor('donor', 'Donor'),
  requestor('requestor', 'Requester'),
  organization('organization', 'Organization');

  final String apiValue;
  final String label;
  const SenderType(this.apiValue, this.label);

  static SenderType parse(String value) => values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => throw FormatException('Unknown sender type: $value'),
      );
}

enum Gender {
  male('male', 'Male'),
  female('female', 'Female'),
  other('other', 'Other');

  final String apiValue;
  final String label;
  const Gender(this.apiValue, this.label);

  static Gender parse(String value) => values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => throw FormatException('Unknown gender: $value'),
      );
}

enum AvailableTime {
  morning('morning', 'Morning'),
  afternoon('afternoon', 'Afternoon'),
  evening('evening', 'Evening'),
  anytime('anytime', 'Anytime');

  final String apiValue;
  final String label;
  const AvailableTime(this.apiValue, this.label);

  static AvailableTime parse(String value) => values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => throw FormatException('Unknown available time: $value'),
      );
}
