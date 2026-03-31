import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasource/asset_remote_datasource.dart';
import '../../data/repository/asset_repository_impl.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/entities/asset_request_entity.dart';
import '../../domain/usecases/get_assets_usecase.dart';
import '../../domain/usecases/get_asset_requests_usecase.dart';
import '../widgets/asset_card.dart';
import '../widgets/asset_request_card.dart';
import 'create_asset_request_page.dart';

/// Assigned Assets page with tabs: Allocated Assets + Asset Requests
class AssignedAssetsPage extends StatefulWidget {
  final int? serviceId;

  const AssignedAssetsPage({super.key, this.serviceId});

  @override
  State<AssignedAssetsPage> createState() => _AssignedAssetsPageState();
}

class _AssignedAssetsPageState extends State<AssignedAssetsPage>
    with SingleTickerProviderStateMixin {
  List<AssetEntity> _assets = [];
  List<AssetRequestEntity> _assetRequests = [];
  bool _isLoading = false; // start false — wait for profile
  bool _hasLoaded = false; // guard to fire API only once
  String? _errorMessage;
  int? _userId; // stored once profile loads
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Do NOT call _loadAll here — wait for UserProfileBloc to provide userId
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Builds shared dependencies once for both API calls
  ({GetAssetsUseCase assets, GetAssetRequestsUseCase requests})
  _buildUseCases() {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = AssetRemoteDataSourceImpl(apiClient);
    final repository = AssetRepositoryImpl(remoteDataSource: remoteDataSource);
    return (
      assets: GetAssetsUseCase(repository),
      requests: GetAssetRequestsUseCase(repository),
    );
  }

  /// Fetches both allocated assets and asset requests simultaneously
  Future<void> _loadAll(int userId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final useCases = _buildUseCases();

      // Fire both API calls in parallel
      final results = await Future.wait([
        useCases.assets(),
        useCases.requests(userId), // dynamic user ID from UserProfileBloc
      ]);

      final assetsResult = results[0] as dynamic;
      final requestsResult = results[1] as dynamic;

      String? error;

      assetsResult.fold(
        (failure) {
          error = failure.message;
        },
        (data) {
          _assets = List<AssetEntity>.from(data as List);
        },
      );

      requestsResult.fold(
        (failure) {
          error ??= failure.message;
        },
        (data) {
          _assetRequests = List<AssetRequestEntity>.from(data as List);
        },
      );

      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.backgroundMedium,
        leadingWidth: 110,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: MediaQuery.of(context).size.width * 0.048,
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
        title: Text(
          AppStrings.assignedAssets,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              final refreshed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const CreateAssetRequestPage(),
                ),
              );
              // If form was submitted successfully, reload the list
              if (refreshed == true && _userId != null) {
                _loadAll(_userId!);
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.016,
                vertical: screenHeight * 0.016,
              ),
              child: SvgPicture.asset(AppAssets.addIcon),
            ),
          ),
        ],
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [Tab(text: 'Allocated'), Tab(text: 'Requests')],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, profileState) {
          if (profileState is UserProfileLoaded && !_hasLoaded) {
            _userId = profileState.profile.userId;
            _hasLoaded = true;
            // Schedule after current frame to avoid calling setState during build
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _loadAll(_userId!),
            );
          }
          return _buildBody(context);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ApiErrorState(
        title: 'Unable to load assets',
        rawMessage: _errorMessage!,
        onRetry: _userId != null ? () => _loadAll(_userId!) : null,
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [_buildAssetList(context), _buildRequestList(context)],
    );
  }

  Widget _buildAssetList(BuildContext context) {
    if (_assets.isEmpty) {
      return _buildEmptyState(context, Icons.devices, 'No assets assigned');
    }

    return RefreshIndicator(
      onRefresh: _userId != null ? () => _loadAll(_userId!) : () async {},
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.002,
        ),
        itemCount: _assets.length,
        itemBuilder:
            (context, index) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height < 700 ? 12 : 16,
              ),
              child: AssetCard(asset: _assets[index]),
            ),
      ),
    );
  }

  Widget  _buildRequestList(BuildContext context) {
    if (_assetRequests.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.assignment_outlined,
        'No asset requests found',
      );
    }

    return RefreshIndicator(
      onRefresh: _userId != null ? () => _loadAll(_userId!) : () async {},
      child: ListView.builder(
        itemCount: _assetRequests.length,
        itemBuilder:
            (context, index) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height < 700 ? 12 : 16,
              ),
              child: AssetRequestCard(request: _assetRequests[index]),
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textSecondary.withOpacity(0.5), size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
