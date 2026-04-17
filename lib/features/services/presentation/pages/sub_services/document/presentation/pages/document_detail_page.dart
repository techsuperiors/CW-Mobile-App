import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/app_navigator.dart';
import '../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../employee_agreement/data/datasources/agreement_remote_datasource.dart';
import '../../../employee_agreement/data/repositories/agreement_repository_impl.dart';
import '../../../employee_agreement/domain/usecases/get_agreement_list_usecase.dart';
import '../../../employee_agreement/domain/usecases/submit_agreement_consent_usecase.dart';
import '../../../employee_agreement/domain/models/employee_agreement_model.dart';
import '../../../employee_agreement/presentation/bloc/agreement_bloc.dart';
import '../../../employee_agreement/presentation/pages/common_agreement_detail_page.dart';
import '../../../employee_agreement/presentation/widgets/employee_agreement_card.dart';
import '../../data/datasources/document_remote_datasource.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/models/document_file_model.dart';
import '../../domain/models/document_folder_model.dart';
import '../../domain/usecases/delete_document_usecase.dart';
import '../../domain/usecases/get_document_folder_files_usecase.dart';
import '../../domain/usecases/upload_document_file_usecase.dart';
import '../cubit/document_detail_cubit.dart';
import '../cubit/document_detail_state.dart';
import '../widgets/document_file_card.dart';
import 'document_file_preview_page.dart';

class DocumentDetailPage extends StatefulWidget {
  final DocumentFolderModel folder;
  final bool isShared;

  const DocumentDetailPage({
    super.key,
    required this.folder,
    this.isShared = false,
  });

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  late final DocumentDetailCubit _detailCubit;
  late final AgreementBloc _agreementBloc;
  late final DeleteDocumentUseCase _deleteDocumentUseCase;
  bool _isUploadingFile = false;
  bool _shouldRefreshParent = false;

  bool get _isEmployeeAgreementsFolder =>
      widget.folder.name.trim().toLowerCase() == 'employee agreements' ||
      widget.folder.name.trim().toLowerCase().contains('employee agree');

  @override
  void initState() {
    super.initState();
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: networkInfo,
      onTokenExpired: () {
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );
    final remoteDataSource = DocumentRemoteDataSourceImpl(apiClient);
    final repository = DocumentRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    _deleteDocumentUseCase = DeleteDocumentUseCase(repository);

    _detailCubit = DocumentDetailCubit(
      getDocumentFolderFilesUseCase: GetDocumentFolderFilesUseCase(repository),
      uploadDocumentFileUseCase: UploadDocumentFileUseCase(repository),
    )..loadFolder(widget.folder);

    final agreementRemoteDataSource = AgreementRemoteDataSourceImpl(apiClient);
    final agreementRepository = AgreementRepositoryImpl(
      remoteDataSource: agreementRemoteDataSource,
      networkInfo: networkInfo,
    );
    _agreementBloc = AgreementBloc(
      getAgreementListUseCase: GetAgreementListUseCase(agreementRepository),
      submitAgreementConsentUseCase: SubmitAgreementConsentUseCase(
        agreementRepository,
      ),
    );
  }

  @override
  void dispose() {
    _detailCubit.close();
    _agreementBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_shouldRefreshParent);
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _detailCubit),
          BlocProvider.value(value: _agreementBloc),
        ],
        child: ResponsiveScaffold(
          backgroundColor: AppColors.backgroundMedium,
          appBar: AppBar(
            forceMaterialTransparency: true,
            elevation: 0,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(_shouldRefreshParent),
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
            leadingWidth: 110,
            title: Text(
              widget.folder.name,
              style: AppTextStyles.heading4(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              if (!_isEmployeeAgreementsFolder)
                IconButton(
                  onPressed: _isUploadingFile ? null : _handleUploadFile,
                  icon:
                      _isUploadingFile
                          ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(Icons.add, color: AppColors.iconprofilecolor),
                ),
              AppSpacing.hSm,
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            onTap: NavigationHelper.getBottomNavHandler(context),
          ),
          body: BlocBuilder<DocumentDetailCubit, DocumentDetailState>(
            builder: (context, state) {
              if (state is DocumentDetailInitial ||
                  state is DocumentDetailLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is DocumentDetailError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        color: AppColors.error,
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _detailCubit.loadFolder(widget.folder),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final files = (state as DocumentDetailLoaded).files;
              if (_isEmployeeAgreementsFolder) {
                return _buildAgreementList(context, files);
              }

              return Column(
                children: [Expanded(child: _buildFileList(context, files))],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFileList(BuildContext context, List<DocumentFileModel> files) {
    final groupedFiles = _groupedFiles(files);
    final screenHeight = MediaQuery.of(context).size.height;

    if (groupedFiles.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noData,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.002,
        vertical: screenHeight * 0.01,
      ),
      itemCount: groupedFiles.length,

      itemBuilder: (context, index) {
        final category = groupedFiles.keys.elementAt(index);
        final categoryFiles = groupedFiles[category]!;

        return Container(
          margin: EdgeInsets.only(bottom: screenHeight * 0.018),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.022,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.042,
                  vertical: screenHeight * 0.01,
                ),
                child: Text(
                  _getCategoryTitle(category),
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ...categoryFiles.map(
                (file) => Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                  child: DocumentFileCard(
                    file: file,
                    onDownload: () => _handleDownload(file),
                    onTap: () => _handleFileTap(file),
                    onMoreTap: () => _showFileActions(file),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleUploadFile() async {
    if (_isUploadingFile) return;

    try {
      setState(() => _isUploadingFile = true);
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const [
          'png',
          'jpg',
          'jpeg',
          'pdf',
          'doc',
          'xlsx',
          'xls',
        ],
      );

      final selectedPath =
          result != null && result.files.isNotEmpty
              ? result.files.first.path
              : null;
      if (selectedPath == null || selectedPath.isEmpty) {
        return;
      }

      final error = await _detailCubit.uploadFile(
        folder: widget.folder,
        filePath: selectedPath,
      );
      if (!mounted) return;

      if (error == null) {
        _shouldRefreshParent = true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'File uploaded successfully.'),
          backgroundColor: error == null ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
    }
  }

  Widget _buildAgreementList(
    BuildContext context,
    List<DocumentFileModel> files,
  ) {
    final agreements = files.map(_toEmployeeAgreementModel).toList();
    final screenHeight = MediaQuery.of(context).size.height;

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.01,
        vertical: screenHeight * 0.01,
      ),
      itemCount: agreements.length,
      itemBuilder: (context, index) {
        final spacing =
            screenHeight < 600 ? 12.0 : (screenHeight < 700 ? 14.0 : 16.0);
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: EmployeeAgreementCard(agreement: agreements[index]),
        );
      },
    );
  }

  Map<String, List<DocumentFileModel>> _groupedFiles(
    List<DocumentFileModel> allFiles,
  ) {
    final grouped = <String, List<DocumentFileModel>>{};
    for (final file in allFiles) {
      final category = file.fileTypeCategory;
      grouped.putIfAbsent(category, () => <DocumentFileModel>[]).add(file);
    }
    return grouped;
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'pdf':
        return 'PDF';
      case 'document':
        return 'Document';
      case 'image':
        return 'JPG';
      default:
        return 'Other Files';
    }
  }

  bool _canDelete(DocumentFileModel file) {
    if (file.isAgreementItem) return false;
    final directoryId = int.tryParse(file.folderId ?? '');
    final documentId = int.tryParse(file.id);
    return directoryId != null && documentId != null;
  }

  void _showFileActions(DocumentFileModel file) {
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
                title: Text(
                  'Download',
                  style: AppTextStyles.bodyLarge(context),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleDownload(file);
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
                  _shareFile(file);
                },
              ),
              if (_canDelete(file))
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
                    _deleteFile(file);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDownload(DocumentFileModel file) async {
    if (!file.hasPreviewUrl) {
      _showSnack('No downloadable file available for ${file.name}');
      return;
    }

    try {
      final allowed = await _ensureDownloadPermission();
      if (!allowed) {
        _showSnack('Storage permission is required to save this file.');
        return;
      }

      final directory = await _resolveDownloadDirectory();
      final localFile = await _downloadToFile(file: file, directory: directory);
      _showSnack('Saved to ${localFile.path}', isError: false);
    } catch (e) {
      _showSnack('Unable to download file: $e');
    }
  }

  Future<void> _shareFile(DocumentFileModel file) async {
    if (!file.hasPreviewUrl) {
      _showSnack('No file available to share.');
      return;
    }

    try {
      final tempDirectory = await getTemporaryDirectory();
      final localFile = await _downloadToFile(
        file: file,
        directory: tempDirectory,
      );
      await Share.shareXFiles([XFile(localFile.path)], text: file.name);
    } catch (e) {
      _showSnack('Unable to share file: $e');
    }
  }

  Future<void> _deleteFile(DocumentFileModel file) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete File'),
          content: Text('Delete "${file.name}" from this folder?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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

    final directoryId = int.tryParse(file.folderId ?? '');
    final documentId = int.tryParse(file.id);
    if (directoryId == null || documentId == null) {
      _showSnack('This file cannot be deleted right now.');
      return;
    }

    final result = await _deleteDocumentUseCase(
      directoryId: directoryId,
      documentId: documentId,
    );
    result.fold((failure) => _showSnack(failure.message), (_) {
      _shouldRefreshParent = true;
      _showSnack('File deleted successfully.', isError: false);
      _detailCubit.loadFolder(widget.folder);
    });
  }

  Future<File> _downloadToFile({
    required DocumentFileModel file,
    required Directory directory,
  }) async {
    await directory.create(recursive: true);
    final extension = _resolveExtension(file);
    final fileName = _sanitizeFileName(file.name, extension);
    final localPath = path.join(directory.path, fileName);

    final response = await Dio().get<List<int>>(
      file.downloadUrl!,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw Exception('Empty file response');
    }

    final localFile = File(localPath);
    await localFile.writeAsBytes(bytes, flush: true);
    return localFile;
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

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  bool _isOfficeDocument(DocumentFileModel file) {
    switch (file.fileType.toLowerCase()) {
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
        return true;
      default:
        return false;
    }
  }

  Future<void> _openOfficeDocument(DocumentFileModel file) async {
    if (!file.hasPreviewUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file available to open'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    try {
      final tempDirectory = await getTemporaryDirectory();
      await tempDirectory.create(recursive: true);

      final extension = _resolveExtension(file);
      final fileName = _sanitizeFileName(file.name, extension);
      final localPath = path.join(tempDirectory.path, fileName);

      final response = await Dio().get<List<int>>(
        file.downloadUrl!,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) {
        throw Exception('Empty file response');
      }

      final localFile = File(localPath);
      await localFile.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(localFile.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.isEmpty
                  ? 'No app available to open this file'
                  : result.message,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _resolveExtension(DocumentFileModel file) {
    final urlExtension =
        file.downloadUrl == null
            ? ''
            : path.extension(Uri.parse(file.downloadUrl!).path);

    if (urlExtension.isNotEmpty) {
      return urlExtension;
    }

    final existingNameExtension = path.extension(file.name);
    if (existingNameExtension.isNotEmpty) {
      return existingNameExtension;
    }

    switch (file.fileType.toLowerCase()) {
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
    final cleanBase = rawName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final baseWithoutExtension =
        extension.isNotEmpty &&
                cleanBase.toLowerCase().endsWith(extension.toLowerCase())
            ? cleanBase.substring(0, cleanBase.length - extension.length)
            : cleanBase;
    final fallback =
        baseWithoutExtension.isEmpty ? 'document_file' : baseWithoutExtension;
    return '$fallback$extension';
  }

  EmployeeAgreementModel _toEmployeeAgreementModel(DocumentFileModel file) {
    return EmployeeAgreementModel(
      id: file.agreementId ?? 0,
      agreementName: file.name,
      employeeName: file.agreementEmployeeName ?? 'N/A',
      employeeAvatar: file.agreementEmployeeAvatar ?? '',
      agreementType: file.agreementType ?? '-',
      assignedBy: file.agreementAssignedBy ?? 'N/A',
      assignedByAvatar: file.agreementAssignedByAvatar ?? '',
      expiryDate: file.agreementExpiryDate ?? 'N/A',
      status: file.agreementStatus ?? '',
      content: file.agreementContent,
      signatureUrl: file.agreementSignatureUrl,
      documentUrl: file.downloadUrl,
    );
  }

  Future<void> _handleFileTap(DocumentFileModel file) async {
    if (!file.isAgreementItem || file.agreementId == null) {
      if (!file.hasPreviewUrl) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No preview available for this file'),
            backgroundColor: AppColors.info,
          ),
        );
        return;
      }
      if (_isOfficeDocument(file)) {
        await _openOfficeDocument(file);
        return;
      }
      final refreshed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentFilePreviewPage(file: file),
        ),
      );
      if (refreshed == true && mounted) {
        _detailCubit.loadFolder(widget.folder);
      }
      return;
    }

    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: networkInfo,
      onTokenExpired: () {
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );
    final remoteDataSource = AgreementRemoteDataSourceImpl(apiClient);
    final repository = AgreementRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    final agreementBloc = AgreementBloc(
      getAgreementListUseCase: GetAgreementListUseCase(repository),
      submitAgreementConsentUseCase: SubmitAgreementConsentUseCase(repository),
    );

    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlocProvider.value(
              value: agreementBloc,
              child: CommonAgreementDetailPage(
                agreementId: file.agreementId!,
                agreementName: file.name,
                status: file.agreementStatus ?? '',
                content: file.agreementContent,
                signatureUrl: file.agreementSignatureUrl,
                documentUrl: file.downloadUrl,
                useLegacyHtmlPreview: file.fileType.toLowerCase() == 'html',
              ),
            ),
      ),
    );

    await agreementBloc.close();

    if (refreshed == true && mounted) {
      _detailCubit.loadFolder(widget.folder);
    }
  }
}
