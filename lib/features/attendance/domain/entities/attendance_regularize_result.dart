/// Attendance Regularize Result entity
class AttendanceRegularizeResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const AttendanceRegularizeResult({
    required this.success,
    required this.message,
    this.data,
  });
}
