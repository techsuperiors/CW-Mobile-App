/// Punch-in result entity
class PunchInResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  PunchInResult({
    required this.success,
    required this.message,
    this.data,
  });
}

