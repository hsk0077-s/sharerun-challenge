import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers/app_providers.dart';
import '../../core/strings/app_strings.dart';
import '../../data/repositories/auth_repository.dart';

/// 소셜 로그인으로 새 계정이 생겼다는 사실을, 닉네임 화면 전까지 기억한다.
///
/// 로그인 직후 안내를 보다가 앱이 꺼지면, 다음에 닉네임 시트가 열리기 전에
/// 같은 안내를 다시 보여 주기 위해 폰에 남겨 둔다.
class NewSocialAccountNoticeStore {
  static const uidKey = 'src.auth.pending_new_account_uid';
  static const providerKey = 'src.auth.pending_new_account_provider';

  static Future<void> mark({
    required String uid,
    required String providerName,
  }) async {
    final trimmedUid = uid.trim();
    final trimmedName = providerName.trim();
    if (trimmedUid.isEmpty || trimmedName.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(uidKey, trimmedUid);
      await prefs.setString(providerKey, trimmedName);
    } catch (e) {
      debugPrint('new social account notice mark: $e');
    }
  }

  /// 이 uid로 로그인한 새 계정이면 제공자 이름(카카오, 네이버). 아니면 null.
  static Future<String?> pendingProvider(String uid) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(uidKey) != trimmedUid) return null;
      final name = prefs.getString(providerKey)?.trim() ?? '';
      return name.isEmpty ? null : name;
    } catch (e) {
      debugPrint('new social account notice read: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(uidKey);
      await prefs.remove(providerKey);
    } catch (e) {
      debugPrint('new social account notice clear: $e');
    }
  }
}

/// 새 소셜 계정 안내. 이어가면 true, 다른 방법으로 로그인(로그아웃)하면 false.
/// 바깥을 누르거나 뒤로 가도 로그아웃으로 본다.
Future<bool> showNewSocialAccountNotice(
  BuildContext context, {
  required String providerName,
}) async {
  final proceed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          Navigator.of(dialogContext).pop(false);
        },
        child: AlertDialog(
          key: const Key('new-social-account-notice'),
          title: const Text(AppStrings.newSocialAccountTitle),
          content: Text(AppStrings.newSocialAccountBody(providerName)),
          actions: [
            TextButton(
              key: const Key('new-social-account-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.newSocialAccountCancel),
            ),
            FilledButton(
              key: const Key('new-social-account-continue'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.newSocialAccountContinue),
            ),
          ],
        ),
      );
    },
  );
  return proceed == true;
}

/// 안내에서 다른 방법으로 로그인하기로 한 뒤. Firebase 세션과 폰에 남긴
/// 로그인 기억을 지운다. 새 계정 안내는 그 uid에 남겨 둔다. 같은 계정으로
/// 다시 들어오면 닉네임 전에 한번 더 보여 준다. 이메일로 계정을 합치지는 않는다.
Future<void> signOutAfterNewSocialAccountCancel(WidgetRef ref) async {
  try {
    await ref.read(authRepositoryProvider).signOut();
  } catch (e) {
    debugPrint('new social account cancel signOut: $e');
  }
  try {
    await ref.read(localAuthStoreProvider).clear();
  } catch (e) {
    debugPrint('new social account cancel clear: $e');
  }
  ref.read(persistedAuthSessionProvider.notifier).replace(null);
}
