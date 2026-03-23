import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_assets.dart';
import '../../domain/models/service_model.dart';

/// Services data provider - can be replaced with API call
class ServicesData {
  static List<ServiceModel> getServices() {
    return [
      ServiceModel(
        id: '1',
        title: AppStrings.attendance,
        description: AppStrings.trackAttendanceEasily,
        iconPath: AppAssets.iconAttendance,
        iconColor: AppColors.serviceBlue,
        backgroundColor: AppColors.serviceBlueBg,
        requiredPermission: 'Attendance:Attendance Dashboard:Read',
      ),
      ServiceModel(
        id: '2',
        title: AppStrings.leave,
        description: AppStrings.quickLeaveRequests,
        iconPath: AppAssets.iconLeave,
        iconColor: AppColors.servicePurple,
        backgroundColor: AppColors.servicePurpleBg,
        anyOfPermissions: [
          'Leave Management:My Leaves:Read',
          'Leave Management:Team Leaves:Read',
        ],
      ),
      ServiceModel(
        id: '3',
        title: AppStrings.policies,
        description: AppStrings.allCompanyPolicies,
        iconPath: AppAssets.iconPolicies,
        iconColor: AppColors.serviceGreen,
        backgroundColor: AppColors.serviceGreenBg,
        anyOfPermissions: [
        "Company Policies:My Policy:Read",
        "Company Policies:Team Policy:Read"
        ],
      ),
      ServiceModel(
        id: '4',
        title: AppStrings.employeeAgreement,
        description: AppStrings.trackAttendanceEasilyDescription,
        iconPath: AppAssets.iconEmployeeAgreement,
        iconColor: AppColors.serviceOrange,
        backgroundColor: AppColors.serviceOrangeBg,
        requiredPermission: 'Employee Agreements:Employee Agreements:Read',
      ),
      ServiceModel(
        id: '5',
        title: AppStrings.visit,
        description: AppStrings.visitDescription,
        iconPath: AppAssets.iconVisit,
        iconColor: AppColors.serviceBlue,
        backgroundColor: AppColors.serviceBlueBg,
        requiredPermission: 'Visit & Geo Tracking:Dashboard:Read',
      ),
      ServiceModel(
        id: '6',
        title: AppStrings.expenses,
        description: AppStrings.expensesDescription,
        iconPath: AppAssets.iconExpenses,
        iconColor: AppColors.servicePinkDark,
        backgroundColor: AppColors.servicePinkDarkBg,
        anyOfPermissions: [
          'Expense Management:Trip:Read',
          'Expense Management:Reimbursements:Reimbursement:Read',
        ],
      ),
      ServiceModel(
        id: '7',
        title: AppStrings.payslips,
        description: AppStrings.payslipAtFingertips,
        iconPath: AppAssets.iconPayslip,
        iconColor: AppColors.serviceTeal,
        backgroundColor: AppColors.serviceTealBg,
        requiredPermission: 'Payroll Management:Payslip:Read',
      ),
      ServiceModel(
        id: '8',
        title: AppStrings.document,
        description: AppStrings.documentStore,
        iconPath: AppAssets.iconDocument,
        iconColor: AppColors.serviceYellow,
        backgroundColor: AppColors.serviceYellowBg,
        requiredPermission:
          'Document Management:My Drive:Read',

      ),
      ServiceModel(
        id: '9',
        title: AppStrings.assets,
        description: AppStrings.assetTrackingSimplified,
        iconPath: AppAssets.iconAssets,
        iconColor: AppColors.servicePurple,
        backgroundColor: AppColors.servicePurpleBg,
        anyOfPermissions: [
          'Asset Management:Assigned Asset:Read',
        ],
      ),
      ServiceModel(
        id: '10',
        title: AppStrings.tickets,
        description: AppStrings.ticketSupportFast,
        iconPath: AppAssets.iconTickets,
        iconColor: AppColors.servicePinkDark,
        backgroundColor: AppColors.servicePinkDarkBg,
        anyOfPermissions: [
          'Ticket Management:Ticket Dashboard:Read',
          'Ticket Management:My Tickets:Read',
        ],
      ),
    ];
  }
}
