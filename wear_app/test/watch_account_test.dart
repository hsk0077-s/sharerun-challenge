import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/core/sync_uploader.dart';
import 'package:share_run_wear/core/watch_account.dart';
import 'package:share_run_wear/core/watch_platform.dart';

class _Call {
  _Call(this.uri, this.body, this.headers);

  final Uri uri;
  final Map<String, Object?> body;
  final Map<String, String> headers;
}

class _FakePoster implements JsonPoster {
  final calls = <_Call>[];
  final replies = <String, List<HttpReply>>{};
  Object? failWith;

  void on(String part, HttpReply reply) =>
      (replies[part] ??= []).add(reply);

  @override
  Future<HttpReply> post(
    Uri uri,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    calls.add(_Call(uri, body, headers));
    if (failWith != null) throw failWith!;
    for (final entry in replies.entries) {
      if (uri.toString().contains(entry.key) && entry.value.isNotEmpty) {
        return entry.value.length > 1 ? entry.value.removeAt(0) : entry.value.first;
      }
    }
    return const HttpReply(404, {});
  }
}

const _pairedOk = HttpReply(200, {
  'uid': 'u1',
  'nickname': '달림이',
  'custom_token': 'custom-1',
});
const _signedIn = HttpReply(200, {
  'idToken': 'id-1',
  'refreshToken': 'refresh-1',
  'expiresIn': '3600',
});

WatchAccount _account(_FakePoster poster, KeyValueStore store, {DateTime Function()? clock}) =>
    WatchAccount(
      store: store,
      poster: poster,
      baseUrl: 'https://api.test',
      apiKey: 'key',
      clock: clock,
    );

void main() {
  test('a valid code is traded for an account and remembered', () async {
    final poster = _FakePoster()
      ..on('/auth/watch-pair', _pairedOk)
      ..on('signInWithCustomToken', _signedIn);
    final store = MemoryStore();
    final account = _account(poster, store);

    await account.pair('482910');

    expect(account.isPaired, isTrue);
    expect(account.nickname, '달림이');
    expect(poster.calls.first.body['code'], '482910');
    expect(poster.calls.first.body['device_id'], isNotEmpty);
    expect(poster.calls[1].body['token'], 'custom-1');
    expect(store.values['watch.refresh_token'], 'refresh-1');

    final again = _account(_FakePoster(), store);
    await again.load();
    expect(again.isPaired, isTrue);
    expect(again.nickname, '달림이');
  });

  test('a wrong or expired code is refused and nothing is saved', () async {
    final poster = _FakePoster()
      ..on('/auth/watch-pair', const HttpReply(400, {'detail': 'invalid_code'}));
    final store = MemoryStore();
    final account = _account(poster, store);

    await expectLater(account.pair('000000'), throwsA(isA<PairingRejected>()));
    expect(account.isPaired, isFalse);
    expect(store.values.keys, ['watch.device_id']); // 같은 번호로 다시 연결하려고 남긴다
    await expectLater(account.pair('12'), throwsA(isA<PairingRejected>()));
  });

  test('no network or no server settings is reported as unavailable', () async {
    final poster = _FakePoster()..failWith = Exception('offline');
    await expectLater(
      _account(poster, MemoryStore()).pair('482910'),
      throwsA(isA<PairingUnavailable>()),
    );
    final unconfigured = WatchAccount(store: MemoryStore(), baseUrl: '', apiKey: '');
    await expectLater(unconfigured.pair('482910'), throwsA(isA<PairingUnavailable>()));
  });

  test('the ID token is reused until it is about to expire, then refreshed', () async {
    var now = DateTime(2026, 10, 24, 12);
    final poster = _FakePoster()
      ..on('/auth/watch-pair', _pairedOk)
      ..on('signInWithCustomToken', _signedIn)
      ..on('securetoken', const HttpReply(200, {
        'id_token': 'id-2',
        'refresh_token': 'refresh-2',
        'expires_in': '3600',
      }));
    final store = MemoryStore();
    final account = _account(poster, store, clock: () => now);
    await account.pair('482910');

    expect(await account.idToken(), 'id-1');
    now = now.add(const Duration(minutes: 30));
    expect(await account.idToken(), 'id-1');
    now = now.add(const Duration(minutes: 30));
    expect(await account.idToken(), 'id-2');
    expect(store.values['watch.refresh_token'], 'refresh-2');
  });

  test('a revoked refresh token unpairs the watch', () async {
    var now = DateTime(2026, 10, 24, 12);
    final poster = _FakePoster()
      ..on('/auth/watch-pair', _pairedOk)
      ..on('signInWithCustomToken', _signedIn)
      ..on('securetoken', const HttpReply(400, {}));
    final store = MemoryStore();
    final account = _account(poster, store, clock: () => now);
    await account.pair('482910');
    now = now.add(const Duration(hours: 2));

    expect(await account.idToken(), isNull);
    expect(account.isPaired, isFalse);
    expect(store.values.keys, ['watch.device_id']); // 같은 번호로 다시 연결하려고 남긴다
  });

  test('a 401 refreshes the token once and sends the request again', () async {
    final poster = _FakePoster()
      ..on('/auth/watch-pair', _pairedOk)
      ..on('signInWithCustomToken', _signedIn)
      ..on('securetoken', const HttpReply(200, {
        'id_token': 'id-2',
        'expires_in': '3600',
      }))
      ..on('/actions/runs/validate', const HttpReply(401, {}))
      ..on('/actions/runs/validate', const HttpReply(200, {'decision': 'verified'}));
    final account = _account(poster, MemoryStore());
    await account.pair('482910');

    final reply = await account.postSigned('/actions/runs/validate', {'a': 1});
    expect(reply!.ok, isTrue);
    final sent = poster.calls.where((c) => c.uri.path == '/actions/runs/validate');
    expect(sent.map((c) => c.headers['Authorization']), ['Bearer id-1', 'Bearer id-2']);
  });

  test('"disconnect all watches" on the phone unpairs this watch', () async {
    final poster = _FakePoster()
      ..on('/auth/watch-pair', _pairedOk)
      ..on('signInWithCustomToken', _signedIn)
      ..on('/actions/runs/validate', const HttpReply(401, {'detail': 'watch_revoked'}));
    final store = MemoryStore();
    final account = _account(poster, store);
    await account.pair('482910');

    expect(await account.postSigned('/actions/runs/validate', {'a': 1}), isNull);
    expect(account.isPaired, isFalse);
    expect(store.values.keys, ['watch.device_id']);
    // 같은 사유로는 토큰을 다시 받지 않는다.
    expect(poster.calls.where((c) => c.uri.path.contains('securetoken')), isEmpty);
  });

  PendingRun run(String id, {int steps = 5400}) => PendingRun(
        activityId: id,
        distanceKm: 5,
        durationSeconds: 1800,
        heartRates: const [150],
        startedAt: DateTime.utc(2026, 10, 24, 1),
        endedAt: DateTime.utc(2026, 10, 24, 1, 30),
        totalSteps: steps,
      );

  test('the uploaded body carries the watch step total and watch flag', () {
    final body = run('a1').toValidateRunBody();
    expect(body['total_steps'], 5400);
    expect(body['started_at'], '2026-10-24T01:00:00.000Z');
    expect(body['ended_at'], '2026-10-24T01:30:00.000Z');
    expect(body['cadence_spm'], isEmpty);
    expect((body['device_info']! as Map)['watch_used'], isTrue);
    expect(run('a2', steps: 0).toValidateRunBody().containsKey('total_steps'), isFalse);
  });

  test('uploaded and refused runs leave the queue; offline runs stay', () async {
    final poster = _FakePoster()
      ..on('/auth/watch-pair', _pairedOk)
      ..on('signInWithCustomToken', _signedIn)
      ..on('/actions/runs/validate', const HttpReply(200, {}))
      ..on('/actions/runs/validate', const HttpReply(422, {}))
      ..on('/actions/runs/validate', const HttpReply(503, {}));
    final account = _account(poster, MemoryStore());
    await account.pair('482910');
    final queue = SyncQueue()
      ..add(run('a1'))
      ..add(run('a2'))
      ..add(run('a3'));
    var saved = 0;
    final uploader = SyncUploader(
      account: account,
      queue: queue,
      onChanged: () async => saved++,
    );

    expect(await uploader.flush(), 2);
    expect(queue.runs.map((r) => r.activityId), ['a3']);
    expect(saved, 1);
  });

  test('nothing is sent when the watch is not paired', () async {
    final poster = _FakePoster();
    final queue = SyncQueue()..add(run('a1'));
    final uploader = SyncUploader(
      account: _account(poster, MemoryStore()),
      queue: queue,
    );
    expect(await uploader.flush(), 0);
    expect(queue.length, 1);
    expect(poster.calls, isEmpty);
  });

  test('the queue survives a restart with its step totals', () async {
    final store = MemoryStore();
    final queueStore = QueueStore(store);
    final queue = SyncQueue()..add(run('a1', steps: 777));
    await queueStore.save(queue);
    final restored = await QueueStore(store).load();
    expect(restored.runs.single.totalSteps, 777);
    expect(restored.runs.single.activityId, 'a1');
  });

  test('the watch sends the same device id every time it pairs', () async {
    final poster = _FakePoster()
      ..on('/auth/watch-pair', _pairedOk)
      ..on('signInWithCustomToken', _signedIn)
      ..on('/auth/watch-pair', _pairedOk)
      ..on('signInWithCustomToken', _signedIn);
    final store = MemoryStore();
    final account = _account(poster, store);
    await account.pair('482910');
    await account.unpair();
    await account.pair('111111');

    final sent = poster.calls
        .where((c) => c.uri.path == '/auth/watch-pair')
        .map((c) => c.body['device_id'])
        .toList();
    expect(sent.toSet().length, 1);
    expect(sent.first, isA<String>());
  });

  test('a full account tells the person what to do', () async {
    final poster = _FakePoster()
      ..on('/auth/watch-pair', const HttpReply(409, {'detail': 'too_many_watches'}));
    final account = _account(poster, MemoryStore());
    expect(
      () => account.pair('482910'),
      throwsA(isA<PairingRejected>().having((e) => e.message, 'message', 'watch_limit')),
    );
    expect(account.isPaired, isFalse);
  });
}

