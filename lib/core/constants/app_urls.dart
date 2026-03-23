/// API Endpoints
/// Centralized location for all API endpoint paths
class AppUrls {
  AppUrls._(); // Private constructor to prevent instantiation

  // Authentication endpoints
  static const String login = '/api/mobile/app/users/login';
  static const String logout = '/api/users/logout';

  // Forgot password flow
  static const String forgotPassword = '/api/mobile/app/users/forgot/password';
  static const String validatePasswordResetOtp =
      '/api/mobile/app/users/validate/password/reset/otp';
  static const String resetPassword = '/api/mobile/app/users/reset/password';
  static const String changePassword = '/api/users/change/password';

  // Dashboard endpoints
  // static const String dashboardStats = '/api/api/mobile/app/dashboard/stats';
  static const String upcomingEvents =
      '/api/dashboard/employee/upcoming/events';

  // User endpoints
  static const String getUserProfile = '/api/mobile/app/users/profile';

  // static const String updateUserProfile = '/api/api/mobile/app/users/profile';
  // https://app.collectivwork.com/api/attendance/punchOut
  // Attendance endpoints
  static const String punchIn = '/api/attendance/punchIn';
  static const String punchOut = '/api/attendance/punchOut';
  static const String attendanceDetails = '/api/attendance/details';
  static const String attendanceUserDetail = '/api/attendance/user/detail';
  static const String attendanceRequest = '/api/attendance/request';
  static const String attendanceRange = '/api/attendance/range';
  static const String attendanceRequestComments =
      '/api/attendance/request/comments';
  static const String attendanceRequestCommentsList =
      '/api/attendance/request/comments/list';

  // static const String attendanceHistory = '/api/api/mobile/app/attendance/history';

  // Leave/Request endpoints
  static const String leaveTypesList = '/api/leaves/type/list';
  static const String applyLeave = '/api/leaves/request';

  // static const String leaveHistory = '/api/api/mobile/app/leaves/history';
  // static const String leaveRequests = '/api/api/mobile/app/leaves/requests';

  // Services endpoints
  // static const String services = '/api/api/mobile/app/services';
  static const String payslipRun = '/api/payroll/run/slip';
  static const String employeePoliciesList =
      '/api/admin/policies/list/employee';
  static const String employeePolicyDetail = '/api/admin/policies/client';
  static const String clientFileUpload = '/api/admin/clients/upload/file';
  static const String employeePolicyMapperUpdate =
      '/api/admin/policies/employee/mapper/update';

  // Posts endpoints
  // static const String posts = '/api/api/mobile/app/posts';

  // Approval endpoints
  // static const String approvals = '/api/api/mobile/app/approvals';

  // Agreement endpoints
  static const String agreementList = '/api/employee/agreement/assigned/list';
  static const String agreementConsent = '/api/employee/agreement/consent';

  // Ticket endpoints
  static const String ticketList = '/api/tickets/mobile/app/list';
  static const String ticketStats = '/api/tickets/mobile/app/stats';
  static const String ticketDetails = '/api/tickets/details';
  static const String ticketFileUpload = '/api/tickets/file/upload';
  static const String ticketFileDelete = '/api/tickets/delete/document';

  //Asset endpoints
  static const String assetList = '/api/admin/asset/allocated/list';
  static const String assetRequestList = '/api/admin/asset/request/list';
  static const String assetCategoryList =
      '/api/admin/assets/category/name/list';
  static const String createAssetRequest = '/api/admin/asset/request';

  // Calendar endpoints
  static const String calendarData = '/api/users/dashboard/holiday/leave/data';

  // Leave endpoints
  static const String leaveStats = '/api/mobile/app/users/leave/stats';
  static const String leaveHistory = '/api/leaves/history';

  // Leave requests endpoint
  static const String leaveRequests = '/api/mobile/app/users/leave/requests';
  static const String leaveTeamRequestList = '/api/leaves/team/request/list';
  static const String leaveRequestDetails = '/api/leaves/request/details';
  static const String leaveRequestStatus = '/api/leaves/request/status';
  static const String leaveWithdraw = '/api/leaves/withdraw/status';
  static const String leaveFileUpload = '/api/leaves/file/upload';
  static const String leaveFileDelete = '/api/leaves/file/delete';
  static const String leaveComments = '/api/leaves/comments';
  static const String leaveCommentsList = '/api/leaves/comments/list';

  // Regularize list endpoint
  static const String regularizeList =
      '/api/mobile/app/users/attendance/regularize/list';
  static const String regularizeTeamList = '/api/attendance/request/team';
  static const String regularizeRequestDetails =
      '/api/attendance/request/details';
  static const String regularizeRequestStatus =
      '/api/attendance/request/status';

  // WFH request endpoints
  static const String wfhRequests =
      '/api/mobile/app/users/wfh/requests'; // This causes error in the mobile
  static const String wfhTeamRequests = '/api/attendance/wfh/request/team';
  static const String wfhRequestRaise = '/api/attendance/wfh/request';
  static const String wfhRequestStatus = '/api/attendance/wfh/request/status';
  static const String wfhRequestDetails = '/api/attendance/wfh/request/details';

  // On-Duty requests endpoint
  // static const String onDutyRequests = '/api/mobile/app/users/on-duty/requests';
  static const String onDutyRequests = '/api/attendance/onDuty/request';

  static const String onDutyTeamRequests =
      '/api/attendance/onDuty/request/team';
  static const String onDutyRequestDetails =
      '/api/attendance/onDuty/request/details';
  static const String onDutyRequestStatus =
      '/api/attendance/onDuty/request/status';
  static const String onDutyRequestRaise = '/api/attendance/onDuty/request';

  // Overtime request endpoints
  static const String overtimeRequests = '/api/overtime/request/user/list';
  static const String overtimeTeamRequests = '/api/overtime/request/team/list';
  static const String overtimeRequestDetails = '/api/overtime/request/details';
  static const String overtimeRequestCreate = '/api/overtime/request/create';
  static const String overtimeRequestUpdate = '/api/overtime/request/update';
  static const String overtimeRequestStatus = '/api/overtime/request/update/status';

  // Comp-off endpoints
  static const String compOffList = '/api/leaves/compoff/list';
  static const String compOffTeamList = '/api/leaves/team/compoff/list';
  static const String compOffDetails = '/api/leaves/compoff/details';
  static const String compOffRequest = '/api/leaves/compoff/request';
  static const String compOffStatus = '/api/leaves/compoff/status';

  // static const String compOffComments = '/api/leaves/comments';
  static const String compOffComments = '/api/leaves/compoff/comments';
  static const String compOffCommentsList = '/api/leaves/compoff/comments/list';
  static const String compOffFileUpload = '/api/leaves/file/upload';

  // Notification endpoint
  static const String notificationList = '/api/users/notification/list';
  static const String notificationCount = '/api/users/notification/count';
  static const String notificationView = '/api/users/notification/view';
  static const String notificationRead = '/api/users/notification/read';

  // Expense endpoints
  static const String expenseList = '/api/expense/list';
  static const String expenseDetails = '/api/expense/details';
}
