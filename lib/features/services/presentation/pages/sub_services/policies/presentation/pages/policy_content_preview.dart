import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/policy_model.dart';

class PolicyContentPreviewPage extends StatefulWidget {
  final PolicyModel policy;

  const PolicyContentPreviewPage({required this.policy});

  @override
  State<PolicyContentPreviewPage> createState() =>
      PolicyContentPreviewPageState();
}

class PolicyContentPreviewPageState extends State<PolicyContentPreviewPage> {
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

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isFile =
        widget.policy.isFile &&
        widget.policy.fileUrl != null &&
        widget.policy.fileUrl!.isNotEmpty;

    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        forceMaterialTransparency: true,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: sw * 0.048, // 4.8% of screen width
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
        leadingWidth: 110,
        title: Text(
          widget.policy.name,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: sw * 0.002),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
}
