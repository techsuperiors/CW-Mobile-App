import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webcontent_converter/webcontent_converter.dart';

import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
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

  const CommonAgreementDetailPage({
    super.key,
    required this.agreementId,
    required this.agreementName,
    required this.status,
    this.content,
    this.signatureUrl,
    this.documentUrl,
    this.showDocumentsOnly = false,
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
  Uint8List? _signatureBytes;
  bool _isDownloading = false;

  bool get _hasPdfDocument =>
      widget.documentUrl != null && widget.documentUrl!.isNotEmpty;
  bool get _hasHtmlContent =>
      widget.content != null && widget.content!.trim().isNotEmpty;
  bool get _isSigned => widget.status.toLowerCase() == 'signed';
  bool get _canDownloadSignedDocument =>
      _isSigned && (_hasPdfDocument || _hasHtmlContent);

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
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.download_rounded),
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
          _hasPdfDocument
              ? _buildPdfLayout(context)
              : SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAgreementContentCard(),
                    if (!widget.showDocumentsOnly && !_isSigned)
                      _buildConsentSection(context),
                  ],
                ),
              ),
    );
  }

  Widget _buildPdfLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildPdfViewer()),
        if (!widget.showDocumentsOnly && !_isSigned)
          SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: _buildConsentSection(context),
          ),
      ],
    );
  }

  Widget _buildConsentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              _signatureBytes != null ? 'Change Signature' : 'Add Signature',
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

            return SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    (_isAgreed && _signatureBytes != null && !isSubmitting)
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
    );
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

    final fileName = _sanitizeFileName(widget.agreementName, '.pdf');
    final directory = await _resolveGenerationDirectory();
    await directory.create(recursive: true);
    final file = File(path.join(directory.path, fileName));

    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(documentUrl));
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

    if (Platform.isAndroid) {
      await _saveToDownloads(
        file: file,
        fileName: fileName,
        subdirectory: 'Agreements',
      );
    }

    _showSnack(
      Platform.isIOS
          ? 'Agreement saved to Files in the Agreements folder.'
          : 'Agreement downloaded to your Downloads folder.',
      isError: false,
    );
    await OpenFilex.open(file.path);
  }

  Future<void> _downloadHtmlAgreementAsPdf() async {
    final htmlContent = widget.content?.trim() ?? '';
    if (htmlContent.isEmpty) {
      throw Exception('Agreement content is not available.');
    }

    final fileName = _sanitizeFileName(widget.agreementName, '.pdf');
    final directory = await _resolveGenerationDirectory();
    await directory.create(recursive: true);
    final filePath = path.join(directory.path, fileName);

    final savedPath = await WebcontentConverter.contentToPDF(
      content: _buildPdfHtmlDocument(),
      savedPath: filePath,
      format: PaperFormat.a4,
      margins: PdfMargins.px(top: 16, bottom: 16, right: 16, left: 16),
    );

    if (savedPath == null || savedPath.isEmpty) {
      throw Exception('Could not generate agreement PDF.');
    }

    final file = File(savedPath);
    if (!await file.exists()) {
      throw Exception('Generated agreement PDF could not be found.');
    }

    if (Platform.isAndroid) {
      await _saveToDownloads(
        file: file,
        fileName: fileName,
        subdirectory: 'Agreements',
      );
    }

    _showSnack(
      Platform.isIOS
          ? 'Agreement saved to Files in the Agreements folder.'
          : 'Agreement downloaded to your Downloads folder.',
      isError: false,
    );
    await OpenFilex.open(file.path);
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

  Future<void> _saveToDownloads({
    required File file,
    required String fileName,
    required String subdirectory,
  }) async {
    final result = await _downloadsChannel.invokeMethod<Map<dynamic, dynamic>>(
      'saveFileToDownloads',
      <String, dynamic>{
        'sourcePath': file.path,
        'fileName': fileName,
        'mimeType': 'application/pdf',
        'subdirectory': subdirectory,
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
  }

  Future<Directory> _resolveGenerationDirectory() async {
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

  String _buildPdfHtmlDocument() {
    final htmlContent = widget.content?.trim() ?? '';
    final signatureTag =
        widget.signatureUrl != null && widget.signatureUrl!.isNotEmpty
            ? '<img src="${widget.signatureUrl!}" alt="Candidate Signature" style="width:100px;height:70px;object-fit:contain;" />'
            : '';

    final contentWithSignature =
        htmlContent.contains('[Candidate Signature]')
            ? htmlContent.replaceAll('[Candidate Signature]', signatureTag)
            : '$htmlContent${signatureTag.isEmpty ? '' : '<div style="margin-top:16px;">$signatureTag</div>'}';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <base href="https://app.collectivwork.com/">
  <style>
    @page { size: A4; margin: 12mm; }
    * {
      box-sizing: border-box;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }
    html, body {
      margin: 0;
      padding: 0;
      background: #ffffff;
      color: #111111;
      font-family: Arial, sans-serif;
    }
    img {
      max-width: 100%;
      height: auto;
      display: block;
    }
    .brand {
      margin-bottom: 24px;
      font-size: 24px;
      font-weight: 700;
    }
    .content {
      line-height: 1.6;
      font-size: 14px;
    }
    p { margin: 0 0 8px 0; }
  </style>
</head>
<body>
  <div class="brand">Collectivwork</div>
  <div class="content">$contentWithSignature</div>
</body>
</html>
''';
  }

  Widget _buildPdfViewer() {
    return Container(
      margin: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SfPdfViewer.network(
          widget.documentUrl!,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
          enableTextSelection: false,
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
