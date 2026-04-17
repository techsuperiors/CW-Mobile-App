import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webcontent_converter/webcontent_converter.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../../policies/presentation/widgets/policy_pdf_annotation_editor.dart';
import '../../../policies/presentation/widgets/signature_dialog.dart';
import '../bloc/agreement_bloc.dart';
import '../bloc/agreement_event.dart';
import '../bloc/agreement_state.dart';

class CommonAgreementDetailPage extends StatefulWidget {
  final int agreementId;
  final String agreementName;
  final String status;
  final String? content;
  final String? signatureUrl;
  final String? documentUrl;
  final bool showDocumentsOnly;
  final bool useLegacyHtmlPreview;

  const CommonAgreementDetailPage({
    super.key,
    required this.agreementId,
    required this.agreementName,
    required this.status,
    this.content,
    this.signatureUrl,
    this.documentUrl,
    this.showDocumentsOnly = false,
    this.useLegacyHtmlPreview = false,
  });

  @override
  State<CommonAgreementDetailPage> createState() =>
      _CommonAgreementDetailPageState();
}

class _CommonAgreementDetailPageState extends State<CommonAgreementDetailPage> {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'collectivwork/downloads',
  );

  bool _isAgreed = false;
  late final PolicyPdfEditorController _pdfEditorController;
  Uint8List? _legacySignatureBytes;
  bool _isDownloading = false;
  File? _previewPdfFile;
  bool _isPreparingPreview = true;
  String? _previewError;

  bool get _hasPdfDocument =>
      widget.documentUrl != null && widget.documentUrl!.isNotEmpty;

  bool get _hasHtmlContent =>
      widget.content != null && widget.content!.trim().isNotEmpty;

  bool get _isSigned => widget.status.toLowerCase() == 'signed';

  bool get _canDownloadSignedDocument =>
       (_hasPdfDocument || _hasHtmlContent);

  bool get _hasPreviewSource => _hasPdfDocument || _hasHtmlContent;

  bool get _isEditableAgreement => !widget.showDocumentsOnly && !_isSigned;

  bool get _usesLegacyHtmlPreview => _hasHtmlContent && !_hasPdfDocument;

  RegExp get _legacySignaturePlaceholderPattern => RegExp(
    r"""^\s*(?:<p[^>]*>\s*)?<span[^>]*data-lexical-mention=(['"])true\1[^>]*>\s*\[Candidate Signature\]\s*<\/span>(?:\s*<\/p>)?\s*""",
    caseSensitive: false,
  );

  bool get _showsLegacySignaturePlaceholder {
    final content = widget.content ?? '';
    return _legacySignaturePlaceholderPattern.hasMatch(content);
  }

  bool get _hasLegacySignature =>
      _showsLegacySignaturePlaceholder &&
      (_legacySignatureBytes != null ||
          (widget.signatureUrl ?? '').trim().isNotEmpty);

  bool get _legacyCanSubmitWithoutSignature =>
      !_showsLegacySignaturePlaceholder;

  @override
  void initState() {
    super.initState();
    _pdfEditorController = PolicyPdfEditorController();
    if (!_usesLegacyHtmlPreview) {
      _preparePreviewPdf();
    } else {
      _isPreparingPreview = false;
    }
  }

  @override
  void dispose() {
    _pdfEditorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        forceMaterialTransparency: true,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: MediaQuery.of(context).size.width * 0.048,
              ),
              Flexible(
                child: Text(
                  AppStrings.back,
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
          widget.agreementName,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        actions: [
          if (_canDownloadSignedDocument)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _isDownloading ? null : _downloadAgreement,
                tooltip: 'Download',
                icon:
                    _isDownloading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                        : const Icon(
                          Icons.download_rounded,
                          color: AppColors.primary,
                        ),
              ),
            ),
        ],
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body:
          _usesLegacyHtmlPreview
              ? _buildLegacyHtmlLayout(context)
              : _hasPreviewSource
              ? _buildPdfLayout(context)
              : Center(
                child: Padding(
                  padding: AppSpacing.pagePadding,
                  child: Text(
                    'Agreement document is not available yet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge(
                      context,
                    ).copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
    );
  }

  Widget _buildLegacyHtmlLayout(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildLegacyHtmlPreviewCard(context),
        if (_isEditableAgreement)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildConsentSection(context),
          ),
      ],
    );
  }

  Widget _buildLegacyHtmlPreviewCard(BuildContext context) {
    final content = widget.content ?? '';
    final cleanedContent =
        _showsLegacySignaturePlaceholder
            ? content.replaceFirst(_legacySignaturePlaceholderPattern, '')
            : content;
    final normalizedContent = cleanedContent.replaceAll('\n', '<br/>');
    final networkSignatureUrl = widget.signatureUrl?.trim() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      padding: AppSpacing.cardPaddingSmall,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.agreementName,
            style: AppTextStyles.bodyMediumHeading(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.vLg,
          if (_showsLegacySignaturePlaceholder) ...[
            if (_legacySignatureBytes != null)
              Image.memory(
                _legacySignatureBytes!,
                width: 140,
                fit: BoxFit.contain,
              )
            else if (networkSignatureUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: networkSignatureUrl,
                width: 140,
                fit: BoxFit.contain,
                placeholder:
                    (context, url) => const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                errorWidget:
                    (context, url, error) =>
                        const Icon(Icons.broken_image_outlined),
              ),
            if (_hasLegacySignature) AppSpacing.vLg,
          ],
          Html(
            data: normalizedContent,
            style: {
              'html': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                backgroundColor: Colors.white,
              ),
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(
                  AppTextStyles.bodyMedium(context).fontSize ?? 14,
                ),
                color: AppColors.textPrimary,
                lineHeight: const LineHeight(1.7),
                fontWeight: FontWeight.w400,
              ),
              'p': Style(
                margin: Margins.only(bottom: AppSpacing.md),
                padding: HtmlPaddings.zero,
                lineHeight: const LineHeight(1.7),
              ),
              'div': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                lineHeight: const LineHeight(1.7),
              ),
              'span': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(
                  AppTextStyles.bodyMedium(context).fontSize ?? 14,
                ),
                color: AppColors.textPrimary,
                lineHeight: const LineHeight(1.7),
              ),
              'strong': Style(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              'b': Style(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              'em': Style(
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
              ),
              'i': Style(
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
              ),
              'ul': Style(
                margin: Margins.only(
                  bottom: AppSpacing.md,
                  left: AppSpacing.lg,
                ),
                padding: HtmlPaddings.zero,
              ),
              'ol': Style(
                margin: Margins.only(
                  bottom: AppSpacing.md,
                  left: AppSpacing.lg,
                ),
                padding: HtmlPaddings.zero,
              ),
              'li': Style(
                margin: Margins.only(bottom: AppSpacing.xs),
                lineHeight: const LineHeight(1.6),
              ),
              'table': Style(
                width: Width(100, Unit.percent),
                margin: Margins.only(bottom: AppSpacing.md),
                border: Border.all(color: AppColors.border),
              ),
              'th': Style(
                backgroundColor: AppColors.backgroundMedium,
                padding: HtmlPaddings.all(AppSpacing.sm),
                border: Border.all(color: AppColors.border),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              'td': Style(
                padding: HtmlPaddings.all(AppSpacing.sm),
                border: Border.all(color: AppColors.border),
                color: AppColors.textPrimary,
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPdfLayout(BuildContext context) {
    if (_isEditableAgreement) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildEditablePdfContent(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildConsentSection(context),
          ),
        ],
      );
    }

    return Column(
      children: [Expanded(child: _buildPdfViewer())],
    );
  }

  Future<void> _preparePreviewPdf() async {
    if (!_hasPreviewSource) {
      if (!mounted) return;
      setState(() {
        _isPreparingPreview = false;
        _previewError = null;
      });
      return;
    }

    try {
      final previewFile = await _getOrCreatePreviewPdf();

      if (!mounted) return;
      setState(() {
        _previewPdfFile = previewFile;
        _previewError = null;
        _isPreparingPreview = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _previewError = ErrorMessageMapper.toUserFriendlyMessage(
          error.toString(),
        );
        _isPreparingPreview = false;
      });
    }
  }

  Widget _buildConsentSection(BuildContext context) {
    if (_usesLegacyHtmlPreview) {
      return _buildLegacyConsentSection(context);
    }

    return AnimatedBuilder(
      animation: _pdfEditorController,
      builder: (context, _) {
        final hasRequiredSignature =
            _pdfEditorController.hasSignatureAnnotations;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.vLg,
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pdfEditorController.startTextPlacement,
                        icon: const Icon(Icons.text_fields_rounded),
                        label: Text(
                          'Add Text',
                          style: AppTextStyles.bodySmall(context),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _handleAddSignature,
                        icon: const Icon(Icons.draw_outlined),
                        label: Text(
                          'Add Signature',
                          style: AppTextStyles.bodySmall(context),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            !_pdfEditorController.hasSelectedAnnotation
                                ? null
                                : _pdfEditorController.deleteSelectedAnnotation,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          'Delete Selected',
                          style: AppTextStyles.bodySmall(context),
                        ),
                      ),
                      if (_pdfEditorController.isAwaitingPlacement)
                        OutlinedButton.icon(
                          onPressed: _pdfEditorController.cancelPlacement,
                          icon: const Icon(Icons.close_rounded),
                          label: Text(
                            'Cancel Placement',
                            style: AppTextStyles.bodySmall(context),
                          ),
                        ),
                    ],
                  ),
                  if (_pdfEditorController.placementMessage != null) ...[
                    AppSpacing.vMd,
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.cardPaddingSmall,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _pdfEditorController.placementMessage!,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.vLg,
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
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vXxs,
            Padding(
              padding: AppSpacing.pagePadding,
              child: BlocConsumer<AgreementBloc, AgreementState>(
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
                                  hasRequiredSignature &&
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
                          vertical:
                              MediaQuery.of(context).size.height * 0.0175,
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
                                style: AppTextStyles.bodyMediumHeading(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                    ),
                  );
                },
              ),
            ),
            AppSpacing.vLg,
          ],
        );
      },
    );
  }

  Widget _buildLegacyConsentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.vLg,
        if (_showsLegacySignaturePlaceholder)
          Padding(
            padding: AppSpacing.pagePadding,
            child: OutlinedButton.icon(
              onPressed: _handleLegacySignature,
              icon: const Icon(Icons.draw_outlined),
              label: Text(
                _hasLegacySignature ? 'Update Signature' : 'Add Signature',
                style: AppTextStyles.bodySmall(context),
              ),
            ),
          ),
        if (_legacyCanSubmitWithoutSignature)
          Padding(
            padding: AppSpacing.pagePadding,
            child: Text(
              'No candidate signature placeholder is configured in this agreement. You can submit acknowledgment directly.',
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ),
        Padding(
          padding: AppSpacing.pagePadding,
          child: Row(
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
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vXxs,
        Padding(
          padding: AppSpacing.pagePadding,
          child: BlocConsumer<AgreementBloc, AgreementState>(
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

                final userProfileState = context.read<UserProfileBloc>().state;
                if (userProfileState is UserProfileLoaded) {
                  final userId = userProfileState.profile.userId;
                  context.read<AgreementBloc>().add(RefreshAgreementList(userId));
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
              final canSubmit =
                  _isAgreed &&
                  (_legacyCanSubmitWithoutSignature || _hasLegacySignature) &&
                  !isSubmitting;

              return SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      canSubmit ? () => _submitAgreementConsent(context) : null,
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
                            style: AppTextStyles.bodyMediumHeading(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                ),
              );
            },
          ),
        ),
        AppSpacing.vLg,
      ],
    );
  }

  Widget _buildEditablePdfContent() {
    if (_isPreparingPreview) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_previewError != null) {
      return _buildPdfViewer();
    }

    final previewFile = _previewPdfFile;
    if (previewFile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: PolicyPdfAnnotationEditor(
        sourcePdfFilePath: previewFile.path,
        controller: _pdfEditorController,
        readOnly: false,
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

  Future<void> _handleLegacySignature() async {
    final result = await showDialog<Uint8List>(
      context: context,
      builder: (context) => const SignatureDialog(),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _legacySignatureBytes = result;
    });
  }

  Future<void> _downloadAgreement() async {
    if (!_hasPdfDocument && !_hasHtmlContent) {
      _showSnack('Agreement document is not available yet.', isError: true);
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final hasPermission = await _ensureDownloadPermission();
      if (!hasPermission) {
        if (!mounted) return;
        await _showPermissionDeniedDialog();
        return;
      }

      if (_hasPdfDocument) {
        await _downloadPdfAgreement();
      } else {
        await _downloadHtmlAgreementAsPdf();
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _downloadPdfAgreement() async {
    final documentUrl = widget.documentUrl;
    if (documentUrl == null || documentUrl.isEmpty) {
      throw Exception('Agreement PDF is not available.');
    }

    final sourceFileName = _extractFileNameFromUrl(documentUrl);
    final fileName = _sanitizeFileName(
      sourceFileName.trim().isEmpty
          ? '${widget.agreementName}.pdf'
          : sourceFileName,
      '.pdf',
    );

    final tempFile = await _downloadAgreementPdfToFile(
      sourceUrl: documentUrl,
      directory: await _resolveAgreementTempDirectory(),
      fileName: fileName,
    );

    final savedFile =
        Platform.isAndroid
            ? await _saveAgreementToDownloads(
              tempFile: tempFile,
              fileName: fileName,
            )
            : await _copyAgreementToDirectory(
              sourceFile: tempFile,
              directory: await _resolveAgreementDocumentsDirectory(),
              fileName: fileName,
            );

    _showSnack(
      Platform.isIOS
          ? 'Agreement saved to Files in the Agreements folder.'
          : 'Agreement downloaded to your Downloads folder.',
      isError: false,
    );
    await OpenFilex.open(savedFile.path);
  }

  Future<void> _downloadHtmlAgreementAsPdf() async {
    final htmlContent = widget.content?.trim() ?? '';
    if (htmlContent.isEmpty) {
      throw Exception('Agreement content is not available.');
    }

    final fileName = _sanitizeFileName(widget.agreementName, '.pdf');
    final tempFile = await _generateAgreementPdfFile(
      directory: await _resolveAgreementTempDirectory(),
      fileName: fileName,
    );

    final savedFile =
        Platform.isAndroid
            ? await _saveAgreementToDownloads(
              tempFile: tempFile,
              fileName: fileName,
            )
            : await _copyAgreementToDirectory(
              sourceFile: tempFile,
              directory: await _resolveAgreementDocumentsDirectory(),
              fileName: fileName,
            );

    _showSnack(
      Platform.isIOS
          ? 'Agreement saved to Files in the Agreements folder.'
          : 'Agreement downloaded to your Downloads folder.',
      isError: false,
    );
    await OpenFilex.open(savedFile.path);
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

  String _extractFileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final segments = uri?.pathSegments ?? const <String>[];
    if (segments.isNotEmpty && segments.last.trim().isNotEmpty) {
      return segments.last;
    }

    return 'agreement.pdf';
  }

  Future<File> _downloadAgreementPdfToFile({
    required String sourceUrl,
    required Directory directory,
    required String fileName,
  }) async {
    await directory.create(recursive: true);
    final filePath = path.join(directory.path, fileName);
    final file = File(filePath);

    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(sourceUrl));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Could not download agreement PDF.');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes, flush: true);
    } finally {
      httpClient.close(force: true);
    }

    if (!await file.exists()) {
      throw Exception('Downloaded agreement PDF could not be found.');
    }

    return file;
  }

  Future<File> _generateAgreementPdfFile({
    required Directory directory,
    required String fileName,
    Uint8List? signatureBytes,
  }) async {
    await directory.create(recursive: true);
    final filePath = path.join(directory.path, fileName);
    final savedPath = await WebcontentConverter.contentToPDF(
      content: _buildPdfHtmlDocument(signatureBytes: signatureBytes),
      savedPath: filePath,
      format: PaperFormat.a4,
      margins: PdfMargins.px(top: 0, bottom: 0, right: 0, left: 0),
    );

    if (savedPath == null || savedPath.isEmpty) {
      throw Exception('Could not generate agreement PDF.');
    }

    final file = File(savedPath);
    if (!await file.exists()) {
      throw Exception('Generated agreement PDF could not be found.');
    }

    return file;
  }

  Future<Uint8List> _buildSignedAgreementPdf({
    required String sourcePdfFilePath,
    required List<PolicyPdfAnnotation> annotations,
  }) async {
    final sourceFile = File(sourcePdfFilePath);
    if (!await sourceFile.exists()) {
      throw Exception('Unable to load the source agreement PDF.');
    }

    final sourcePdfBytes = await sourceFile.readAsBytes();
    if (sourcePdfBytes.isEmpty) {
      throw Exception('Unable to load the source agreement PDF.');
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

              if (annotation.isText &&
                  (annotation.text ?? '').trim().isNotEmpty) {
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

  Future<File> _getOrCreatePreviewPdf() async {
    final inMemoryPreview = _previewPdfFile;
    if (inMemoryPreview != null && await inMemoryPreview.exists()) {
      return inMemoryPreview;
    }

    final previewDirectory = await _resolveAgreementTempDirectory();
    final cachedPreviewFile = File(
      path.join(previewDirectory.path, _previewFileName),
    );
    if (await cachedPreviewFile.exists()) {
      _previewPdfFile = cachedPreviewFile;
      return cachedPreviewFile;
    }

    final previewFile =
        _hasPdfDocument
            ? await _downloadAgreementPdfToFile(
              sourceUrl: widget.documentUrl!,
              directory: previewDirectory,
              fileName: _previewFileName,
            )
            : await _generateAgreementPdfFile(
              directory: previewDirectory,
              fileName: _previewFileName,
            );

    _previewPdfFile = previewFile;
    return previewFile;
  }

  String get _previewFileName {
    final sourceFingerprint =
        _hasPdfDocument ? widget.documentUrl!.trim() : _buildPdfHtmlDocument();
    final previewHash = _stableHash(sourceFingerprint);
    return 'Agreement_preview_${widget.agreementId}_${_sanitizeFileName(widget.agreementName, '')}_$previewHash.pdf';
  }

  String _stableHash(String value) {
    const int fnvOffsetBasis = 0x811C9DC5;
    const int fnvPrime = 0x01000193;

    var hash = fnvOffsetBasis;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<File> _saveAgreementToDownloads({
    required File tempFile,
    required String fileName,
  }) async {
    final result = await _downloadsChannel.invokeMethod<Map<dynamic, dynamic>>(
      'saveFileToDownloads',
      <String, dynamic>{
        'sourcePath': tempFile.path,
        'fileName': fileName,
        'mimeType': 'application/pdf',
        'subdirectory': 'Agreements',
      },
    );

    if (result == null) {
      throw Exception('Could not save agreement to Downloads.');
    }

    final isSuccess = result['success'] == true;
    if (!isSuccess) {
      throw Exception(
        (result['error'] as String?) ??
            'Could not save agreement to Downloads.',
      );
    }

    final savedPath = result['path'] as String?;
    if (savedPath != null && savedPath.isNotEmpty) {
      return File(savedPath);
    }

    return tempFile;
  }

  Future<File> _copyAgreementToDirectory({
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

  Future<Directory> _resolveAgreementTempDirectory() async {
    final tempDirectory = await getTemporaryDirectory();
    return Directory(path.join(tempDirectory.path, 'Agreements'));
  }

  Future<Directory> _resolveAgreementDocumentsDirectory() async {
    if (Platform.isIOS) {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return Directory(path.join(documentsDirectory.path, 'Agreements'));
    }

    final externalDirectory = await getExternalStorageDirectory();
    if (externalDirectory != null) {
      return Directory(path.join(externalDirectory.path, 'Agreements'));
    }

    return Directory(
      path.join((await getApplicationDocumentsDirectory()).path, 'Agreements'),
    );
  }

  String _sanitizeFileName(String rawName, String extension) {
    final normalizedName =
        rawName.trim().isEmpty ? 'agreement' : rawName.trim();
    final sanitized = normalizedName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return sanitized.endsWith(extension) ? sanitized : '$sanitized$extension';
  }

  String _buildPdfHtmlDocument({Uint8List? signatureBytes}) {
    final htmlContent = widget.content?.trim() ?? '';
    final effectiveSignatureTag = _resolveSignatureTag(signatureBytes);

    final contentWithSignature =
        _usesLegacyHtmlPreview
            ? _showsLegacySignaturePlaceholder
            ? htmlContent.replaceFirst(
              _legacySignaturePlaceholderPattern,
              effectiveSignatureTag.isEmpty
                  ? ''
                  : '<div style="margin-bottom:16px;">$effectiveSignatureTag</div>',
            )
            : htmlContent
            : _showsLegacySignaturePlaceholder
            ? htmlContent.replaceFirst(
              _legacySignaturePlaceholderPattern,
              effectiveSignatureTag.isEmpty
                  ? ''
                  : '<div style="margin-bottom:16px;">$effectiveSignatureTag</div>',
            )
            : htmlContent.contains('[Candidate Signature]')
            ? htmlContent.replaceAll('[Candidate Signature]', effectiveSignatureTag)
            : '$htmlContent${effectiveSignatureTag.isEmpty ? '' : '<div style="margin-top:16px;">$effectiveSignatureTag</div>'}';

    final normalized = _wrapHtmlDocument(contentWithSignature);
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
      color: #212121 !important;
      width: 100% !important;
      height: auto !important;
      overflow: visible !important;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      font-size: 14px;
      line-height: 1.6;
      -webkit-text-size-adjust: 100% !important;
    }

    [style*="position: fixed"],
    [style*="position:fixed"],
    [style*="position: sticky"],
    [style*="position:sticky"],
    [style*="overflow: hidden"],
    [style*="overflow:hidden"] {
      position: static !important;
      overflow: visible !important;
      height: auto !important;
      max-height: none !important;
    }

    img, svg, canvas {
      max-width: 100% !important;
      height: auto !important;
      display: block;
    }

    table {
      width: 100% !important;
      border-collapse: collapse !important;
      margin: 12px 0 !important;
    }

    table, thead, tbody, tr, td, th {
      page-break-inside: avoid !important;
      break-inside: avoid !important;
    }

    th, td {
      border: 1px solid #E0E0E0 !important;
      padding: 8px !important;
      text-align: left !important;
      vertical-align: top !important;
      color: #212121 !important;
    }

    th {
      background: #F2F2F7 !important;
      font-weight: 600 !important;
    }
  </style>
</head>''');

    return withHeadStyle.replaceFirst(
      '<body>',
      '<body style="background:#ffffff !important; margin:0; padding:0; height:auto !important; overflow:visible !important;">',
    );
  }

  String _wrapHtmlDocument(String rawHtml) {
    return rawHtml.contains('<!DOCTYPE html>')
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
  }

  Widget _buildPdfViewer() {
    if (_isPreparingPreview) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_previewError != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _previewError!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(color: AppColors.textPrimary),
              ),
              AppSpacing.vLg,
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isPreparingPreview = true;
                    _previewError = null;
                  });
                  _preparePreviewPdf();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final previewFile = _previewPdfFile;
    if (previewFile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SfPdfViewer.file(
          previewFile,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
          enableTextSelection: false,
        ),
      ),
    );
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isError ? ErrorMessageMapper.toUserFriendlyMessage(message) : message,
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showPermissionDeniedDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Storage Permission Needed'),
          content: const Text(
            'Allow storage access to save the agreement PDF to your device.',
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

  Future<void> _submitAgreementConsent(BuildContext context) async {
    if (_usesLegacyHtmlPreview) {
      await _submitLegacyHtmlAgreementConsent(context);
      return;
    }

    if (_previewPdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agreement PDF is not available yet.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_pdfEditorController.hasSignatureAnnotations) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one signature'),
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
      final signedPdfFile = File(
        '${tempDir.path}/signed_agreement_${widget.agreementId}_$timestamp.pdf',
      );
      final signedPdfBytes = await _buildSignedAgreementPdf(
        sourcePdfFilePath: _previewPdfFile!.path,
        annotations: _pdfEditorController.annotations,
      );
      await signedPdfFile.writeAsBytes(signedPdfBytes, flush: true);
      if (!mounted) return;

      agreementBloc.add(
        SubmitAgreementConsent(
          agreementId: widget.agreementId,
          agreementAcknowledged: _isAgreed,
          signedPdfFilePath: signedPdfFile.path,
        ),
      );

      Future.delayed(const Duration(seconds: 5), () async {
        try {
          if (await signedPdfFile.exists()) {
            await signedPdfFile.delete();
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

  Future<void> _submitLegacyHtmlAgreementConsent(BuildContext context) async {
    if (!_legacyCanSubmitWithoutSignature && !_hasLegacySignature) {
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
      final signedPdfFile = await _generateAgreementPdfFile(
        directory: tempDir,
        fileName: 'signed_agreement_${widget.agreementId}_$timestamp.pdf',
        signatureBytes: _legacySignatureBytes,
      );
      if (!mounted) return;

      agreementBloc.add(
        SubmitAgreementConsent(
          agreementId: widget.agreementId,
          agreementAcknowledged: _isAgreed,
          signedPdfFilePath: signedPdfFile.path,
        ),
      );

      Future.delayed(const Duration(seconds: 5), () async {
        try {
          if (await signedPdfFile.exists()) {
            await signedPdfFile.delete();
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

  String _resolveSignatureTag(Uint8List? signatureBytes) {
    if (signatureBytes != null && signatureBytes.isNotEmpty) {
      final encoded = base64Encode(signatureBytes);
      return '<img src="data:image/png;base64,$encoded" alt="Candidate Signature" style="width:100px;height:70px;object-fit:contain;" />';
    }

    final signatureUrl = widget.signatureUrl?.trim() ?? '';
    if (signatureUrl.isNotEmpty) {
      return '<img src="$signatureUrl" alt="Candidate Signature" style="width:100px;height:70px;object-fit:contain;" />';
    }

    return '';
  }
}
