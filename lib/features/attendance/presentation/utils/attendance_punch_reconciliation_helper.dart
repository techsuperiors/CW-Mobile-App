class AttendancePunchReconciliationHelper {
  const AttendancePunchReconciliationHelper._();

  static bool requiresPunchInReconciliation(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('already') && normalized.contains('in');
  }

  static bool requiresPunchOutReconciliation(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('already') && normalized.contains('out');
  }

  static String toUserMessage(String message) {
    final normalized = message.toLowerCase();
    if (requiresPunchInReconciliation(message)) {
      return 'Already punched in from another device. Syncing latest session...';
    }
    if (requiresPunchOutReconciliation(message)) {
      return 'Already punched out from another device. Syncing latest session...';
    }
    if (normalized.contains('network') || normalized.contains('connection')) {
      return 'Network issue. Please check your connection.';
    }
    if (normalized.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return message;
  }
}
