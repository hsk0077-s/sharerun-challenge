import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'run_recording_policy.dart';

/// Once, immediately before the first run. Settings can open it again.
Future<void> ensureRunRecordingChecklist(BuildContext context) {
  return _presentRunRecordingChecklist(context, beforeRun: true);
}

Future<void> openRunRecordingChecklist(BuildContext context) {
  return _presentRunRecordingChecklist(context, beforeRun: false);
}

Future<void> _presentRunRecordingChecklist(
  BuildContext context, {
  required bool beforeRun,
}) async {
  if (beforeRun) {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(runChecklistCompletedKey) ?? false) return;
  }
  if (!context.mounted) return;
  final granted = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => RunRecordingChecklistPage(beforeRun: beforeRun),
    ),
  );
  if (granted == null) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(runChecklistCompletedKey, true);
  if (!context.mounted) return;
  if (shouldWarnRunMayStop(
    beforeRun: beforeRun,
    locationReady: granted,
    notificationReady: granted,
    batteryReady: granted,
  )) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(recordingMayStopWarning)),
    );
  }
}

class RunRecordingChecklistPage extends StatefulWidget {
  const RunRecordingChecklistPage({super.key, required this.beforeRun});

  final bool beforeRun;

  @override
  State<RunRecordingChecklistPage> createState() =>
      _RunRecordingChecklistPageState();
}

class _RunRecordingChecklistPageState extends State<RunRecordingChecklistPage>
    with WidgetsBindingObserver {
  var _loading = true;
  var _busy = false;
  var _locationReady = false;
  var _notificationReady = true;
  var _batteryReady = true;
  var _notificationApplies = false;
  var _batteryApplies = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_reload());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_reload());
  }

  Future<void> _reload() async {
    final android = Platform.isAndroid;
    var locationReady = false;
    var notificationReady = true;
    var batteryReady = true;
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      locationReady = serviceOn &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always);
    } catch (error, stack) {
      debugPrint('run checklist location: $error\n$stack');
    }
    if (android) {
      try {
        final status = await FlutterForegroundTask.checkNotificationPermission();
        notificationReady = status == NotificationPermission.granted;
      } catch (error, stack) {
        debugPrint('run checklist notification: $error\n$stack');
        notificationReady = false;
      }
      try {
        batteryReady = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      } catch (error, stack) {
        debugPrint('run checklist battery: $error\n$stack');
        batteryReady = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _locationReady = locationReady;
      _notificationReady = notificationReady;
      _batteryReady = batteryReady;
      _notificationApplies = android;
      _batteryApplies = android;
    });
  }

  Future<void> _onLocation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        await Geolocator.openLocationSettings();
        return;
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (error, stack) {
      debugPrint('run checklist location request: $error\n$stack');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  Future<void> _onNotification() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await Permission.notification.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    } catch (error, stack) {
      debugPrint('run checklist notification request: $error\n$stack');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  Future<void> _onBattery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final opened =
          await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('배터리 설정 화면을 열지 못했습니다.')),
        );
      }
    } catch (error, stack) {
      debugPrint('run checklist battery settings: $error\n$stack');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _close() {
    if (_loading) {
      Navigator.of(context).pop();
      return;
    }
    final ready = _locationReady && _notificationReady && _batteryReady;
    Navigator.of(context).pop(ready);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _locationReady && _notificationReady && _batteryReady;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.settingsBackground,
        appBar: AppBar(
          backgroundColor: AppColors.settingsBackground,
          elevation: 0,
          foregroundColor: AppColors.textBlack,
          title: Text(
            '달리기 기록 설정',
            style: AppTextStyles.header1.copyWith(fontSize: 20),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              '화면을 끄거나 다른 앱을 켜도 경로 기록과 음성 코칭이 이어지도록 아래 항목을 확인해 주세요.',
              style: AppTextStyles.inputText.copyWith(height: 1.45),
            ),
            const SizedBox(height: 16),
            _CheckRow(
              title: '위치 권한',
              body: '앱을 사용하는 동안 허용해 주세요. 항상 허용은 요청하지 않습니다.',
              ready: _locationReady,
              readyLabel: '허용됨',
              actionLabel: '허용하기',
              loading: _loading || _busy,
              onAction: _locationReady ? null : _onLocation,
            ),
            if (_notificationApplies) ...[
              const SizedBox(height: 10),
              _CheckRow(
                title: '알림 권한',
                body: '달리기 기록 알림을 표시합니다. Android 13 이상에서 필요합니다.',
                ready: _notificationReady,
                readyLabel: '허용됨',
                actionLabel: '허용하기',
                loading: _loading || _busy,
                onAction: _notificationReady ? null : _onNotification,
              ),
            ],
            if (_batteryApplies) ...[
              const SizedBox(height: 10),
              _CheckRow(
                title: '배터리 최적화',
                body: runRecordingBatteryGuidance,
                ready: _batteryReady,
                readyLabel: '설정됨',
                actionLabel: '설정 열기',
                loading: _loading || _busy,
                onAction: _batteryReady ? null : _onBattery,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading || _busy ? null : _close,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tealAccent,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(widget.beforeRun ? '확인하고 달리기' : '확인'),
            ),
            if (widget.beforeRun) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading || _busy ? null : _close,
                child: const Text('나중에'),
              ),
            ],
            if (!ready && !_loading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.beforeRun
                      ? '허용하지 않아도 달리기는 시작할 수 있습니다.'
                      : '항목을 나중에 바꿔도 됩니다.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.title,
    required this.body,
    required this.ready,
    required this.readyLabel,
    required this.actionLabel,
    required this.loading,
    required this.onAction,
  });

  final String title;
  final String body;
  final bool ready;
  final String readyLabel;
  final String actionLabel;
  final bool loading;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  ready ? readyLabel : '필요',
                  style: AppTextStyles.caption.copyWith(
                    color: ready ? AppColors.tealAccent : AppColors.textGrey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(body, style: AppTextStyles.caption.copyWith(height: 1.4)),
            if (onAction != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: loading ? null : onAction,
                  child: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
