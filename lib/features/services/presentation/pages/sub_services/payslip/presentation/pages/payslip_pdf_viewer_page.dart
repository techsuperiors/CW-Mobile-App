import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webcontent_converter/webcontent_converter.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/payslip_model.dart';

/// Payslip preview page with HTML rendering and PDF download support.
class PayslipPdfViewerPage extends StatefulWidget {
  final PayslipModel payslip;

  const PayslipPdfViewerPage({super.key, required this.payslip});

  @override
  State<PayslipPdfViewerPage> createState() => _PayslipPdfViewerPageState();
}

class _PayslipPdfViewerPageState extends State<PayslipPdfViewerPage> {
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
    } else {
      _isPageLoading = false;
    }
  }

  Future<void> _downloadPdf() async {
    if (_htmlContent.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payslip template is not available yet.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final fileName =
          'Payslip_${widget.payslip.displayName.replaceAll(' ', '_')}.pdf';
      final directory = await _resolveDownloadDirectory();
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payslip Successfully downloaded'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<Directory> _resolveDownloadDirectory() async {
    if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }

    final scopedDownloadDirs = await getExternalStorageDirectories(
      type: StorageDirectory.downloads,
    );
    if (scopedDownloadDirs != null && scopedDownloadDirs.isNotEmpty) {
      return scopedDownloadDirs.first;
    }

    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      return externalDir;
    }

    return getApplicationDocumentsDirectory();
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
          style: AppTextStyles.bodyLarge(
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
