import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../friend_code.dart';
import '../friend_errors.dart';
import '../friends_providers.dart';

Future<void> showFriendAcceptSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const FriendAcceptSheet(),
  );
}

/// Paste the code a friend sent and become friends. The pasted text may be the
/// whole shared message; only the code in it is used.
class FriendAcceptSheet extends ConsumerStatefulWidget {
  const FriendAcceptSheet({super.key});

  static const fieldKey = Key('friend-accept-field');
  static const pasteKey = Key('friend-accept-paste');
  static const submitKey = Key('friend-accept-submit');
  static const errorKey = Key('friend-accept-error');

  @override
  ConsumerState<FriendAcceptSheet> createState() => _FriendAcceptSheetState();
}

class _FriendAcceptSheetState extends ConsumerState<FriendAcceptSheet> {
  final _controller = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text ?? '';
    if (text.isEmpty) return;
    setState(() {
      _controller.text = text;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final token = extractFriendToken(_controller.text);
    if (token == null) {
      // No friend code in the text: nothing is sent to the server.
      setState(() => _error = friendInvalidCodeMessage(context));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final result = await ref.read(friendsApiProvider).accept(token);
      if (!mounted) return;
      ref.invalidate(friendsListProvider);
      setState(() => _busy = false);
      final message = result.alreadyFriends
          ? RemainingSurface.tr(context, 'friends.accept.already', '이미 친구예요.')
          : RemainingSurface.tr(context, 'friends.accept.added', '친구가 됐어요.');
      messenger.showSnackBar(SnackBar(content: Text(message)));
      unawaited(navigator.maybePop());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = friendErrorMessage(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          tokens.spacing.page,
          0,
          tokens.spacing.page,
          tokens.spacing.page + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              RemainingSurface.tr(context, 'friends.enter_code', '친구 코드 입력'),
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: tokens.spacing.sm),
            TextField(
              key: FriendAcceptSheet.fieldKey,
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: RemainingSurface.tr(
                    context, 'friends.accept.hint', '받은 친구 코드를 붙여 넣어 주세요'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              SizedBox(height: tokens.spacing.xs),
              Text(
                _error!,
                key: FriendAcceptSheet.errorKey,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            SizedBox(height: tokens.spacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: FriendAcceptSheet.pasteKey,
                    onPressed: _busy ? null : () => unawaited(_paste()),
                    icon: const Icon(Icons.content_paste),
                    label: Text(RemainingSurface.tr(
                        context, 'friends.accept.paste', '클립보드에서 붙여넣기')),
                  ),
                ),
                SizedBox(width: tokens.spacing.sm),
                Expanded(
                  child: FilledButton(
                    key: FriendAcceptSheet.submitKey,
                    onPressed: _busy ? null : () => unawaited(_submit()),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(RemainingSurface.tr(
                            context, 'friends.accept.submit', '친구 맺기')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
