import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/policy_model.dart';
import '../data/policies_remote_data.dart';
import '../widgets/signature_dialog.dart';

/// Policy detail page showing full policy content and acknowledgment
class PolicyDetailPage extends StatefulWidget {
  final PolicyModel policy;

  const PolicyDetailPage({super.key, required this.policy});

  @override
  State<PolicyDetailPage> createState() => _PolicyDetailPageState();
}

class _PolicyDetailPageState extends State<PolicyDetailPage> {
  bool _isAgreed = false;
  Uint8List? _signatureBytes;
  late Future<PolicyModel> _policyFuture;
  bool _isSubmittingAcknowledgment = false;
  bool _shouldRefreshOnExit = false;

  @override
  void initState() {
    super.initState();
    _policyFuture = PoliciesRemoteData.getPolicyDetail(widget.policy.id);
  }

  Future<void> _reloadPolicy() async {
    setState(() {
      _policyFuture = PoliciesRemoteData.getPolicyDetail(widget.policy.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !mounted) return;
        await _handleBackPressed();
      },
      child: ResponsiveScaffold(
        backgroundColor: AppColors.backgroundMedium,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          leading: GestureDetector(
            onTap: _handleBackPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size:
                      MediaQuery.of(context).size.width *
                      0.048, // ~4.8% of screen width
                ),
                Flexible(
                  child: Text(
                    "Back",
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
            widget.policy.name,
            style: AppTextStyles.heading4(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0, // Services is active
          onTap: NavigationHelper.getBottomNavHandler(context),
        ),
        body: FutureBuilder<PolicyModel>(
          future: _policyFuture,
          builder: (context, snapshot) {
            final policy = snapshot.data ?? widget.policy;

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && !snapshot.hasData) {
              return ApiErrorState(
                title: 'Unable to load policy details',
                rawMessage: snapshot.error.toString(),
                onRetry: _reloadPolicy,
              );
            }
            return RefreshIndicator(
              onRefresh: _reloadPolicy,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.01,
                ),
                children: [
                  _buildSummaryCard(policy),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildContentCard(policy),
                  if (!policy.isAcknowledged) ...[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    _buildAcknowledgmentSection(policy),
                  ],
                  if ((policy.signatureUrl ?? '').isNotEmpty) ...[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    _buildSignatureSection(policy),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleBackPressed() async {
    if (!_isSubmittingAcknowledgment) {
      if (mounted) {
        Navigator.of(context).pop(_shouldRefreshOnExit);
      }
      return;
    }

    await _showSubmissionInProgressDialog();
  }

  Future<void> _showSubmissionInProgressDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Submission In Progress'),
          content: const Text(
            'Acknowledgment is in progress. Please wait until it completes before going back.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(PolicyModel policy) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width * 0.042,
      ), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Kebab Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  policy.name,
                  style: AppTextStyles.heading4(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ), // 2% of screen height
          // Assigned By
          _buildSummaryRow(
            context,
            'Assigned By',
            policy.assignedBy,
            policy.assignedByAvatar,
          ),
          Divider(
            height: MediaQuery.of(context).size.height * 0.03,
            color: AppColors.border,
          ),
          // Assigned To
          _buildSummaryRow(
            context,
            'Assigned To',
            policy.assignedTo,
            policy.assignedToAvatar,
          ),
          Divider(
            height: MediaQuery.of(context).size.height * 0.03,
            color: AppColors.border,
          ),
          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status: ',
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              Flexible(
                child: Text(
                  policy.status,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color:
                        policy.isAcknowledged
                            ? AppColors.success
                            : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    String? avatarPath,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: screenWidth * 0.267, // ~26.7% of screen width
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // ~4.2% of screen width
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (avatarPath != null) ...[
                SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
                CircleAvatar(
                  radius: smallerDimension * 0.033,
                  // ~3.3% of smaller dimension
                  backgroundImage:
                      avatarPath.startsWith('http')
                          ? NetworkImage(avatarPath)
                          : AssetImage(avatarPath) as ImageProvider,
                ),
              ],
              SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
              Text(
                value,
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(PolicyModel policy) {
    if (policy.isFile && policy.fileUrl != null && policy.fileUrl!.isNotEmpty) {
      return _buildPreviewCard(
        policy: policy,
        title: 'Policy Document',
        subtitle: 'Tap to preview this PDF file',
        icon: Icons.picture_as_pdf_outlined,
        iconColor: AppColors.error,
      );
    }

    if ((policy.htmlContent ?? '').trim().isNotEmpty) {
      return _buildPreviewCard(
        policy: policy,
        title: 'Policy Content',
        subtitle: 'Tap to preview the policy page',
        icon: Icons.description_outlined,
        iconColor: Theme.of(context).colorScheme.primary,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width * 0.042,
      ), // ~4.2% of screen width
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getPolicyContent(policy),
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard({
    required PolicyModel policy,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: () => _openPolicyPreview(policy),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(sw * 0.045),
        child: Row(
          children: [
            Container(
              width: sw * 0.15,
              height: sw * 0.15,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: sw * 0.08),
            ),
            SizedBox(width: sw * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: sh * 0.006),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(width: sw * 0.02),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: sw * 0.045,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPolicyPreview(PolicyModel policy) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PolicyContentPreviewPage(policy: policy),
      ),
    );
  }

  Widget _buildAcknowledgmentSection(PolicyModel policy) {
    final showSignatureControls = policy.isConsentSignatureEnabled;
    final requiresSignature = showSignatureControls;
    final existingSignatureUrl = (policy.signatureUrl ?? '').trim();
    final hasExistingSignature = existingSignatureUrl.isNotEmpty;
    final canSubmit =
        _isAgreed &&
        !_isSubmittingAcknowledgment &&
        (!requiresSignature || _signatureBytes != null || hasExistingSignature);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width * 0.042,
      ), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ), // 2% of screen height
          if (showSignatureControls) ...[
            if (_signatureBytes != null) ...[
              Container(
                height:
                    MediaQuery.of(context).size.height *
                    0.125, // 12.5% of screen height
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_signatureBytes!, fit: BoxFit.contain),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.015,
              ), // 1.5% of screen height
            ] else if ((policy.signatureUrl ?? '').isNotEmpty) ...[
              Container(
                height: MediaQuery.of(context).size.height * 0.125,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: policy.signatureUrl!,
                    fit: BoxFit.contain,
                    placeholder:
                        (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    errorWidget:
                        (context, url, error) =>
                            const Icon(Icons.error_outline),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isAgreed && !_isSubmittingAcknowledgment
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
                  // 1.75% of screen height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textSecondary,
                ),
                child: Text(
                  (_signatureBytes != null || hasExistingSignature)
                      ? 'Change Signature'
                      : 'Add Signature',
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          ],
          // Submit Acknowledgment Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: canSubmit ? () => _submitAcknowledgment(policy) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height * 0.0175,
                ), // 1.75% of screen height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isSubmittingAcknowledgment
                    ? 'Submitting...'
                    : 'Submit Acknowledgment',
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(PolicyModel policy) {
    final screenHeight = MediaQuery.of(context).size.height;
    final signatureUrl = (policy.signatureUrl ?? '').trim();
    final hasSignature = signatureUrl.isNotEmpty;
    final isPdf = signatureUrl.toLowerCase().endsWith('.pdf');

    if (hasSignature && isPdf) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signed Document',
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            _buildSelectedPdfCard(
              title: _extractFileNameFromUrl(signatureUrl),
              subtitle: 'Tap to preview the signed PDF',
              onTap:
                  () => _openPdfPreviewFromUrl(
                    signatureUrl,
                    title: 'Signed Agreement',
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signature',
            style: AppTextStyles.bodyLarge(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: screenHeight * 0.125),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.backgroundMedium,
            ),
            child:
                hasSignature
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: signatureUrl,
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        errorWidget:
                            (context, url, error) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Unable to load signature.',
                                  style: AppTextStyles.bodySmall(
                                    context,
                                  ).copyWith(color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                      ),
                    )
                    : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Signature not available.',
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAcknowledgment(PolicyModel policy) async {
    final userId = PoliciesRemoteData.resolveUserId();
    if (userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to resolve current user. Please login again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingAcknowledgment = true;
    });

    try {
      final requiresSignature = policy.isConsentSignatureEnabled;
      String signatureUrl = policy.signatureUrl ?? '';
      if (requiresSignature) {
        if (signatureUrl.isEmpty || _signatureBytes != null) {
          final signatureBytes = _signatureBytes;
          if (signatureBytes != null) {
            if (policy.isFile && (policy.fileUrl ?? '').trim().isNotEmpty) {
              final signedPdfBytes = await _buildSignedAgreementPdf(
                sourcePdfUrl: policy.fileUrl!,
                signatureBytes: signatureBytes,
              );
              final signedPdfName = 'signed_agreement_policy_${policy.id}.pdf';
              signatureUrl = await PoliciesRemoteData.uploadSignedPdf(
                pdfBytes: signedPdfBytes,
                fileName: signedPdfName,
              );
            } else {
              signatureUrl = await PoliciesRemoteData.uploadSignature(
                signatureBytes,
              );
            }
          } else {
            throw Exception('Please add your signature before submitting.');
          }
        }
      }

      await PoliciesRemoteData.submitPolicyAcknowledgment(
        policyId: policy.id,
        userId: userId,
        eConsentRequired: requiresSignature,
        signatureUrl: signatureUrl,
      );

      await _reloadPolicy();
      if (!mounted) return;

      setState(() {
        _isAgreed = false;
        _signatureBytes = null;
        _shouldRefreshOnExit = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acknowledgment submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAcknowledgment = false;
        });
      }
    }
  }

  Widget _buildSelectedPdfCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(sw * 0.035),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.backgroundMedium,
        ),
        child: Row(
          children: [
            Container(
              width: sw * 0.12,
              height: sw * 0.12,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.error,
                size: sw * 0.065,
              ),
            ),
            SizedBox(width: sw * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: sh * 0.004),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(width: sw * 0.02),
            Icon(
              Icons.open_in_new_rounded,
              size: sw * 0.05,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _extractFileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final segments = uri?.pathSegments ?? const <String>[];
    if (segments.isNotEmpty && segments.last.trim().isNotEmpty) {
      return segments.last;
    }
    return 'signed_agreement.pdf';
  }

  Future<void> _openPdfPreviewFromUrl(
    String url, {
    required String title,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PolicyPdfPreviewPage(title: title, pdfUrl: url),
      ),
    );
  }

  Future<Uint8List> _buildSignedAgreementPdf({
    required String sourcePdfUrl,
    required Uint8List signatureBytes,
  }) async {
    final response = await Dio().get<List<int>>(
      sourcePdfUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    final sourcePdfBytes = Uint8List.fromList(response.data ?? const <int>[]);
    if (sourcePdfBytes.isEmpty) {
      throw Exception('Unable to load the source policy PDF.');
    }

    final document = pw.Document();
    final signatureImage = pw.MemoryImage(signatureBytes);
    final rasterPages = Printing.raster(sourcePdfBytes, dpi: 144);
    final pages = <PdfRaster>[];

    await for (final page in rasterPages) {
      pages.add(page);
    }

    if (pages.isEmpty) {
      throw Exception('Unable to prepare the signed agreement PDF.');
    }

    for (var index = 0; index < pages.length; index++) {
      final page = pages[index];
      final pageImageBytes = await page.toPng();
      final pageImage = pw.MemoryImage(pageImageBytes);
      final pageFormat = PdfPageFormat(
        page.width.toDouble(),
        page.height.toDouble(),
      );
      final isFirstPage = index == 0;

      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) {
            final stackChildren = <pw.Widget>[
              pw.Positioned.fill(
                child: pw.Image(pageImage, fit: pw.BoxFit.fill),
              ),
            ];

            if (isFirstPage) {
              stackChildren.add(
                pw.Positioned(
                  left: 24,
                  top: 24,
                  child: pw.SizedBox(
                    width: 150,
                    height: 55,
                    child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                  ),
                ),
              );
            }

            return pw.Stack(children: stackChildren);
          },
        ),
      );
    }

    return document.save();
  }

  String _getPolicyContent(PolicyModel policy) {
    return (policy.content != null && policy.content!.trim().isNotEmpty)
        ? policy.content!
        : '''At Tech Superior Consulting, we are dedicated to maintaining a professional and respectful workplace. This policy outlines the expectations for all employees to ensure a positive, productive, and secure work environment.

Our Commitment:
• Honesty, integrity, accountability, teamwork, transparency, and ethical behavior
• Maintaining a safe and positive work environment
• Adherence to company guidelines and policies
• Respect for colleagues and professional conduct

Confidentiality:
• Protection of confidential information and client data
• Strict prohibition against unauthorized sharing of sensitive information
• Safeguarding internal documents and company resources

Asset Usage:
• Responsible usage of company assets (laptops, access cards, digital systems)
• Adherence to defined work hours, attendance rules, and leave policies
• Responsible performance of remote work with secure access to company systems

Consequences:
• Corrective action for misuse of company equipment
• Disciplinary action for violation of IT security standards
• Company's right to take action for policy violations

By acknowledging this policy, you agree to uphold company values and contribute to a productive, secure, and supportive workplace.''';
  }
}

class _PolicyContentPreviewPage extends StatefulWidget {
  final PolicyModel policy;

  const _PolicyContentPreviewPage({required this.policy});

  @override
  State<_PolicyContentPreviewPage> createState() =>
      _PolicyContentPreviewPageState();
}

class _PolicyContentPreviewPageState extends State<_PolicyContentPreviewPage> {
  late final WebViewController _webViewController;
  bool _isHtmlLoading = false;

  @override
  void initState() {
    super.initState();
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {
                if (!mounted) return;
                setState(() {
                  _isHtmlLoading = false;
                });
              },
            ),
          );

    if ((widget.policy.htmlContent ?? '').trim().isNotEmpty) {
      _loadHtmlContent(widget.policy.htmlContent!);
    }
  }

  Future<void> _loadHtmlContent(String htmlContent) async {
    setState(() {
      _isHtmlLoading = true;
    });
    await _webViewController.loadRequest(
      Uri.dataFromString(
        _buildPolicyHtmlDocument(htmlContent),
        mimeType: 'text/html',
        encoding: utf8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFile =
        widget.policy.isFile &&
        widget.policy.fileUrl != null &&
        widget.policy.fileUrl!.isNotEmpty;

    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          widget.policy.name,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                isFile
                    ? SfPdfViewer.network(widget.policy.fileUrl!)
                    : Stack(
                      children: [
                        Positioned.fill(
                          child: WebViewWidget(controller: _webViewController),
                        ),
                        if (_isHtmlLoading)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

class _PolicyPdfPreviewPage extends StatelessWidget {
  final String title;
  final String pdfUrl;

  const _PolicyPdfPreviewPage({required this.title, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          title,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SfPdfViewer.network(pdfUrl),
          ),
        ),
      ),
    );
  }
}

String _buildPolicyHtmlDocument(String rawHtml) {
  final normalized =
      rawHtml.contains('<!DOCTYPE html>')
          ? rawHtml
          : '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
  </head>
  <body>$rawHtml</body>
</html>
''';

  final withHeadStyle = normalized.replaceFirst('</head>', '''
  <base href="https://app.collectivwork.com/">
  <style>
    * {
      box-sizing: border-box;
      max-width: 100%;
    }

    html, body {
      margin: 0;
      padding: 0;
      background: #ffffff !important;
      color: #111111;
      min-height: 100%;
      width: 100%;
      overflow-x: hidden;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.6;
    }

    body {
      padding: 16px;
    }

    img {
      max-width: 100%;
      height: auto;
      display: block;
    }

    table {
      width: 100% !important;
      border-collapse: collapse;
    }
  </style>
</head>''');

  return withHeadStyle.replaceFirst(
    '<body>',
    '<body style="background:#ffffff !important; margin:0; padding:16px;">',
  );
}
