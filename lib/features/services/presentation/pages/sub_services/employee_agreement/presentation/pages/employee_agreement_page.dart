import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../../../../../../user/presentation/bloc/user_profile_event.dart';
import '../../data/datasources/agreement_remote_datasource.dart';
import '../../data/repositories/agreement_repository_impl.dart';
import '../../domain/usecases/get_agreement_list_usecase.dart';
import '../../domain/usecases/submit_agreement_consent_usecase.dart';
import '../bloc/agreement_bloc.dart';
import '../bloc/agreement_event.dart';
import '../bloc/agreement_state.dart';
import '../utils/agreement_mapper.dart';
import '../widgets/employee_agreement_card.dart';
import '../../domain/models/employee_agreement_model.dart';

/// Employee Agreement page showing list of agreements
class EmployeeAgreementPage extends StatefulWidget {
  final int? serviceId;

  const EmployeeAgreementPage({
    super.key,
    this.serviceId,
  });

  @override
  State<EmployeeAgreementPage> createState() => _EmployeeAgreementPageState();
}

class _EmployeeAgreementPageState extends State<EmployeeAgreementPage> {
  late final AgreementBloc _agreementBloc;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    // Initialize dependencies
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    final remoteDataSource = AgreementRemoteDataSourceImpl(apiClient);
    final repository = AgreementRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    final getAgreementListUseCase = GetAgreementListUseCase(repository);
    final submitAgreementConsentUseCase = SubmitAgreementConsentUseCase(repository);
    _agreementBloc = AgreementBloc(
      getAgreementListUseCase: getAgreementListUseCase,
      submitAgreementConsentUseCase: submitAgreementConsentUseCase,
    );
  }

  @override
  void dispose() {
    _agreementBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _agreementBloc,
      child: ResponsiveScaffold(
        backgroundColor: AppColors.background,
        padding: EdgeInsets.zero,
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
                  size: MediaQuery.of(context).size.width * 0.048, // ~4.8% of screen width
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
            AppStrings.employeeAgreement,
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0, // Services is active
          onTap: NavigationHelper.getBottomNavHandler(context),
        ),
        body: BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, profileState) {
            // Load user profile if not loaded yet
            if (profileState is UserProfileInitial) {
              context.read<UserProfileBloc>().add(const LoadUserProfile());
            }
            
            // Get user_id from profile and load agreements once
            if (profileState is UserProfileLoaded && !_hasLoaded) {
              final userId = profileState.profile.userId;
              _hasLoaded = true;
              _agreementBloc.add(LoadAgreementList(userId));
            }

            // Show loading if profile is not loaded yet
            if (profileState is! UserProfileLoaded) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return BlocBuilder<AgreementBloc, AgreementState>(
              builder: (context, state) {
                if (state is AgreementLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

            if (state is AgreementError) {
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
                        _hasLoaded = false;
                        // Get user_id from profile and reload agreements
                        final userProfileState = context.read<UserProfileBloc>().state;
                        if (userProfileState is UserProfileLoaded) {
                          final userId = userProfileState.profile.userId;
                          _agreementBloc.add(LoadAgreementList(userId));
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is AgreementLoaded) {
              final agreements = state.agreementList.agreements
                  .map((agreement) => AgreementMapper.toEmployeeAgreementModel(agreement))
                  .toList();

              if (agreements.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No agreements found',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.01,
                ),
                itemCount: agreements.length,
                itemBuilder: (context, index) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final spacing = screenHeight < 600 ? 12.0 : (screenHeight < 700 ? 14.0 : 16.0);
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing),
                    child: EmployeeAgreementCard(agreement: agreements[index]),
                  );
                },
              );
            }

                // Initial state
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

