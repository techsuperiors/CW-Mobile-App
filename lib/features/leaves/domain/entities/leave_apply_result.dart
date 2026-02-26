/// Leave Apply Result entity
class LeaveApplyResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const LeaveApplyResult({
    required this.success,
    required this.message,
    this.data,
  });
}
