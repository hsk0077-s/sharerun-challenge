import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'mini_bot_intent.dart';
import 'mini_bot_navigator.dart';
import 'mini_bot_voice.dart';

/// Extra space under the shell mic so it sits fully above the tab bar.
const double miniBotFabBottomClearance = 24;

/// Home tab (0) and challenge lobby tab (2) only. The tab shell owns the
/// button so the screen goldens stay the same.
Widget? miniBotEntryForTab(int index) {
  return switch (index) {
    0 => const Padding(
        padding: EdgeInsets.only(bottom: miniBotFabBottomClearance),
        child: MiniBotEntryButton(
          key: Key('mini-bot-entry-home'),
          heroTag: 'mini-bot-shell',
        ),
      ),
    2 => const Padding(
        padding: EdgeInsets.only(bottom: miniBotFabBottomClearance),
        child: MiniBotEntryButton(
          key: Key('mini-bot-entry-lobby'),
          heroTag: 'mini-bot-shell',
        ),
      ),
    _ => null,
  };
}

class MiniBotEntryButton extends StatelessWidget {
  const MiniBotEntryButton({
    super.key,
    required this.heroTag,
  });

  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return FloatingActionButton.small(
      heroTag: heroTag,
      tooltip: '미니봇',
      backgroundColor: tokens.colors.primary,
      foregroundColor: tokens.colors.onPrimary,
      onPressed: () => MiniBotSheet.show(context),
      child: const Icon(Icons.mic_none_rounded),
    );
  }
}

class _MiniBotLine {
  const _MiniBotLine({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}

class MiniBotSheet extends StatefulWidget {
  const MiniBotSheet({
    super.key,
    this.hostContext,
    this.voice,
    this.speech,
    this.onExecute,
  });

  /// Context that stays mounted after the sheet closes, used for navigation.
  final BuildContext? hostContext;

  final MiniBotVoice? voice;
  final MiniBotSpeechToText? speech;

  /// When set, confirm calls this instead of navigating. Tests use it.
  final void Function(MiniBotRead read)? onExecute;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MiniBotSheet(hostContext: context),
    );
  }

  @override
  State<MiniBotSheet> createState() => _MiniBotSheetState();
}

class _MiniBotSheetState extends State<MiniBotSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final MiniBotVoice _voice;
  late final MiniBotSpeechToText _speech;
  late final bool _ownsVoice;

  final _lines = <_MiniBotLine>[];
  MiniBotRead? _pending;

  @override
  void initState() {
    super.initState();
    _ownsVoice = widget.voice == null;
    _voice = widget.voice ?? FlutterTtsMiniBotVoice();
    _speech = widget.speech ?? const MiniBotSpeechToTextHook();
    _lines.add(const _MiniBotLine(text: MiniBotCopy.greeting, fromUser: false));
    unawaited(_voice.speak(MiniBotCopy.greeting));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    if (_ownsVoice) {
      unawaited(_voice.dispose());
    } else {
      unawaited(_voice.stop());
    }
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _submit(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    final read = MiniBotInterpreter.interpret(text);
    setState(() {
      _lines.add(_MiniBotLine(text: text, fromUser: true));
      _pending = read.awaitsConfirm ? read : null;
      _lines.add(_MiniBotLine(text: read.reply, fromUser: false));
    });
    unawaited(_voice.speak(read.reply));
    _scrollToEnd();
    _input.clear();
  }

  Future<void> _onMic() async {
    final heard = await _speech.listen();
    if (!mounted) return;
    final text = heard?.trim() ?? '';
    if (text.isEmpty) {
      setState(() {
        _pending = null;
        _lines.add(
          const _MiniBotLine(text: MiniBotCopy.sttUnavailable, fromUser: false),
        );
      });
      unawaited(_voice.speak(MiniBotCopy.sttUnavailable));
      _scrollToEnd();
      return;
    }
    _submit(text);
  }

  void _onCancel() {
    if (_pending == null) return;
    setState(() {
      _pending = null;
      _lines.add(
        const _MiniBotLine(text: MiniBotCopy.cancelled, fromUser: false),
      );
    });
    unawaited(_voice.speak(MiniBotCopy.cancelled));
    _scrollToEnd();
  }

  void _onConfirm() {
    final pending = _pending;
    if (pending == null || !pending.awaitsConfirm) return;
    final executed = MiniBotCopy.executed(pending.destination);
    if (widget.onExecute != null) {
      setState(() {
        _pending = null;
        _lines.add(_MiniBotLine(text: executed, fromUser: false));
      });
      unawaited(_voice.speak(executed));
      _scrollToEnd();
      widget.onExecute!(pending);
      return;
    }
    final host = widget.hostContext;
    if (host == null || !host.mounted) return;
    unawaited(_voice.speak(executed));
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!host.mounted) return;
      MiniBotNavigator.go(host, pending.destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenCap = media.size.height * 0.78;
          final maxHeight = constraints.maxHeight.isFinite
              ? math.min(screenCap, constraints.maxHeight)
              : screenCap;
          return Align(
            alignment: Alignment.bottomCenter,
            child: _sheetBody(
              context,
              tokens: tokens,
              textTheme: textTheme,
              height: maxHeight,
              safeBottom: media.padding.bottom,
            ),
          );
        },
      ),
    );
  }

  Widget _sheetBody(
    BuildContext context, {
    required SrcTokens tokens,
    required TextTheme textTheme,
    required double height,
    required double safeBottom,
  }) {
    return Material(
      key: const Key('mini-bot-sheet'),
      color: tokens.colors.surface,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(tokens.radii.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: tokens.spacing.sm),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.colors.outline,
                  borderRadius: tokens.radii.capsule,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.md,
                tokens.spacing.sm,
                tokens.spacing.xs,
                0,
              ),
              child: Row(
                children: [
                  Icon(Icons.mic_none_rounded, color: tokens.colors.primary),
                  SizedBox(width: tokens.spacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '쉐어런 미니봇',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: tokens.colors.ink,
                          ),
                        ),
                        Text(
                          '안내 → 추천 → 확인 → 실행',
                          style: textTheme.labelSmall?.copyWith(
                            color: tokens.colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('mini-bot-close'),
                    tooltip: '닫기',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: EdgeInsets.all(tokens.spacing.md),
                itemCount: _lines.length,
                itemBuilder: (context, index) {
                  final line = _lines[index];
                  return _Bubble(line: line);
                },
              ),
            ),
            if (_pending != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('mini-bot-cancel'),
                        onPressed: _onCancel,
                        child: const Text('취소'),
                      ),
                    ),
                    SizedBox(width: tokens.spacing.sm),
                    Expanded(
                      child: FilledButton(
                        key: const Key('mini-bot-confirm'),
                        onPressed: _onConfirm,
                        child: const Text('이동하기'),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.md,
                tokens.spacing.sm,
                tokens.spacing.md,
                0,
              ),
              child: SingleChildScrollView(
                key: const Key('mini-bot-chips'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Chip(
                      key: const Key('mini-bot-chip-intro'),
                      label: MiniBotPrompts.intro,
                      onTap: () => _submit(MiniBotPrompts.intro),
                    ),
                    _Chip(
                      key: const Key('mini-bot-chip-join'),
                      label: MiniBotPrompts.joinBeginner,
                      onTap: () => _submit(MiniBotPrompts.joinBeginner),
                    ),
                    _Chip(
                      key: const Key('mini-bot-chip-lobby'),
                      label: MiniBotPrompts.joinLobby,
                      onTap: () => _submit(MiniBotPrompts.joinLobby),
                    ),
                    _Chip(
                      key: const Key('mini-bot-chip-cpr'),
                      label: MiniBotPrompts.cpr,
                      onTap: () => _submit(MiniBotPrompts.cpr),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.md,
                tokens.spacing.sm,
                tokens.spacing.md,
                tokens.spacing.md + safeBottom,
              ),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    key: const Key('mini-bot-mic'),
                    tooltip: '말하기',
                    onPressed: _onMic,
                    icon: const Icon(Icons.mic_rounded),
                  ),
                  SizedBox(width: tokens.spacing.xs),
                  Expanded(
                    child: TextField(
                      key: const Key('mini-bot-input'),
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _submit,
                      decoration: const InputDecoration(
                        hintText: '한글로 말해 주세요',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('mini-bot-send'),
                    tooltip: '보내기',
                    onPressed: () => _submit(_input.text),
                    icon:
                        Icon(Icons.send_rounded, color: tokens.colors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return Padding(
      padding: EdgeInsets.only(right: tokens.spacing.xs),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.line});

  final _MiniBotLine line;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final align = line.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = line.fromUser
        ? tokens.colors.primary
        : tokens.colors.canvas;
    final fg = line.fromUser ? tokens.colors.onPrimary : tokens.colors.ink;
    return Align(
      alignment: align,
      child: Container(
        margin: EdgeInsets.only(bottom: tokens.spacing.xs),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.sm,
          vertical: tokens.spacing.xs,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: tokens.radii.card,
        ),
        child: Text(
          line.text,
          style: textTheme.bodyMedium?.copyWith(color: fg, height: 1.35),
        ),
      ),
    );
  }
}
