import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/document_folder_model.dart';
import '../data/document_data.dart';
import '../widgets/document_folder_card.dart';
import 'document_detail_page.dart';

/// Document page showing list of folders with Document/Shared tabs
class DocumentPage extends StatefulWidget {
  final int? serviceId;

  const DocumentPage({
    super.key,
    this.serviceId,
  });

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                  AppStrings.services,
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
          AppStrings.document,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
              size: screenWidth * 0.053, // ~5.3% of screen width
            ),
            onPressed: () {
              // Handle menu tap
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentTab(context),
          _buildSharedTab(context),
        ],
      ),
    );
  }

  Widget _buildDocumentTab(BuildContext context) {
    final folders = DocumentData.getEmployeeFolders();
    final screenHeight = MediaQuery.of(context).size.height;

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: screenHeight * 0.025,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final spacing = screenHeight < 600 ? 12.0 : (screenHeight < 700 ? 14.0 : 16.0);
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: DocumentFolderCard(
            folder: folders[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentDetailPage(
                    folder: folders[index],
                    isShared: false,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSharedTab(BuildContext context) {
    final folders = DocumentData.getSharedFolders();
    final screenHeight = MediaQuery.of(context).size.height;

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: screenHeight * 0.025,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final spacing = screenHeight < 600 ? 12.0 : (screenHeight < 700 ? 14.0 : 16.0);
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: DocumentFolderCard(
            folder: folders[index],
            isSelected: index == 0, // First item selected as shown in design
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentDetailPage(
                    folder: folders[index],
                    isShared: true,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
