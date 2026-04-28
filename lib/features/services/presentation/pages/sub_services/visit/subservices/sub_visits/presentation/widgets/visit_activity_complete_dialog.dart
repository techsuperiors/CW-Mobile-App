import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/visit_model.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import 'visit_activity_capture_dialog.dart';

class VisitActivityCompleteDialog extends StatelessWidget {
  final VisitActivityModel activity;

  const VisitActivityCompleteDialog({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return VisitActivityCaptureDialog(
      activity: activity,
      locationActionLabel: 'capture activity completion location',
      locationRequiredMessage:
          'Location access is needed before completing this activity.',
      selfiePrompt: 'Take a selfie to complete this activity',
      readyBodyKey: 'complete-dialog-body',
      isSubmittingSelector:
          (state, activityId) => state.completingVisitActivityIds.contains(
            activityId,
          ),
      successMessageSelector: (state) => state.completeActivitySuccessMessage,
      errorMessageSelector: (state) => state.completeActivityError,
      lastHandledActivityIdSelector: (state) => state.lastCompletedActivityId,
      onSubmit: (context, activity, location, imageFile) {
        context.read<VisitBloc>().add(
          CompleteVisitActivityRequested(
            CompleteVisitActivityParams(
              activityId: activity.id,
              activityEndLat: location.latitude,
              activityEndLng: location.longitude,
              activityCheckoutSelfiePath: imageFile.path,
            ),
          ),
        );
      },
    );
  }
}
