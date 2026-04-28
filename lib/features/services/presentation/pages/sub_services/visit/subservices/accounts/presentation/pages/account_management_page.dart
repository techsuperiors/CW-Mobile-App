import 'package:collectivWork/core/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../../../request/presentation/widgets/request_listing/request_empty_state.dart';
import '../../data/datasources/account_remote_datasource.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/models/account_model.dart';
import '../../domain/usecases/get_accounts_usecase.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';
import '../widgets/account_cards.dart';
import '../widgets/create_address_sheet.dart';
import '../widgets/create_customer_sheet.dart';
import 'address_details_page.dart';
import 'customer_details_page.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  static Widget withDependencies({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  }) {
    final remoteDataSource = AccountRemoteDataSourceImpl(apiClient: apiClient);
    final repository = AccountRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );

    return BlocProvider(
      create:
          (_) => AccountBloc(
            getAccountCustomersUseCase: GetAccountCustomersUseCase(repository),
            getAccountAddressesUseCase: GetAccountAddressesUseCase(repository),
            getAccountCustomerDetailsUseCase: GetAccountCustomerDetailsUseCase(
              repository,
            ),
            getAccountAddressDetailsUseCase: GetAccountAddressDetailsUseCase(
              repository,
            ),
            createAccountAddressUseCase: CreateAccountAddressUseCase(repository),
            createAccountCustomerUseCase: CreateAccountCustomerUseCase(
              repository,
            ),
          )..add(const LoadAccountCustomers()),
      child: const AccountManagementPage(),
    );
  }

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging || _tabController.index != 1) {
      return;
    }
    final bloc = context.read<AccountBloc>();
    final state = bloc.state;
    if (state.addresses.isEmpty && !state.isAddressesLoading) {
      bloc.add(const LoadAccountAddresses());
    }
  }

  Future<void> _openCreateCustomerSheet() async {
    final accountBloc = context.read<AccountBloc>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => BlocProvider.value(
            value: accountBloc,
            child: const CreateCustomerSheet(),
          ),
    );

    if (result == true && mounted) {
      accountBloc.add(const LoadAccountCustomers(forceRefresh: true));
    }
  }

  Future<void> _openCreateAddressSheet() async {
    final accountBloc = context.read<AccountBloc>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => BlocProvider.value(
            value: accountBloc,
            child: const CreateAddressSheet(),
          ),
    );

    if (result == true && mounted) {
      accountBloc.add(const LoadAccountAddresses(forceRefresh: true));
    }
  }

  Future<void> _refreshCurrentTab() async {
    final bloc = context.read<AccountBloc>();
    if (_tabController.index == 0) {
      bloc.add(const LoadAccountCustomers(forceRefresh: true));
      await bloc.stream.firstWhere((state) => !state.isCustomersLoading);
      return;
    }

    bloc.add(const LoadAccountAddresses(forceRefresh: true));
    await bloc.stream.firstWhere((state) => !state.isAddressesLoading);
  }

  Future<void> _openCustomerDetails(AccountCustomerModel customer) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => BlocProvider.value(
              value: context.read<AccountBloc>(),
              child: CustomerDetailsPage(customerId: customer.id),
            ),
      ),
    );
  }

  Future<void> _openAddressDetails(AccountAddressModel address) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => BlocProvider.value(
              value: context.read<AccountBloc>(),
              child: AddressDetailsPage(addressId: address.id),
            ),
      ),
    );
  }

  List<AccountCustomerModel> _filteredCustomers(
    List<AccountCustomerModel> items,
  ) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((item) {
          final haystacks = [
            item.customerName,
            item.customerCode,
            item.businessDomain,
            item.status,
          ];
          return haystacks.any(
            (value) => value.toLowerCase().contains(_searchQuery),
          );
        })
        .toList(growable: false);
  }

  List<AccountAddressModel> _filteredAddresses(
    List<AccountAddressModel> items,
  ) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((item) {
          final haystacks = [
            item.addressName,
            item.addressType,
            item.city,
            item.state,
            item.country,
            item.pincode,
          ];
          return haystacks.any(
            (value) => value.toLowerCase().contains(_searchQuery),
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
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
              AppStrings.account,
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
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                _buildTabs(context),
                AppSpacing.vMd,
                _buildSearchAndFilterSection(context),
                AppSpacing.vMd,
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCustomersTab(context, state),
                      _buildAddressesTab(context, state),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilterSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      children: [
        // Search bar
        Expanded(
          child: Container(
            height: screenHeight * 0.050,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2), // light grey background
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              style: AppTextStyles.bodyMedium(context),
              decoration: InputDecoration(
                hintText: AppStrings.search,
                hintStyle: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textTertiary),

                prefixIcon: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: SvgPicture.asset(
                    AppAssets.searchIcon,
                    width: screenWidth * 0.045,
                    colorFilter: const ColorFilter.mode(
                      Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // 👈 curved border
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),

                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.010,
                ),
              ),

              onChanged: (value) {},
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // 4.2% of screen width
        SizedBox(
          height: screenHeight * 0.050, // 5.0% of screen height
          child: InkWell(
            onTap: () async {},
            customBorder: const CircleBorder(),
            child: SvgPicture.asset(AppAssets.filterIcon),
          ),
        ),
        SizedBox(
          height: screenHeight * 0.050, // 5.0% of screen height

          child: InkWell(
            onTap:
                () async =>
                    _tabController.index == 0
                        ? _openCreateCustomerSheet()
                        : _openCreateAddressSheet(),
            customBorder: const CircleBorder(),
            child: SvgPicture.asset(AppAssets.addIcon),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyMediumHeading(
          context,
        ).copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.bodyMediumHeading(context),
        tabs: const [Tab(text: 'Customer'), Tab(text: 'Address')],
      ),
    );
  }

  Widget _buildCustomersTab(BuildContext context, AccountState state) {
    if (state.isCustomersLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.customersError != null && state.customers.isEmpty) {
      return ApiErrorState(
        rawMessage: state.customersError,
        title: 'Unable to load customers',
        onRetry:
            () => context.read<AccountBloc>().add(
              const LoadAccountCustomers(forceRefresh: true),
            ),
      );
    }

    final items = _filteredCustomers(state.customers);
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshCurrentTab,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: 400, child: RequestEmptyState()),
        ),
      );
    }

    final groupedItems = _groupByMonth<AccountCustomerModel>(
      items,
      (item) => item.createdAt,
    );

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: groupedItems.entries
            .map((entry) {
              return _buildMonthSection(
                context,
                heading: entry.key,
                children: entry.value
                    .map(
                      (customer) => AccountCustomerCard(
                        customer: customer,
                        onTap: () => _openCustomerDetails(customer),
                      ),
                    )
                    .toList(growable: false),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildAddressesTab(BuildContext context, AccountState state) {
    if (state.isAddressesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.addressesError != null && state.addresses.isEmpty) {
      return ApiErrorState(
        rawMessage: state.addressesError,
        title: 'Unable to load addresses',
        onRetry:
            () => context.read<AccountBloc>().add(
              const LoadAccountAddresses(forceRefresh: true),
            ),
      );
    }

    final items = _filteredAddresses(state.addresses);
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshCurrentTab,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: 400, child: RequestEmptyState()),
        ),
      );
    }

    final groupedItems = _groupByMonth<AccountAddressModel>(
      items,
      (item) => item.createdAt,
    );

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: groupedItems.entries
            .map((entry) {
              return _buildMonthSection(
                context,
                heading: entry.key,
                children: entry.value
                    .map(
                      (address) => AccountAddressCard(
                        address: address,
                        onTap: () => _openAddressDetails(address),
                      ),
                    )
                    .toList(growable: false),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildMonthSection(
    BuildContext context, {
    required String heading,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.vSm,
        Text(
          heading,
          style: AppTextStyles.bodySmall(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
        AppSpacing.vSm,
        ...children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: child,
          ),
        ),
      ],
    );
  }

  Map<String, List<T>> _groupByMonth<T>(
    List<T> items,
    DateTime? Function(T item) dateSelector,
  ) {
    final grouped = <String, List<T>>{};
    final formatter = DateFormat('MMMM yyyy');

    for (final item in items) {
      final date = dateSelector(item);
      final key = date == null ? 'Unknown' : formatter.format(date);
      grouped.putIfAbsent(key, () => <T>[]).add(item);
    }

    return grouped;
  }
}
