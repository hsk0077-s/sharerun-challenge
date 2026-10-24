import 'sync_queue.dart';
import 'watch_account.dart';
import 'watch_platform.dart';

const _queueKey = 'watch.sync_queue';

/// 대기열을 저장소에 넣고 꺼낸다. 앱을 다시 켜도 올리지 못한 기록이 남는다.
class QueueStore {
  const QueueStore(this._store);

  final KeyValueStore _store;

  Future<SyncQueue> load() async {
    final raw = await _store.read(_queueKey);
    return raw == null ? SyncQueue() : SyncQueue.decode(raw);
  }

  Future<void> save(SyncQueue queue) => _store.write(_queueKey, queue.encode());
}

/// 대기열의 기록을 계정으로 서버에 올린다.
///
/// 서버가 같은 `activity_id`를 한 번만 인정하므로 다시 보내도 중복 지급이 없다.
/// 성공하거나 서버가 "이 본문은 안 된다"(400·409·413·422)고 답한 기록은 뺀다.
/// 네트워크 오류, 로그인 만료, 429, 5xx는 남겨 두었다가 다음에 다시 올린다.
class SyncUploader {
  SyncUploader({required this.account, required this.queue, this.onChanged});

  final WatchAccount account;
  final SyncQueue queue;
  final Future<void> Function()? onChanged;

  var _busy = false;

  /// 이번에 대기열에서 뺀 기록 수.
  Future<int> flush({String? deviceId}) async {
    if (_busy || !account.isPaired) return 0;
    _busy = true;
    var done = 0;
    try {
      for (final run in queue.runs) {
        final reply = await account.postSigned(
          '/actions/runs/validate',
          run.toValidateRunBody(deviceId: deviceId),
        );
        if (reply == null) break; // 연결·로그인 문제: 나머지도 같은 이유로 실패한다.
        if (reply.ok || _final(reply.status)) {
          queue.acknowledge(run.activityId);
          done++;
        } else if (reply.status == 429) {
          break;
        }
      }
      if (done > 0) await onChanged?.call();
    } finally {
      _busy = false;
    }
    return done;
  }

  static bool _final(int status) =>
      status == 400 || status == 409 || status == 413 || status == 422;
}
