import 'dart:convert';
import 'dart:io';

import 'package:collectivWork/features/services/presentation/pages/sub_services/policies/presentation/pages/policy_pdf_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:webcontent_converter/webcontent_converter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/policy_model.dart';
import '../data/policies_remote_data.dart';
import '../widgets/policy_pdf_annotation_editor.dart';
import '../widgets/signature_dialog.dart';

/// Policy detail page showing full policy content and acknowledgment
class PolicyDetailPage extends StatefulWidget {
  final PolicyModel policy;

  const PolicyDetailPage({super.key, required this.policy});

  @override
  State<PolicyDetailPage> createState() => _PolicyDetailPageState();
}

class _PolicyDetailPageState extends State<PolicyDetailPage> {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'collectivwork/downloads',
  );

  bool _isAgreed = false;
  Uint8List? _signatureBytes;
  late Future<PolicyModel> _policyFuture;
  late final PolicyPdfEditorController _pdfEditorController;
  late final WebViewController _htmlPreviewController;
  bool _isSubmittingAcknowledgment = false;
  bool _shouldRefreshOnExit = false;
  bool _isDocumentExpanded = true;
  bool _isHtmlLoading = false;
  bool _isDownloadingPolicy = false;
  String? _loadedHtmlContent;

  @override
  void initState() {
    super.initState();
    _pdfEditorController = PolicyPdfEditorController();
    _htmlPreviewController =
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
    _policyFuture = PoliciesRemoteData.getPolicyDetail(widget.policy.id);
  }

  @override
  void dispose() {
    _pdfEditorController.dispose();
    super.dispose();
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
          forceMaterialTransparency: true,
          backgroundColor: AppColors.backgroundMedium,
          leading: GestureDetector(
            onTap: _handleBackPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).colorScheme.primary,
                  size:
                      MediaQuery.of(context).size.width *
                      0.048, // ~4.8% of screen width
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
            widget.policy.name,
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
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
            color: Colors.black.withValues(alpha: 0.05),
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
            _assignedByDisplayValue(policy),
            policy.assignedByAvatar,
            alwaysShowAvatar: true,
            avatarFallbackName: policy.assignedBy,
            avatarFallbackColor: _parseColor(policy.assignedByProfileColor),
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
                    color: _statusColor(policy),
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
    {
    bool alwaysShowAvatar = false,
    String? avatarFallbackName,
    Color? avatarFallbackColor,
  }
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;
    final trimmedAvatarPath = avatarPath?.trim();
    final shouldShowAvatar =
        alwaysShowAvatar || (trimmedAvatarPath != null && trimmedAvatarPath.isNotEmpty);
    final displayValue =
        label == 'Assigned Date' || label == 'Updated On'
            ? _formatSummaryDate(value)
            : value;

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
              if (shouldShowAvatar) ...[
                SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
                _buildAvatar(
                  context: context,
                  name: avatarFallbackName ?? value,
                  avatarPath: trimmedAvatarPath,
                  radius: smallerDimension * 0.033,
                  fallbackColor: avatarFallbackColor,
                ),
              ] ,
              SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
              Flexible(
                child: Text(
                  displayValue,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSummaryDate(String value) {
    if (value.trim().isEmpty || value == 'N/A') {
      return value;
    }

    final parsedDate = DateFormat('dd/MM/yyyy').tryParse(value);
    if (parsedDate == null) {
      return value;
    }

    return DateFormat('dd-MMM-yyyy').format(parsedDate);
  }

  String _assignedByDisplayValue(PolicyModel policy) {
    final employeeId = policy.assignedByEmployeeId?.trim();
    if (employeeId == null || employeeId.isEmpty) {
      return policy.assignedBy;
    }
    return '${policy.assignedBy} ($employeeId)';
  }

  Widget _buildAvatar({
    required BuildContext context,
    required String name,
    required String? avatarPath,
    required double radius,
    Color? fallbackColor,
  }) {
    final avatarSize = radius * 2;
    final trimmedAvatarPath = avatarPath?.trim();

    if (trimmedAvatarPath != null && trimmedAvatarPath.startsWith('http')) {
      return SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: trimmedAvatarPath,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorWidget:
                (_, __, ___) => _buildAvatarFallback(
                  context,
                  name,
                  radius,
                  fallbackColor: fallbackColor,
                ),
          ),
        ),
      );
    }

    if (trimmedAvatarPath != null && trimmedAvatarPath.isNotEmpty) {
      return SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: ClipOval(
          child: Image.asset(
            trimmedAvatarPath,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => _buildAvatarFallback(
                  context,
                  name,
                  radius,
                  fallbackColor: fallbackColor,
                ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: fallbackColor ?? AppColors.border,
      child: _buildAvatarFallback(
        context,
        name,
        radius,
        fallbackColor: fallbackColor,
      ),
    );
  }

  Widget _buildAvatarFallback(
    BuildContext context,
    String name,
    double radius,
    {
    Color? fallbackColor,
  }) {
    final trimmedName = name.trim();
    final parts = trimmedName.split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final list = parts.toList();
    final initials =
        list.isEmpty
            ? ''
            : list.length == 1
            ? list.first.substring(0, 1).toUpperCase()
            : '${list.first.substring(0, 1)}${list.last.substring(0, 1)}'
                .toUpperCase();

    if (initials.isEmpty) {
      return Icon(
        Icons.person,
        size: radius,
        color: Colors.white,
      );
    }

    return Center(
      child: Text(
        initials,
        style: AppTextStyles.labelSmall(context).copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceFirst('#', '');
    if (normalized.length != 6 && normalized.length != 8) return null;
    final value = int.tryParse(
      normalized.length == 6 ? 'FF$normalized' : normalized,
      radix: 16,
    );
    if (value == null) return null;
    return Color(value);
  }

  Color _statusColor(PolicyModel policy) {
    final normalizedStatus = policy.status.trim().toLowerCase();
    if (policy.isAcknowledged) {
      return AppColors.success;
    }
    if (normalizedStatus == 'viewed') {
      return AppColors.info;
    }
    return AppColors.warning;
  }

  Widget _buildContentCard(PolicyModel policy) {
    if (policy.isFile && policy.fileUrl != null && policy.fileUrl!.isNotEmpty) {
      return _buildPdfEditorCard(policy);
    }

    if ((policy.htmlContent ?? '').trim().isNotEmpty) {
      _ensureHtmlContentLoaded(policy.htmlContent!);
      return _buildHtmlContentCard(policy);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildPdfEditorCard(PolicyModel policy) {
    final sourcePdfUrl = (policy.fileUrl ?? '').trim();
    final requiresSignature = policy.isConsentSignatureEnabled;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _isDocumentExpanded = !_isDocumentExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Policy Document',
                      style: AppTextStyles.bodyMediumHeading(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_canDownload(policy))
                    IconButton(
                      tooltip: 'Download policy',
                      onPressed:
                          _isDownloadingPolicy
                              ? null
                              : () => _downloadPolicyFile(policy),
                      icon:
                          _isDownloadingPolicy
                              ? const SizedBox(
                                width: AppSpacing.lg,
                                height: AppSpacing.lg,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : const Icon(Icons.download_rounded),
                    ),
                  AnimatedRotation(
                    turns: _isDocumentExpanded ? 0.0 : -0.25,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: const Icon(Icons.arrow_drop_down_outlined),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:
                _isDocumentExpanded
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSpacing.vMd,
                        Text(
                          policy.isAcknowledged
                              ? 'Review the policy document below.'
                              : 'Add text and signatures directly on the PDF before submitting.',
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                        if (!policy.isAcknowledged) ...[
                          AppSpacing.vLg,
                          AnimatedBuilder(
                            animation: _pdfEditorController,
                            builder: (context, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed:
                                            _isSubmittingAcknowledgment
                                                ? null
                                                : _pdfEditorController
                                                    .startTextPlacement,
                                        icon: const Icon(
                                          Icons.text_fields_rounded,
                                        ),
                                        label: Text(
                                          'Add Text',
                                          style: AppTextStyles.bodySmall(context),
                                        ),
                                      ),
                                      if (requiresSignature)
                                        OutlinedButton.icon(
                                          onPressed:
                                              _isSubmittingAcknowledgment
                                                  ? null
                                                  : _handleAddSignature,
                                          icon: const Icon(Icons.draw_outlined),
                                          label: Text(
                                            'Add Signature',
                                            style: AppTextStyles.bodySmall(
                                              context,
                                            ),
                                          ),
                                        ),
                                      OutlinedButton.icon(
                                        onPressed:
                                            _isSubmittingAcknowledgment ||
                                                    !_pdfEditorController
                                                        .hasSelectedAnnotation
                                                ? null
                                                : _pdfEditorController
                                                    .deleteSelectedAnnotation,
                                        icon: const Icon(Icons.delete_outline),
                                        label: Text(
                                          'Delete Selected',
                                          style: AppTextStyles.bodySmall(context),
                                        ),
                                      ),
                                      if (_pdfEditorController
                                          .isAwaitingPlacement)
                                        OutlinedButton.icon(
                                          onPressed:
                                              _isSubmittingAcknowledgment
                                                  ? null
                                                  : _pdfEditorController
                                                      .cancelPlacement,
                                          icon: const Icon(Icons.close_rounded),
                                          label: Text(
                                            'Cancel Placement',
                                            style: AppTextStyles.bodySmall(
                                              context,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (_pdfEditorController.placementMessage !=
                                      null) ...[
                                    AppSpacing.vMd,
                                    Container(
                                      width: double.infinity,
                                      padding: AppSpacing.cardPaddingSmall,
                                      decoration: BoxDecoration(
                                        color: AppColors.info.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.info.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _pdfEditorController.placementMessage!,
                                        style: AppTextStyles.bodySmall(
                                          context,
                                        ).copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                        AppSpacing.vLg,
                        PolicyPdfAnnotationEditor(
                          sourcePdfUrl: sourcePdfUrl,
                          controller: _pdfEditorController,
                          readOnly:
                              policy.isAcknowledged ||
                              _isSubmittingAcknowledgment,
                        ),
                      ],
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHtmlContentCard(PolicyModel policy) {
    final htmlContent = (policy.htmlContent ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _isDocumentExpanded = !_isDocumentExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Policy Document',
                      style: AppTextStyles.bodyMediumHeading(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_canDownloadHtmlPolicy(policy))
                    IconButton(
                      tooltip: 'Download policy',
                      onPressed:
                          _isDownloadingPolicy
                              ? null
                              : () => _downloadHtmlPolicyContent(
                                policy,
                                htmlContent: htmlContent,
                              ),
                      icon:
                          _isDownloadingPolicy
                              ? const SizedBox(
                                width: AppSpacing.lg,
                                height: AppSpacing.lg,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : const Icon(Icons.download_rounded),
                    ),
                  AnimatedRotation(
                    turns: _isDocumentExpanded ? 0.0 : -0.25,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: const Icon(Icons.arrow_drop_down_outlined),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:
                _isDocumentExpanded
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSpacing.vMd,
                        Text(
                          'Review the policy content below.',
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                        AppSpacing.vLg,
                        _buildHtmlPreviewSurface(),
                      ],
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHtmlPreviewSurface() {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.45,
        maxHeight: screenHeight * 0.75,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: WebViewWidget(controller: _htmlPreviewController),
            ),
            if (_isHtmlLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.white,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddSignature() async {
    final result = await showDialog<Uint8List>(
      context: context,
      builder: (context) => const SignatureDialog(),
    );

    if (result == null || !mounted) {
      return;
    }

    _pdfEditorController.addSignatureAnnotation(signatureBytes: result);
  }

  Widget _buildAcknowledgmentSection(PolicyModel policy) {
    final requiresSignature = policy.isConsentSignatureEnabled;
    final usesInlinePdfEditor =
        policy.isFile && (policy.fileUrl ?? '').trim().isNotEmpty;

    return AnimatedBuilder(
      animation: _pdfEditorController,
      builder: (context, _) {
        final existingSignatureUrl = (policy.signatureUrl ?? '').trim();
        final hasExistingSignature = existingSignatureUrl.isNotEmpty;
        final hasRequiredSignature =
            usesInlinePdfEditor
                ? _pdfEditorController.hasSignatureAnnotations
                : (_signatureBytes != null || hasExistingSignature);
        final canSubmit =
            _isAgreed &&
            !_isSubmittingAcknowledgment &&
            (!requiresSignature || hasRequiredSignature);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _isAgreed,
                    onChanged:
                        (value) {
                          setState(() {
                            _isAgreed = value ?? false;
                          });
                        },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: Text(
                      'I have read and agree to the company policy',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vMd,
              if (requiresSignature && usesInlinePdfEditor) ...[
                // Text(
                //   hasRequiredSignature
                //       ? 'Signature added to the PDF. You can drag, resize, or add more before submitting.'
                //       : 'Add at least one signature directly on the PDF before submitting.',
                //   style: AppTextStyles.bodySmall(context).copyWith(
                //     color:
                //         hasRequiredSignature
                //             ? AppColors.success
                //             : AppColors.textSecondary,
                //     fontWeight: FontWeight.w400,
                //
                //   ),
                // ),
                AppSpacing.vLg,
              ]
              else if (requiresSignature) ...[
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
                  AppSpacing.vMd,
                ] else if (hasExistingSignature) ...[
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
                  AppSpacing.vMd,
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
                        vertical:
                            MediaQuery.of(context).size.height * 0.0175,
                      ),
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
                      style: AppTextStyles.bodyMediumHeading(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            _isAgreed
                                ? AppColors.background
                                : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                AppSpacing.vLg,
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      canSubmit ? () => _submitAcknowledgment(policy) : null,
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
                  child: Text(
                    _isSubmittingAcknowledgment
                        ? 'Submitting...'
                        : 'Submit Acknowledgment',
                    style: AppTextStyles.bodyMediumHeading(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
              color: Colors.black.withValues(alpha: 0.05),
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
              style: AppTextStyles.bodyMedium(context).copyWith(
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
            color: Colors.black.withValues(alpha: 0.05),
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
            style: AppTextStyles.bodyMedium(context).copyWith(
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
      final usesInlinePdfEditor =
          policy.isFile && (policy.fileUrl ?? '').trim().isNotEmpty;
      String signatureUrl = policy.signatureUrl ?? '';
      if (usesInlinePdfEditor) {
        final annotations = _pdfEditorController.annotations;
        if (requiresSignature && !_pdfEditorController.hasSignatureAnnotations) {
          throw Exception(
            'Please add at least one signature directly on the PDF before submitting.',
          );
        }

        if (annotations.isNotEmpty) {
          final signedPdfBytes = await _buildSignedAgreementPdf(
            sourcePdfUrl: policy.fileUrl!,
            annotations: annotations,
          );
          final signedPdfName = 'signed_agreement_policy_${policy.id}.pdf';
          signatureUrl = await PoliciesRemoteData.uploadSignedPdf(
            pdfBytes: signedPdfBytes,
            fileName: signedPdfName,
          );
        }
      } else if (requiresSignature) {
        if (signatureUrl.isEmpty || _signatureBytes != null) {
          final signatureBytes = _signatureBytes;
          if (signatureBytes != null) {
            signatureUrl = await PoliciesRemoteData.uploadSignature(
              signatureBytes,
            );
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

      _pdfEditorController.setAnnotations(const <PolicyPdfAnnotation>[]);
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
                color: AppColors.error.withValues(alpha: 0.10),
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
                    style: AppTextStyles.bodyMediumHeading(context).copyWith(
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

  void _ensureHtmlContentLoaded(String htmlContent) {
    final normalizedHtml = htmlContent.trim();
    if (normalizedHtml.isEmpty || _loadedHtmlContent == normalizedHtml) {
      return;
    }

    _loadedHtmlContent = normalizedHtml;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadHtmlContent(normalizedHtml);
    });
  }

  Future<void> _loadHtmlContent(String htmlContent) async {
    if (!mounted) return;
    setState(() {
      _isHtmlLoading = true;
    });

    await _htmlPreviewController.loadRequest(
      Uri.dataFromString(
        _buildPolicyHtmlDocument(htmlContent),
        mimeType: 'text/html',
        encoding: utf8,
      ),
    );
  }

  bool _canDownload(PolicyModel policy) =>
      policy.allowDownload &&
      policy.isFile &&
      (policy.fileUrl?.trim().isNotEmpty ?? false);

  bool _canDownloadHtmlPolicy(PolicyModel policy) =>
      policy.allowDownload && (policy.htmlContent?.trim().isNotEmpty ?? false);

  Future<void> _downloadPolicyFile(PolicyModel policy) async {
    final fileUrl = policy.fileUrl?.trim() ?? '';
    if (fileUrl.isEmpty) {
      _showSnack('Policy PDF is not available for download.', isError: true);
      return;
    }

    setState(() {
      _isDownloadingPolicy = true;
    });

    try {
      final hasPermission = await _ensureDownloadPermission();
      if (!hasPermission) {
        if (!mounted) return;
        await _showPermissionDeniedDialog();
        return;
      }

      final sourceFileName = _extractFileNameFromUrl(fileUrl);
      final fileName = _sanitizeFileName(
        sourceFileName.trim().isEmpty ? '${policy.name}.pdf' : sourceFileName,
        '.pdf',
      );

      final tempFile = await _downloadPolicyToFile(
        sourceUrl: fileUrl,
        directory: await _resolvePolicyTempDirectory(),
        fileName: fileName,
      );

      final savedFile =
          Platform.isAndroid
              ? await _savePolicyToDownloads(
                tempFile: tempFile,
                fileName: fileName,
              )
              : await _copyFileToDirectory(
                sourceFile: tempFile,
                directory: await _resolvePolicyDocumentsDirectory(),
                fileName: fileName,
              );

      _showSnack(
        Platform.isIOS
            ? 'Policy PDF saved to Files in the Policies folder.'
            : 'Policy PDF downloaded to your Downloads folder.',
        isError: false,
      );

      await OpenFilex.open(savedFile.path);
    } catch (error) {
      _showSnack(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPolicy = false;
        });
      }
    }
  }

  Future<void> _downloadHtmlPolicyContent(
    PolicyModel policy, {
    required String htmlContent,
  }) async {
    if (htmlContent.isEmpty) {
      _showSnack('Policy content is not available for download.', isError: true);
      return;
    }

    setState(() {
      _isDownloadingPolicy = true;
    });

    try {
      final hasPermission = await _ensureDownloadPermission();
      if (!hasPermission) {
        if (!mounted) return;
        await _showPermissionDeniedDialog();
        return;
      }

      final fileName = _sanitizeFileName(policy.name, '.pdf');
      final file = await _getOrCreateHtmlDownloadFile(
        policy: policy,
        htmlContent: htmlContent,
        fileName: fileName,
      );

      if (Platform.isAndroid) {
        await _savePolicyToDownloads(tempFile: file, fileName: fileName);
      }

      _showSnack(
        Platform.isIOS
            ? 'Policy PDF saved to Files in the Policies folder.'
            : 'Policy PDF downloaded to your Downloads folder.',
        isError: false,
      );
      await OpenFilex.open(file.path);
    } catch (error) {
      _showSnack(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPolicy = false;
        });
      }
    }
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
        builder: (_) => PolicyPdfPreviewPage(title: title, pdfUrl: url),
      ),
    );
  }

  Future<Uint8List> _buildSignedAgreementPdf({
    required String sourcePdfUrl,
    required List<PolicyPdfAnnotation> annotations,
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
      final pageAnnotations =
          annotations
              .where((annotation) => annotation.pageIndex == index)
              .toList();
      final pageFormat = PdfPageFormat(
        page.width.toDouble(),
        page.height.toDouble(),
      );

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

            for (final annotation in pageAnnotations) {
              if (annotation.isSignature && annotation.signatureBytes != null) {
                stackChildren.add(
                  pw.Positioned(
                    left: annotation.xRatio * page.width.toDouble(),
                    top: annotation.yRatio * page.height.toDouble(),
                    child: pw.SizedBox(
                      width: annotation.widthRatio * page.width.toDouble(),
                      height: annotation.heightRatio * page.height.toDouble(),
                      child: pw.Image(
                        pw.MemoryImage(annotation.signatureBytes!),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                );
                continue;
              }

              if (annotation.isText && (annotation.text ?? '').trim().isNotEmpty) {
                stackChildren.add(
                  pw.Positioned(
                    left: annotation.xRatio * page.width.toDouble(),
                    top: annotation.yRatio * page.height.toDouble(),
                    child: pw.Container(
                      width: annotation.widthRatio * page.width.toDouble(),
                      constraints: pw.BoxConstraints(
                        minHeight: annotation.heightRatio * page.height.toDouble(),
                      ),
                      child: pw.Text(
                        annotation.text!.trim(),
                        style: pw.TextStyle(
                          color: PdfColors.black,
                          fontSize:
                              annotation.fontScale * page.width.toDouble(),
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }
            }

            return pw.Stack(children: stackChildren);
          },
        ),
      );
    }

    return document.save();
  }

  Future<bool> _ensureDownloadPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final androidInfo = await _androidSdkInt();
    if (androidInfo != null && androidInfo >= 29) {
      return true;
    }

    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) {
      return true;
    }

    final storageResult = await Permission.storage.request();
    return storageResult.isGranted;
  }

  Future<int?> _androidSdkInt() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      return await _downloadsChannel.invokeMethod<int>('getAndroidSdkInt');
    } catch (_) {
      return null;
    }
  }

  Future<void> _showPermissionDeniedDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Storage Permission Needed'),
          content: const Text(
            'Allow storage access to save the policy PDF to your device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<Directory> _resolvePolicyTempDirectory() async {
    final tempDirectory = await getTemporaryDirectory();
    return Directory(path.join(tempDirectory.path, 'Policies'));
  }

  Future<Directory> _resolvePolicyDocumentsDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return Directory(path.join(documentsDirectory.path, 'Policies'));
  }

  Future<File> _downloadPolicyToFile({
    required String sourceUrl,
    required Directory directory,
    required String fileName,
  }) async {
    await directory.create(recursive: true);
    final filePath = path.join(directory.path, fileName);
    final response = await Dio().get<List<int>>(
      sourceUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = Uint8List.fromList(response.data ?? const <int>[]);
    if (bytes.isEmpty) {
      throw Exception('Unable to download policy PDF.');
    }

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> _getOrCreateHtmlDownloadFile({
    required PolicyModel policy,
    required String htmlContent,
    required String fileName,
  }) async {
    final previewFile = await _getOrCreateHtmlPreviewPdf(
      policy: policy,
      htmlContent: htmlContent,
    );

    if (Platform.isIOS) {
      return _copyFileToDirectory(
        sourceFile: previewFile,
        directory: await _resolvePolicyDocumentsDirectory(),
        fileName: fileName,
      );
    }

    return previewFile;
  }

  Future<File> _getOrCreateHtmlPreviewPdf({
    required PolicyModel policy,
    required String htmlContent,
  }) async {
    final previewDirectory = await _resolvePolicyTempDirectory();
    final previewFileName =
        'Policy_preview_${policy.id}_${_stableContentHash(htmlContent)}.pdf';
    final cachedPreviewFile = File(
      path.join(previewDirectory.path, previewFileName),
    );

    if (await cachedPreviewFile.exists()) {
      return cachedPreviewFile;
    }

    return _generateHtmlPolicyPdfFile(
      htmlContent: htmlContent,
      directory: previewDirectory,
      fileName: previewFileName,
    );
  }

  Future<File> _generateHtmlPolicyPdfFile({
    required String htmlContent,
    required Directory directory,
    required String fileName,
  }) async {
    await directory.create(recursive: true);
    final filePath = path.join(directory.path, fileName);
    final savedPath = await WebcontentConverter.contentToPDF(
      content: _buildPolicyPdfHtmlDocument(htmlContent),
      savedPath: filePath,
      format: PaperFormat.a4,
      margins: PdfMargins.px(top: 0, bottom: 0, right: 0, left: 0),
    );

    if (savedPath == null || savedPath.isEmpty) {
      throw Exception('Could not generate policy PDF.');
    }

    final file = File(savedPath);
    if (!await file.exists()) {
      throw Exception('Generated policy PDF could not be found.');
    }

    return file;
  }

  Future<File> _savePolicyToDownloads({
    required File tempFile,
    required String fileName,
  }) async {
    final result = await _downloadsChannel.invokeMethod<Map<dynamic, dynamic>>(
      'saveFileToDownloads',
      <String, dynamic>{
        'sourcePath': tempFile.path,
        'fileName': fileName,
        'mimeType': 'application/pdf',
        'subdirectory': 'Policies',
      },
    );

    if (result == null) {
      throw Exception('Could not save policy PDF to Downloads.');
    }

    final isSuccess = result['success'] == true;
    if (!isSuccess) {
      throw Exception(
        (result['error'] as String?) ??
            'Could not save policy PDF to Downloads.',
      );
    }

    final savedPath = result['path'] as String?;
    if (savedPath != null && savedPath.isNotEmpty) {
      return File(savedPath);
    }

    return tempFile;
  }

  Future<File> _copyFileToDirectory({
    required File sourceFile,
    required Directory directory,
    required String fileName,
  }) async {
    await directory.create(recursive: true);
    final destinationPath = path.join(directory.path, fileName);
    final destinationFile = File(destinationPath);

    if (destinationFile.existsSync()) {
      destinationFile.deleteSync();
    }

    return sourceFile.copy(destinationPath);
  }

  String _sanitizeFileName(String rawName, String extension) {
    final normalizedName = rawName.trim().isEmpty ? 'policy' : rawName.trim();
    final sanitized = normalizedName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return sanitized.endsWith(extension) ? sanitized : '$sanitized$extension';
  }

  String _stableContentHash(String value) {
    const int fnvOffsetBasis = 0x811C9DC5;
    const int fnvPrime = 0x01000193;

    var hash = fnvOffsetBasis;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isError ? ErrorMessageMapper.toUserFriendlyMessage(message) : message,
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
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
    <style>
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        margin: 0;
        padding: 16px;
        color: #101828;
        background: #ffffff;
        line-height: 1.6;
        word-wrap: break-word;
      }
      img, table {
        max-width: 100%;
      }
      table {
        border-collapse: collapse;
      }
      td, th {
        border: 1px solid #d0d5dd;
        padding: 8px;
      }
    </style>
  </head>
  <body>$rawHtml</body>
</html>
''';
    return normalized;
  }

  String _buildPolicyPdfHtmlDocument(String rawHtml) {
    final normalized = _buildPolicyHtmlDocument(rawHtml);
    final withHeadStyle = normalized.replaceFirst('</head>', '''
  <base href="https://app.collectivwork.com/">
  <style>
    @page {
      size: A4;
      margin: 8mm;
    }

    * {
      box-sizing: border-box;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }

    html, body {
      margin: 0 !important;
      padding: 0 !important;
      background: #ffffff !important;
      color: #111111 !important;
      font-size: 100% !important;
      width: 100% !important;
      min-height: 0 !important;
      height: auto !important;
      overflow: visible !important;
    }

    body, div, section, article, main, header, footer, aside,
    .container, .container-fluid, .content, .page, .wrapper {
      min-height: 0 !important;
      height: auto !important;
      overflow: visible !important;
      max-height: none !important;
    }

    [style*="overflow: hidden"],
    [style*="overflow:hidden"],
    [style*="overflow-y: hidden"],
    [style*="overflow-y:hidden"],
    [style*="height: 100vh"],
    [style*="height:100vh"],
    [style*="position: fixed"],
    [style*="position:fixed"],
    [style*="position: sticky"],
    [style*="position:sticky"] {
      overflow: visible !important;
      height: auto !important;
      max-height: none !important;
      position: static !important;
    }

    img, svg, canvas {
      max-width: 100% !important;
      height: auto !important;
      display: block;
    }

    table {
      width: 100% !important;
      border-collapse: collapse;
    }

    table, thead, tbody, tr, td, th {
      page-break-inside: avoid !important;
      break-inside: avoid !important;
    }
  </style>
</head>''');

    return withHeadStyle.replaceFirst(
      '<body>',
      '<body style="background:#ffffff !important; margin:0; padding:0; height:auto !important; overflow:visible !important;">',
    );
  }

  String _getPolicyContent(PolicyModel policy) {
    final content = policy.content?.trim().toLowerCase();

    if (content == null ||
        content.isEmpty ||
        content == 'null' ||
        content == 'n/a' ||
        content == 'undefined') {
      return '';
    }

    return policy.content!.trim();
  }
}
