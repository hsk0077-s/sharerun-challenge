import 'package:flutter/services.dart';

/// Media-volume reading for the in-run coach. Missing data is not muted:
/// a phone without this channel must still coach, and iOS keeps using the
/// ambient TTS category for the hardware silent switch.
class VoiceCoachMuteProbe {
  const VoiceCoachMuteProbe({this.readMediaVolume});

  static const channelName = 'share_run/voice_coach_mute';
  static const channel = MethodChannel(channelName);

  /// Test hook. Production reads [channel].
  final Future<int?> Function()? readMediaVolume;

  Future<bool> isMuted() async {
    try {
      final volume = await _readVolume();
      return voiceCoachOutputMuted(mediaVolume: volume);
    } catch (_) {
      return false;
    }
  }

  Future<int?> _readVolume() async {
    final read = readMediaVolume;
    if (read != null) return read();
    try {
      return await channel.invokeMethod<int>('mediaVolume');
    } catch (_) {
      return null;
    }
  }
}

/// `0` is device-silent (Android media stream). Null means unknown.
bool voiceCoachOutputMuted({required int? mediaVolume}) {
  if (mediaVolume == null) return false;
  return mediaVolume <= 0;
}
