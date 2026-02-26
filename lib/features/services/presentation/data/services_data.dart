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
        iconColor: AppColors.servicePurple,
        backgroundColor: AppColors.servicePurpleBg,
      ),
      ServiceModel(
        id: '2',
        title: AppStrings.leave,
        description: AppStrings.quickLeaveRequests,
        iconPath: AppAssets.iconLeave,
        iconColor: AppColors.serviceOrange,
        backgroundColor: AppColors.serviceOrangeBg,
      ),
      ServiceModel(
        id: '3',
        title: AppStrings.policies,
        description: AppStrings.allCompanyPolicies,
        iconPath: AppAssets.iconPolicies,
        iconColor: AppColors.servicePurpleDark,
        backgroundColor: AppColors.servicePurpleDarkBg,
      ),
      ServiceModel(
        id: '4',
        title: AppStrings.employeeAgreement,
        description: AppStrings.trackAttendanceEasilyDescription,
        iconPath: AppAssets.iconEmployeeAgreement,
        iconColor: AppColors.servicePurpleDark,
        backgroundColor: AppColors.servicePurpleDarkBg,
      ),
      ServiceModel(
        id: '5',
        title: AppStrings.visit,
        description: AppStrings.visitDescription,
        iconPath: AppAssets.iconVisit,
        iconColor: AppColors.servicePurpleDark,
        backgroundColor: AppColors.servicePurpleDarkBg,
      ),
      ServiceModel(
        id: '6',
        title: AppStrings.expenses,
        description: AppStrings.expensesDescription,
        iconPath: AppAssets.iconPayslip, // Using payslip icon as placeholder for expenses
        iconColor: AppColors.servicePurpleDark,
        backgroundColor: AppColors.servicePurpleDarkBg,
      ),
      ServiceModel(
        id: '7',
        title: AppStrings.payslips,
        description: AppStrings.payslipAtFingertips,
        iconPath: AppAssets.iconPayslip,
        iconColor: AppColors.serviceBlue,
        backgroundColor: AppColors.serviceBlueBg,
      ),
      ServiceModel(
        id: '8',
        title: AppStrings.document,
        description: AppStrings.documentStore,
        iconPath: AppAssets.iconDocument,
        iconColor: AppColors.servicePink,
        backgroundColor: AppColors.servicePinkBg,
      ),
      ServiceModel(
        id: '9',
        title: AppStrings.assets,
        description: AppStrings.assetTrackingSimplified,
        iconPath: AppAssets.iconAssets,
        iconColor: AppColors.serviceOrangeDark,
        backgroundColor: AppColors.serviceOrangeDarkBg,
      ),
      ServiceModel(
        id: '10',
        title: AppStrings.tickets,
        description: AppStrings.ticketSupportFast,
        iconPath: AppAssets.iconTickets,
        iconColor: AppColors.serviceTeal,
        backgroundColor: AppColors.serviceTealBg,
      ),
    ];
  }
}
