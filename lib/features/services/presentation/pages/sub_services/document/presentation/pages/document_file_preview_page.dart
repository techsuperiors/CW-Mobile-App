import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../data/datasources/document_remote_datasource.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/models/document_file_model.dart';
import '../../domain/usecases/delete_document_usecase.dart';

class DocumentFilePreviewPage extends StatefulWidget {
  final DocumentFileModel file;

  const DocumentFilePreviewPage({super.key, required this.file});

  @override
  State<DocumentFilePreviewPage> createState() => _DocumentFilePreviewPageState();
}

class _DocumentFilePreviewPageState extends State<DocumentFilePreviewPage> {
  WebViewController? _webViewController;
  late final DeleteDocumentUseCase _deleteDocumentUseCase;

  bool _isDownloading = false;
  bool _isSharing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = DocumentRemoteDataSourceImpl(apiClient);
    final repository = DocumentRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    _deleteDocumentUseCase = DeleteDocumentUseCase(repository);

    if (_usesWebView) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(widget.file.downloadUrl!));
    }

    if (_isOfficeDocumentType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openOfficeDocument(popAfterOpen: true);
      });
    }
  }

  bool get _usesWebView =>
      widget.file.hasPreviewUrl &&
      !_isOfficeDocumentType &&
      !widget.file.isPdfType &&
      !widget.file.isImageType;

  bool get _isOfficeDocumentType {
    switch (widget.file.fileType.toLowerCase()) {
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
        return true;
      default:
        return false;
    }
  }

  bool get _canDelete {
    if (widget.file.isAgreementItem) return false;
    final directoryId = int.tryParse(widget.file.folderId ?? '');
    final documentId = int.tryParse(widget.file.id);
    return directoryId != null && documentId != null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isBusy = _isDownloading || _isSharing || _isDeleting;

    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 110,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: isBusy ? null : () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: screenWidth * 0.048,
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
        title: Text(
          widget.file.name,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isBusy)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.more_vert,
                size: screenWidth * 0.053,
                color: AppColors.attendanceTeal,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showActionsMenu(context),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  void _showActionsMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.02,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('Download', style: AppTextStyles.bodyLarge(context)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _downloadFile();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.share,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('Share', style: AppTextStyles.bodyLarge(context)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareFile();
                },
              ),
              if (_canDelete)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Delete',
                    style: AppTextStyles.bodyLarge(
                      context,
                    ).copyWith(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _deleteFile();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadFile() async {
    if (_isDownloading) return;
    if (!widget.file.hasPreviewUrl) {
      _showSnack('No downloadable file available for ${widget.file.name}');
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final allowed = await _ensureDownloadPermission();
      if (!allowed) {
        _showSnack('Storage permission is required to save this file.');
        return;
      }

      final directory = await _resolveDownloadDirectory();
      final file = await _downloadToFile(directory: directory);
      _showSnack('Saved to ${file.path}', isError: false);
    } catch (e) {
      _showSnack('Unable to download file: $e');
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _shareFile() async {
    if (_isSharing) return;
    if (!widget.file.hasPreviewUrl) {
      _showSnack('No file available to share.');
      return;
    }

    setState(() => _isSharing = true);
    try {
      final tempDirectory = await getTemporaryDirectory();
      final file = await _downloadToFile(directory: tempDirectory);
      await Share.shareXFiles([XFile(file.path)], text: widget.file.name);
    } catch (e) {
      _showSnack('Unable to share file: $e');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _openOfficeDocument({bool popAfterOpen = false}) async {
    if (_isDownloading) return;
    if (!widget.file.hasPreviewUrl) {
      _showSnack('No file available to open.');
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final tempDirectory = await getTemporaryDirectory();
      final file = await _downloadToFile(directory: tempDirectory);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        _showSnack(result.message.isEmpty
            ? 'No app available to open this file.'
            : result.message);
      } else if (popAfterOpen && mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      _showSnack('Unable to open file: $e');
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _deleteFile() async {
    if (_isDeleting || !_canDelete) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete File'),
          content: Text('Delete "${widget.file.name}" from this folder?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final directoryId = int.tryParse(widget.file.folderId ?? '');
    final documentId = int.tryParse(widget.file.id);
    if (directoryId == null || documentId == null) {
      _showSnack('This file cannot be deleted right now.');
      return;
    }

    setState(() => _isDeleting = true);
    try {
      final result = await _deleteDocumentUseCase(
        directoryId: directoryId,
        documentId: documentId,
      );
      result.fold(
        (failure) => _showSnack(failure.message),
        (_) {
          _showSnack('File deleted successfully.', isError: false);
          Navigator.of(context).pop(true);
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<File> _downloadToFile({required Directory directory}) async {
    await directory.create(recursive: true);

    final extension = _resolveExtension();
    final fileName = _sanitizeFileName(widget.file.name, extension);
    final filePath = path.join(directory.path, fileName);

    final dio = Dio();
    final response = await dio.get<List<int>>(
      widget.file.downloadUrl!,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = response.data;
    if (bytes == null) {
      throw Exception('Empty file response');
    }

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<bool> _ensureDownloadPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) {
      return true;
    }

    final storageResult = await Permission.storage.request();
    if (storageResult.isGranted) {
      return true;
    }

    final manageStatus = await Permission.manageExternalStorage.status;
    if (manageStatus.isGranted) {
      return true;
    }

    final manageResult = await Permission.manageExternalStorage.request();
    return manageResult.isGranted;
  }

  Future<Directory> _resolveDownloadDirectory() async {
    if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }

    final publicDownloadDir = Directory('/storage/emulated/0/Download');
    if (await publicDownloadDir.exists()) {
      return publicDownloadDir;
    }

    return (await getExternalStorageDirectory()) ??
        await getApplicationDocumentsDirectory();
  }

  String _resolveExtension() {
    final urlExtension = widget.file.downloadUrl == null
        ? ''
        : path.extension(Uri.parse(widget.file.downloadUrl!).path);

    if (urlExtension.isNotEmpty) {
      return urlExtension;
    }

    final existingNameExtension = path.extension(widget.file.name);
    if (existingNameExtension.isNotEmpty) {
      return existingNameExtension;
    }

    switch (widget.file.fileType.toLowerCase()) {
      case 'pdf':
        return '.pdf';
      case 'jpg':
      case 'jpeg':
        return '.jpg';
      case 'png':
        return '.png';
      case 'doc':
        return '.doc';
      case 'docx':
        return '.docx';
      case 'xls':
        return '.xls';
      case 'xlsx':
        return '.xlsx';
      default:
        return '';
    }
  }

  String _sanitizeFileName(String rawName, String extension) {
    final cleanBase = rawName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    final baseWithoutExtension = extension.isNotEmpty &&
            cleanBase.toLowerCase().endsWith(extension.toLowerCase())
        ? cleanBase.substring(0, cleanBase.length - extension.length)
        : cleanBase;

    final fallback = baseWithoutExtension.isEmpty ? 'document_file' : baseWithoutExtension;
    return '$fallback$extension';
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!widget.file.hasPreviewUrl) {
      return _buildMessage(
        context,
        'No preview available for this file.',
        Icons.insert_drive_file_outlined,
      );
    }

    if (widget.file.isPdfType) {
      return SfPdfViewer.network(widget.file.downloadUrl!);
    }

    if (widget.file.isImageType) {
      return Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: widget.file.downloadUrl!,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) => _buildMessage(
              context,
              'Unable to load image preview.',
              Icons.broken_image_outlined,
            ),
          ),
        ),
      );
    }

    if (_isOfficeDocumentType) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }

    return _buildMessage(
      context,
      'Preview is not supported for this file type.',
      Icons.preview_outlined,
    );
  }

  Widget _buildMessage(BuildContext context, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
