import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_donation_app/core/models/blood_request.dart';
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
}
