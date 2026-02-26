/// API Endpoints
/// Centralized location for all API endpoint paths
class AppUrls {
  AppUrls._(); // Private constructor to prevent instantiation

  // Authentication endpoints
  static const String login = '/api/mobile/app/users/login';
  static const String logout = '/api/mobile/app/users/logout';

  // Dashboard endpoints
  // static const String dashboardStats = '/api/api/mobile/app/dashboard/stats';
  static const String upcomingEvents = '/api/dashboard/employee/upcoming/events';

  // User endpoints
  static const String getUserProfile = '/api/mobile/app/users/profile';
  // static const String updateUserProfile = '/api/api/mobile/app/users/profile';

  // Attendance endpoints
  static const String punchIn = '/api/attendance/punchIn';
  static const String attendanceDetails = '/api/attendance/details';
  // static const String punchOut = '/api/api/mobile/app/attendance/punch-out';
  // static const String attendanceHistory = '/api/api/mobile/app/attendance/history';

  // Leave/Request endpoints
  static const String leaveTypesList = '/api/leaves/type/list';
  // static const String applyLeave = '/api/api/mobile/app/leaves/apply';
  // static const String leaveHistory = '/api/api/mobile/app/leaves/history';
  // static const String leaveRequests = '/api/api/mobile/app/leaves/requests';

  // Services endpoints
  // static const String services = '/api/api/mobile/app/services';

  // Posts endpoints
  // static const String posts = '/api/api/mobile/app/posts';

  // Approval endpoints
  // static const String approvals = '/api/api/mobile/app/approvals';
}

