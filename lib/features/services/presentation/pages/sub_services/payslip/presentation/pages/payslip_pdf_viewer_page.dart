import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:native_screenshot_widget/native_screenshot_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  final NativeScreenshotController _screenshotController =
      NativeScreenshotController();
  Uint8List? _pdfBytes;

  String get _htmlContent => widget.payslip.template.trim();

  @override
  void initState() {
    super.initState();
    _htmlDocument = _buildHtmlDocument(_htmlContent);
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

  Future<Uint8List> _generatePdfBytes() async {
    if (_pdfBytes != null) {
      return _pdfBytes!;
    }

    final screenshotBytes = await _screenshotController.takeScreenshot();
    if (screenshotBytes == null || screenshotBytes.isEmpty) {
      throw Exception('Could not capture payslip preview.');
    }

    final document = pw.Document();
    final screenshotImage = pw.MemoryImage(screenshotBytes);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        build:
            (context) => pw.Center(
              child: pw.Image(screenshotImage, fit: pw.BoxFit.contain),
            ),
      ),
    );

    final pdfBytes = await document.save();

    return pdfBytes;
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
      final pdfBytes = await _generatePdfBytes();

      if (_pdfBytes == null && mounted) {
        setState(() {
          _pdfBytes = pdfBytes;
        });
      }

      final fileName =
          'Payslip_${widget.payslip.displayName.replaceAll(' ', '_')}.pdf';

      await Printing.layoutPdf(name: fileName, onLayout: (_) async => pdfBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Choose "Save as PDF" to download the payslip.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
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

  String _buildHtmlDocument(String rawHtml) {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leadingWidth: 150,

        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Row(
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
                      child: NativeScreenshot(
                        controller: _screenshotController,
                        child: Container(
                          color: Colors.white,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
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
                  ),
                  if (_isPageLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
    );
  }
}
