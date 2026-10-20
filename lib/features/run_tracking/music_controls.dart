import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MusicKey { previous, playPause, next }

/// 달리기 중 음악. 앱이 음악을 틀지 않고, 사용자가 쓰는 음악 앱을 조절하거나 연다.
abstract class MusicBridge {
  /// 이 기기에서 조절할 수 있는지(안드로이드만).
  bool get supported;

  /// 지금 재생 중인 앱에 미디어 키를 보낸다. 보냈으면 true.
  Future<bool> send(MusicKey key);

  /// 기기의 기본 음악 앱을 연다. 열었으면 true.
  Future<bool> openApp();
}

class ChannelMusicBridge implements MusicBridge {
  const ChannelMusicBridge();

  static const _channel = MethodChannel('share_run/music');

  @override
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> send(MusicKey key) async {
    if (!supported) return false;
    try {
      final action = switch (key) {
        MusicKey.previous => 'previous',
        MusicKey.playPause => 'playPause',
        MusicKey.next => 'next',
      };
      return await _channel.invokeMethod<bool>('key', {'action': action}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> openApp() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('openApp') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final musicBridgeProvider = Provider<MusicBridge>((ref) => const ChannelMusicBridge());

/// 달리기 화면의 음악 줄. 이전 곡 · 재생/일시정지 · 다음 곡 · 음악 앱 열기.
/// 조절할 수 없는 기기에서는 아무것도 그리지 않는다.
class MusicControls extends ConsumerWidget {
  const MusicControls({super.key});

  static const previousKey = Key('music-previous');
  static const playPauseKey = Key('music-play-pause');
  static const nextKey = Key('music-next');
  static const openKey = Key('music-open');

  Future<void> _tell(BuildContext context, bool ok, String failure) async {
    if (ok || !context.mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bridge = ref.watch(musicBridgeProvider);
    if (!bridge.supported) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    Widget button(Key key, IconData icon, String label, Future<void> Function() onTap) {
      return IconButton(
        key: key,
        tooltip: label,
        iconSize: 30,
        color: scheme.onSurface,
        icon: Icon(icon),
        onPressed: onTap,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        button(previousKey, Icons.skip_previous_rounded, '이전 곡', () async {
          final ok = await bridge.send(MusicKey.previous);
          if (context.mounted) await _tell(context, ok, '음악을 조절하지 못했어요.');
        }),
        button(playPauseKey, Icons.play_circle_fill_rounded, '재생 / 일시정지', () async {
          final ok = await bridge.send(MusicKey.playPause);
          if (context.mounted) await _tell(context, ok, '음악을 조절하지 못했어요.');
        }),
        button(nextKey, Icons.skip_next_rounded, '다음 곡', () async {
          final ok = await bridge.send(MusicKey.next);
          if (context.mounted) await _tell(context, ok, '음악을 조절하지 못했어요.');
        }),
        const SizedBox(width: 12),
        button(openKey, Icons.library_music_rounded, '음악 앱 열기', () async {
          final ok = await bridge.openApp();
          if (context.mounted) {
            await _tell(context, ok, '음악 앱을 찾지 못했어요. 쓰는 음악 앱을 직접 열어 주세요.');
          }
        }),
      ],
    );
  }
}
