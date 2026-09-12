import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'avatar_choice.dart';
import 'user_profile_notifier.dart';

final avatarChoiceStoreProvider = Provider<AvatarChoiceStore>(
  (ref) => const AvatarChoiceStore(),
);

final avatarChoiceProvider =
    NotifierProvider<AvatarChoiceNotifier, AvatarChoice>(
  AvatarChoiceNotifier.new,
);

class AvatarChoiceNotifier extends Notifier<AvatarChoice> {
  @override
  AvatarChoice build() {
    final gender = ref.watch(userGenderProvider);
    final fallback = AvatarChoice.fromGender(gender);
    Future.microtask(_hydrate);
    return fallback;
  }

  Future<void> _hydrate() async {
    try {
      final stored = await ref.read(avatarChoiceStoreProvider).read();
      if (stored == null) return;
      if (stored.presetId == state.presetId &&
          stored.photoBase64 == state.photoBase64) {
        return;
      }
      state = stored;
    } catch (e) {
      debugPrint('AvatarChoice hydrate: $e');
    }
  }

  Future<void> selectPreset(String presetId) async {
    final next = AvatarChoice(presetId: presetId);
    state = next;
    if (presetId == AvatarChoice.maleId || presetId == AvatarChoice.femaleId) {
      try {
        await ref.read(userProfileNotifierProvider.notifier).updateGender(
              presetId,
            );
      } catch (_) {}
    }
    await _persist(next);
  }

  Future<bool> pickGalleryPhoto({ImagePicker? picker}) async {
    final granted = await _ensureGalleryPermission();
    if (!granted) return false;
    try {
      final file = await (picker ?? ImagePicker()).pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 72,
      );
      if (file == null) return false;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return false;
      final next = AvatarChoice(
        presetId: AvatarChoice.photoId,
        photoBase64: base64Encode(bytes),
      );
      state = next;
      await _persist(next);
      return true;
    } catch (e) {
      debugPrint('AvatarChoice pickGalleryPhoto: $e');
      return false;
    }
  }

  Future<void> _persist(AvatarChoice choice) async {
    try {
      await ref.read(avatarChoiceStoreProvider).write(choice);
    } catch (e) {
      debugPrint('AvatarChoice persist: $e');
    }
  }

  static Future<bool> _ensureGalleryPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status = await Permission.photos.request();
        return status.isGranted || status.isLimited;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        final photos = await Permission.photos.request();
        if (photos.isGranted || photos.isLimited) return true;
        final storage = await Permission.storage.request();
        return storage.isGranted || storage.isLimited;
      }
      return true;
    } catch (e) {
      debugPrint('AvatarChoice gallery permission: $e');
      // Photo picker on modern Android often works without a runtime grant.
      return true;
    }
  }
}
