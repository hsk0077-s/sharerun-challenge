import 'watch_platform.dart';

/// 워치 러닝 한 번의 상태와 숫자. 화면과 동기화 큐가 같은 값을 쓴다.
enum RunPhase { idle, running, paused, finished }

class RunSession {
  RunSession({this.targetKm = 3, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final double targetKm;
  final DateTime Function() _clock;

  RunPhase _phase = RunPhase.idle;
  DateTime? _startedAt;
  DateTime? _endedAt;
  DateTime? _resumedAt;
  Duration _moving = Duration.zero;
  double _distanceKm = 0;
  int _lastHeartRate = 0;
  int _steps = 0;
  final _heartRates = <int>[];
  final _route = <GpsFix>[];
  final _paceSamples = <Map<String, Object>>[];
  double _lastPaceKm = 0;

  RunPhase get phase => _phase;
  DateTime? get startedAt => _startedAt;
  DateTime? get endedAt => _endedAt;
  double get distanceKm => _distanceKm;
  int get lastHeartRate => _lastHeartRate;
  int get steps => _steps;
  List<int> get heartRates => List.unmodifiable(_heartRates);
  List<GpsFix> get route => List.unmodifiable(_route);
  List<Map<String, Object>> get paceSamples => List.unmodifiable(_paceSamples);

  /// 일시정지 시간은 빼고, 실제로 움직인 시간.
  Duration get movingTime {
    if (_phase == RunPhase.running && _resumedAt != null) {
      return _moving + _clock().difference(_resumedAt!);
    }
    return _moving;
  }

  /// km당 초. 거리가 거의 없으면 0.
  int get paceSecondsPerKm {
    if (_distanceKm < 0.01) return 0;
    return (movingTime.inSeconds / _distanceKm).round();
  }

  void start() {
    if (_phase != RunPhase.idle) return;
    _phase = RunPhase.running;
    _startedAt = _resumedAt = _clock();
  }

  void pause() {
    if (_phase != RunPhase.running) return;
    _moving += _clock().difference(_resumedAt!);
    _resumedAt = null;
    _phase = RunPhase.paused;
  }

  void resume() {
    if (_phase != RunPhase.paused) return;
    _resumedAt = _clock();
    _phase = RunPhase.running;
  }

  void finish() {
    if (_phase != RunPhase.running && _phase != RunPhase.paused) return;
    if (_phase == RunPhase.running) {
      _moving += _clock().difference(_resumedAt!);
    }
    _resumedAt = null;
    _endedAt = _clock();
    _phase = RunPhase.finished;
  }

  void addDistance(double km) {
    if (_phase != RunPhase.running || km <= 0 || km.isNaN || km.isInfinite) {
      return;
    }
    _distanceKm += km;
    _samplePace();
  }

  /// 네이티브가 모아 둔 경로로 바꾼다. 같은 점을 두 번 넣지 않는다.
  void replaceRoute(List<GpsFix> fixes) {
    _route
      ..clear()
      ..addAll(fixes.length > 400 ? fixes.sublist(fixes.length - 400) : fixes);
  }

  void _samplePace() {
    if (_phase != RunPhase.running) return;
    if (_distanceKm + 1e-9 < _lastPaceKm + 0.05) return;
    final pace = paceSecondsPerKm;
    if (pace <= 0 || _startedAt == null) return;
    _lastPaceKm = _distanceKm;
    _paceSamples.add({
      'secondsPerKm': pace,
      'recordedAt': _clock().toUtc().toIso8601String(),
    });
  }

  /// 센서가 달리기 시작부터 센 걸음 수(누적). 줄어드는 값은 무시한다.
  void setSteps(int total) {
    if (_phase != RunPhase.running || total <= _steps) return;
    _steps = total;
  }

  void addHeartRate(int bpm) {
    if (_phase != RunPhase.running) return;
    // 센서가 주는 비현실적 값은 버린다.
    if (bpm < 30 || bpm > 230) return;
    _lastHeartRate = bpm;
    _heartRates.add(bpm);
  }
}

/// `5:42` 처럼 km당 페이스를 보여 준다. 값이 없으면 `--:--`.
String formatPace(int secondsPerKm) {
  if (secondsPerKm <= 0 || secondsPerKm >= 60 * 60) return '--:--';
  final m = secondsPerKm ~/ 60;
  final s = secondsPerKm % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatKm(double km) => km.toStringAsFixed(km >= 10 ? 1 : 2);

String formatMinutes(Duration d) => '${d.inMinutes}분';
