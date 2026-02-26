import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/document_file_model.dart';
import '../../domain/models/document_folder_model.dart';
import '../data/document_data.dart';
import '../widgets/document_file_card.dart';

/// Document detail page showing files with filters
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

class _DocumentDetailPageState extends State<DocumentDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  String? _selectedFilter; // 'pdf', 'document', 'image', 'other', or null for all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.isShared ? 1 : 0,
    );
    _currentTabIndex = widget.isShared ? 1 : 0;
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DocumentFileModel> get _filteredFiles {
    // Get files based on current tab
    final allFiles = _currentTabIndex == 0
        ? DocumentData.getFilesForFolder(widget.folder.id)
        : DocumentData.getAllFiles(); // Shared tab shows all files
    
    if (_selectedFilter == null) {
      return allFiles;
    }
    
    return allFiles.where((file) => file.fileTypeCategory == _selectedFilter).toList();
  }

  Map<String, List<DocumentFileModel>> get _groupedFiles {
    final files = _filteredFiles;
    final Map<String, List<DocumentFileModel>> grouped = {};
    
    for (var file in files) {
      final category = file.fileTypeCategory;
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(file);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
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
                size: screenWidth * 0.048, // ~4.8% of screen width
              ),
              Flexible(
                child: Text(
                  AppStrings.document,
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
          widget.folder.name,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: AppColors.textSecondary,
              size: screenWidth * 0.053, // ~5.3% of screen width
            ),
            onPressed: () {
              // Handle add file
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add file functionality'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.bodyMedium(context),
          tabs: const [
            Tab(text: AppStrings.document),
            Tab(text: 'Shared'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(context),
          // File list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFileList(context),
                _buildFileList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.042,
        vertical: screenHeight * 0.015,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(context, 'All', null),
            SizedBox(width: screenWidth * 0.021),
            _buildFilterChip(context, 'PDF', 'pdf'),
            SizedBox(width: screenWidth * 0.021),
            _buildFilterChip(context, 'Document', 'document'),
            SizedBox(width: screenWidth * 0.021),
            _buildFilterChip(context, 'Image', 'image'),
            SizedBox(width: screenWidth * 0.021),
            _buildFilterChip(context, 'Other', 'other'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String? filter) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? filter : null;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: AppTextStyles.bodySmall(context).copyWith(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildFileList(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final groupedFiles = _groupedFiles;

    if (groupedFiles.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noData,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.01,
        vertical: screenHeight * 0.01,
      ),
      itemCount: groupedFiles.length,
      itemBuilder: (context, index) {
        final category = groupedFiles.keys.elementAt(index);
        final files = groupedFiles[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
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
            // Files in this category
            ...files.map((file) => DocumentFileCard(
                  file: file,
                  onDownload: () {
                    _handleDownload(file);
                  },
                )),
          ],
        );
      },
    );
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'pdf':
        return 'Portable Document Format (PDF)';
      case 'document':
        return 'Document';
      case 'image':
        return 'Joint Photographic Experts Group (JPG)';
      default:
        return 'Other Files';
    }
  }

  void _handleDownload(DocumentFileModel file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${file.name}...'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    // Here you would implement actual download logic
  }
}
