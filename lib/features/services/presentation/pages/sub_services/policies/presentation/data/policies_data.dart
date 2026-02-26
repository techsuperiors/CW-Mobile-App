import '../../../../../../../../core/constants/app_assets.dart';
import '../../domain/models/policy_model.dart';

/// Policies data provider - can be replaced with API call
class PoliciesData {
  static List<PolicyModel> getPolicies() {
    return [
      PolicyModel(
        id: 1,
        name: 'System Lock Policy',
        assignedBy: 'Riya Rawat',
        assignedByAvatar: AppAssets.placeholderAvatar,
        assignedTo: 'Riya Rawat',
        assignedToAvatar: AppAssets.placeholderAvatar,
        assignedDate: '16/07/2025',
        status: 'Acknowledged Pending',
        isAcknowledged: false,
        content: '''At Tech Superior Consulting, we are dedicated to maintaining a professional and respectful workplace. This policy outlines the expectations for all employees to ensure a positive, productive, and secure work environment.

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

By acknowledging this policy, you agree to uphold company values and contribute to a productive, secure, and supportive workplace.''',
      ),
      PolicyModel(
        id: 2,
        name: 'Data Encryption Protocol',
        assignedBy: 'Anil Verma',
        assignedByAvatar: AppAssets.placeholderAvatar,
        assignedTo: 'Anil Verma',
        assignedToAvatar: AppAssets.placeholderAvatar,
        assignedDate: '12/08/2025',
        status: 'Acknowledged Pending',
        isAcknowledged: false,
        content: 'Data Encryption Protocol policy content...',
      ),
      PolicyModel(
        id: 3,
        name: 'User Access Review',
        assignedBy: 'Fatima Khan',
        assignedByAvatar: AppAssets.placeholderAvatar,
        assignedTo: 'Fatima Khan',
        assignedToAvatar: AppAssets.placeholderAvatar,
        assignedDate: '22/09/2025',
        status: 'Acknowledged Pending',
        isAcknowledged: false,
        content: 'User Access Review policy content...',
      ),
      PolicyModel(
        id: 4,
        name: 'Incident Response Plan',
        assignedBy: 'Ravi Patel',
        assignedByAvatar: AppAssets.placeholderAvatar,
        assignedTo: 'Ravi Patel',
        assignedToAvatar: AppAssets.placeholderAvatar,
        assignedDate: '05/10/2025',
        status: 'Acknowledged 10/10/2025, 11:00 AM',
        isAcknowledged: true,
        acknowledgedDate: '10/10/2025, 11:00 AM',
        content: 'Incident Response Plan policy content...',
      ),
      PolicyModel(
        id: 5,
        name: 'Backup Policy Review',
        assignedBy: 'Selina Lee',
        assignedByAvatar: AppAssets.placeholderAvatar,
        assignedTo: 'Selina Lee',
        assignedToAvatar: AppAssets.placeholderAvatar,
        assignedDate: '30/11/2025',
        status: 'Acknowledged 01/12/2025, 09:00 AM',
        isAcknowledged: true,
        acknowledgedDate: '01/12/2025, 09:00 AM',
        content: 'Backup Policy Review policy content...',
      ),
    ];
  }
}

