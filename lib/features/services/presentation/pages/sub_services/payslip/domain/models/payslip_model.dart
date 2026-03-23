import 'package:intl/intl.dart';

/// Payslip model for payslip page
class PayslipModel {
  final int id;
  final String payrollMonth;
  final String template;
  final dynamic totalDeductions;
  final String grossSalary;
  final String netSalary;
  final bool payslipVisible;
  final Map<String, dynamic>? userPayGroup;

  // Derived fields
  final String displayName;
  final String month;
  final String year;

  const PayslipModel({
    required this.id,
    required this.payrollMonth,
    required this.template,
    required this.totalDeductions,
    required this.grossSalary,
    required this.netSalary,
    required this.payslipVisible,
    this.userPayGroup,
    required this.displayName,
    required this.month,
    required this.year,
  });

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    final payrollM = json['payroll_month']?.toString() ?? '';
    String display = '';
    String m = '';
    String y = '';

    if (payrollM.isNotEmpty && payrollM.length >= 7) {
      try {
        final date = DateTime.parse('$payrollM-01');
        m = DateFormat('MMM').format(date); // Jan, Feb
        y = DateFormat('yyyy').format(date); // 2026
        display = '$m $y';
      } catch (e) {
        display = payrollM;
      }
    }

    return PayslipModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      payrollMonth: payrollM,
      template: json['template']?.toString() ?? '',
      totalDeductions: json['total_deductions'] ?? 0,
      grossSalary: json['gross_salary']?.toString() ?? '0',
      netSalary: json['net_salary']?.toString() ?? '0',
      payslipVisible: json['payslip_visible'] == true,
      userPayGroup: json['UserPayGroup'] as Map<String, dynamic>?,
      displayName: display.isNotEmpty ? display : payrollM,
      month: m,
      year: y,
    );
  }
}
