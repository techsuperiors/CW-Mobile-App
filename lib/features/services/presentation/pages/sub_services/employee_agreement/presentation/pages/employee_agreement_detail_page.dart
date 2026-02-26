import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../policies/presentation/widgets/signature_dialog.dart';
import '../../domain/models/employee_agreement_model.dart';
import '../../../../../../../../core/constants/app_assets.dart';

/// Employee Agreement detail page showing full agreement content and signature
class EmployeeAgreementDetailPage extends StatefulWidget {
  final EmployeeAgreementModel agreement;

  const EmployeeAgreementDetailPage({
    super.key,
    required this.agreement,
  });

  @override
  State<EmployeeAgreementDetailPage> createState() => _EmployeeAgreementDetailPageState();
}

class _EmployeeAgreementDetailPageState extends State<EmployeeAgreementDetailPage> {
  bool _isAgreed = false;
  Uint8List? _signatureBytes;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.048, // ~4.8% of screen width
              ),
              Flexible(
                child: Text(
                  AppStrings.employeeAgreement,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 150,
        title: Text(
          'Assign Agreement',
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.053, // ~5.3% of screen width
            ),
            onPressed: () {
              // Handle kebab menu tap
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Agreement Content Card with dotted border
            _buildAgreementContentCard(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
            // Checkbox
            Row(
              children: [
                Checkbox(
                  value: _isAgreed,
                  onChanged: (value) {
                    setState(() {
                      _isAgreed = value ?? false;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: Text(
                    'I have read and agree to the company policy',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02), // 2% of screen height
            // Signature Preview (if added)
            if (_signatureBytes != null) ...[
              Container(
                height: MediaQuery.of(context).size.height * 0.125, // 12.5% of screen height
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _signatureBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
            ],
            // Add Signature Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAgreed
                    ? () async {
                        final result = await showDialog<Uint8List>(
                          context: context,
                          builder: (context) => const SignatureDialog(),
                        );
                        if (result != null) {
                          setState(() {
                            _signatureBytes = result;
                          });
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.0175), // 1.75% of screen height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textSecondary,
                ),
                child: Text(
                  _signatureBytes != null ? 'Change Signature' : 'Add Signature',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
            // Submit Acknowledgment Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (_isAgreed && _signatureBytes != null)
                    ? () {
                        // Handle submit
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Agreement submitted successfully'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        // Navigate back after a short delay
                        Future.delayed(const Duration(seconds: 1), () {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        });
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.0175), // 1.75% of screen height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Submit Acknowledgment',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementContentCard() {
    // Extract content without the header (Collectivwork and address)
    final content = widget.agreement.content ?? '';
    final lines = content.split('\n');
    // Skip the first two lines (Collectivwork and address) if they exist
    final contentStartIndex = lines.length > 2 && 
        lines[0].trim() == 'Collectivwork' && 
        lines[1].contains('Market Hill') ? 2 : 0;
    final agreementContent = lines.sublist(contentStartIndex).join('\n');
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicator at the very top with no padding
          SvgPicture.asset(
            AppAssets.indicatorLogo,
            width: 50,
            height: 7,
            fit: BoxFit.contain,
          ),
          // Rest of the content with padding
          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.042, // ~4.2% of screen width
              MediaQuery.of(context).size.height * 0.015, // 1.5% of screen height
              MediaQuery.of(context).size.width * 0.042,
              MediaQuery.of(context).size.height * 0.02, // 2% of screen height
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      AppAssets.appLogo,
                      width: MediaQuery.of(context).size.width * 0.067, // ~6.7% of screen width
                      height: MediaQuery.of(context).size.width * 0.067,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.021), // ~2.1% of screen width
                    Text(
                      'Collectivwork',
                      style: AppTextStyles.heading3(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005), // 0.5% of screen height
                Text(
                  '20 Market Hill, South CV47 DHF, United Kingdom',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03), // 3% of screen height
                // Agreement Content (without duplicate header)
                Text(
                  agreementContent,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

