import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../policies/presentation/widgets/signature_dialog.dart';
import '../bloc/agreement_bloc.dart';
import '../bloc/agreement_event.dart';
import '../bloc/agreement_state.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';

class CommonAgreementDetailPage extends StatefulWidget {
  final int agreementId;
  final String agreementName;
  final String status;
  final String? content;
  final String? signatureUrl;
  final String? documentUrl;

  const CommonAgreementDetailPage({
    super.key,
    required this.agreementId,
    required this.agreementName,
    required this.status,
    this.content,
    this.signatureUrl,
    this.documentUrl,
  });

  @override
  State<CommonAgreementDetailPage> createState() =>
      _CommonAgreementDetailPageState();
}

class _CommonAgreementDetailPageState extends State<CommonAgreementDetailPage> {
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
              Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.048,
              ),
              Flexible(
                child: Text(
                  AppStrings.back,
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w400, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 110,
        title: Text(
          widget.agreementName,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: Colors.white),
        ),

        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.documentUrl != null && widget.documentUrl!.isNotEmpty)
              _buildPdfViewer()
            else
              _buildAgreementContentCard(),
            if (widget.status.toLowerCase() != 'signed') ...[
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
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
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              if (_signatureBytes != null) ...[
                Container(
                  height: MediaQuery.of(context).size.height * 0.125,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_signatureBytes!, fit: BoxFit.contain),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isAgreed
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
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.0175,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textSecondary,
                  ),
                  child: Text(
                    _signatureBytes != null
                        ? 'Change Signature'
                        : 'Add Signature',
                    style: AppTextStyles.bodyLarge(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              BlocConsumer<AgreementBloc, AgreementState>(
                listener: (context, state) {
                  if (state is AgreementConsentSubmitted) {
                    final navigator = Navigator.of(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.message ?? 'Agreement submitted successfully',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );

                    final userProfileState =
                        context.read<UserProfileBloc>().state;
                    if (userProfileState is UserProfileLoaded) {
                      final userId = userProfileState.profile.userId;
                      context.read<AgreementBloc>().add(
                        RefreshAgreementList(userId),
                      );
                    }

                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        navigator.pop(true);
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
                      onPressed:
                          (_isAgreed &&
                                  _signatureBytes != null &&
                                  !isSubmitting)
                              ? () => _submitAgreementConsent(context)
                              : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.0175,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          isSubmitting
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
                                style: AppTextStyles.bodyLarge(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w600),
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

  Widget _buildPdfViewer() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      margin: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SfPdfViewer.network(
          widget.documentUrl!,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
        ),
      ),
    );
  }

  Widget _buildAgreementContentCard() {
    final htmlContent = widget.content ?? '';
    final hasSignature =
        widget.signatureUrl != null && widget.signatureUrl!.isNotEmpty;
    final showSignatureAbove =
        hasSignature && htmlContent.contains('[Candidate Signature]');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppAssets.indicatorLogo,
            width: 50,
            height: 7,
            fit: BoxFit.contain,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.042,
              MediaQuery.of(context).size.height * 0.015,
              MediaQuery.of(context).size.width * 0.042,
              MediaQuery.of(context).size.height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      AppAssets.appLogo,
                      width: MediaQuery.of(context).size.width * 0.067,
                      height: MediaQuery.of(context).size.width * 0.067,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.021),
                    Text(
                      'Collectivwork',
                      style: AppTextStyles.heading3(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Builder(
                  builder: (context) {
                    if (showSignatureAbove) {
                      final parts = htmlContent.split('[Candidate Signature]');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHtml(parts[0], context),
                          SizedBox(
                            width: 100,
                            height: 70,
                            child: CachedNetworkImage(
                              imageUrl: widget.signatureUrl!,
                              fit: BoxFit.contain,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error, size: 16),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.005,
                          ),
                          _buildHtml(
                            '[Candidate Signature]${parts.length > 1 ? parts[1] : ''}',
                            context,
                          ),
                        ],
                      );
                    }
                    return _buildHtml(htmlContent, context);
                  },
                ),
                if (hasSignature && !showSignatureAbove) ...[
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  SizedBox(
                    width: 100,
                    height: 70,
                    child: CachedNetworkImage(
                      imageUrl: widget.signatureUrl!,
                      fit: BoxFit.contain,
                      placeholder:
                          (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      errorWidget:
                          (context, url, error) =>
                              const Icon(Icons.error, size: 16),
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

  Widget _buildHtml(String data, BuildContext context) {
    return Html(
      data: data,
      style: {
        'body': Style(
          fontSize: FontSize(MediaQuery.of(context).size.width * 0.037),
          color: AppColors.textPrimary,
          lineHeight: const LineHeight(1.6),
          fontWeight: FontWeight.w400,
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'p': Style(margin: Margins.only(bottom: 8), padding: HtmlPaddings.zero),
        'strong': Style(fontWeight: FontWeight.bold),
        'em': Style(fontStyle: FontStyle.italic),
        'b': Style(fontWeight: FontWeight.bold),
        'i': Style(fontStyle: FontStyle.italic),
      },
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

    final agreementBloc = context.read<AgreementBloc>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signatureFile = File('${tempDir.path}/signature_$timestamp.png');
      await signatureFile.writeAsBytes(_signatureBytes!);
      if (!mounted) return;

      agreementBloc.add(
        SubmitAgreementConsent(
          agreementId: widget.agreementId,
          agreementAcknowledged: _isAgreed,
          signatureFilePath: signatureFile.path,
        ),
      );

      Future.delayed(const Duration(seconds: 5), () async {
        try {
          if (await signatureFile.exists()) {
            await signatureFile.delete();
          }
        } catch (_) {}
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to submit agreement: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

}
