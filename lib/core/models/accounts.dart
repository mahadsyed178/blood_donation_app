import 'enums.dart';
import 'json_helpers.dart';

/// `donors.dtos.DonorOut`
class Donor {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final BloodType bloodType;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? nationalId;
  final double? weightKg;
  final DateTime? lastDonationDate;
  final AvailableTime? availableTime;
  final String? profilePicUrl;
  final String? areaLabel;
  final String? deviceToken;
  final bool isEmailVerified;
  final bool isActive;
  final bool isAvailable;
  final DateTime createdAt;

  const Donor({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.bloodType,
    this.gender,
    this.dateOfBirth,
    this.nationalId,
    this.weightKg,
    this.lastDonationDate,
    this.availableTime,
    this.profilePicUrl,
    this.areaLabel,
    this.deviceToken,
    required this.isEmailVerified,
    required this.isActive,
    required this.isAvailable,
    required this.createdAt,
  });

  /// A donor needs a stored location before the nearby feed or accepting
  /// a request will work (backend: `list_nearby_for_donor`).
  bool get hasLocation => areaLabel != null && areaLabel!.isNotEmpty;

  factory Donor.fromJson(Map<String, dynamic> json) => Donor(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        bloodType: BloodType.parse(json['blood_type'] as String),
        gender: json['gender'] == null ? null : Gender.parse(json['gender'] as String),
        dateOfBirth: parseDateOrNull(json['date_of_birth']),
        nationalId: json['national_id'] as String?,
        weightKg: parseDoubleOrNull(json['weight_kg']),
        lastDonationDate: parseDateOrNull(json['last_donation_date']),
        availableTime: json['available_time'] == null
            ? null
            : AvailableTime.parse(json['available_time'] as String),
        profilePicUrl: json['profile_pic_url'] as String?,
        areaLabel: json['area_label'] as String?,
        deviceToken: json['device_token'] as String?,
        isEmailVerified: json['is_email_verified'] as bool,
        isActive: json['is_active'] as bool,
        isAvailable: json['is_available'] as bool,
        createdAt: parseDateTime(json['created_at']),
      );

  Donor copyWith({bool? isAvailable, String? areaLabel}) => Donor(
        id: id,
        fullName: fullName,
        email: email,
        phone: phone,
        bloodType: bloodType,
        gender: gender,
        dateOfBirth: dateOfBirth,
        nationalId: nationalId,
        weightKg: weightKg,
        lastDonationDate: lastDonationDate,
        availableTime: availableTime,
        profilePicUrl: profilePicUrl,
        areaLabel: areaLabel ?? this.areaLabel,
        deviceToken: deviceToken,
        isEmailVerified: isEmailVerified,
        isActive: isActive,
        isAvailable: isAvailable ?? this.isAvailable,
        createdAt: createdAt,
      );
}

/// `donors.dtos.DonorSignup`
class DonorSignupRequest {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final BloodType bloodType;
  final Gender gender;
  final DateTime dateOfBirth;
  final String? nationalId;
  final double? weightKg;
  final DateTime? lastDonationDate;
  final AvailableTime? availableTime;

  const DonorSignupRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.bloodType,
    required this.gender,
    required this.dateOfBirth,
    this.nationalId,
    this.weightKg,
    this.lastDonationDate,
    this.availableTime,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'blood_type': bloodType.apiValue,
        'gender': gender.apiValue,
        'date_of_birth': formatDateOnly(dateOfBirth),
        if (nationalId != null) 'national_id': nationalId,
        if (weightKg != null) 'weight_kg': weightKg,
        if (lastDonationDate != null)
          'last_donation_date': formatDateOnly(lastDonationDate!),
        if (availableTime != null) 'available_time': availableTime!.apiValue,
      };
}

/// `donors.dtos.DonorUpdateProfile` — only set fields are sent.
class DonorProfileUpdate {
  final String? fullName;
  final String? phone;
  final BloodType? bloodType;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? nationalId;
  final double? weightKg;
  final DateTime? lastDonationDate;
  final AvailableTime? availableTime;

  const DonorProfileUpdate({
    this.fullName,
    this.phone,
    this.bloodType,
    this.gender,
    this.dateOfBirth,
    this.nationalId,
    this.weightKg,
    this.lastDonationDate,
    this.availableTime,
  });

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (bloodType != null) 'blood_type': bloodType!.apiValue,
        if (gender != null) 'gender': gender!.apiValue,
        if (dateOfBirth != null) 'date_of_birth': formatDateOnly(dateOfBirth!),
        if (nationalId != null) 'national_id': nationalId,
        if (weightKg != null) 'weight_kg': weightKg,
        if (lastDonationDate != null)
          'last_donation_date': formatDateOnly(lastDonationDate!),
        if (availableTime != null) 'available_time': availableTime!.apiValue,
      };
}

/// `requestors.dtos.RequestorOut`
class Requestor {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? profilePicUrl;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime createdAt;

  const Requestor({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profilePicUrl,
    required this.isEmailVerified,
    required this.isActive,
    required this.createdAt,
  });

  factory Requestor.fromJson(Map<String, dynamic> json) => Requestor(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        profilePicUrl: json['profile_pic_url'] as String?,
        isEmailVerified: json['is_email_verified'] as bool,
        isActive: json['is_active'] as bool,
        createdAt: parseDateTime(json['created_at']),
      );
}

/// `requestors.dtos.RequestorSignup`
class RequestorSignupRequest {
  final String fullName;
  final String email;
  final String phone;
  final String password;

  const RequestorSignupRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
      };
}

/// `requestors.dtos.RequestorUpdateProfile`
class RequestorProfileUpdate {
  final String? fullName;
  final String? phone;
  const RequestorProfileUpdate({this.fullName, this.phone});

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      };
}

/// `hospitals.dtos.HospitalOut` and `organizations.dtos.OrganizationOut`
/// have identical shapes; one class serves both.
class Institution {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? logoUrl;
  final ApprovalStatus approvalStatus;
  final bool isEmailVerified;
  final DateTime createdAt;

  const Institution({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.logoUrl,
    required this.approvalStatus,
    required this.isEmailVerified,
    required this.createdAt,
  });

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String,
        logoUrl: json['logo_url'] as String?,
        approvalStatus: ApprovalStatus.parse(json['approval_status'] as String),
        isEmailVerified: json['is_email_verified'] as bool,
        createdAt: parseDateTime(json['created_at']),
      );
}

/// `*.dtos.TokenOut`
class TokenResponse {
  final String accessToken;
  final String tokenType;
  const TokenResponse({required this.accessToken, required this.tokenType});

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String? ?? 'bearer',
      );
}

/// The signed-in account, whatever its role. Exactly one of the role
/// payloads is set (none for admin, which has no table).
class AuthUser {
  final UserRole role;
  final String id;
  final String displayName;
  final String email;
  final String? phone;
  final Donor? donor;
  final Requestor? requestor;
  final Institution? hospital;
  final Institution? organization;

  const AuthUser({
    required this.role,
    required this.id,
    required this.displayName,
    required this.email,
    this.phone,
    this.donor,
    this.requestor,
    this.hospital,
    this.organization,
  });

  factory AuthUser.donor(Donor d) => AuthUser(
        role: UserRole.donor,
        id: d.id,
        displayName: d.fullName,
        email: d.email,
        phone: d.phone,
        donor: d,
      );

  factory AuthUser.requestor(Requestor r) => AuthUser(
        role: UserRole.requestor,
        id: r.id,
        displayName: r.fullName,
        email: r.email,
        phone: r.phone,
        requestor: r,
      );

  factory AuthUser.hospital(Institution h) => AuthUser(
        role: UserRole.hospital,
        id: h.id,
        displayName: h.name,
        email: h.email,
        phone: h.phone,
        hospital: h,
      );

  factory AuthUser.organization(Institution o) => AuthUser(
        role: UserRole.organization,
        id: o.id,
        displayName: o.name,
        email: o.email,
        phone: o.phone,
        organization: o,
      );

  factory AuthUser.admin(String email) => AuthUser(
        role: UserRole.admin,
        id: 'admin',
        displayName: 'Administrator',
        email: email,
      );

  AuthUser withDonor(Donor d) => AuthUser.donor(d);
  AuthUser withRequestor(Requestor r) => AuthUser.requestor(r);
}
