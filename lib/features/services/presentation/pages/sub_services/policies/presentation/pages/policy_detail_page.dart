import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/policy_model.dart';
import '../data/policies_remote_data.dart';
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
  late Future<PolicyModel> _policyFuture;
  late final WebViewController _webViewController;
  bool _isHtmlLoading = false;
  bool _isSubmittingAcknowledgment = false;
  String? _loadedHtmlContent;

  @override
  void initState() {
    super.initState();
    _policyFuture = PoliciesRemoteData.getPolicyDetail(widget.policy.id);
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {
                if (!mounted) return;
                setState(() {
                  _isHtmlLoading = false;
                });
              },
            ),
          );
  }

  Future<void> _reloadPolicy() async {
    setState(() {
      _policyFuture = PoliciesRemoteData.getPolicyDetail(widget.policy.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
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
                  "Back",
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
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
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: FutureBuilder<PolicyModel>(
        future: _policyFuture,
        builder: (context, snapshot) {
          final policy = snapshot.data ?? widget.policy;
          final hasEmbeddedScrollableContent =
              policy.isFile ||
              ((policy.htmlContent ?? '').trim().isNotEmpty);

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: MediaQuery.of(context).size.width * 0.12,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reloadPolicy,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (hasEmbeddedScrollableContent) {
            return _buildEmbeddedContentLayout(policy);
          }

          return RefreshIndicator(
            onRefresh: _reloadPolicy,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.01,
              ),
              children: [
                _buildSummaryCard(policy),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildContentCard(policy),
                if (!policy.isAcknowledged) ...[
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildAcknowledgmentSection(policy),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmbeddedContentLayout(PolicyModel policy) {
    final horizontalPadding = MediaQuery.of(context).size.width * 0.01;
    final spacing = MediaQuery.of(context).size.height * 0.02;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, spacing),
          child: _buildSummaryCard(policy),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: _buildContentCard(policy, isExpandedLayout: true),
          ),
        ),
        if (!policy.isAcknowledged)
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                spacing,
              ),
              child: _buildAcknowledgmentSection(policy),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(PolicyModel policy) {
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
                  policy.name,
                  style: AppTextStyles.heading4(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02), // 2% of screen height
          // Assigned By
          _buildSummaryRow(
            context,
            'Assigned By',
            policy.assignedBy,
            policy.assignedByAvatar,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
          // Assigned To
          _buildSummaryRow(
            context,
            'Assigned To',
            policy.assignedTo,
            policy.assignedToAvatar,
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
                  policy.status,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: policy.isAcknowledged
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
                  backgroundImage:
                      avatarPath.startsWith('http')
                          ? NetworkImage(avatarPath)
                          : AssetImage(avatarPath) as ImageProvider,
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

  Widget _buildContentCard(PolicyModel policy, {bool isExpandedLayout = false}) {
    if (policy.isFile && policy.fileUrl != null && policy.fileUrl!.isNotEmpty) {
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
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
        child: isExpandedLayout
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SfPdfViewer.network(policy.fileUrl!),
              )
            : SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SfPdfViewer.network(policy.fileUrl!),
                ),
              ),
      );
    }

    if ((policy.htmlContent ?? '').trim().isNotEmpty) {
      _ensureHtmlLoaded(policy.htmlContent!);
      final webView = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: WebViewWidget(
          controller: _webViewController,
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),
      );
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
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
        child: isExpandedLayout
            ? Stack(
                children: [
                  Positioned.fill(child: webView),
                  if (_isHtmlLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              )
            : SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Stack(
                  children: [
                    Positioned.fill(child: webView),
                    if (_isHtmlLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
      );
    }

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getPolicyContent(policy),
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcknowledgmentSection(PolicyModel policy) {
    final requiresSignature = policy.eConsentRequired;
    final canSubmit =
        _isAgreed &&
        !_isSubmittingAcknowledgment &&
        (!requiresSignature || _signatureBytes != null);

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
          // Signature Preview (if added/already available)
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
          ] else if ((policy.signatureUrl ?? '').isNotEmpty) ...[
            Container(
              height: MediaQuery.of(context).size.height * 0.125,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: policy.signatureUrl!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error_outline),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAgreed
                  && !_isSubmittingAcknowledgment
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
                (_signatureBytes != null || (policy.signatureUrl ?? '').isNotEmpty)
                    ? 'Change Signature'
                    : 'Add Signature',
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          // Submit Acknowledgment Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: canSubmit
                  ? () => _submitAcknowledgment(policy)
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
                _isSubmittingAcknowledgment
                    ? 'Submitting...'
                    : 'Submit Acknowledgment',
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

  Future<void> _loadHtmlContent(String htmlContent) async {
    final htmlDocument = _buildHtmlDocument(htmlContent);
    if (mounted) {
      setState(() {
        _isHtmlLoading = true;
      });
    }
    await _webViewController.loadRequest(
      Uri.dataFromString(
        htmlDocument,
        mimeType: 'text/html',
        encoding: utf8,
      ),
    );
  }

  void _ensureHtmlLoaded(String htmlContent) {
    if (_loadedHtmlContent == htmlContent || _isHtmlLoading) return;
    _loadedHtmlContent = htmlContent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadHtmlContent(htmlContent);
    });
  }

  Future<void> _submitAcknowledgment(PolicyModel policy) async {
    final userId = PoliciesRemoteData.resolveUserId();
    if (userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to resolve current user. Please login again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingAcknowledgment = true;
    });

    try {
      String signatureUrl = policy.signatureUrl ?? '';
      if (policy.eConsentRequired) {
        final signatureBytes = _signatureBytes;
        if (signatureBytes == null) return;
        signatureUrl = await PoliciesRemoteData.uploadSignature(signatureBytes);
      }

      await PoliciesRemoteData.submitPolicyAcknowledgment(
        policyId: policy.id,
        userId: userId,
        eConsentRequired: policy.eConsentRequired,
        signatureUrl: signatureUrl,
      );

      await _reloadPolicy();
      if (!mounted) return;

      setState(() {
        _isAgreed = false;
        _signatureBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acknowledgment submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAcknowledgment = false;
        });
      }
    }
  }

  String _buildHtmlDocument(String rawHtml) {
    final normalized =
        rawHtml.contains('<!DOCTYPE html>')
            ? rawHtml
            : '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
  </head>
  <body>$rawHtml</body>
</html>
''';

    final withHeadStyle = normalized.replaceFirst(
      '</head>',
      '''
  <base href="https://app.collectivwork.com/">
  <style>
    * {
      box-sizing: border-box;
      max-width: 100%;
    }

    html, body {
      margin: 0;
      padding: 0;
      background: #ffffff !important;
      color: #111111;
      min-height: 100%;
      width: 100%;
      overflow-x: hidden;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.6;
    }

    body {
      padding: 16px;
    }

    img {
      max-width: 100%;
      height: auto;
      display: block;
    }

    table {
      width: 100% !important;
      border-collapse: collapse;
    }
  </style>
</head>''',
    );

    return withHeadStyle.replaceFirst(
      '<body>',
      '<body style="background:#ffffff !important; margin:0; padding:16px;">',
    );
  }

  String _getPolicyContent(PolicyModel policy) {
    return (policy.content != null && policy.content!.trim().isNotEmpty)
        ? policy.content!
        : '''At Tech Superior Consulting, we are dedicated to maintaining a professional and respectful workplace. This policy outlines the expectations for all employees to ensure a positive, productive, and secure work environment.

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
