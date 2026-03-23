DateTime parseApiDate(dynamic date) {
  if (date == null) return DateTime.now();

  final parsed = DateTime.tryParse(date.toString());
  return parsed?.toLocal() ?? DateTime.now();
}

DateTime? parseApiDateNullable(dynamic date) {
  if (date == null) return null;

  return DateTime.tryParse(date.toString())?.toLocal();
}