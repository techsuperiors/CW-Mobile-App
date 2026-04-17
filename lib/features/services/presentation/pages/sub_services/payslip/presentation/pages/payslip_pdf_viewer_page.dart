import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webcontent_converter/webcontent_converter.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../domain/models/payslip_model.dart';

/// Payslip preview page with HTML rendering and PDF download support.
class PayslipPdfViewerPage extends StatefulWidget {
  final PayslipModel payslip;

  const PayslipPdfViewerPage({super.key, required this.payslip});

  @override
  State<PayslipPdfViewerPage> createState() => _PayslipPdfViewerPageState();
}

class _PayslipPdfViewerPageState extends State<PayslipPdfViewerPage> {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'collectivwork/downloads',
  );
  bool _isDownloading = false;
  late final String _pdfHtmlDocument;
  File? _previewPdfFile;
  bool _isPreparingPreview = true;
  String? _previewError;

  String get _htmlContent => widget.payslip.template.trim();

  @override
  void initState() {
    super.initState();
    _pdfHtmlDocument = _buildPdfHtmlDocument(_htmlContent);
    _preparePreviewPdf();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _preparePreviewPdf() async {
    if (_htmlContent.isEmpty) {
      if (mounted) {
        setState(() {
          _isPreparingPreview = false;
          _previewError = null;
        });
      }
      return;
    }

    try {
      final file = await _getOrCreatePreviewPdf();

      if (!mounted) return;
      setState(() {
        _previewPdfFile = file;
        _previewError = null;
        _isPreparingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = ErrorMessageMapper.toUserFriendlyMessage(e.toString());
        _isPreparingPreview = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_htmlContent.isEmpty) {
      _showSnack(
        'Payslip template is not available yet.',
        isError: true,
      );
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

      final fileName =
          'Payslip_${_sanitizeFileName(widget.payslip.displayName, '.pdf')}';
      final file = await _getOrCreateDownloadFile(fileName);

      if (Platform.isAndroid) {
        await _saveToDownloads(file: file, fileName: fileName);
      }

      _showSnack(
        Platform.isIOS
            ? 'Payslip saved to Files in the Payslips folder.'
            : 'Payslip downloaded to your Downloads folder.',
        isError: false,
      );
      await OpenFilex.open(file.path);
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
      final sdk = await _downloadsChannel.invokeMethod<int>('getAndroidSdkInt');
      return sdk;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToDownloads({
    required File file,
    required String fileName,
  }) async {
    final result = await _downloadsChannel.invokeMethod<Map<dynamic, dynamic>>(
      'saveFileToDownloads',
      <String, dynamic>{
        'sourcePath': file.path,
        'fileName': fileName,
        'mimeType': 'application/pdf',
        'subdirectory': 'Payslips',
      },
    );

    if (result == null) {
      throw Exception('Could not save payslip to Downloads.');
    }

    final isSuccess = result['success'] == true;
    if (!isSuccess) {
      throw Exception(
        (result['error'] as String?) ?? 'Could not save payslip to Downloads.',
      );
    }
  }

  Future<Directory> _resolveGenerationDirectory() async {
    if (Platform.isIOS) {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return Directory(path.join(documentsDirectory.path, 'Payslips'));
    }

    final externalDirectory = await getExternalStorageDirectory();
    if (externalDirectory != null) {
      return Directory(path.join(externalDirectory.path, 'Payslips'));
    }

    return Directory(
      path.join((await getApplicationDocumentsDirectory()).path, 'Payslips'),
    );
  }

  Future<Directory> _resolvePreviewDirectory() async {
    final temporaryDirectory = await getTemporaryDirectory();
    return Directory(path.join(temporaryDirectory.path, 'Payslips'));
  }

  Future<File> _getOrCreatePreviewPdf() async {
    final inMemoryPreview = _previewPdfFile;
    if (inMemoryPreview != null && await inMemoryPreview.exists()) {
      return inMemoryPreview;
    }

    final previewDirectory = await _resolvePreviewDirectory();
    final cachedPreviewFile = File(
      path.join(previewDirectory.path, _previewFileName),
    );
    if (await cachedPreviewFile.exists()) {
      _previewPdfFile = cachedPreviewFile;
      return cachedPreviewFile;
    }

    final generatedFile = await _generatePdfFile(
      directory: previewDirectory,
      fileName: _previewFileName,
    );
    _previewPdfFile = generatedFile;
    return generatedFile;
  }

  String get _previewFileName {
    final normalizedMonth =
        widget.payslip.payrollMonth.trim().isEmpty
            ? 'unknown_month'
            : widget.payslip.payrollMonth.trim();
    final templateHash = _stableTemplateHash(_htmlContent);
    return 'Payslip_preview_${widget.payslip.id}_${_sanitizeFileName(normalizedMonth, '')}_$templateHash.pdf';
  }

  String _stableTemplateHash(String value) {
    const int fnvOffsetBasis = 0x811C9DC5;
    const int fnvPrime = 0x01000193;

    var hash = fnvOffsetBasis;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<File> _getOrCreateDownloadFile(String fileName) async {
    final previewFile = _previewPdfFile;
    if (previewFile != null && await previewFile.exists()) {
      if (Platform.isIOS) {
        return _copyPdfToDirectory(
          sourceFile: previewFile,
          directory: await _resolveGenerationDirectory(),
          fileName: fileName,
        );
      }
      return previewFile;
    }

    final cachedPreviewFile = await _getOrCreatePreviewPdf();
    if (Platform.isIOS) {
      return _copyPdfToDirectory(
        sourceFile: cachedPreviewFile,
        directory: await _resolveGenerationDirectory(),
        fileName: fileName,
      );
    }

    return cachedPreviewFile;
  }

  Future<File> _copyPdfToDirectory({
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

  Future<File> _generatePdfFile({
    required Directory directory,
    required String fileName,
  }) async {
    await directory.create(recursive: true);
    final filePath = path.join(directory.path, fileName);
    final savedPath = await WebcontentConverter.contentToPDF(
      content: _pdfHtmlDocument,
      savedPath: filePath,
      format: PaperFormat.a4,
      // Keep converter margins at zero and control printable space via CSS.
      // Applying margins in both places can push an otherwise single-page
      // payslip onto a second page on mobile PDF generation.
      margins: PdfMargins.px(top: 0, bottom: 0, right: 0, left: 0),
    );
    if (savedPath == null || savedPath.isEmpty) {
      throw Exception('Could not generate payslip PDF.');
    }

    final file = File(savedPath);
    if (!await file.exists()) {
      throw Exception('Generated payslip PDF could not be found.');
    }

    return file;
  }

  String _sanitizeFileName(String rawName, String extension) {
    final normalizedName =
        rawName.trim().isEmpty ? 'payslip' : rawName.trim();
    final sanitized = normalizedName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return sanitized.endsWith(extension) ? sanitized : '$sanitized$extension';
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
            'Allow storage access to save the payslip PDF to your device.',
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

  String _buildPdfHtmlDocument(String rawHtml) {
    final normalized = _wrapHtmlDocument(rawHtml);
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

    body {
      zoom: 0.97;
      -webkit-text-size-adjust: 100% !important;
    }

    body > * {
      width: calc(100% / 0.97) !important;
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leadingWidth: 110,

        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: screenWidth * 0.048,
              ),
              Flexible(
                child: Text(
                  'Back',
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

        title: Text(
          widget.payslip.displayName,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
            _isDownloading
                ? SizedBox(
              width: screenWidth * 0.05,
              height: screenWidth * 0.05,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.textPrimary,
                ),
              ),
            )
                : Icon(
              Icons.download_rounded,
              color: AppColors.textPrimary,
              size: screenWidth * 0.058,
            ),
            onPressed: _isDownloading ? null : _downloadPdf,
          ),
        ],
      ),
      body:
      _htmlContent.isEmpty
          ? Center(
        child: Text(
          'Payslip template is not available yet.',
          style: AppTextStyles.bodyLarge(
            context,
          ).copyWith(color: AppColors.textPrimary),
        ),
      )
          : _buildPdfPreview(screenWidth),
    );
  }

  Widget _buildPdfPreview(double screenWidth) {
    if (_isPreparingPreview) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_previewError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
              const SizedBox(height: 16),
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
      padding: EdgeInsets.all(screenWidth * 0.03),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SfPdfViewer.file(
            previewFile,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            enableTextSelection: false,
          ),
        ),
      ),
    );
  }
}
