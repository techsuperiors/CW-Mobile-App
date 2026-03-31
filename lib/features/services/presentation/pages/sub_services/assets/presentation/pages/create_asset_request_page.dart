import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../data/datasource/asset_remote_datasource.dart';
import '../../data/repository/asset_repository_impl.dart';
import '../../domain/entities/asset_category_entity.dart';
import '../../domain/usecases/create_asset_request_usecase.dart';
import '../../domain/usecases/get_asset_categories_usecase.dart';

/// Form page for creating a new asset request
class CreateAssetRequestPage extends StatefulWidget {
  const CreateAssetRequestPage({super.key});

  @override
  State<CreateAssetRequestPage> createState() => _CreateAssetRequestPageState();
}

class _CreateAssetRequestPageState extends State<CreateAssetRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  List<AssetCategoryEntity> _categories = [];
  AssetCategoryEntity? _selectedCategory;
  AssetSubCategoryEntity? _selectedSubCategory;
  String _requestType = 'Allocation';

  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  String? _categoryError;

  late GetAssetCategoriesUseCase _getCategoriesUseCase;
  late CreateAssetRequestUseCase _createRequestUseCase;
  int? _userId;

  final List<String> _requestTypes = ['Allocation', 'Replacement', 'Repair'];

  @override
  void initState() {
    super.initState();
    _initUseCases();
  }

  void _initUseCases() {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = AssetRemoteDataSourceImpl(apiClient);
    final repository = AssetRepositoryImpl(remoteDataSource: remoteDataSource);
    _getCategoriesUseCase = GetAssetCategoriesUseCase(repository);
    _createRequestUseCase = CreateAssetRequestUseCase(repository);
  }

  Future<void> _loadCategories(int userId) async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    final result = await _getCategoriesUseCase(userId);
    result.fold(
      (failure) => setState(() {
        _categoryError = failure.message;
        _isLoadingCategories = false;
      }),
      (categories) => setState(() {
        _categories = categories.where((c) => c.requestable).toList();
        _isLoadingCategories = false;
      }),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack('Please select a category', isError: true);
      return;
    }
    if (_selectedSubCategory == null) {
      _showSnack('Please select a sub-category', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _createRequestUseCase(
      userId: _userId!,
      assetCategoryId: _selectedCategory!.id,
      assetSubCategoryId: _selectedSubCategory!.id,
      reason: _reasonController.text.trim(),
      requestType: _requestType,
    );

    setState(() => _isSubmitting = false);

    result.fold((failure) => _showSnack(failure.message, isError: true), (_) {
      _showSnack('Asset request created successfully!');
      Navigator.of(context).pop(true); // return true = refresh parent
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isError ? ErrorMessageMapper.toUserFriendlyMessage(message) : message,
        ),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, profileState) {
        if (profileState is UserProfileLoaded && _userId == null) {
          _userId = profileState.profile.userId;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _loadCategories(_userId!),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            forceMaterialTransparency: true,
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
                    size: sw * 0.048,
                  ),
                  Flexible(
                    child: Text(
                      'Back',
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
              'Request Asset',
              style: AppTextStyles.heading4(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body:
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : _categoryError != null
                  ? _buildErrorState()
                  : _buildForm(context, sw, sh),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return ApiErrorState(
      title: 'Unable to load asset categories',
      rawMessage: _categoryError!,
      onRetry: _userId != null ? () => _loadCategories(_userId!) : null,
    );
  }

  Widget _buildForm(BuildContext context, double sw, double sh) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: sw * 0.05,
          vertical: sh * 0.025,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category Dropdown ─────────────────────────────────────────
            _buildLabel('Asset Category *'),
            SizedBox(height: sh * 0.008),
            _buildDropdown<AssetCategoryEntity>(
              context: context,
              hint: 'Select Category',
              value: _selectedCategory,
              items: _categories,
              labelBuilder: (c) => c.categoryName,
              onChanged:
                  (c) => setState(() {
                    _selectedCategory = c;
                    _selectedSubCategory = null; // reset sub-category on change
                  }),
            ),

            SizedBox(height: sh * 0.022),

            // ── Sub-Category Dropdown ─────────────────────────────────────
            _buildLabel('Sub-Category *'),
            SizedBox(height: sh * 0.008),
            _buildDropdown<AssetSubCategoryEntity>(
              context: context,
              hint:
                  _selectedCategory == null
                      ? 'Select a category first'
                      : 'Select Sub-Category',
              value: _selectedSubCategory,
              items: _selectedCategory?.subCategories ?? [],
              labelBuilder: (s) => s.subCategoryName,
              onChanged:
                  _selectedCategory == null
                      ? null
                      : (s) => setState(() => _selectedSubCategory = s),
            ),

            SizedBox(height: sh * 0.022),

            // ── Request Type ──────────────────────────────────────────────
            // _buildLabel('Request Type *'),
            // SizedBox(height: sh * 0.008),
            // _buildDropdown<String>(
            //   context: context,
            //   hint: 'Select Request Type',
            //   value: _requestType,
            //   items: _requestTypes,
            //   labelBuilder: (t) => t,
            //   onChanged:
            //       (t) => setState(() => _requestType = t ?? 'Allocation'),
            // ),

            SizedBox(height: sh * 0.022),

            // ── Reason TextField ──────────────────────────────────────────
            _buildLabel('Reason *'),
            SizedBox(height: sh * 0.008),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Reason is required'
                          : null,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter reason for the asset request…',
                hintStyle: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04,
                  vertical: sh * 0.018,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.error, width: 1),
                ),
              ),
            ),

            SizedBox(height: sh * 0.04),

            // ── Submit Button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: sh * 0.065,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                        : Text(
                          'Submit Request',
                          style: AppTextStyles.bodyLarge(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium(
        context,
      ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?)? onChanged,
  }) {
    final sw = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textPrimary),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          onChanged: onChanged,
          items:
              items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        labelBuilder(item),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
