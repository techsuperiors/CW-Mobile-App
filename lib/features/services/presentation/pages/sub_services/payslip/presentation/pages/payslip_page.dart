import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../bloc/payslip_bloc.dart';
import '../bloc/payslip_event.dart';
import '../bloc/payslip_state.dart';
import '../widgets/payslip_card.dart';

/// Payslip page showing grid of monthly payslips
class PayslipPage extends StatefulWidget {
  final int? serviceId;

  const PayslipPage({
    super.key,
    this.serviceId,
  });

  @override
  State<PayslipPage> createState() => _PayslipPageState();
}

class _PayslipPageState extends State<PayslipPage> {
  String selectedYear = DateTime.now().year.toString();

  @override
  void initState() {
    super.initState();
    _fetchPayslips();
  }

  void _fetchPayslips() {
    context.read<PayslipBloc>().add(FetchPayslipsEvent(year: selectedYear));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => (currentYear - index).toString());

    return ResponsiveScaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: screenWidth * 0.048,
              ),
              Flexible(
                child: Text(
                  "Back",
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 110,
        title: Text(
          AppStrings.payslips,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter by year',
            initialValue: selectedYear,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: screenWidth * 0.045,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedYear,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            onSelected: (value) {
              if (value == selectedYear) return;
              setState(() {
                selectedYear = value;
              });
              _fetchPayslips();
            },
            itemBuilder:
                (context) =>
                    years
                        .map(
                          (year) => PopupMenuItem<String>(
                            value: year,
                            child: Text(year),
                          ),
                        )
                        .toList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: BlocBuilder<PayslipBloc, PayslipState>(
        builder: (context, state) {
          if (state is PayslipLoading || state is PayslipInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PayslipError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchPayslips,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is PayslipLoaded) {
            final payslips = state.payslips;

            if (payslips.isEmpty) {
              return Center(
                child: Text(
                  'No payslips found for $selectedYear',
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _fetchPayslips();
              },
              child: GridView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.02,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: screenWidth * 0.03,
                  mainAxisSpacing: screenHeight * 0.02,
                  childAspectRatio: 0.85,
                ),
                itemCount: payslips.length,
                itemBuilder: (context, index) {
                  return PayslipCard(payslip: payslips[index]);
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
