import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/profile/avatar_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to empty so gender fallback can apply', () async {
    const store = AvatarChoiceStore();
    expect(await store.read(), isNull);
  });

  test('persists a character preset across a fresh store read', () async {
    const store = AvatarChoiceStore();
    await store.write(const AvatarChoice(presetId: 'snail'));

    const restarted = AvatarChoiceStore();
    final stored = await restarted.read();
    expect(stored, isNotNull);
    expect(stored!.presetId, 'snail');
    expect(stored.isPhoto, isFalse);
    expect(AvatarPresets.byId('snail').label, '달팽이');
    expect(AvatarPresets.all.length, greaterThan(2));
  });

  test('persists a gallery photo as cosmetic-only bytes', () async {
    const store = AvatarChoiceStore();
    final bytes = base64Encode(List<int>.generate(16, (i) => i));
    await store.write(
      AvatarChoice(presetId: AvatarChoice.photoId, photoBase64: bytes),
    );

    final stored = await const AvatarChoiceStore().read();
    expect(stored!.isPhoto, isTrue);
    expect(stored.photoBytes, isNotNull);
    expect(stored.photoBytes!.length, 16);
  });
}
