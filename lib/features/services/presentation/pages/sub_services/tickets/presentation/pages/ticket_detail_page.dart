import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/usecases/get_ticket_details_usecase.dart';
import '../../domain/usecases/get_ticket_list_usecase.dart';
import '../../domain/usecases/get_ticket_stats_usecase.dart';
import '../../domain/usecases/upload_ticket_file_usecase.dart';
import '../../domain/usecases/delete_ticket_file_usecase.dart';
import '../bloc/ticket_bloc.dart';
import '../bloc/ticket_event.dart';
import '../bloc/ticket_state.dart';
import '../../domain/entities/ticket.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Ticket detail page
class TicketDetailPage extends StatefulWidget {
  final int ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  late TicketBloc _ticketBloc;
  late DeleteTicketFileUseCase _deleteTicketFileUseCase;
  late UploadTicketFileUseCase _uploadTicketFileUseCase;
  final List<_SelectedTicketFile> _selectedFiles = [];
  bool _isPickingFiles = false;
  bool _isUploadingFiles = false;
  final Set<String> _deletingDocumentIds = <String>{};

  @override
  void initState() {
    super.initState();
    // Initialize dependencies
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    final remoteDataSource = TicketRemoteDataSourceImpl(apiClient);
    final repository = TicketRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    final getTicketListUseCase = GetTicketListUseCase(repository);
    final getTicketStatsUseCase = GetTicketStatsUseCase(repository);
    final getTicketDetailsUseCase = GetTicketDetailsUseCase(repository);
    final uploadTicketFileUseCase = UploadTicketFileUseCase(repository);
    _uploadTicketFileUseCase = uploadTicketFileUseCase;
    _deleteTicketFileUseCase = DeleteTicketFileUseCase(repository);
    _ticketBloc = TicketBloc(
      getTicketListUseCase: getTicketListUseCase,
      getTicketStatsUseCase: getTicketStatsUseCase,
      getTicketDetailsUseCase: getTicketDetailsUseCase,
      uploadTicketFileUseCase: uploadTicketFileUseCase,
    );

    // Load ticket details
    _ticketBloc.add(LoadTicketDetails(widget.ticketId));
  }

  @override
  void dispose() {
    _ticketBloc.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingFiles) return;

    setState(() => _isPickingFiles = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final newFiles =
            result.files
                .where((file) => file.path != null && file.path!.isNotEmpty)
                .map((file) => _SelectedTicketFile.fromPath(file.path!))
                .where(
                  (file) =>
                      !_selectedFiles.any(
                        (existing) => existing.path == file.path,
                      ),
                )
                .toList();

        if (newFiles.isNotEmpty) {
          setState(() {
            _selectedFiles.addAll(newFiles);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFiles = false);
      }
    }
  }

  void _removeSelectedFile(String path) {
    setState(() {
      _selectedFiles.removeWhere((file) => file.path == path);
    });
  }

  Future<void> _uploadFile(BuildContext context) async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Get client_id from UserProfileBloc
    final profileState = context.read<UserProfileBloc>().state;
    if (profileState is! UserProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User profile not loaded'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final clientId = profileState.profile.clientId;
    final totalFiles = _selectedFiles.length;

    setState(() {
      _isUploadingFiles = true;
    });

    for (final file in List<_SelectedTicketFile>.from(_selectedFiles)) {
      final result = await _uploadTicketFileUseCase(
        clientId,
        widget.ticketId,
        file.path,
      );

      if (!mounted) return;

      final shouldContinue = result.fold((failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
        return false;
      }, (_) => true);

      if (!shouldContinue) {
        setState(() {
          _isUploadingFiles = false;
        });
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _selectedFiles.clear();
      _isUploadingFiles = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          totalFiles == 1
              ? 'File uploaded successfully'
              : '$totalFiles files uploaded successfully',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    _ticketBloc.add(LoadTicketDetails(widget.ticketId));
  }

  Future<void> _deleteDocument(
    BuildContext context, {
    required int supportDocumentId,
    required TicketDocument document,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete file'),
          content: Text('Delete "${document.name}" from this ticket?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _deletingDocumentIds.add(document.id);
    });

    final result = await _deleteTicketFileUseCase(
      supportDocumentId,
      document.id,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
        _ticketBloc.add(LoadTicketDetails(widget.ticketId));
      },
    );

    if (!mounted) return;

    setState(() {
      _deletingDocumentIds.remove(document.id);
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.primary;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.primary;
      case 'in-progress':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      case 'escalated':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  void back() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploadingFiles,
      child: BlocProvider.value(
        value: _ticketBloc,
        child: BlocListener<TicketBloc, TicketState>(
          bloc: _ticketBloc,
          listener: (context, state) {
            if (state is TicketFileUploaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File uploaded successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
              // Clear selected file
              setState(() {
                _selectedFiles.clear();
              });
              // Reload ticket details to show new file
              _ticketBloc.add(LoadTicketDetails(widget.ticketId));
              // Navigate back and refresh list
              // Navigator.of(context).pop(true);
            } else if (state is TicketFileUploadError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: BlocBuilder<TicketBloc, TicketState>(
            bloc: _ticketBloc,
            builder: (context, state) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;

              return ResponsiveScaffold(
                backgroundColor: AppColors.backgroundMedium,
                appBar: AppBar(
                  forceMaterialTransparency: true,
                  elevation: 0,
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textPrimary,
                  leading: GestureDetector(
                    onTap: () {
                      back();
                    },
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
                            "Back",
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
                    state is TicketDetailsLoaded ? state.details.ticketID : '',
                    style: AppTextStyles.heading4(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  centerTitle: false,
                  actions: [],
                ),
                bottomNavigationBar: BottomNavBar(
                  currentIndex: 0,
                  onTap: NavigationHelper.getBottomNavHandler(context),
                ),
                body: _buildBody(context, state, screenWidth, screenHeight),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TicketState state,
    double screenWidth,
    double screenHeight,
  ) {
    // Show loading overlay if file is uploading
    final isUploading = state is TicketFileUploading || _isUploadingFiles;

    if (state is TicketDetailsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is TicketDetailsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _ticketBloc.add(LoadTicketDetails(widget.ticketId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is TicketDetailsLoaded) {
      final details = state.details;
      return Stack(
        children: [
          Column(
            children: [
              // Divider after AppBar
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.002),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ticket Details Card
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.042),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and menu
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    details.subject,
                                    style: AppTextStyles.heading4(
                                      context,
                                    ).copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            // Raised By
                            _buildDetailRow(
                              context,
                              'Raised By',
                              details.createdByUser?.fullName ?? 'N/A',
                              showAvatar: true,
                              avatarUrl: details.createdByUser?.imageUrl,
                              avatarColor: details.createdByUser?.profileColor,
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.border,
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            // Ticket Category
                            _buildDetailRow(
                              context,
                              'Ticket Category',
                              details.ticketCategory?.categoryName ?? 'N/A',
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.border,
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            // Raised Date
                            _buildDetailRow(
                              context,
                              'Raised Date',
                              _formatDate(details.createdAt),
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.border,
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            // Priority
                            Row(
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.3,
                                  child: Text(
                                    'Priority',
                                    style: AppTextStyles.bodySmall(
                                      context,
                                    ).copyWith(color: AppColors.textSecondary),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: screenWidth * 0.03,
                                        height: 2,
                                        color: _getPriorityColor(
                                          details.priority,
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.015),
                                      Text(
                                        details.priority,
                                        style: AppTextStyles.bodySmall(
                                          context,
                                        ).copyWith(
                                          color: _getPriorityColor(
                                            details.priority,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.border,
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            // Status
                            _buildDetailRow(
                              context,
                              'Status',
                              details.ticketStatus,
                              statusColor: _getStatusColor(
                                details.ticketStatus,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            // Description
                            Text(
                              'Description',
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              details.description.isNotEmpty
                                  ? details.description
                                  : 'No description provided.',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            if (details.documents.isNotEmpty) ...[
                              SizedBox(height: screenHeight * 0.02),
                              // Documents
                              Wrap(
                                spacing: screenWidth * 0.02,
                                runSpacing: screenWidth * 0.02,
                                children:
                                    details.documents.map((doc) {
                                      final isPdf = doc.url
                                          .toLowerCase()
                                          .contains('.pdf');
                                      final isDeleting = _deletingDocumentIds
                                          .contains(doc.id);

                                      return GestureDetector(
                                        onTap:
                                            isDeleting
                                                ? null
                                                : () {
                                                  final url =
                                                      doc.url.toLowerCase();

                                                  if (url.endsWith('.pdf')) {
                                                    _openPdf(context, doc.url);
                                                  } else {
                                                    _openImage(
                                                      context,
                                                      doc.url,
                                                    );
                                                  }
                                                },
                                        child: Container(
                                          width: screenWidth * 0.25,
                                          height: screenWidth * 0.25,
                                          decoration: BoxDecoration(
                                            color: AppColors.backgroundLight,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                isPdf
                                                    ? Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .picture_as_pdf,
                                                            color: Colors.red,
                                                            size:
                                                                screenWidth *
                                                                0.1,
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            "PDF",
                                                            style: TextStyle(
                                                              fontSize:
                                                                  screenWidth *
                                                                  0.03,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                    : CachedNetworkImage(
                                                      imageUrl: doc.url,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (
                                                            context,
                                                            url,
                                                          ) => const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => Icon(
                                                            Icons.image,
                                                            size:
                                                                screenWidth *
                                                                0.1,
                                                            color:
                                                                AppColors
                                                                    .textSecondary,
                                                          ),
                                                    ),
                                                Positioned(
                                                  top: 6,
                                                  right: 6,
                                                  child: GestureDetector(
                                                    onTap:
                                                        isDeleting
                                                            ? null
                                                            : () => _deleteDocument(
                                                              context,
                                                              supportDocumentId:
                                                                  details.id,
                                                              document: doc,
                                                            ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .backgroundMedium
                                                            .withOpacity(0.3),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child:
                                                          isDeleting
                                                              ? SizedBox(
                                                                width:
                                                                    screenWidth *
                                                                    0.04,
                                                                height:
                                                                    screenWidth *
                                                                    0.04,
                                                                child: const CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  valueColor:
                                                                      AlwaysStoppedAnimation<
                                                                        Color
                                                                      >(
                                                                        Colors
                                                                            .white,
                                                                      ),
                                                                ),
                                                              )
                                                              : Icon(
                                                                Icons
                                                                    .delete_forever_outlined,

                                                                color:
                                                                    Colors.red,
                                                                size:
                                                                    screenWidth *
                                                                    0.045,
                                                              ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ],
                            // else ...[
                            SizedBox(height: screenHeight * 0.02),
                            // Show selected file preview and submit button
                            if (_selectedFiles.isNotEmpty) ...[
                              SizedBox(height: screenHeight * 0.02),
                              Wrap(
                                spacing: screenWidth * 0.02,
                                runSpacing: screenWidth * 0.02,
                                children:
                                    _selectedFiles.map((file) {
                                      return Stack(
                                        children: [
                                          Container(
                                            width: screenWidth * 0.25,
                                            height: screenWidth * 0.25,
                                            decoration: BoxDecoration(
                                              color: AppColors.backgroundLight,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child:
                                                  file.isPdf
                                                      ? Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .picture_as_pdf,
                                                              color: Colors.red,
                                                              size:
                                                                  screenWidth *
                                                                  0.1,
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        6,
                                                                  ),
                                                              child: Text(
                                                                file.displayName,
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      screenWidth *
                                                                      0.026,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                      : Image.file(
                                                        File(file.path),
                                                        fit: BoxFit.cover,
                                                      ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: GestureDetector(
                                              onTap:
                                                  _isUploadingFiles
                                                      ? null
                                                      : () =>
                                                          _removeSelectedFile(
                                                            file.path,
                                                          ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: screenWidth * 0.045,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                            ],
                            SizedBox(height: screenHeight * 0.02),

                            // Upload button only
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _isUploadingFiles ? null : _pickImage,
                                  child: Container(
                                    width: screenWidth * 0.25,
                                    height: screenWidth * 0.25,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.upload,
                                          size: screenWidth * 0.06,
                                          color: AppColors.textSecondary,
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Text(
                                          'Upload File',
                                          style: AppTextStyles.labelSmall(
                                            context,
                                          ).copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // ],
                            Row(
                              children: [
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        _isUploadingFiles
                                            ? null
                                            : () => _uploadFile(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textWhite,
                                      padding: EdgeInsets.symmetric(
                                        vertical: screenHeight * 0.018,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      _isUploadingFiles
                                          ? 'Uploading...'
                                          : 'Submit',
                                      style: AppTextStyles.buttonLarge(
                                        context,
                                      ).copyWith(color: AppColors.textWhite),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isUploading) const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _openImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),

              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPdf(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: 50,
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "PDF Preview",
                      style: TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(child: SfPdfViewer.network(url)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool showAvatar = false,
    Color? statusColor,
    String? avatarUrl,
    String? avatarColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        SizedBox(
          width: screenWidth * 0.3,
          child: Text(
            label,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showAvatar) ...[
                CircleAvatar(
                  radius: screenWidth * 0.04,
                  backgroundColor:
                      avatarColor != null
                          ? Color(
                            int.parse(avatarColor.replaceFirst('#', '0xFF')),
                          )
                          : AppColors.backgroundLight,
                  backgroundImage:
                      avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                  child:
                      avatarUrl == null || avatarUrl.isEmpty
                          ? Icon(
                            Icons.person,
                            size: screenWidth * 0.04,
                            color: AppColors.textSecondary,
                          )
                          : null,
                ),
                SizedBox(width: screenWidth * 0.02),
              ],
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: statusColor ?? AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedTicketFile {
  final String path;
  final bool isPdf;

  const _SelectedTicketFile({required this.path, required this.isPdf});

  factory _SelectedTicketFile.fromPath(String path) {
    return _SelectedTicketFile(
      path: path,
      isPdf: path.toLowerCase().endsWith('.pdf'),
    );
  }

  String get displayName => path.split(Platform.pathSeparator).last;
}

/// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
