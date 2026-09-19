import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_donation_app/core/geo/geo_utils.dart';
import 'package:blood_donation_app/core/models/blood_request.dart';
import 'package:blood_donation_app/features/BloodRequestsLifeCycle/state/matching_rank.dart';
import 'package:latlong2/latlong.dart';
import 'package:blood_donation_app/core/models/enums.dart';

void main() {
  test('BloodRequest parses the backend wire format', () {
    final json = {
      'id': '2c1a2f6e-1a2b-4c3d-8e9f-0a1b2c3d4e5f',
      'requestor_id': '3c1a2f6e-1a2b-4c3d-8e9f-0a1b2c3d4e5f',
      'organization_id': null,
      'patient_name': 'Ahmed',
      'blood_type_needed': 'O-',
      'units_needed': 3,
      'units_secured': 1,
      'urgency_level': 'critical',
      'required_by': '2026-09-20T10:00:00Z',
      'hospital_name_text': 'Civil Hospital',
      'hospital_id': null,
      'is_hospital_backed': false,
      'status': 'partially_matched',
      'current_radius_km': 25.0,
      'contact_phone': '03001234567',
      'area_label': 'Saddar',
      'cancellation_reason': null,
      'created_at': '2026-09-19T10:00:00Z',
      'updated_at': '2026-09-19T11:00:00Z',
      'distance_km': 2.4,
    };
    final r = BloodRequest.fromJson(json);
    expect(r.bloodTypeNeeded, BloodType.oNeg);
    expect(r.urgencyLevel, UrgencyLevel.critical);
    expect(r.status, RequestStatus.partiallyMatched);
    expect(r.status.isOpen, isTrue);
    expect(r.unitsRemaining, 2);
    expect(r.distanceKm, 2.4);
    expect(r.placeLabel, 'Civil Hospital');
  });

  test('enum wire values round-trip', () {
    for (final s in RequestStatus.values) {
      expect(RequestStatus.parse(s.apiValue), s);
    }
    for (final b in BloodType.values) {
      expect(BloodType.parse(b.apiValue), b);
    }
    expect(UserRole.parse('requestor').pathSegment, 'requestors');
  });

  testWidgets('material widgets build', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('ok'))));
    expect(find.text('ok'), findsOneWidget);
  });

  group('GeoUtils', () {
    test('haversine Karachi Saddar -> Clifton is ~5 km', () {
      final km = GeoUtils.haversineKm(24.8560, 67.0200, 24.8138, 67.0300);
      expect(km, closeTo(4.8, 0.3));
    });

    test('formatDistance rounds and never prints coordinates', () {
      expect(GeoUtils.formatDistance(0.32), '~300 m');
      expect(GeoUtils.formatDistance(3.24), '~3.2 km');
      expect(GeoUtils.formatDistance(14.7), '~15 km');
    });

    test('rejects invalid coordinates', () {
      expect(GeoUtils.isValidCoordinate(0, 0), isFalse);
      expect(GeoUtils.isValidCoordinate(null, 67), isFalse);
      expect(GeoUtils.isValidCoordinate(91, 67), isFalse);
      expect(GeoUtils.isValidCoordinate(24.86, 181), isFalse);
      expect(GeoUtils.isValidCoordinate(double.nan, 67), isFalse);
      expect(GeoUtils.isValidCoordinate(24.86, 67.01), isTrue);
    });

    test('approximate() shifts 300-500 m deterministically', () {
      const exact = LatLng(24.86, 67.01);
      final a = GeoUtils.approximate(exact, seed: 'abc');
      final b = GeoUtils.approximate(exact, seed: 'abc');
      expect(a, b);
      final km = GeoUtils.distanceKm(exact, a);
      expect(km, inInclusiveRange(0.29, 0.51));
    });

    test('service area check', () {
      const area = ServiceArea(name: 't', center: LatLng(24.86, 67.01), radiusKm: 60);
      expect(area.contains(const LatLng(24.9, 67.1)), isTrue);
      expect(area.contains(const LatLng(31.5, 74.3)), isFalse); // Lahore
    });
  });

  test('donor ranking: exact type > compatible, then distance, then recency', () {
    BloodRequest make(String id, BloodType t, double km, int minutesAgo, {UrgencyLevel u = UrgencyLevel.routine}) =>
        BloodRequest(
          id: id,
          patientName: 'p',
          bloodTypeNeeded: t,
          unitsNeeded: 1,
          unitsSecured: 0,
          urgencyLevel: u,
          requiredBy: DateTime.now().add(const Duration(hours: 5)),
          isHospitalBacked: false,
          status: RequestStatus.active,
          currentRadiusKm: 8,
          contactPhone: '03001234567',
          createdAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
          updatedAt: DateTime.now(),
          distanceKm: km,
        );
    final ranked = rankRequestsForDonor([
      make('far-exact', BloodType.oPos, 9, 5),
      make('near-compat', BloodType.aPos, 1, 5),
      make('near-exact-old', BloodType.oPos, 2, 60),
      make('near-exact-new', BloodType.oPos, 2, 1),
    ], BloodType.oPos);
    expect(ranked.map((r) => r.id).toList(),
        ['near-exact-new', 'near-exact-old', 'far-exact', 'near-compat']);
  });
}
