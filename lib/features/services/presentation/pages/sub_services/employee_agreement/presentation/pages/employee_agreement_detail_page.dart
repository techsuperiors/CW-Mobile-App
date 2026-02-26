import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../policies/presentation/widgets/signature_dialog.dart';
import '../../domain/models/employee_agreement_model.dart';
import '../../../../../../../../core/constants/app_assets.dart';
import '../bloc/agreement_bloc.dart';
import '../bloc/agreement_event.dart';
import '../bloc/agreement_state.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';

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
          widget.agreement.agreementName,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Agreement Content Card with dotted border
            _buildAgreementContentCard(),
            // Only show checkbox, signature, and submit buttons if status is not "Signed"
            if (widget.agreement.status.toLowerCase() != 'signed') ...[
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
              BlocConsumer<AgreementBloc, AgreementState>(
                listener: (context, state) {
                  if (state is AgreementConsentSubmitted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.message ?? 'Agreement submitted successfully',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    
                    // Refresh the agreement list before navigating back
                    final userProfileState = context.read<UserProfileBloc>().state;
                    if (userProfileState is UserProfileLoaded) {
                      final userId = userProfileState.profile.userId;
                      final agreementBloc = context.read<AgreementBloc>();
                      agreementBloc.add(RefreshAgreementList(userId));
                    }
                    
                    // Navigate back after a short delay to allow refresh to start
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        Navigator.of(context).pop(true); // Return true to indicate success
                      }
                    });
                  } else if (state is AgreementConsentError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final isSubmitting = state is AgreementConsentSubmitting;
                  
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: (_isAgreed && _signatureBytes != null && !isSubmitting)
                          ? () => _submitAgreementConsent(context)
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
                      child: isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                          : Text(
                              'Submit Acknowledgment',
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementContentCard() {
    String htmlContent = widget.agreement.content ?? '';
    bool hasSignature = widget.agreement.signatureUrl != null && 
        widget.agreement.signatureUrl!.isNotEmpty;
    bool showSignatureAbove = hasSignature && htmlContent.contains('[Candidate Signature]');
    
    // Remove signature from HTML if we're going to show it separately
    if (showSignatureAbove) {
      // We'll show signature separately, so keep HTML as is
    }
    
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
                // Agreement Content rendered as HTML
                // Split HTML to show signature above "[Candidate Signature]"
                Builder(
                  builder: (context) {
                    if (showSignatureAbove) {
                      final parts = htmlContent.split('[Candidate Signature]');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Content before signature
                          Html(
                            data: parts[0],
                            style: {
                              "body": Style(
                                fontSize: FontSize(MediaQuery.of(context).size.width * 0.037),
                                color: AppColors.textPrimary,
                                lineHeight: const LineHeight(1.6),
                                fontWeight: FontWeight.w400,
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                              ),
                              "p": Style(
                                margin: Margins.only(bottom: 8),
                                padding: HtmlPaddings.zero,
                              ),
                              "strong": Style(
                                fontWeight: FontWeight.bold,
                              ),
                              "em": Style(
                                fontStyle: FontStyle.italic,
                              ),
                              "b": Style(
                                fontWeight: FontWeight.bold,
                              ),
                              "i": Style(
                                fontStyle: FontStyle.italic,
                              ),
                            },
                          ),
                          // Signature image with explicit size constraints
                          // SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                          SizedBox(
                            width: 100,
                            height: 70,
                            child: CachedNetworkImage(
                              imageUrl: widget.agreement.signatureUrl!,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const SizedBox(
                                width: 100,
                                height: 70,
                                child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => const SizedBox(
                                width: 100,
                                height: 70,
                                child: Icon(Icons.error, size: 16),
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                          // "[Candidate Signature]" text
                          Html(
                            data: '[Candidate Signature]${parts.length > 1 ? parts[1] : ''}',
                            style: {
                              "body": Style(
                                fontSize: FontSize(MediaQuery.of(context).size.width * 0.037),
                                color: AppColors.textPrimary,
                                lineHeight: const LineHeight(1.6),
                                fontWeight: FontWeight.w400,
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                              ),
                              "p": Style(
                                margin: Margins.only(bottom: 8),
                                padding: HtmlPaddings.zero,
                              ),
                              "strong": Style(
                                fontWeight: FontWeight.bold,
                              ),
                              "em": Style(
                                fontStyle: FontStyle.italic,
                              ),
                              "b": Style(
                                fontWeight: FontWeight.bold,
                              ),
                              "i": Style(
                                fontStyle: FontStyle.italic,
                              ),
                            },
                          ),
                        ],
                      );
                    }
                    // Default HTML rendering if no signature or pattern not found
                    return Html(
                      data: htmlContent,
                      style: {
                        "body": Style(
                          fontSize: FontSize(MediaQuery.of(context).size.width * 0.037),
                          color: AppColors.textPrimary,
                          lineHeight: const LineHeight(1.6),
                          fontWeight: FontWeight.w400,
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        "p": Style(
                          margin: Margins.only(bottom: 8),
                          padding: HtmlPaddings.zero,
                        ),
                        "strong": Style(
                          fontWeight: FontWeight.bold,
                        ),
                        "em": Style(
                          fontStyle: FontStyle.italic,
                        ),
                        "b": Style(
                          fontWeight: FontWeight.bold,
                        ),
                        "i": Style(
                          fontStyle: FontStyle.italic,
                        ),
                      },
                    );
                  },
                ),
                // If signature URL exists but pattern not found, display it below
                if (hasSignature && !showSignatureAbove) ...[
                  // SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  SizedBox(
                    width: 100,
                    height: 70,
                    child: CachedNetworkImage(
                      imageUrl: widget.agreement.signatureUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox(
                        width: 100,
                        height: 70,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => const SizedBox(
                        width: 100,
                        height: 70,
                        child: Icon(Icons.error, size: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAgreementConsent(BuildContext context) async {
    if (_signatureBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a signature'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signatureFile = File('${tempDir.path}/signature_$timestamp.png');
      
      // Write signature bytes to file
      await signatureFile.writeAsBytes(_signatureBytes!);

      // Get the bloc from context
      final bloc = context.read<AgreementBloc>();
      
      // Submit consent
      bloc.add(
        SubmitAgreementConsent(
          agreementId: widget.agreement.id,
          agreementAcknowledged: _isAgreed,
          signatureFilePath: signatureFile.path,
        ),
      );

      // Clean up the temporary file after a delay
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          if (await signatureFile.exists()) {
            await signatureFile.delete();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit agreement: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

