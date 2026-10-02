import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_run_challenge/features/pedometer/daily_metrics_account.dart';
import 'package:share_run_challenge/features/pedometer/kst_calendar.dart';
import 'package:share_run_challenge/features/pedometer/pedometer_health_cap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const today = '2026-09-30';
  const yesterday = '2026-09-29';

  setUp(() {
    DailyMetricsAccount.debugReset();
    PedometerHealthCap.forget();
  });

  tearDown(DailyMetricsAccount.debugReset);

  test('empty prefs restore the week and the month cache from the account',
      () async {
    SharedPreferences.setMockInitialValues({});
    DailyMetricsAccount.debugLoad = (_) async => const [
          DailyMetricDoc(dayKey: '2026-08-01', steps: 50, source: 'sensor'),
          DailyMetricDoc(dayKey: '2026-09-01', steps: 900, source: 'sensor'),
          DailyMetricDoc(dayKey: '2026-09-28', steps: 1111, source: 'sensor'),
          DailyMetricDoc(
            dayKey: yesterday,
            steps: 2222,
            source: 'health_connect',
            lastHealth: 2222,
          ),
          DailyMetricDoc(dayKey: today, steps: 3333, source: 'sensor'),
          DailyMetricDoc(dayKey: today, steps: 0, source: 'sensor'),
        ];

    await DailyMetricsAccount.pullIntoPrefs(uid: 'account', todayKey: today);
    final prefs = await SharedPreferences.getInstance();
    final week = KstCalendar.thisWeekDays(DateTime.utc(2026, 9, 30));

    expect(prefs.getInt('2026-08-01_steps'), isNull);
    expect(prefs.getInt('2026-09-01_steps'), 900);
    expect(prefs.getInt('2026-09-28_steps'), 1111);
    expect(prefs.getInt('${yesterday}_steps'), 2222);
    expect(prefs.getInt('${today}_steps'), 3333);
    expect(week.map((day) => day.key),
        containsAll(['2026-09-28', yesterday, today]));
    final history = prefs.getStringList('pedometer_weekly_history') ?? [];
    expect(history, contains('2026-09-28:1111'));
    expect(history, contains('$yesterday:2222'));
    expect(history, contains('$today:3333'));
  });

  test('today takes a larger server value, then stays inside the health cap',
      () async {
    SharedPreferences.setMockInitialValues({
      '${today}_steps': 100,
    });
    DailyMetricsAccount.debugLoad = (_) async => const [
          DailyMetricDoc(dayKey: today, steps: 3333, source: 'sensor'),
        ];
    await DailyMetricsAccount.pullIntoPrefs(uid: 'account', todayKey: today);
    final raised = await SharedPreferences.getInstance();
    expect(raised.getInt('${today}_steps'), 3333);

    DailyMetricsAccount.debugReset();
    PedometerHealthCap.forget();
    SharedPreferences.setMockInitialValues({
      '${today}_steps': 29999,
    });
    DailyMetricsAccount.debugLoad = (_) async => const [
          DailyMetricDoc(
            dayKey: today,
            steps: 4000,
            source: 'health_connect',
            lastHealth: 3900,
          ),
        ];

    await DailyMetricsAccount.pullIntoPrefs(uid: 'account', todayKey: today);
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getInt('${today}_steps'), 4000);
    expect(PedometerHealthCap.fromPrefs(prefs, todayKey: today), 3900);
  });

  test('0 never overwrites a day and a new day does not clobber yesterday',
      () async {
    DailyMetricsAccount.debugUseMemory = true;
    DailyMetricsAccount.debugDocs[yesterday] = const DailyMetricDoc(
      dayKey: yesterday,
      steps: 8000,
      source: 'sensor',
    );

    expect(
      await DailyMetricsAccount.commit(
        uid: 'account',
        todayKey: today,
        dayKey: today,
        steps: 0,
        source: 'sensor',
      ),
      isFalse,
    );
    expect(DailyMetricsAccount.debugDocs.containsKey(today), isFalse);
    expect(DailyMetricsAccount.debugDocs[yesterday]!.steps, 8000);

    expect(
      await DailyMetricsAccount.commit(
        uid: 'account',
        todayKey: today,
        dayKey: today,
        steps: 120,
        source: 'sensor',
      ),
      isTrue,
    );
    expect(DailyMetricsAccount.debugDocs[today]!.steps, 120);
    expect(DailyMetricsAccount.debugDocs[today]!.source, 'sensor');
    expect(DailyMetricsAccount.debugDocs[yesterday]!.steps, 8000);

    expect(
      await DailyMetricsAccount.commit(
        uid: 'account',
        todayKey: today,
        dayKey: yesterday,
        steps: 50,
        source: 'sensor',
      ),
      isFalse,
    );
    expect(DailyMetricsAccount.debugDocs[yesterday]!.steps, 8000);

    expect(
      await DailyMetricsAccount.commit(
        uid: 'account',
        todayKey: today,
        dayKey: yesterday,
        steps: 0,
        source: 'health_connect',
        lastHealth: 3900,
      ),
      isFalse,
    );
    expect(DailyMetricsAccount.debugDocs[yesterday]!.steps, 8000);
    expect(DailyMetricsAccount.debugDocs[yesterday]!.source, 'sensor');
  });

  test('source is recorded and a health heal may lower only today', () async {
    DailyMetricsAccount.debugUseMemory = true;
    DailyMetricsAccount.debugDocs[today] = const DailyMetricDoc(
      dayKey: today,
      steps: 29999,
      source: 'sensor',
    );
    DailyMetricsAccount.debugDocs[yesterday] = const DailyMetricDoc(
      dayKey: yesterday,
      steps: 29999,
      source: 'sensor',
    );

    expect(
      await DailyMetricsAccount.commit(
        uid: 'account',
        todayKey: today,
        dayKey: today,
        steps: 4000,
        source: 'health',
        lastHealth: 3900,
      ),
      isTrue,
    );
    expect(DailyMetricsAccount.debugDocs[today]!.steps, 4000);
    expect(DailyMetricsAccount.debugDocs[today]!.source, 'health_connect');
    expect(DailyMetricsAccount.debugDocs[today]!.lastHealth, 3900);

    expect(
      await DailyMetricsAccount.commit(
        uid: 'account',
        todayKey: today,
        dayKey: yesterday,
        steps: 4000,
        source: 'health_connect',
        lastHealth: 3900,
      ),
      isFalse,
    );
    expect(DailyMetricsAccount.debugDocs[yesterday]!.steps, 29999);
    expect(DailyMetricsAccount.debugDocs[yesterday]!.source, 'sensor');

    expect(
      await DailyMetricsAccount.commit(
        uid: 'account',
        todayKey: today,
        dayKey: today,
        steps: 30001,
        source: 'sensor',
      ),
      isFalse,
    );
    expect(DailyMetricsAccount.debugDocs[today]!.steps, 4000);
  });

  test('empty week days come from health, and 0 does not upload', () async {
    const friday = '2026-10-02';
    SharedPreferences.setMockInitialValues({
      '2026-09-28_steps': 8000,
    });
    DailyMetricsAccount.debugUseMemory = true;
    final asked = <String>[];

    await DailyMetricsAccount.backfillMissingDays(
      uid: 'account',
      todayKey: friday,
      dayKeys: DailyMetricsAccount.weekDaysBefore(friday),
      readSteps: (day) async {
        asked.add(day);
        if (day == '2026-09-30') return 5940;
        if (day == '2026-10-01') return 0;
        return null;
      },
    );

    expect(
      DailyMetricsAccount.weekDaysBefore(friday),
      ['2026-09-28', '2026-09-29', '2026-09-30', '2026-10-01'],
    );
    expect(asked, isNot(contains('2026-09-28')));
    expect(asked, containsAll(['2026-09-29', '2026-09-30', '2026-10-01']));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('2026-09-28_steps'), 8000);
    expect(prefs.getInt('2026-09-30_steps'), 5940);
    expect(prefs.getInt('2026-10-01_steps'), isNull);
    expect(prefs.getInt('${friday}_steps'), isNull);
    expect(DailyMetricsAccount.debugDocs['2026-09-30']!.steps, 5940);
    expect(
      DailyMetricsAccount.debugDocs['2026-09-30']!.source,
      'health_connect',
    );
    expect(DailyMetricsAccount.debugDocs.containsKey('2026-10-01'), isFalse);
    expect(DailyMetricsAccount.debugDocs.containsKey('2026-09-28'), isFalse);
    final history = prefs.getStringList('pedometer_weekly_history') ?? [];
    expect(history, contains('2026-09-30:5940'));
    expect(history, contains('2026-09-28:8000'));
  });
}
