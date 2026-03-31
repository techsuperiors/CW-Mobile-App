import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../core/constants/app_assets.dart';
import 'request_audience_scope.dart';

class RequestAudienceFilterButton extends StatelessWidget {
  final RequestAudienceScope selectedScope;
  final List<RequestAudienceScope> availableScopes;
  final ValueChanged<RequestAudienceScope> onSelected;

  const RequestAudienceFilterButton({
    super.key,
    required this.selectedScope,
    required this.availableScopes,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RequestAudienceScope>(
      tooltip: 'Filter users',
      onSelected: onSelected,
      itemBuilder:
          (context) =>
              availableScopes.map((scope) {
                return PopupMenuItem<RequestAudienceScope>(
                  value: scope,
                  child: Row(
                    children: [
                      Expanded(child: Text(scope.label)),
                      if (scope == selectedScope)
                        Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                );
              }).toList(),
      child: SvgPicture.asset(AppAssets.filterIcon),
    );
  }
}
