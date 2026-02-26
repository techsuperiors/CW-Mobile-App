import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/constants/app_assets.dart';
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
import '../bloc/ticket_bloc.dart';
import '../bloc/ticket_event.dart';
import '../bloc/ticket_state.dart';
import '../../domain/entities/ticket.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Ticket detail page
class TicketDetailPage extends StatefulWidget {
  final int ticketId;

  const TicketDetailPage({
    super.key,
    required this.ticketId,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  late TicketBloc _ticketBloc;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedFile;

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
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _uploadFile(BuildContext context) {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
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
    _ticketBloc.add(UploadTicketFile(
      clientId: clientId,
      ticketId: widget.ticketId,
      filePath: _selectedFile!.path,
    ));
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider.value(
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
              _selectedFile = null;
            });
            // Reload ticket details to show new file
            _ticketBloc.add(LoadTicketDetails(widget.ticketId));
            // Navigate back and refresh list
            Navigator.of(context).pop(true);
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
              appBar: AppBar(
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
                        size: screenWidth * 0.048,
                      ),
                      Flexible(
                        child: Text(
                          AppStrings.tickets,
                          style: AppTextStyles.bodyLarge(context).copyWith(
                            fontWeight: FontWeight.w500,
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
                actions: [

                ],
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
    );
  }

  Widget _buildBody(BuildContext context, TicketState state, double screenWidth, double screenHeight) {
    // Show loading overlay if file is uploading
    final isUploading = state is TicketFileUploading;

    if (state is TicketDetailsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is TicketDetailsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.error,
              ),
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
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.042),
            child: CustomPaint(
              painter: DashedLinePainter(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.042),
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
                                style: AppTextStyles.heading4(context).copyWith(
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
                                style: AppTextStyles.bodySmall(context).copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: screenWidth * 0.03,
                                    height: 2,
                                    color: _getPriorityColor(details.priority),
                                  ),
                                  SizedBox(width: screenWidth * 0.015),
                                  Text(
                                    details.priority,
                                    style: AppTextStyles.bodySmall(context).copyWith(
                                      color: _getPriorityColor(details.priority),
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
                          statusColor: _getStatusColor(details.ticketStatus),
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
                            children: details.documents.map((doc) {
                              return GestureDetector(
                                onTap: () {
                                  // Handle document view/download
                                },
                                child: Container(
                                  width: screenWidth * 0.25,
                                  height: screenWidth * 0.25,
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: doc.url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) => Icon(
                                        Icons.image,
                                        size: screenWidth * 0.1,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          SizedBox(height: screenHeight * 0.02),
                          // Upload button only
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: screenWidth * 0.25,
                              height: screenWidth * 0.25,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload,
                                    size: screenWidth * 0.06,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  Text(
                                    'Upload File',
                                    style: AppTextStyles.labelSmall(context).copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        // Show selected file preview and submit button
                        if (_selectedFile != null) ...[
                          SizedBox(height: screenHeight * 0.02),
                          Row(
                            children: [
                              Container(
                                width: screenWidth * 0.25,
                                height: screenWidth * 0.25,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedFile!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _uploadFile(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textWhite,
                                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Submit',
                                    style: AppTextStyles.buttonLarge(context).copyWith(
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
          if (isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
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
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showAvatar) ...[
                CircleAvatar(
                  radius: screenWidth * 0.04,
                  backgroundColor: avatarColor != null
                      ? Color(int.parse(avatarColor.replaceFirst('#', '0xFF')))
                      : AppColors.backgroundLight,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          size: screenWidth * 0.04,
                          color: AppColors.textSecondary,
                        )
                      : null,
                ),
                SizedBox(width: screenWidth * 0.02),
              ],
              Text(
                value,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: statusColor ?? AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

