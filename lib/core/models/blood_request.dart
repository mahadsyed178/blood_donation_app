import 'enums.dart';
import 'json_helpers.dart';

/// `blood_requests.dtos.BloodRequestOut`. [distanceKm] is only present on
/// the donor's nearby feed (`NearbyBloodRequestOut`).
class BloodRequest {
  final String id;
  final String? requestorId;
  final String? organizationId;
  final String patientName;
  final BloodType bloodTypeNeeded;
  final int unitsNeeded;
  final int unitsSecured;
  final UrgencyLevel urgencyLevel;
  final DateTime requiredBy;
  final String? hospitalNameText;
  final String? hospitalId;
  final bool isHospitalBacked;
  final RequestStatus status;
  final double currentRadiusKm;
  final String contactPhone;
  final String? areaLabel;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? distanceKm;

  const BloodRequest({
    required this.id,
    this.requestorId,
    this.organizationId,
    required this.patientName,
    required this.bloodTypeNeeded,
    required this.unitsNeeded,
    required this.unitsSecured,
    required this.urgencyLevel,
    required this.requiredBy,
    this.hospitalNameText,
    this.hospitalId,
    required this.isHospitalBacked,
    required this.status,
    required this.currentRadiusKm,
    required this.contactPhone,
    this.areaLabel,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm,
  });

  int get unitsRemaining => unitsNeeded - unitsSecured;
  double get progress => unitsNeeded == 0 ? 0 : unitsSecured / unitsNeeded;

  /// Where the patient is: the hospital if named, else the area label.
  String get placeLabel =>
      (hospitalNameText?.isNotEmpty ?? false) ? hospitalNameText! : (areaLabel ?? 'Location not set');

  factory BloodRequest.fromJson(Map<String, dynamic> json) => BloodRequest(
        id: json['id'] as String,
        requestorId: json['requestor_id'] as String?,
        organizationId: json['organization_id'] as String?,
        patientName: json['patient_name'] as String,
        bloodTypeNeeded: BloodType.parse(json['blood_type_needed'] as String),
        unitsNeeded: parseInt(json['units_needed']),
        unitsSecured: parseInt(json['units_secured']),
        urgencyLevel: UrgencyLevel.parse(json['urgency_level'] as String),
        requiredBy: parseDateTime(json['required_by']),
        hospitalNameText: json['hospital_name_text'] as String?,
        hospitalId: json['hospital_id'] as String?,
        isHospitalBacked: json['is_hospital_backed'] as bool,
        status: RequestStatus.parse(json['status'] as String),
        currentRadiusKm: parseDouble(json['current_radius_km']),
        contactPhone: json['contact_phone'] as String,
        areaLabel: json['area_label'] as String?,
        cancellationReason: json['cancellation_reason'] as String?,
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
        distanceKm: parseDoubleOrNull(json['distance_km']),
      );
}

/// `blood_requests.dtos.BloodRequestCreate`
class BloodRequestCreate {
  final String patientName;
  final BloodType bloodTypeNeeded;
  final int unitsNeeded;
  final UrgencyLevel urgencyLevel;
  final DateTime requiredBy;
  final String? hospitalName;
  final String contactPhone;
  final double latitude;
  final double longitude;
  final String areaLabel;

  const BloodRequestCreate({
    required this.patientName,
    required this.bloodTypeNeeded,
    required this.unitsNeeded,
    required this.urgencyLevel,
    required this.requiredBy,
    this.hospitalName,
    required this.contactPhone,
    required this.latitude,
    required this.longitude,
    required this.areaLabel,
  });

  Map<String, dynamic> toJson() => {
        'patient_name': patientName,
        'blood_type_needed': bloodTypeNeeded.apiValue,
        'units_needed': unitsNeeded,
        'urgency_level': urgencyLevel.apiValue,
        'required_by': requiredBy.toUtc().toIso8601String(),
        if (hospitalName != null && hospitalName!.trim().isNotEmpty)
          'hospital_name': hospitalName!.trim(),
        'contact_phone': contactPhone,
        'latitude': latitude,
        'longitude': longitude,
        'area_label': areaLabel,
      };
}

/// `request_matches.dtos.MatchRequestSummaryOut`
class MatchRequestSummary {
  final String id;
  final String patientName;
  final BloodType bloodTypeNeeded;
  final int unitsNeeded;
  final int unitsSecured;
  final UrgencyLevel urgencyLevel;
  final RequestStatus status;
  final DateTime requiredBy;
  final String? hospitalNameText;
  final bool isHospitalBacked;
  final double currentRadiusKm;
  final String? areaLabel;

  const MatchRequestSummary({
    required this.id,
    required this.patientName,
    required this.bloodTypeNeeded,
    required this.unitsNeeded,
    required this.unitsSecured,
    required this.urgencyLevel,
    required this.status,
    required this.requiredBy,
    this.hospitalNameText,
    required this.isHospitalBacked,
    required this.currentRadiusKm,
    this.areaLabel,
  });

  String get placeLabel =>
      (hospitalNameText?.isNotEmpty ?? false) ? hospitalNameText! : (areaLabel ?? 'Location not set');

  factory MatchRequestSummary.fromJson(Map<String, dynamic> json) =>
      MatchRequestSummary(
        id: json['id'] as String,
        patientName: json['patient_name'] as String,
        bloodTypeNeeded: BloodType.parse(json['blood_type_needed'] as String),
        unitsNeeded: parseInt(json['units_needed']),
        unitsSecured: parseInt(json['units_secured']),
        urgencyLevel: UrgencyLevel.parse(json['urgency_level'] as String),
        status: RequestStatus.parse(json['status'] as String),
        requiredBy: parseDateTime(json['required_by']),
        hospitalNameText: json['hospital_name_text'] as String?,
        isHospitalBacked: json['is_hospital_backed'] as bool,
        currentRadiusKm: parseDouble(json['current_radius_km']),
        areaLabel: json['area_label'] as String?,
      );
}

/// `request_matches.dtos.RequestMatchDetailOut`
class RequestMatch {
  final String id;
  final String bloodRequestId;
  final String? donorId;
  final String? organizationId;
  final int unitsCommitted;
  final DateTime? eta;
  final MatchStatus status;
  final String? cancelReason;
  final DateTime acceptedAt;
  final DateTime? completedAt;
  final String? acceptorName;
  final String? acceptorPhone;
  final String? posterName;
  final String posterPhone;
  final MatchRequestSummary bloodRequest;
  final double? distanceKm;

  const RequestMatch({
    required this.id,
    required this.bloodRequestId,
    this.donorId,
    this.organizationId,
    required this.unitsCommitted,
    this.eta,
    required this.status,
    this.cancelReason,
    required this.acceptedAt,
    this.completedAt,
    this.acceptorName,
    this.acceptorPhone,
    this.posterName,
    required this.posterPhone,
    required this.bloodRequest,
    this.distanceKm,
  });

  bool get isOpen => status == MatchStatus.accepted;

  factory RequestMatch.fromJson(Map<String, dynamic> json) => RequestMatch(
        id: json['id'] as String,
        bloodRequestId: json['blood_request_id'] as String,
        donorId: json['donor_id'] as String?,
        organizationId: json['organization_id'] as String?,
        unitsCommitted: parseInt(json['units_committed']),
        eta: parseDateTimeOrNull(json['eta']),
        status: MatchStatus.parse(json['status'] as String),
        cancelReason: json['cancel_reason'] as String?,
        acceptedAt: parseDateTime(json['accepted_at']),
        completedAt: parseDateTimeOrNull(json['completed_at']),
        acceptorName: json['acceptor_name'] as String?,
        acceptorPhone: json['acceptor_phone'] as String?,
        posterName: json['poster_name'] as String?,
        posterPhone: json['poster_phone'] as String,
        bloodRequest: MatchRequestSummary.fromJson(
          json['blood_request'] as Map<String, dynamic>,
        ),
        distanceKm: parseDoubleOrNull(json['distance_km']),
      );

  RequestMatch copyWith({MatchStatus? status, DateTime? eta, String? cancelReason}) =>
      RequestMatch(
        id: id,
        bloodRequestId: bloodRequestId,
        donorId: donorId,
        organizationId: organizationId,
        unitsCommitted: unitsCommitted,
        eta: eta ?? this.eta,
        status: status ?? this.status,
        cancelReason: cancelReason ?? this.cancelReason,
        acceptedAt: acceptedAt,
        completedAt: completedAt,
        acceptorName: acceptorName,
        acceptorPhone: acceptorPhone,
        posterName: posterName,
        posterPhone: posterPhone,
        bloodRequest: bloodRequest,
        distanceKm: distanceKm,
      );
}
