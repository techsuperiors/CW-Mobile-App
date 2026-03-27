import 'package:flutter/material.dart';
import '../../domain/models/employee_agreement_model.dart';
import 'common_agreement_detail_page.dart';

/// Employee Agreement detail page showing full agreement content and signature
class EmployeeAgreementDetailPage extends StatefulWidget {
  final EmployeeAgreementModel agreement;

  const EmployeeAgreementDetailPage({super.key, required this.agreement});

  @override
  State<EmployeeAgreementDetailPage> createState() =>
      _EmployeeAgreementDetailPageState();
}

class _EmployeeAgreementDetailPageState
    extends State<EmployeeAgreementDetailPage> {
  @override
  Widget build(BuildContext context) {
    return CommonAgreementDetailPage(
      agreementId: widget.agreement.id,
      agreementName: widget.agreement.agreementName,
      status: widget.agreement.status,
      content: widget.agreement.content,
      signatureUrl: widget.agreement.signatureUrl,
      documentUrl: widget.agreement.documentUrl,
    );
  }
}
