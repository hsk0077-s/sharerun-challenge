import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shown once before a verified room or company race, until the runner opts out.
const verificationGuidanceDismissedKey = 'verification_guidance_dismissed_v1';

/// Company races that require a watch heart-rate sample. Matches server config.
const watchHeartRatePrizeTiers = {'advanced', 'half', 'final'};

bool roomRequiresWatchHeartRate(String prizeTier) {
  return watchHeartRatePrizeTiers.contains(prizeTier.trim().toLowerCase());
}

/// Room target, and never below the 1km verified floor.
double verifiedMinDistanceKm(double roomDistanceKm) {
  if (roomDistanceKm.isNaN || roomDistanceKm < 1) return 1;
  return roomDistanceKm;
}

String formatVerifiedDistanceKm(double roomDistanceKm) {
  final km = verifiedMinDistanceKm(roomDistanceKm);
  final tenths = (km * 10).round() / 10;
  if (tenths == tenths.roundToDouble()) return '${tenths.round()}km';
  return '${tenths.toStringAsFixed(1)}km';
}

class VerificationGuidanceCopy {
  const VerificationGuidanceCopy({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.dismissLabel,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String dismissLabel;
}

VerificationGuidanceCopy verificationGuidanceCopy({
  required double roomDistanceKm,
  required bool requiresHeartRate,
}) {
  final distance = formatVerifiedDistanceKm(roomDistanceKm);
  final lines = <String>[
    '이번 방의 검증 최소 거리는 $distance예요. 방 거리가 더 짧아도 1km는 넘어야 해요.',
    '분당 걸음 수는 120~210이어야 해요.',
    '워치가 없으면 보폭과 GPS 속도로 확인해요.',
    '워치 심박은 회사 대회 상급·하프·파이널에서만 필요해요.',
    if (requiresHeartRate) '이 대회는 워치 심박이 있어야 완주로 인정돼요.',
    '기록은 언제나, 보상은 검증된 달리기에만.',
  ];
  return VerificationGuidanceCopy(
    title: '검증 안내',
    body: lines.join('\n'),
    confirmLabel: '확인하고 참가',
    dismissLabel: '다시 보지 않기',
  );
}

/// True when the runner may continue the join. False cancels before payment.
Future<bool> confirmVerificationGuidance(
  BuildContext context, {
  required double roomDistanceKm,
  required bool requiresHeartRate,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(verificationGuidanceDismissedKey) ?? false) return true;
  if (!context.mounted) return false;

  final copy = verificationGuidanceCopy(
    roomDistanceKm: roomDistanceKm,
    requiresHeartRate: requiresHeartRate,
  );
  var hideForever = false;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(copy.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.body, style: const TextStyle(height: 1.45)),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: hideForever,
                  onChanged: (value) {
                    setLocal(() => hideForever = value ?? false);
                  },
                  title: Text(copy.dismissLabel),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('닫기'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(copy.confirmLabel),
              ),
            ],
          );
        },
      );
    },
  );
  if (accepted != true) return false;
  if (hideForever) {
    await prefs.setBool(verificationGuidanceDismissedKey, true);
  }
  return true;
}
