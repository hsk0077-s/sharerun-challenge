import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../core/theme/theme.dart';
import '../../app/providers/app_providers.dart';
import '../../data/models/company_tournament_config.dart';
import '../donation/today_donation.dart';
import '../onboarding/src_onboarding_controller.dart' show UserTier;
import '../tournaments/providers/company_tournament_providers.dart';
import 'mini_bot_intent.dart';
import 'mini_bot_navigator.dart';
import 'mini_bot_voice.dart';
import '../snail_faq/snail_faq.dart';
import 'mini_bot_dock.dart';
import 'snail_bot_face.dart';

/// Extra space under the shell mic so it sits fully above the tab bar.
const double miniBotFabBottomClearance = 24;

/// 달팽이봇을 연 화면. 화면마다 추천 질문 칩이 다르다.
enum MiniBotScreen { home, lobby }

/// 달팽이봇 버튼 위에 잠깐 뜨는 한마디. 하루에 하나씩 돌아가며, 봇이 실제로 답할 수 있는 내용만 쓴다.
abstract final class MiniBotBubble {
  static const home = [
    '궁금한 게 있으면 저를 눌러 물어보세요',
    '오늘 목표나 SHARE가 궁금하면 물어보세요',
    '기록 지키기가 헷갈리면 제가 알려 드려요',
  ];
  static const lobby = [
    '어떤 챌린지가 맞는지 모르겠으면 물어보세요',
    '참가비와 순위별 상금이 궁금하면 눌러 보세요',
    '초급은 무료인지도 알려 드려요',
  ];

  static String forScreen(MiniBotScreen screen, DateTime now) {
    final list = screen == MiniBotScreen.home ? home : lobby;
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return list[dayOfYear % list.length];
  }
}

/// 화면별 추천 질문. FAQ id로 가리키고 글자는 FAQ에서 가져온다.
abstract final class MiniBotFaqChips {
  static const home = ['DO-03', 'SH-05', 'GR-07', 'SH-03'];
  static const lobby = ['CO-01', 'CO-02', 'CO-08', 'CO-03'];

  static List<String> forScreen(MiniBotScreen screen) =>
      screen == MiniBotScreen.lobby ? lobby : home;

  /// 칩에 보여 줄 짧은 이름. 누르면 FAQ의 원래 질문이 그대로 전달된다.
  static const shortLabels = {
    'DO-03': '오늘 내 기부',
    'SH-05': '내 SHARE',
    'GR-07': '내 등급',
    'SH-03': '하루 SHARE 한도',
    'CO-01': '어떤 대회?',
    'CO-02': '참가비',
    'CO-08': '순위별 상금',
    'CO-03': '초급은 무료?',
  };
}

/// Home tab (0) and challenge lobby tab (2) only. The tab shell owns the
/// button so the screen goldens stay the same.
Widget? miniBotEntryForTab(int index) {
  return switch (index) {
    0 => const Padding(
        padding: EdgeInsets.only(bottom: miniBotFabBottomClearance),
        child: MiniBotEntryButton(
          key: Key('mini-bot-entry-home'),
          heroTag: 'mini-bot-shell',
          screen: MiniBotScreen.home,
        ),
      ),
    2 => const Padding(
        padding: EdgeInsets.only(bottom: miniBotFabBottomClearance),
        child: MiniBotEntryButton(
          key: Key('mini-bot-entry-lobby'),
          heroTag: 'mini-bot-shell',
          screen: MiniBotScreen.lobby,
        ),
      ),
    _ => null,
  };
}

class MiniBotEntryButton extends StatelessWidget {
  const MiniBotEntryButton({
    super.key,
    required this.heroTag,
    this.screen = MiniBotScreen.home,
  });

  final Object heroTag;
  final MiniBotScreen screen;

  /// 얼굴 버튼 크기. 둥근 테두리까지 그림에 들어 있다.
  static const double faceSize = MiniBotDockMath.size;

  @override
  Widget build(BuildContext context) {
    return MiniBotDock(
      onOpen: () => MiniBotSheet.show(context, screen: screen),
      message: MiniBotBubble.forScreen(screen, DateTime.now()),
      messageId: screen.name,
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
    this.prizeConfig,
    this.faq,
    this.faqValues = const {},
    this.screen = MiniBotScreen.home,
  });

  /// 열 때 서버에서 확인된 내 값(SHARE 잔액 등). 없는 값은 지어내지 않는다.
  final Map<String, String> faqValues;

  /// 이 화면에 맞는 추천 질문 칩을 고른다.
  final MiniBotScreen screen;

  /// 미리 써 둔 FAQ. 비워 두면 앱에 든 파일을 읽는다. 시험에서 바꿔 끼운다.
  final SnailFaq? faq;

  /// Context that stays mounted after the sheet closes, used for navigation.
  final BuildContext? hostContext;

  final MiniBotVoice? voice;
  final MiniBotSpeechToText? speech;

  /// When set, confirm calls this instead of navigating. Tests use it.
  final void Function(MiniBotRead read)? onExecute;

  /// Server prize-race fees. Null until config has loaded.
  final CompanyTournamentConfig? prizeConfig;

  static Future<void> show(
    BuildContext context, {
    MiniBotScreen screen = MiniBotScreen.home,
  }) {
    CompanyTournamentConfig? prizeConfig;
    try {
      prizeConfig = ProviderScope.containerOf(context, listen: false)
          .read(companyTournamentConfigProvider)
          .asData
          ?.value;
    } catch (_) {
      prizeConfig = null;
    }
    final values = _confirmedValues(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MiniBotSheet(
        hostContext: context,
        prizeConfig: prizeConfig,
        faqValues: values,
        screen: screen,
      ),
    );
  }

  /// 서버가 확인해 앱에 내려온 값만 모은다. 아직 못 받은 값은 넣지 않는다.
  static Map<String, String> _confirmedValues(BuildContext context) {
    final values = <String, String>{};
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final wallet = container.read(activeWalletProvider).asData?.value;
      if (wallet != null) {
        values['SHARE잔액'] = _grouped(wallet.shareBalance);
        values['VALUE잔액'] = _grouped(wallet.valueTokenBalance);
      }
      final profile = container.read(activeUserProfileProvider).asData?.value;
      if (profile != null) {
        final tier = UserTier.tryFromRankScore(profile.gradeRank) ??
            UserTier.unratedFallback;
        values['등급'] = tier.koreanName;
      }
      final donation = container.read(todayDonationProvider).asData?.value;
      if (donation != null) values['오늘기부기여'] = _grouped(donation.todayWon);
    } catch (_) {}
    return values;
  }

  static String _grouped(int value) {
    final text = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
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
  SnailFaq? _faq;
  var _mood = SnailBotMood.smiling;

  final _lines = <_MiniBotLine>[];
  MiniBotRead? _pending;
  var _listening = false;

  @override
  void initState() {
    super.initState();
    _ownsVoice = widget.voice == null;
    _voice = widget.voice ?? FlutterTtsMiniBotVoice();
    _speech = widget.speech ?? MiniBotSpeechToTextHook();
    _lines.add(const _MiniBotLine(text: MiniBotCopy.greeting, fromUser: false));
    unawaited(_voice.speak(MiniBotCopy.greeting));
    _faq = widget.faq;
    if (_faq == null) unawaited(_loadFaq());
  }

  Future<void> _loadFaq() async {
    try {
      final faq = await SnailFaq.load();
      if (mounted) setState(() => _faq = faq);
    } catch (error) {
      debugPrint('mini-bot faq: $error');
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    unawaited(_speech.stop());
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
    if (_listening) unawaited(_speech.stop());
    final faq = _faq;
    final faqHit = faq?.matchScored(text);
    // FAQ에 적어 둔 질문과 거의 같은 말은 이동·결제 해석보다 FAQ가 먼저 답한다.
    // (예: "대회 참가비는 얼마예요?"를 "참가하기"로 오해하지 않게.)
    final strongFaq =
        faqHit != null && faqHit.score >= SnailFaq.strongScore ? faqHit : null;
    final read = strongFaq != null
        ? MiniBotRead(
            intent: MiniBotIntent.unknown,
            destination: MiniBotDestination.none,
            reply: strongFaq.entry.answer,
            needsConfirm: false,
          )
        : MiniBotInterpreter.interpret(
            text,
            prizeConfig: widget.prizeConfig,
          );
    final shown = !AppEnv.inAppPurchasesEnabled &&
            MiniBotRoutes.isPurchaseDestination(read.destination)
        ? MiniBotRead(
            intent: read.intent,
            destination: MiniBotDestination.none,
            reply: '이 버전에서는 앱 안에서 결제하지 않아요.',
            needsConfirm: false,
          )
        : read;
    // 그 밖의 이동·결제로 이어지는 말은 기존 확인 흐름이 먼저다. 나머지 질문은 FAQ가 답한다.
    var reply = shown.reply;
    var mood = SnailBotMood.smiling;
    if (shown.intent == MiniBotIntent.unknown) {
      final match = strongFaq?.entry ?? faq?.match(text);
      if (match != null) {
        reply = SnailFaq.answerFor(match, widget.faqValues);
        mood = reply == SnailFaq.valueUnavailable
            ? SnailBotMood.disappointed
            : SnailBotMood.joy;
      } else {
        reply = faq?.fallbackAnswer ?? read.reply;
        mood = SnailBotMood.disappointed;
      }
    }
    setState(() {
      _mood = mood;
      _lines.add(_MiniBotLine(text: text, fromUser: true));
      _pending = shown.awaitsConfirm ? shown : null;
      _lines.add(_MiniBotLine(text: reply, fromUser: false));
    });
    unawaited(_voice.speak(reply));
    _scrollToEnd();
    _input.clear();
  }

  void _reply(String text, {bool clearPending = false}) {
    setState(() {
      _mood = SnailBotMood.disappointed;
      if (clearPending) _pending = null;
      _lines.add(_MiniBotLine(text: text, fromUser: false));
    });
    unawaited(_voice.speak(text));
    _scrollToEnd();
  }

  Future<void> _onMic() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    setState(() {
      _listening = true;
      _mood = SnailBotMood.listening;
    });
    await _voice.stop();
    if (!mounted) return;
    MiniBotListen heard;
    try {
      heard = await _speech.listen();
    } catch (error) {
      debugPrint('mini-bot mic: $error');
      heard = const MiniBotListen.unavailable();
    }
    if (!mounted) return;
    setState(() {
      _listening = false;
      if (_mood == SnailBotMood.listening) _mood = SnailBotMood.smiling;
    });
    switch (heard.kind) {
      case MiniBotListenKind.cancelled:
        return;
      case MiniBotListenKind.heard:
        final text = heard.text?.trim() ?? '';
        if (text.isEmpty) {
          _reply(MiniBotCopy.sttEmpty, clearPending: true);
          return;
        }
        _submit(text);
        return;
      case MiniBotListenKind.denied:
        _reply(MiniBotCopy.micDenied, clearPending: true);
        return;
      case MiniBotListenKind.empty:
        _reply(MiniBotCopy.sttEmpty, clearPending: true);
        return;
      case MiniBotListenKind.unavailable:
        _reply(MiniBotCopy.sttUnavailable, clearPending: true);
        return;
    }
  }

  void _onCancel() {
    if (_pending == null) return;
    setState(() {
      _mood = SnailBotMood.smiling;
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
        _mood = SnailBotMood.joy;
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
                  SnailBotFace(
                    key: const Key('mini-bot-face'),
                    size: 40,
                    mood: _mood,
                  ),
                  SizedBox(width: tokens.spacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '달팽이봇',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: tokens.colors.ink,
                          ),
                        ),
                        Text(
                          '궁금한 걸 물어보세요',
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
            if (_pending != null) ...[
              if (_pending!.amountLabel != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spacing.md,
                    0,
                    tokens.spacing.md,
                    tokens.spacing.xs,
                  ),
                  child: Text(
                    _pending!.amountLabel!,
                    key: const Key('mini-bot-amount'),
                    style: textTheme.labelMedium?.copyWith(
                      color: tokens.colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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
                        child: Text(_pending!.confirmLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    for (final id in MiniBotFaqChips.forScreen(widget.screen))
                      if (_faq?.questionOf(id) case final question?)
                        _Chip(
                          key: Key('mini-bot-faq-chip-$id'),
                          label: MiniBotFaqChips.shortLabels[id] ?? question,
                          onTap: () => _submit(question),
                        ),
                    for (final chip in MiniBotPrompts.visibleChips)
                      _Chip(
                        key: Key('mini-bot-chip-${chip.id}'),
                        label: chip.label,
                        onTap: () => _submit(chip.label),
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
                    tooltip: _listening ? '멈추기' : '말하기',
                    onPressed: _onMic,
                    icon: _listening
                        ? const Icon(
                            Icons.stop_rounded,
                            key: Key('mini-bot-listening'),
                          )
                        : const Icon(Icons.mic_rounded),
                  ),
                  SizedBox(width: tokens.spacing.xs),
                  Expanded(
                    child: TextField(
                      key: const Key('mini-bot-input'),
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _submit,
                      decoration: InputDecoration(
                        hintText:
                            _listening ? MiniBotCopy.listening : '한글로 말해 주세요',
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
    final bg = line.fromUser ? tokens.colors.primary : tokens.colors.canvas;
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
