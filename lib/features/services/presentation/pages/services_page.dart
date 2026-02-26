import 'package:flutter/material.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/assets/presentation/pages/assigned_assets_page.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/employee_agreement/presentation/pages/employee_agreement_page.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/leave/presentation/pages/leave_request_page.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/policies/presentation/pages/policies_page.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/attendence/presentation/pages/attendance_detail_page.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/tickets/presentation/pages/tickets_page.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/payslip/presentation/pages/payslip_page.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/document/presentation/pages/document_page.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/service_model.dart';
import '../widgets/services_grid.dart';
import '../data/services_data.dart';

/// Services page
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final List<ServiceModel> _services = ServicesData.getServices();

  void _onServiceTap(ServiceModel service) {
    // Convert String ID to integer
    final serviceId = int.tryParse(service.id) ?? 0;
    
    // Navigate based on service ID using switch case
    switch (serviceId) {
      case 1: // Attendance
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AttendanceDetailPage(),
          ),
        );
        break;
      case 2: // Leave
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LeaveRequestPage(),
          ),
        );
        break;
      case 3: // Policies
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PoliciesPage(serviceId: serviceId),
          ),
        );
        break;
      case 4: // Employee Agreement
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeAgreementPage(serviceId: serviceId),
          ),
        );
        break;
      case 7: // Payslips
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayslipPage(serviceId: serviceId),
          ),
        );
        break;
      case 8: // Document
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentPage(serviceId: serviceId),
          ),
        );
        break;
      case 9: // Assets
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssignedAssetsPage(serviceId: serviceId),
          ),
        );
        break;
      case 10: // Tickets
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TicketsPage(),
          ),
        );
        break;
      // Add more cases for other services as needed
      default:
        // Handle other services or do nothing
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    
    return ResponsiveScaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.022), // 4.2% of screen width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: screenHeight * 0.04), // 4% of screen height for top spacing
            // Large "Services" title
            Text(
              AppStrings.services,
              style: AppTextStyles.heading1(context).copyWith(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            SizedBox(height: screenHeight * 0.03), // 3% of screen height
            // "Our Services" section title
            Text(
              AppStrings.ourServices,
              style: AppTextStyles.heading3(context).copyWith(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            SizedBox(height: screenHeight * 0.02), // 2% of screen height
            ServicesGrid(
              services: _services,
              onServiceTap: _onServiceTap,
            ),
            SizedBox(height: screenHeight * 0.02), // Bottom spacing
          ],
        ),
      ),
    );
  }
}
