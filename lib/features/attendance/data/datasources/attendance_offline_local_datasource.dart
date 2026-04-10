import 'package:shared_preferences/shared_preferences.dart';

import '../models/offline_attendance_action_model.dart';

abstract class AttendanceOfflineLocalDataSource {
  Future<List<OfflineAttendanceActionModel>> getPendingActions();
  Future<void> addPendingAction(OfflineAttendanceActionModel action);
  Future<void> removePendingAction(String actionId);
  Future<void> updatePendingAction(OfflineAttendanceActionModel action);
  Future<bool> hasPendingActions();
  Future<OfflineAttendanceActionModel?> getLatestPendingAction();
}

class AttendanceOfflineLocalDataSourceImpl
    implements AttendanceOfflineLocalDataSource {
  static const _storageKey = 'attendance_pending_sync_queue_v1';

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  @override
  Future<List<OfflineAttendanceActionModel>> getPendingActions() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <OfflineAttendanceActionModel>[];
    return List<OfflineAttendanceActionModel>.from(
      OfflineAttendanceActionModel.decodeList(raw),
    );
  }

  @override
  Future<void> addPendingAction(OfflineAttendanceActionModel action) async {
    final actions = await getPendingActions();
    actions.add(action);
    actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    await _persist(actions);
  }

  @override
  Future<void> removePendingAction(String actionId) async {
    final actions = await getPendingActions();
    actions.removeWhere((action) => action.id == actionId);
    await _persist(actions);
  }

  @override
  Future<void> updatePendingAction(OfflineAttendanceActionModel action) async {
    final actions = await getPendingActions();
    final index = actions.indexWhere((item) => item.id == action.id);
    if (index == -1) return;
    actions[index] = action;
    await _persist(actions);
  }

  @override
  Future<bool> hasPendingActions() async {
    final actions = await getPendingActions();
    return actions.isNotEmpty;
  }

  @override
  Future<OfflineAttendanceActionModel?> getLatestPendingAction() async {
    final actions = await getPendingActions();
    if (actions.isEmpty) return null;
    actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return actions.last;
  }

  Future<void> _persist(List<OfflineAttendanceActionModel> actions) async {
    final prefs = await _prefs;
    if (actions.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }
    await prefs.setString(
      _storageKey,
      OfflineAttendanceActionModel.encodeList(actions),
    );
  }
}
