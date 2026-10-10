/// Copy and decisions for background run recording. No plugins.
const runRecordingNotificationTitle = '쉐어런 · 달리기 기록 중';

const interruptedRunTitle = '이전 달리기가 중단되었습니다';

const interruptedRunBody =
    '앱이 중간에 종료되어 직전 달리기는 저장되지 않았습니다. '
    '보상은 지급되지 않고, 기록도 남지 않습니다.';

const recordingMayStopWarning = '화면이 꺼지면 달리기 기록이 중단될 수 있습니다.';

const runRecordingChecklistMenuLabel = '달리기 기록 설정 점검';

const runRecordingBatteryGuidance =
    "시스템 배터리 최적화 화면에서 쉐어런을 찾아 주세요. "
    "삼성 갤럭시는 '제한 없음'으로 바꿔 주세요.";

const runChecklistCompletedKey = 'src_run_checklist_done';

const runRecordingActiveKey = 'src_run_recording_active';

/// Ongoing notification line. Hours appear only after 60 minutes.
String runRecordingNotificationBody({
  required int elapsedSeconds,
  required double distanceKm,
}) {
  final seconds = elapsedSeconds < 0 ? 0 : elapsedSeconds;
  final km = !distanceKm.isFinite || distanceKm < 0 ? 0.0 : distanceKm;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  final clock = hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}'
      : '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
  return '$clock · ${km.toStringAsFixed(2)} km';
}

/// Warn only when a run is about to start and a needed item is still off.
bool shouldWarnRunMayStop({
  required bool beforeRun,
  required bool locationReady,
  required bool notificationReady,
  required bool batteryReady,
}) {
  if (!beforeRun) return false;
  return !locationReady || !notificationReady || !batteryReady;
}
