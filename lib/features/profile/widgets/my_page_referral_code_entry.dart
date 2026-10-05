import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/constants/economy_constants.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme.dart';

/// Same 7-day window as the server redeem check (`>` 7 days is expired).
bool referralRedeemWindowOpen({
  required DateTime? signedUpAt,
  required DateTime now,
}) {
  if (signedUpAt == null) return false;
  return now.difference(signedUpAt) <= const Duration(days: 7);
}

/// My Page entry under the invite-code card.
///
/// Shown only when this account has no `economy.referredBy` and Auth says
/// the account is still inside the 7-day window.
class MyPageReferralCodeEntry extends ConsumerStatefulWidget {
  const MyPageReferralCodeEntry({super.key});

  static const entryKey = Key('my-page-referral-entry');
  static const fieldKey = Key('my-page-referral-field');
  static const submitKey = Key('my-page-referral-submit');
  static const doneKey = Key('my-page-referral-done');

  @override
  ConsumerState<MyPageReferralCodeEntry> createState() =>
      _MyPageReferralCodeEntryState();
}

class _MyPageReferralCodeEntryState
    extends ConsumerState<MyPageReferralCodeEntry> {
  final _controller = TextEditingController();
  var _busy = false;
  var _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _busy) {
      if (code.isEmpty) _snack(AppStrings.referralRedeemInvalid);
      return;
    }
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    if (uid.isEmpty) {
      _snack(AppStrings.referralRedeemFailed);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(userRepositoryProvider).ensureUserDocument(uid: uid);
      await ref.read(securedActionApiClientProvider).redeemReferralCode(code);
      if (!mounted) return;
      setState(() {
        _done = true;
        _busy = false;
      });
      _snack(AppStrings.referralRedeemSuccess);
    } catch (e, st) {
      debugPrint('MyPageReferralCodeEntry: $e\n$st');
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(ApiErrorMessage.from(e));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final economy = ref.watch(activeUserProfileProvider).value?.economy;
    final referredBy = economy?.referredBy;
    final signedUpAt =
        ref.watch(authStateChangesProvider).value?.metadata.creationTime;
    final hasReferrer = referredBy != null && referredBy.trim().isNotEmpty;
    final runs = (economy?.trialRunCount ?? 0)
        .clamp(0, EconomyConstants.referralTrialRunsRequired);
    final done = _done || hasReferrer;
    final open = referralRedeemWindowOpen(
      signedUpAt: signedUpAt,
      now: DateTime.now(),
    );
    if (!done && !open) return const SizedBox.shrink();

    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(top: tokens.spacing.sm),
      child: done
          ? Text(
              '${AppStrings.referralRedeemDone} · $runs/${EconomyConstants.referralTrialRunsRequired} 런 · 1.1km 이상 달리면 안전해요',
              key: MyPageReferralCodeEntry.doneKey,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: tokens.colors.ink,
              ),
            )
          : Row(
              key: MyPageReferralCodeEntry.entryKey,
              children: [
                Expanded(
                  child: TextField(
                    key: MyPageReferralCodeEntry.fieldKey,
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => unawaited(_submit()),
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.colors.ink,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: AppStrings.referralRedeemEntry,
                      filled: true,
                      fillColor: tokens.colors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: tokens.radii.card,
                        borderSide: BorderSide(color: tokens.colors.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: tokens.radii.card,
                        borderSide: BorderSide(color: tokens.colors.outline),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  key: MyPageReferralCodeEntry.submitKey,
                  onPressed: _busy ? null : () => unawaited(_submit()),
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.colors.accent,
                  ),
                  child: _busy
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.colors.accent,
                          ),
                        )
                      : const Text(AppStrings.referralRedeemSubmit),
                ),
              ],
            ),
    );
  }
}
