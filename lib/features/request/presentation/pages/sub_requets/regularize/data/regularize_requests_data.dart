import '../models/regularize_request_model.dart';

/// Regularize requests data provider
class RegularizeRequestsData {
  /// Get all regularize requests
  static List<RegularizeRequestModel> getRegularizeRequests() {
    return [
      // December 2025 - Pending
      RegularizeRequestModel(
        id: 'reg1',
        requestType: RegularizeRequestType.punchOut,
        fromDate: DateTime(2025, 12, 16),
        toDate: DateTime(2025, 12, 19),
        reason: 'Network Issue',
        status: RegularizeStatus.pending,
        appliedDate: DateTime(2025, 12, 10),
      ),
      // December 2025 - Approved
      RegularizeRequestModel(
        id: 'reg2',
        requestType: RegularizeRequestType.punchIn,
        fromDate: DateTime(2025, 12, 16),
        toDate: DateTime(2025, 12, 19),
        reason: 'Network Issue',
        status: RegularizeStatus.approved,
        appliedDate: DateTime(2025, 12, 10),
      ),
      // November 2025 - Approved
      RegularizeRequestModel(
        id: 'reg3',
        requestType: RegularizeRequestType.punchIn,
        fromDate: DateTime(2025, 11, 30),
        reason: 'Mispunched',
        status: RegularizeStatus.approved,
        appliedDate: DateTime(2025, 11, 20),
      ),
      RegularizeRequestModel(
        id: 'reg4',
        requestType: RegularizeRequestType.both,
        fromDate: DateTime(2025, 11, 26),
        reason: 'I Punched In at 9:26 AM using the biometric device',
        status: RegularizeStatus.rejected,
        appliedDate: DateTime(2025, 11, 15),
      ),
      RegularizeRequestModel(
        id: 'reg5',
        requestType: RegularizeRequestType.punchIn,
        fromDate: DateTime(2025, 11, 12),
        toDate: DateTime(2025, 11, 18),
        reason: 'Network Issues',
        status: RegularizeStatus.approved,
        appliedDate: DateTime(2025, 11, 5),
      ),
      // October 2025 - Approved
      RegularizeRequestModel(
        id: 'reg6',
        requestType: RegularizeRequestType.both,
        fromDate: DateTime(2025, 10, 5),
        reason: 'Network Issue',
        status: RegularizeStatus.approved,
        appliedDate: DateTime(2025, 10, 1),
      ),
      RegularizeRequestModel(
        id: 'reg7',
        requestType: RegularizeRequestType.punchIn,
        fromDate: DateTime(2025, 10, 15),
        reason: 'Mispunched',
        status: RegularizeStatus.approved,
        appliedDate: DateTime(2025, 10, 10),
      ),
      RegularizeRequestModel(
        id: 'reg8',
        requestType: RegularizeRequestType.punchOut,
        fromDate: DateTime(2025, 10, 7),
        toDate: DateTime(2025, 10, 12),
        reason: 'Network Issue',
        status: RegularizeStatus.approved,
        appliedDate: DateTime(2025, 10, 5),
      ),
      RegularizeRequestModel(
        id: 'reg9',
        requestType: RegularizeRequestType.both,
        fromDate: DateTime(2025, 10, 1),
        toDate: DateTime(2025, 10, 2),
        reason: 'Network Issue',
        status: RegularizeStatus.approved,
        appliedDate: DateTime(2025, 9, 28),
      ),
    ];
  }

  /// Get regularize requests filtered by status
  static List<RegularizeRequestModel> getRegularizeRequestsByStatus(RegularizeStatus status) {
    return getRegularizeRequests().where((request) => request.status == status).toList();
  }

  /// Search regularize requests by reason or request type
  static List<RegularizeRequestModel> searchRegularizeRequests(String query) {
    final lowerQuery = query.toLowerCase();
    return getRegularizeRequests()
        .where((request) => 
            request.reason.toLowerCase().contains(lowerQuery) ||
            request.requestType.displayName.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
