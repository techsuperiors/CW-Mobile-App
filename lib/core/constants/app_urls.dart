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
  static const String upcomingEvents = '/api/dashboard/employee/upcoming/events';

  // User endpoints
  static const String getUserProfile = '/api/mobile/app/users/profile';
  // static const String updateUserProfile = '/api/api/mobile/app/users/profile';

  // Attendance endpoints
  static const String punchIn = '/api/attendance/punchIn';
  static const String punchOut = '/api/attendance/punchOut';
  static const String attendanceDetails = '/api/attendance/details';
  static const String attendanceRequest = '/api/attendance/request';
  // static const String attendanceHistory = '/api/api/mobile/app/attendance/history';

  // Leave/Request endpoints
  static const String leaveTypesList = '/api/leaves/type/list';
  static const String applyLeave = '/api/leaves/request';
  // static const String leaveHistory = '/api/api/mobile/app/leaves/history';
  // static const String leaveRequests = '/api/api/mobile/app/leaves/requests';

  // Services endpoints
  // static const String services = '/api/api/mobile/app/services';

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
}

