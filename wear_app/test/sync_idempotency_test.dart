import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/core/sync_uploader.dart';
import 'package:share_run_wear/core/watch_account.dart';
import 'package:share_run_wear/core/watch_platform.dart';

class _ScriptedPoster implements JsonPoster {
  final List<HttpReply> _validate = [];
  final postedIds = <String>[];
  bool throwValidate = false;

  void validateReplies(List<HttpReply> replies) => _validate
    ..clear()
    ..addAll(replies);

  @override
  Future<HttpReply> post(
    Uri uri,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    if (uri.path == '/auth/watch-pair') {
      return const HttpReply(200, {
        'uid': 'u1',
        'nickname': '달림이',
        'custom_token': 'custom-1',
      });
    }
    if (uri.toString().contains('signInWithCustomToken')) {
      return const HttpReply(200, {
        'idToken': 'id-1',
        'refreshToken': 'refresh-1',
        'expiresIn': '3600',
      });
    }
    if (uri.path == '/actions/runs/validate') {
      postedIds.add(body['activity_id']! as String);
      if (throwValidate) throw Exception('offline');
      if (_validate.isEmpty) return const HttpReply(503, {});
      return _validate.length > 1 ? _validate.removeAt(0) : _validate.first;
    }
    return const HttpReply(404, {});
  }
}

class _HoldingPoster implements JsonPoster {
  _HoldingPoster(this.inner);

  final _ScriptedPoster inner;
  final entered = Completer<void>();
  final release = Completer<void>();
  var validatePosts = 0;

  @override
  Future<HttpReply> post(
    Uri uri,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    if (uri.path == '/actions/runs/validate') {
      validatePosts++;
      if (!entered.isCompleted) entered.complete();
      await release.future;
    }
    return inner.post(uri, body, headers: headers);
  }
}

PendingRun _run(String id) => PendingRun(
      activityId: id,
      distanceKm: 2.5,
      durationSeconds: 900,
      heartRates: const [142],
      startedAt: DateTime.utc(2026, 10, 25, 9),
      endedAt: DateTime.utc(2026, 10, 25, 9, 15),
    );

Future<WatchAccount> _paired(JsonPoster poster) async {
  final account = WatchAccount(
    store: MemoryStore(),
    poster: poster,
    baseUrl: 'https://api.test',
    apiKey: 'key',
  );
  await account.pair('482910');
  return account;
}

void main() {
  test('offline keeps every run and the retry uses the same activity id', () async {
    final poster = _ScriptedPoster()..throwValidate = true;
    final account = await _paired(poster);
    final queue = SyncQueue()
      ..add(_run('run-1'))
      ..add(_run('run-2'));
    final uploader = SyncUploader(account: account, queue: queue);

    expect(await uploader.flush(), 0);
    expect(queue.runs.map((r) => r.activityId), ['run-1', 'run-2']);
    expect(poster.postedIds, ['run-1']);

    poster.throwValidate = false;
    poster.validateReplies(const [HttpReply(200, {}), HttpReply(200, {})]);
    expect(await uploader.flush(), 2);
    expect(queue.length, 0);
    expect(poster.postedIds, ['run-1', 'run-1', 'run-2']);
  });

  test('a duplicate enqueue is not posted twice', () async {
    final poster = _ScriptedPoster()
      ..validateReplies(const [HttpReply(200, {})]);
    final account = await _paired(poster);
    final queue = SyncQueue();
    expect(queue.add(_run('run-1')), isTrue);
    expect(queue.add(_run('run-1')), isFalse);
    final uploader = SyncUploader(account: account, queue: queue);

    expect(await uploader.flush(), 1);
    expect(await uploader.flush(), 0);
    expect(poster.postedIds, ['run-1']);
  });

  test('409 drops the run and 503 stops the queue for a later retry', () async {
    final poster = _ScriptedPoster()
      ..validateReplies(const [
        HttpReply(200, {}),
        HttpReply(409, {'detail': 'already'}),
        HttpReply(503, {}),
      ]);
    final account = await _paired(poster);
    final queue = SyncQueue()
      ..add(_run('ok'))
      ..add(_run('dup'))
      ..add(_run('down'))
      ..add(_run('later'));
    final uploader = SyncUploader(account: account, queue: queue);

    expect(await uploader.flush(), 2);
    expect(queue.runs.map((r) => r.activityId), ['down', 'later']);
    expect(poster.postedIds, ['ok', 'dup', 'down']);

    poster.validateReplies(const [HttpReply(200, {}), HttpReply(200, {})]);
    expect(await uploader.flush(), 2);
    expect(queue.length, 0);
    expect(poster.postedIds, ['ok', 'dup', 'down', 'down', 'later']);
  });

  test('429 keeps the rate-limited run and does not send the one after it', () async {
    final poster = _ScriptedPoster()
      ..validateReplies(const [HttpReply(429, {})]);
    final account = await _paired(poster);
    final queue = SyncQueue()
      ..add(_run('first'))
      ..add(_run('second'));
    final uploader = SyncUploader(account: account, queue: queue);

    expect(await uploader.flush(), 0);
    expect(queue.runs.map((r) => r.activityId), ['first', 'second']);
    expect(poster.postedIds, ['first']);
  });

  test('a saved queue retries the same id after a restart', () async {
    final store = MemoryStore();
    final queue = SyncQueue()..add(_run('saved-1'));
    await QueueStore(store).save(queue);

    final restored = await QueueStore(store).load();
    final poster = _ScriptedPoster()
      ..validateReplies(const [HttpReply(200, {})]);
    final account = await _paired(poster);
    final uploader = SyncUploader(account: account, queue: restored);

    expect(await uploader.flush(), 1);
    expect(poster.postedIds, ['saved-1']);
    expect(restored.length, 0);
  });

  test('two flushes of the same queue cannot post one run twice', () async {
    final inner = _ScriptedPoster()
      ..validateReplies(const [HttpReply(200, {})]);
    final poster = _HoldingPoster(inner);
    final account = await _paired(poster);
    final queue = SyncQueue()..add(_run('only'));
    final first = SyncUploader(account: account, queue: queue);
    final second = SyncUploader(account: account, queue: queue);

    final pending = first.flush();
    await poster.entered.future;
    expect(await second.flush(), 0);
    expect(poster.validatePosts, 1);
    poster.release.complete();
    expect(await pending, 1);
    expect(poster.validatePosts, 1);
    expect(inner.postedIds, ['only']);
    expect(queue.length, 0);
  });
}
