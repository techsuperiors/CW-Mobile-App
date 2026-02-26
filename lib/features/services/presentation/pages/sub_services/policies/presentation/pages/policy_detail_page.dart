import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/policy_model.dart';
import '../widgets/signature_dialog.dart';

/// Policy detail page showing full policy content and acknowledgment
class PolicyDetailPage extends StatefulWidget {
  final PolicyModel policy;

  const PolicyDetailPage({
    super.key,
    required this.policy,
  });

  @override
  State<PolicyDetailPage> createState() => _PolicyDetailPageState();
}

class _PolicyDetailPageState extends State<PolicyDetailPage> {
  bool _isAgreed = false;
  Uint8List? _signatureBytes;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.048, // ~4.8% of screen width
              ),
              Flexible(
                child: Text(
                  AppStrings.policies,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 110,
        title: Text(
          widget.policy.name,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.01,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Policy Summary Card
            _buildSummaryCard(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // Policy Content Card
            _buildContentCard(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // Acknowledgment Section
            _buildAcknowledgmentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Kebab Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.policy.name,
                  style: AppTextStyles.heading4(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  size: MediaQuery.of(context).size.width * 0.053, // ~5.3% of screen width
                  color: AppColors.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // Handle kebab menu tap
                },
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02), // 2% of screen height
          // Assigned By
          _buildSummaryRow(
            context,
            'Assigned By',
            widget.policy.assignedBy,
            widget.policy.assignedByAvatar,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
          // Assigned To
          _buildSummaryRow(
            context,
            'Assigned To',
            widget.policy.assignedTo,
            widget.policy.assignedToAvatar,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
          // Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: ',
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  widget.policy.status,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: widget.policy.isAcknowledged
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, String? avatarPath) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: screenWidth * 0.267, // ~26.7% of screen width
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // ~4.2% of screen width
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (avatarPath != null) ...[
                SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
                CircleAvatar(
                  radius: smallerDimension * 0.033, // ~3.3% of smaller dimension
                  backgroundImage: AssetImage(avatarPath),
                ),
              ],
              SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
              Text(
                value,
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getPolicyContent(widget.policy.name),
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgmentSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Row(
            children: [
              Checkbox(
                value: _isAgreed,
                onChanged: (value) {
                  setState(() {
                    _isAgreed = value ?? false;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: Text(
                  'I have read and agree to the company policy',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02), // 2% of screen height
          // Signature Preview (if added)
          if (_signatureBytes != null) ...[
            Container(
              height: MediaQuery.of(context).size.height * 0.125, // 12.5% of screen height
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _signatureBytes!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
          ],
          // Add Signature Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAgreed
                  ? () async {
                      final result = await showDialog<Uint8List>(
                        context: context,
                        builder: (context) => const SignatureDialog(),
                      );
                      if (result != null) {
                        setState(() {
                          _signatureBytes = result;
                        });
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.0175), // 1.75% of screen height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textSecondary,
              ),
              child: Text(
                _signatureBytes != null ? 'Change Signature' : 'Add Signature',
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
          // Submit Acknowledgment Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: (_isAgreed && _signatureBytes != null)
                  ? () {
                      // Handle submit acknowledgment
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Acknowledgment submitted successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      // Navigate back after a short delay
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      });
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
                padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.0175), // 1.75% of screen height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit Acknowledgment',
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPolicyContent(String policyName) {
    // Return policy content from model, or use default
    return widget.policy.content ?? '''At Tech Superior Consulting, we are dedicated to maintaining a professional and respectful workplace. This policy outlines the expectations for all employees to ensure a positive, productive, and secure work environment.

Our Commitment:
• Honesty, integrity, accountability, teamwork, transparency, and ethical behavior
• Maintaining a safe and positive work environment
• Adherence to company guidelines and policies
• Respect for colleagues and professional conduct

Confidentiality:
• Protection of confidential information and client data
• Strict prohibition against unauthorized sharing of sensitive information
• Safeguarding internal documents and company resources

Asset Usage:
• Responsible usage of company assets (laptops, access cards, digital systems)
• Adherence to defined work hours, attendance rules, and leave policies
• Responsible performance of remote work with secure access to company systems

Consequences:
• Corrective action for misuse of company equipment
• Disciplinary action for violation of IT security standards
• Company's right to take action for policy violations

By acknowledging this policy, you agree to uphold company values and contribute to a productive, secure, and supportive workplace.''';
  }
}

