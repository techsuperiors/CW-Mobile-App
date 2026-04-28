import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../request/presentation/widgets/request_listing/request_empty_state.dart';
import '../../data/datasources/employee_directory_remote_datasource.dart';
import '../../data/repositories/employee_directory_repository_impl.dart';
import '../../domain/models/employee_directory_model.dart';
import '../../domain/usecases/get_employee_directory_usecase.dart';
import '../bloc/employee_directory_bloc.dart';
import '../bloc/employee_directory_event.dart';
import '../bloc/employee_directory_state.dart';
import '../widgets/employee_directory_card.dart';
import '../widgets/employee_directory_detail_dialog.dart';

class EmployeeDirectoryPage extends StatefulWidget {
  const EmployeeDirectoryPage({super.key});

  static Widget withDependencies({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  }) {
    final remoteDataSource = EmployeeDirectoryRemoteDataSourceImpl(
      apiClient: apiClient,
    );
    final repository = EmployeeDirectoryRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );

    return BlocProvider(
      create:
          (_) => EmployeeDirectoryBloc(
            getEmployeeDirectoryUseCase: GetEmployeeDirectoryUseCase(
              repository,
            ),
            getEmployeeDirectoryDetailUseCase:
                GetEmployeeDirectoryDetailUseCase(repository),
            clientId: _resolveClientIdFromToken(),
          )..add(const LoadEmployeeDirectory()),
      child: const EmployeeDirectoryPage(),
    );
  }

  @override
  State<EmployeeDirectoryPage> createState() => _EmployeeDirectoryPageState();
}

class _EmployeeDirectoryPageState extends State<EmployeeDirectoryPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent * 0.8;
    if (_scrollController.position.pixels >= threshold) {
      context.read<EmployeeDirectoryBloc>().add(
        const LoadMoreEmployeeDirectory(),
      );
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<EmployeeDirectoryBloc>();
    bloc.add(const LoadEmployeeDirectory(forceRefresh: true));
    await bloc.stream.firstWhere((state) => !state.isLoading);
  }

  Future<void> _openEmployeeDetails(EmployeeDirectoryModel employee) async {
    final bloc = context.read<EmployeeDirectoryBloc>();
    bloc.add(LoadEmployeeDirectoryDetail(userId: employee.userId));

    await showDialog<void>(
      context: context,
      builder:
          (_) => BlocProvider.value(
            value: bloc,
            child: EmployeeDirectoryDetailDialog(employee: employee),
          ),
    );

    if (!mounted) return;
    bloc.add(const ClearEmployeeDirectoryDetail());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount =
        screenWidth >= 900
            ? 4
            : screenWidth >= 600
            ? 3
            : 2;
    final childAspectRatio = screenWidth >= 600 ? 0.86 : 0.6;

    return Scaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
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
                size: AppTextStyles.bodyMedium(context).fontSize,
              ),
              Flexible(
                child: Text(
                  'Back',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 110,
        title: Text(
          AppStrings.employeeDirectory,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: BlocBuilder<EmployeeDirectoryBloc, EmployeeDirectoryState>(
        builder: (context, state) {
          if (state.isLoading && state.employees.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.employees.isEmpty) {
            return ApiErrorState(
              rawMessage: state.error,
              title: 'Unable to load employee directory',
              onRetry:
                  () => context.read<EmployeeDirectoryBloc>().add(
                    const LoadEmployeeDirectory(forceRefresh: true),
                  ),
            );
          }

          if (state.employees.isEmpty) {
            return const RequestEmptyState();
          }

          final itemCount =
              state.employees.length + (state.isLoadingMore ? 1 : 0);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index >= state.employees.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                return EmployeeDirectoryCard(
                  employee: state.employees[index],
                  onTap: () => _openEmployeeDetails(state.employees[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

int _resolveClientIdFromToken() {
  final token = TokenStorage.getToken();
  if (token == null || token.isEmpty) return 0;
  final payload = decodeData<Map<String, dynamic>>(token);
  final rawClientId = payload?['client_id'];
  if (rawClientId is int) return rawClientId;
  if (rawClientId is double) return rawClientId.toInt();
  if (rawClientId is String) return int.tryParse(rawClientId.trim()) ?? 0;
  return 0;
}
