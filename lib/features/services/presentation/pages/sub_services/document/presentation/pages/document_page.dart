import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/app_navigator.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../data/datasources/document_remote_datasource.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/models/document_folder_model.dart';
import '../../domain/usecases/get_document_folders_usecase.dart';
import '../../../employee_agreement/presentation/pages/employee_agreement_page.dart';
import '../cubit/document_folders_cubit.dart';
import '../cubit/document_folders_state.dart';
import '../widgets/document_folder_card.dart';
import 'document_detail_page.dart';

class DocumentPage extends StatefulWidget {
  final int? serviceId;

  const DocumentPage({super.key, this.serviceId});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  late final DocumentFoldersCubit _foldersCubit;

  bool _isEmployeeAgreementFolder(DocumentFolderModel folder) {
    final normalized = folder.name.trim().toLowerCase();
    return normalized == 'employee agreements' ||
        normalized.contains('employee agree');
  }

  @override
  void initState() {
    super.initState();
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo,onTokenExpired: () {
      AppNavigator.pushAndRemoveAll(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    },);
    final remoteDataSource = DocumentRemoteDataSourceImpl(apiClient);
    final repository = DocumentRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );

    _foldersCubit = DocumentFoldersCubit(
      getDocumentFoldersUseCase: GetDocumentFoldersUseCase(repository),
    )..loadFolders();
  }

  @override
  void dispose() {
    _foldersCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider.value(
      value: _foldersCubit,
      child: ResponsiveScaffold(
        backgroundColor: AppColors.backgroundMedium,
        appBar: AppBar(
          elevation: 0,
         forceMaterialTransparency: true,
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
            AppStrings.document,
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          onTap: NavigationHelper.getBottomNavHandler(context),
        ),
        body: BlocBuilder<DocumentFoldersCubit, DocumentFoldersState>(
          builder: (context, state) {
            if (state is DocumentFoldersInitial ||
                state is DocumentFoldersLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DocumentFoldersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.folder_off_outlined,
                      color: AppColors.error,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _foldersCubit.loadFolders,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final loadedState = state as DocumentFoldersLoaded;
            final orderedFolders = <DocumentFolderModel>[
              ...loadedState.sharedFolders,
              ...loadedState.documentFolders,
            ];
            return _buildFolderList(
              context,
              orderedFolders,
              sharedFolderIds: loadedState.sharedFolders
                  .map((folder) => folder.id)
                  .toSet(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFolderList(
    BuildContext context,
    List<DocumentFolderModel> folders, {
    Set<String> sharedFolderIds = const <String>{},
  }) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (folders.isEmpty) {
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
        horizontal: MediaQuery.of(context).size.width * 0.004,
        vertical: screenHeight * 0.005,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final spacing = screenHeight < 600
            ? 6.0
            : (screenHeight < 700 ? 8.0 : 10.0);
        final folder = folders[index];
        final isShared = sharedFolderIds.contains(folder.id);

        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: DocumentFolderCard(
            folder: folder,
            isSelected: isShared,
            onTap: () {
              if (_isEmployeeAgreementFolder(folder)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmployeeAgreementPage(serviceId: widget.serviceId),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentDetailPage(
                    folder: folder,
                    isShared: isShared,
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
