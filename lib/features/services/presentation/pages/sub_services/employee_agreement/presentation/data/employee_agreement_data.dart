import '../../../../../../../../core/constants/app_assets.dart';
import '../../domain/models/employee_agreement_model.dart';

/// Employee Agreement data provider
class EmployeeAgreementData {
  static List<EmployeeAgreementModel> getAgreements() {
    return [
      const EmployeeAgreementModel(
        id: 1,
        employeeName: 'Riya Rawat',
        employeeAvatar: AppAssets.placeholderAvatar,
        agreementType: 'Appointment Letter',
        assignedBy: 'Supriya Singh',
        assignedByAvatar: AppAssets.placeholderAvatar,
        expiryDate: '29/Dec/2025',
        status: 'Sent',
        content: '''Collectivwork
20 Market Hill, South CV47 DHF, United Kingdom

December 29, 2025

Dear Riya Rawat,

We are pleased to offer you the position of Junior Developer at Quantum Leap Technologies. This offer is contingent upon your acceptance and the successful completion of our standard onboarding process.

Position Details:
- Position: Junior Developer
- Start Date: January 8, 2025
- Annual Salary: 60,000, paid bi-weekly

Responsibilities:
- Coding, testing, and debugging software
- Collaborating with other developers and designers
- Participating in code reviews and team meetings

Benefits:
- Comprehensive health, dental, and vision insurance
- 401k plan with company match
- Paid time off
- Opportunities for professional development and advancement

Please confirm your acceptance of this offer by December 1, 2024. We look forward to welcoming you to our team.

Sincerely,
Dr. Evelyn Reed
CEO, Quantum Leap Technologies''',
      ),
      const EmployeeAgreementModel(
        id: 2,
        employeeName: 'Amit Sharma',
        employeeAvatar: AppAssets.placeholderAvatar,
        agreementType: 'Contract',
        assignedBy: 'Rajesh Kumar',
        assignedByAvatar: AppAssets.placeholderAvatar,
        expiryDate: '15/Mar/2026',
        status: 'Sent',
        content: '''Collectivwork
20 Market Hill, South CV47 DHF, United Kingdom

December 29, 2025

Dear Amit Sharma,

We are pleased to offer you a contract position at Quantum Leap Technologies. This contract outlines the terms and conditions of your engagement with our company.

Contract Details:
- Position: Senior Developer
- Contract Duration: 12 months
- Start Date: February 1, 2026
- Monthly Compensation: 8,000

Responsibilities:
- Lead development projects
- Mentor junior developers
- Ensure code quality and best practices

Terms and Conditions:
- This is a fixed-term contract
- All work products are property of the company
- Confidentiality agreement applies

Please review and sign this contract by January 15, 2026.

Sincerely,
Rajesh Kumar
HR Manager, Quantum Leap Technologies''',
      ),
      const EmployeeAgreementModel(
        id: 3,
        employeeName: 'Priya Verma',
        employeeAvatar: AppAssets.placeholderAvatar,
        agreementType: 'Internship',
        assignedBy: 'Maya Singh',
        assignedByAvatar: AppAssets.placeholderAvatar,
        expiryDate: '10/Jun/2024',
        status: 'Sent',
        content: '''Collectivwork
20 Market Hill, South CV47 DHF, United Kingdom

December 29, 2025

Dear Priya Verma,

We are excited to offer you an internship position at Quantum Leap Technologies. This internship will provide you with valuable experience in software development.

Internship Details:
- Position: Software Development Intern
- Duration: 6 months
- Start Date: January 15, 2024
- Stipend: 2,000 per month

Learning Opportunities:
- Work on real-world projects
- Learn from experienced developers
- Attend training sessions and workshops
- Participate in team meetings and code reviews

Please confirm your acceptance by January 5, 2024.

Sincerely,
Maya Singh
Internship Coordinator, Quantum Leap Technologies''',
      ),
      const EmployeeAgreementModel(
        id: 4,
        employeeName: 'Karan Mehta',
        employeeAvatar: AppAssets.placeholderAvatar,
        agreementType: 'Freelance',
        assignedBy: 'Nisha Gupta',
        assignedByAvatar: AppAssets.placeholderAvatar,
        expiryDate: '01/Feb/2023',
        status: 'Sent',
        content: '''Collectivwork
20 Market Hill, South CV47 DHF, United Kingdom

December 29, 2025

Dear Karan Mehta,

We are pleased to engage your services as a freelance developer for Quantum Leap Technologies. This agreement outlines the terms of our working relationship.

Freelance Agreement:
- Project: Mobile App Development
- Duration: 3 months
- Start Date: January 1, 2023
- Payment: 5,000 per month

Scope of Work:
- Develop mobile application features
- Provide regular progress updates
- Deliver completed work on schedule

Payment Terms:
- Payment will be made monthly upon completion of deliverables
- All work products are property of the company

Please sign and return this agreement by December 20, 2022.

Sincerely,
Nisha Gupta
Project Manager, Quantum Leap Technologies''',
      ),
      const EmployeeAgreementModel(
        id: 5,
        employeeName: 'Anita Rao',
        employeeAvatar: AppAssets.placeholderAvatar,
        agreementType: 'Full-time Offer',
        assignedBy: 'Vikram Joshi',
        assignedByAvatar: AppAssets.placeholderAvatar,
        expiryDate: '30/Nov/2025',
        status: 'Sent',
        content: '''Collectivwork
20 Market Hill, South CV47 DHF, United Kingdom

December 29, 2025

Dear Anita Rao,

We are delighted to offer you a full-time position at Quantum Leap Technologies. We believe your skills and experience will be a valuable addition to our team.

Position Details:
- Position: Senior Software Engineer
- Start Date: January 15, 2025
- Annual Salary: 90,000, paid bi-weekly

Responsibilities:
- Design and develop software solutions
- Lead technical projects
- Mentor team members
- Collaborate with cross-functional teams

Benefits Package:
- Comprehensive health, dental, and vision insurance
- 401k plan with company match
- 20 days paid time off
- Flexible working hours
- Professional development budget

Please confirm your acceptance by December 10, 2024.

Sincerely,
Vikram Joshi
CTO, Quantum Leap Technologies''',
      ),
    ];
  }
}

