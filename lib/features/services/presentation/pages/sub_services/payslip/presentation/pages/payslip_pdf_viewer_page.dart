import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  late final WebViewController _webViewController;
  bool _isPageLoading = true;
  late final String _htmlDocument;
  late final String _pdfHtmlDocument;

  String get _htmlContent => widget.payslip.template.trim();

  @override
  void initState() {
    super.initState();
    _htmlDocument = _buildHtmlDocument(_htmlContent);
    _pdfHtmlDocument = _buildPdfHtmlDocument(_htmlContent);
    _webViewController =
    WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isPageLoading = false;
              });
            }
          },
        ),
      );

    if (_htmlContent.isNotEmpty) {
      _webViewController.loadRequest(
        Uri.dataFromString(
          _htmlDocument,
          mimeType: 'text/html',
          encoding: utf8,
        ),
      );
    } else
    {
      _isPageLoading = false;
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
      final directory = await _resolveGenerationDirectory();
      await directory.create(recursive: true);
      final filePath = path.join(directory.path, fileName);
      final savedPath = await WebcontentConverter.contentToPDF(
        content: _pdfHtmlDocument,
        savedPath: filePath,
        format: PaperFormat.a4,
        margins: PdfMargins.px(top: 16, bottom: 16, right: 16, left: 16),
      );
      if (savedPath == null || savedPath.isEmpty) {
        throw Exception('Could not generate payslip PDF.');
      }
      final file = File(savedPath);
      if (!await file.exists()) {
        throw Exception('Downloaded file could not be found.');
      }

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

  String _buildHtmlDocument(String rawHtml) {
    final normalized = _wrapHtmlDocument(rawHtml);
    final withHeadStyle = normalized.replaceFirst('</head>', '''
  <base href="https://app.collectivwork.com/">
  <style>
    * {
      box-sizing: border-box;
    }

    html, body {
      margin: 0;
      padding: 0;
      background: #ffffff !important;
      color: #111111;
      min-height: 100%;
      width: 100%;
      overflow-x: hidden;
    }

    img {
      max-width: 100%;
      height: auto;
      display: block;
    }

    .container {
      background: #ffffff !important;
      min-height: 100vh;
      margin: 0 auto;
    }
  </style>
</head>''');

    return withHeadStyle.replaceFirst(
      '<body>',
      '<body style="background:#ffffff !important; margin:0; padding:0;">',
    );
  }

  String _buildPdfHtmlDocument(String rawHtml) {
    final normalized = _wrapHtmlDocument(rawHtml);
    final withHeadStyle = normalized.replaceFirst('</head>', '''
  <base href="https://app.collectivwork.com/">
  <style>
    @page {
      size: A4;
      margin: 12mm;
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
          : Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.white,
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
                  child: WebViewWidget(
                    controller: _webViewController,
                  ),
                ),
              ),
            ),
          ),
          if (_isPageLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
