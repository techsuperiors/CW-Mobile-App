import '../models/wfh_request_model.dart';

/// WFH requests data provider
class WfhRequestsData {
  /// Get all WFH requests
  static List<WfhRequestModel> getWfhRequests() {
    return [
      // December 2025 - Pending
      WfhRequestModel(
        id: 'wfh1',
        numberOfDays: 2,
        fromDate: DateTime(2025, 12, 16),
        toDate: DateTime(2025, 12, 19),
        reason: "Planned Family Function - Cousin's Wedding",
        status: WfhStatus.pending,
        appliedDate: DateTime(2025, 12, 10),
      ),
      // December 2025 - Approved
      WfhRequestModel(
        id: 'wfh2',
        numberOfDays: 2,
        fromDate: DateTime(2025, 12, 16),
        toDate: DateTime(2025, 12, 19),
        reason: "Planned Family Function - Cousin's Wedding",
        status: WfhStatus.approved,
        appliedDate: DateTime(2025, 12, 10),
      ),
      // November 2025 - Approved
      WfhRequestModel(
        id: 'wfh3',
        numberOfDays: 1,
        fromDate: DateTime(2025, 11, 30),
        reason: "Planned Family Function - Cousin's Wedding",
        status: WfhStatus.approved,
        appliedDate: DateTime(2025, 11, 20),
      ),
      WfhRequestModel(
        id: 'wfh4',
        numberOfDays: 3,
        fromDate: DateTime(2025, 11, 12),
        toDate: DateTime(2025, 11, 18),
        reason: "Planned Family Function - Cousin's Wedding",
        status: WfhStatus.approved,
        appliedDate: DateTime(2025, 11, 5),
      ),
      // November 2025 - Rejected
      WfhRequestModel(
        id: 'wfh5',
        numberOfDays: 1,
        fromDate: DateTime(2025, 11, 26),
        reason: "Planned Family Function - Cousin's Wedding",
        status: WfhStatus.rejected,
        appliedDate: DateTime(2025, 11, 15),
      ),
      // October 2025 - Approved
      WfhRequestModel(
        id: 'wfh6',
        numberOfDays: 1,
        fromDate: DateTime(2025, 10, 5),
        reason: "Flu Symptoms - Doctor's Appointment",
        status: WfhStatus.approved,
        appliedDate: DateTime(2025, 10, 1),
      ),
      WfhRequestModel(
        id: 'wfh7',
        numberOfDays: 5,
        fromDate: DateTime(2025, 10, 15),
        toDate: DateTime(2025, 10, 21),
        reason: "Trip to the Mountains",
        status: WfhStatus.approved,
        appliedDate: DateTime(2025, 10, 10),
      ),
      WfhRequestModel(
        id: 'wfh8',
        numberOfDays: 4,
        fromDate: DateTime(2025, 10, 7),
        toDate: DateTime(2025, 10, 12),
        reason: "Medical Appointment",
        status: WfhStatus.approved,
        appliedDate: DateTime(2025, 10, 5),
      ),
      WfhRequestModel(
        id: 'wfh9',
        numberOfDays: 2,
        fromDate: DateTime(2025, 10, 1),
        toDate: DateTime(2025, 10, 2),
        reason: "Home Repair Issues",
        status: WfhStatus.approved,
        appliedDate: DateTime(2025, 9, 28),
      ),
    ];
  }

  /// Get WFH requests filtered by status
  static List<WfhRequestModel> getWfhRequestsByStatus(WfhStatus status) {
    return getWfhRequests().where((request) => request.status == status).toList();
  }

  /// Search WFH requests by reason
  static List<WfhRequestModel> searchWfhRequests(String query) {
    final lowerQuery = query.toLowerCase();
    return getWfhRequests()
        .where((request) => request.reason.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
