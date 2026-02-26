
import '../models/leave_request_model.dart';

/// Leave requests data provider
class LeaveRequestsData {
  /// Get all leave requests
  static List<LeaveRequestModel> getLeaveRequests() {
    return [
      // Pending leaves
      LeaveRequestModel(
        id: '1',
        leaveType: 'Casual Leave',
        fromDate: DateTime(2024, 12, 16),
        toDate: DateTime(2024, 12, 19),
        reason: "Planned Family Function - Cousin's Wedding",
        status: LeaveStatus.pending,
        appliedDate: DateTime(2024, 12, 10),
      ),
      LeaveRequestModel(
        id: '2',
        leaveType: 'Casual Leave',
        fromDate: DateTime(2024, 12, 16),
        toDate: DateTime(2024, 12, 19),
        reason: "Planned Family Function - Cousin's Wedding",
        status: LeaveStatus.pending,
        appliedDate: DateTime(2024, 12, 10),
      ),
      // Approved leaves
      LeaveRequestModel(
        id: '3',
        leaveType: 'Casual Leave',
        fromDate: DateTime(2024, 12, 16),
        toDate: DateTime(2024, 12, 19),
        reason: "Planned Family Function - Cousin's Wedding",
        status: LeaveStatus.approved,
        appliedDate: DateTime(2024, 11, 25),
      ),
      LeaveRequestModel(
        id: '4',
        leaveType: 'Casual Leave',
        fromDate: DateTime(2024, 11, 30),
        reason: "Planned Family Function - Cousin's Wedding",
        status: LeaveStatus.approved,
        appliedDate: DateTime(2024, 11, 20),
      ),
      LeaveRequestModel(
        id: '5',
        leaveType: 'Casual Leave',
        fromDate: DateTime(2024, 11, 26),
        reason: "Planned Family Function - Cousin's Wedding",
        status: LeaveStatus.rejected,
        appliedDate: DateTime(2024, 11, 15),
      ),
      LeaveRequestModel(
        id: '6',
        leaveType: 'Casual Leave',
        fromDate: DateTime(2024, 11, 12),
        toDate: DateTime(2024, 11, 18),
        reason: "Planned Family Function - Cousin's Wedding",
        status: LeaveStatus.approved,
        appliedDate: DateTime(2024, 11, 5),
      ),
      LeaveRequestModel(
        id: '7',
        leaveType: 'Sick Leave',
        fromDate: DateTime(2024, 10, 5),
        reason: "Flu Symptoms - Doctor's Appointment",
        status: LeaveStatus.approved,
        appliedDate: DateTime(2024, 10, 1),
      ),
      LeaveRequestModel(
        id: '8',
        leaveType: 'Vacation Leave',
        fromDate: DateTime(2024, 10, 15),
        reason: "Trip to the Mountains",
        status: LeaveStatus.approved,
        appliedDate: DateTime(2024, 10, 10),
      ),
      LeaveRequestModel(
        id: '9',
        leaveType: 'Sick Leave',
        fromDate: DateTime(2024, 10, 7),
        toDate: DateTime(2024, 10, 12),
        reason: "Medical Appointment",
        status: LeaveStatus.approved,
        appliedDate: DateTime(2024, 10, 5),
      ),
      LeaveRequestModel(
        id: '10',
        leaveType: 'Personal Leave',
        fromDate: DateTime(2024, 10, 1),
        toDate: DateTime(2024, 10, 2),
        reason: "Home Repair Issues",
        status: LeaveStatus.approved,
        appliedDate: DateTime(2024, 9, 28),
      ),
    ];
  }

  /// Get leave requests filtered by status
  static List<LeaveRequestModel> getLeaveRequestsByStatus(LeaveStatus status) {
    return getLeaveRequests().where((request) => request.status == status).toList();
  }

  /// Get leave requests filtered by type
  static List<LeaveRequestModel> getLeaveRequestsByType(String leaveType) {
    return getLeaveRequests().where((request) => request.leaveType == leaveType).toList();
  }

  /// Search leave requests by reason
  static List<LeaveRequestModel> searchLeaveRequests(String query) {
    final lowerQuery = query.toLowerCase();
    return getLeaveRequests()
        .where((request) => request.reason.toLowerCase().contains(lowerQuery) ||
            request.leaveType.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
