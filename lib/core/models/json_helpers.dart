// Small parsing helpers shared by the hand-written models.

DateTime parseDateTime(dynamic value) => DateTime.parse(value as String);

DateTime? parseDateTimeOrNull(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);

/// Backend `date` fields arrive as `YYYY-MM-DD`; keep them date-only.
DateTime? parseDateOrNull(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);

String formatDateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

double parseDouble(dynamic value) => (value as num).toDouble();

double? parseDoubleOrNull(dynamic value) =>
    value == null ? null : (value as num).toDouble();

int parseInt(dynamic value) => (value as num).toInt();
