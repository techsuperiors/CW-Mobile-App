import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/visit_model.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import 'visit_activity_capture_dialog.dart';

class VisitActivityStartDialog extends StatelessWidget {
  final VisitActivityModel activity;

  const VisitActivityStartDialog({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return VisitActivityCaptureDialog(
      activity: activity,
      locationActionLabel: 'capture activity start location',
      locationRequiredMessage:
          'Location access is needed before starting this activity.',
      selfiePrompt: 'Take a selfie to start this activity',
      readyBodyKey: 'start-dialog-body',
      isSubmittingSelector:
          (state, activityId) => state.startingVisitActivityIds.contains(
            activityId,
          ),
      successMessageSelector: (state) => state.startActivitySuccessMessage,
      errorMessageSelector: (state) => state.startActivityError,
      lastHandledActivityIdSelector: (state) => state.lastStartedActivityId,
      onSubmit: (context, activity, location, imageFile) {
        context.read<VisitBloc>().add(
          StartVisitActivityRequested(
            StartVisitActivityParams(
              activityId: activity.id,
              activityStartLat: location.latitude,
              activityStartLng: location.longitude,
              activityCheckinSelfiePath: imageFile.path,
            ),
          ),
        );
      },
    );
  }
}
