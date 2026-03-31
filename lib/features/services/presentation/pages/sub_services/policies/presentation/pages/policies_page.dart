import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/policy_model.dart';
import '../data/policies_remote_data.dart';
import '../widgets/policy_card.dart';

/// Policies page showing list of policies
class PoliciesPage extends StatefulWidget {
  final int? serviceId;

  const PoliciesPage({
    super.key,
    this.serviceId,
  });

  @override
  State<PoliciesPage> createState() => _PoliciesPageState();
}

class _PoliciesPageState extends State<PoliciesPage> {
  late Future<List<PolicyModel>> _policiesFuture;

  @override
  void initState() {
    super.initState();
    _policiesFuture = PoliciesRemoteData.getPolicies();
  }

  Future<void> _reloadPolicies() async {
    setState(() {
      _policiesFuture = PoliciesRemoteData.getPolicies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
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
                size: MediaQuery.of(context).size.width * 0.048, // ~4.8% of screen width
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
          AppStrings.policies,
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
      body: FutureBuilder<List<PolicyModel>>(
        future: _policiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ApiErrorState(
              title: 'Unable to load policies',
              rawMessage: snapshot.error.toString(),
              onRetry: _reloadPolicies,
            );
          }

          final policies = snapshot.data ?? const [];
          if (policies.isEmpty) {
            return Center(
              child: Text(
                'No policies available',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reloadPolicies,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.01,
                vertical: 8,
              ),
              itemCount: policies.length,
              itemBuilder: (context, index) {
                final screenHeight = MediaQuery.of(context).size.height;
                final spacing =
                    screenHeight < 600 ? 12.0 : (screenHeight < 700 ? 14.0 : 16.0);
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: PolicyCard(
                    policy: policies[index],
                    onPolicyUpdated: _reloadPolicies,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
