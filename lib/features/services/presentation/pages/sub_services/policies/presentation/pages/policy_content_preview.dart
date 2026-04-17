import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/policy_model.dart';

class PolicyContentPreviewPage extends StatefulWidget {
  final PolicyModel policy;

  const PolicyContentPreviewPage({super.key, required this.policy});

  @override
  State<PolicyContentPreviewPage> createState() =>
      PolicyContentPreviewPageState();
}

class PolicyContentPreviewPageState extends State<PolicyContentPreviewPage> {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'collectivwork/downloads',
  );
  late final WebViewController _webViewController;
  bool _isHtmlLoading = false;
  bool _isDownloading = false;

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
        actions: [
          if (_canDownload)
            IconButton(
              icon:
                  _isDownloading
                      ? SizedBox(
                        width: sw * 0.05,
                        height: sw * 0.05,
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
                        size: sw * 0.058,
                      ),
              onPressed: _isDownloading ? null : _downloadPdf,
            ),
        ],
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

  bool get _canDownload =>
      widget.policy.allowDownload &&
      widget.policy.isFile &&
      (widget.policy.fileUrl?.trim().isNotEmpty ?? false);

  Future<void> _downloadPdf() async {
    final fileUrl = widget.policy.fileUrl?.trim() ?? '';
    if (fileUrl.isEmpty) {
      _showSnack('Policy PDF is not available for download.', isError: true);
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

      final sourceFileName = _extractFileNameFromUrl(fileUrl);
      final fileName = _sanitizeFileName(
        sourceFileName.trim().isEmpty ? '${widget.policy.name}.pdf' : sourceFileName,
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
          _isDownloading = false;
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
    return 'policy.pdf';
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
