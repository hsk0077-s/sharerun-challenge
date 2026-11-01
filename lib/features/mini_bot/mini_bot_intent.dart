import '../../l10n/remaining_surface.dart';
import '../../core/config/app_env.dart';
import '../../core/challenge/challenge_entry_fee.dart';
import '../../core/strings/app_strings.dart';
import '../../data/models/company_tournament_config.dart';
import '../iap/models/coach_plus_product.dart';
import '../shop/providers/shop_tab_provider.dart';

/// Mini-bot intents. Typed, chip, and speech text share [MiniBotInterpreter].
///
/// This file does not navigate, join, donate, or charge. A spend read only
/// recommends an existing screen and waits for one confirm tap.
enum MiniBotIntent {
  appIntro,
  joinChallenge,
  openCprTicket,
  donate,
  openSafeGuard,
  chargeShare,
  sponsorRunner,
  brandSponsor,
  subscription,
  coachPlus,
  battlePass,
  unknown,
}

enum MiniBotDestination {
  none,
  beginnerRoom,
  challengeLobby,
  cprStore,
  donateStore,
  safeGuardStore,
  shareCharge,
  personalSponsor,
  brandSponsor,
  subscription,
  coachPlus,
  battlePass,
}

class MiniBotRead {
  const MiniBotRead({
    required this.intent,
    required this.destination,
    required this.reply,
    required this.needsConfirm,
  });

  final MiniBotIntent intent;
  final MiniBotDestination destination;
  final String reply;
  final bool needsConfirm;

  /// True only for moves that must wait for an explicit confirm tap.
  bool get awaitsConfirm =>
      needsConfirm && destination != MiniBotDestination.none;

  /// Opens the existing screen. Never completes the spend by itself.
  String get confirmLabel => switch (destination) {
        MiniBotDestination.donateStore ||
        MiniBotDestination.personalSponsor =>
          RemainingSurface.trNow('mini_bot.mini_bot_intent.body', '후원하기'),
        MiniBotDestination.cprStore ||
        MiniBotDestination.safeGuardStore =>
          RemainingSurface.trNow('mini_bot.mini_bot_intent.body.2', '구매하기'),
        MiniBotDestination.shareCharge => RemainingSurface.trNow('app.myWalletCharge', '교환하기'),
        MiniBotDestination.beginnerRoom ||
        MiniBotDestination.brandSponsor =>
          RemainingSurface.trNow('mini_bot.mini_bot_intent.body.3', '참가하기'),
        MiniBotDestination.challengeLobby ||
        MiniBotDestination.subscription ||
        MiniBotDestination.coachPlus ||
        MiniBotDestination.battlePass ||
        MiniBotDestination.none =>
          RemainingSurface.trNow('mini_bot.mini_bot_intent.body.4', '이동하기'),
      };

  String? get amountLabel => switch (destination) {
        MiniBotDestination.donateStore => MiniBotCopy.donateAmount,
        MiniBotDestination.cprStore ||
        MiniBotDestination.safeGuardStore =>
          MiniBotCopy.itemAmount,
        MiniBotDestination.shareCharge => MiniBotCopy.chargeAmount,
        MiniBotDestination.beginnerRoom => MiniBotCopy.joinAmount,
        MiniBotDestination.personalSponsor => MiniBotCopy.sponsorAmount,
        MiniBotDestination.brandSponsor => MiniBotCopy.brandAmount,
        MiniBotDestination.subscription => MiniBotCopy.subscriptionAmount,
        MiniBotDestination.coachPlus => MiniBotCopy.coachPlusAmount,
        MiniBotDestination.battlePass => MiniBotCopy.battlePassAmount,
        MiniBotDestination.challengeLobby || MiniBotDestination.none => null,
      };
}

class MiniBotChip {
  const MiniBotChip({
    required this.id,
    required this.prompt,
    required this.labelKey,
  });

  final String id;

  /// 해석기에 넘기는 한국어 명령. 화면 언어와 상관없이 같은 칩이 같은 일을 한다.
  final String prompt;
  final String labelKey;

  /// 칩에 보이는 글자. 앱 언어를 따른다.
  String get label => RemainingSurface.trNow(labelKey, prompt);
}

abstract final class MiniBotPrompts {
  static const intro = '앱 소개';
  static const joinBeginner = '챌린지 참가';
  static const joinLobby = '챌린지 로비';
  static const cpr = '심폐소생권';
  static const donate = '후원';
  static const safeGuard = '세이프가드';
  static const charge = '다이아 교환';
  static const sponsor = '스폰서';
  static const runnerSponsor = '러너 후원';
  static const subscription = '구독';
  static const coachPlus = 'Coach+';
  static const battlePass = '배틀패스';

  static const _keys = {
    intro: 'mini_bot.mini_bot_intent.body.5',
    joinBeginner: 'mini_bot.mini_bot_intent.body.6',
    joinLobby: 'mini_bot.copy.chip_lobby',
    cpr: 'mini_bot.mini_bot_intent.body.7',
    donate: 'mini_bot.mini_bot_intent.body.8',
    safeGuard: 'mini_bot.mini_bot_intent.body.9',
    charge: 'mini_bot.mini_bot_intent.body.10',
    sponsor: 'mini_bot.mini_bot_intent.body.11',
    runnerSponsor: 'mini_bot.mini_bot_intent.body.12',
    subscription: 'mini_bot.copy.chip_subscription',
    coachPlus: 'mini_bot.mini_bot_intent.coach_plus',
    battlePass: 'mini_bot.mini_bot_intent.body.13',
  };

  static MiniBotChip _chip(String id, String prompt) =>
      MiniBotChip(id: id, prompt: prompt, labelKey: _keys[prompt]!);

  /// Guide chips first, then monetization. Confirm still opens the screen only.
  static final chips = <MiniBotChip>[
    _chip('intro', intro),
    _chip('lobby', joinLobby),
    _chip('donate', donate),
    _chip('brand', sponsor),
    _chip('runner', runnerSponsor),
    _chip('join', joinBeginner),
    _chip('charge', charge),
    _chip('cpr', cpr),
    _chip('safeguard', safeGuard),
    _chip('subscription', subscription),
    _chip('coach-plus', coachPlus),
    _chip('battle-pass', battlePass),
  ];

  /// 1.0은 현금 결제 칩(러너 후원 결제, 구독, Coach+)을 보여 주지 않는다.
  static const purchaseChipIds = {'runner', 'subscription', 'coach-plus'};

  static List<MiniBotChip> get visibleChips {
    if (AppEnv.inAppPurchasesEnabled) return chips;
    return [
      for (final chip in chips)
        if (!purchaseChipIds.contains(chip.id)) chip,
    ];
  }
}

abstract final class MiniBotCopy {
  static String get greeting => RemainingSurface.trNow(
        'mini_bot.copy.greeting',
        '저는 당신의 달리기 친구, 달팽이예요. 말로 물어보면 바로 도와드릴게요. '
            '이동하거나 결제하기 전에는 꼭 확인받아요.',
      );

  static String get intro => RemainingSurface.trNow(
        'mini_bot.copy.intro',
        '쉐어런은 함께 걷고 달리는 챌린지 앱이에요. '
            '홈에서 오늘 상태를 보고, 챌린지 로비나 초보 1km 챌린지에서 레이스에 참가할 수 있어요. '
            '기록 심폐소생권은 상점 아이템에서 볼 수 있어요. '
            '저는 화면 이동만 돕고, 결제나 참가 확정은 하지 않아요.',
      );

  static String get donateAmount =>
      '${ShopTabNotifier.donateValueAmount} VALUE';

  static String get itemAmount => '${ShopTabNotifier.itemDiaCost} DIA';

  static String get chargeAmount => '1,200 SHARE = 1 DIA';

  static String get joinAmount =>
      '${_grouped(ChallengeEntryFee.beginner1kmShare)} SHARE';

  static String get sponsorAmount => AppStrings.personalSponsorAmount;

  static String get brandAmount => AppStrings.brandSponsorEntryFee;

  static String get subscriptionAmount => RemainingSurface.trNow(
      'mini_bot.copy.subscription_amount', '유료 구독은 Coach+ 하나예요');

  static String get battlePassAmount =>
      '${AppStrings.battlePassTitle} · ${AppStrings.battlePassCurrentLevel}';

  static String get donate => RemainingSurface.trNow(
        'mini_bot.copy.donate',
        '기부 펀딩으로 이동할까요? \${donateAmount}예요. '
            '후원하기를 눌러도 여기서는 기부가 끝나지 않아요. '
            '상점의 기부 버튼으로 직접 눌러 주세요.',
        {'donateAmount': donateAmount},
      );

  static String get joinBeginner => RemainingSurface.trNow(
        'mini_bot.copy.join_beginner',
        '초보 1km 챌린지로 이동할까요? 참가비는 \${joinAmount}예요. '
            '참가하기를 눌러도 참가는 확정되지 않아요. 그 화면에서 직접 확인해 주세요.',
        {'joinAmount': joinAmount},
      );

  static String get joinLobby => RemainingSurface.trNow(
      'mini_bot.copy.join_lobby', '챌린지 로비로 이동할까요? 로비에서 참가할 대회를 고를 수 있어요.');

  static String prizeRace(CompanyTournamentConfig? config) {
    if (config == null || config.tiers.isEmpty) {
      return RemainingSurface.trNow(
        'mini_bot.copy.prize_race_pending',
        '운영자 상금 대회 참가비를 확인 중이에요. '
            '대회 목록에서 서버 참가비를 확인해 주세요. 여기서는 참가하지 않아요.',
      );
    }
    String fee(String id, String label) {
      final tier = config.tier(id);
      if (tier == null) return '';
      return '$label ${_grouped(tier.entryShare)} SHARE';
    }

    final costs = [
      fee('beginner', CompanyTournamentConfig.tierName('beginner')),
      fee('mid', CompanyTournamentConfig.tierName('mid')),
      fee('advanced', CompanyTournamentConfig.tierName('advanced')),
      fee('half', CompanyTournamentConfig.tierName('half')),
    ].where((line) => line.isNotEmpty).join(', ');
    final free =
        config.beginnerFreeEntryEligible && config.freeEntryLabel != null
            ? ' ${config.freeEntryLabel}.'
            : '';
    final week = config.weeklyLimitLabel ?? '';
    final claim = config.prizeIneligibleLabel ?? '';
    return RemainingSurface.trNow(
      'mini_bot.copy.prize_race',
      '운영자 상금 대회로 이동할까요? 참가비는 \$costs예요.\$free \$week \$claim '
          '이동만 하고, 참가는 확정하지 않아요.',
      {'costs': costs, 'free': free, 'week': week, 'claim': claim},
    );
  }

  static String get cpr => RemainingSurface.trNow(
        'mini_bot.copy.cpr',
        '상점의 기록 심폐소생권으로 이동할까요? \${itemAmount}예요. '
            '구매하기를 눌러도 결제하지 않아요. 상점 화면에서 직접 구매해 주세요.',
        {'itemAmount': itemAmount},
      );

  static String get safeGuard => RemainingSurface.trNow(
        'mini_bot.copy.safe_guard',
        '상점의 세이프 가드로 이동할까요? \${itemAmount}예요. '
            '구매하기를 눌러도 결제하지 않아요. '
            '상점의 세이프 가드 칸에서 직접 구매해 주세요.',
        {'itemAmount': itemAmount},
      );

  static String get charge => RemainingSurface.trNow(
        'mini_bot.copy.charge',
        '다이아 교환소로 이동할까요? \${chargeAmount}예요. '
            '교환하기를 눌러도 여기서는 결제되지 않아요. 교환소에서 직접 바꿔 주세요.',
        {'chargeAmount': chargeAmount},
      );

  static String get sponsor => RemainingSurface.trNow(
        'mini_bot.copy.sponsor',
        '러너 후원 화면으로 이동할까요? \${sponsorAmount}예요. '
            '후원하기를 눌러도 여기서는 후원이 끝나지 않아요. '
            '그 화면의 후원 버튼으로 직접 확정해 주세요.',
        {'sponsorAmount': sponsorAmount},
      );

  static String get brand => RemainingSurface.trNow(
        'mini_bot.copy.brand',
        '브랜드 스폰서 챌린지는 아직 준비 중이에요. '
            '지금 진행 중인 스폰서 챌린지가 없어요. 열리면 챌린지 탭에서 알려 드릴게요.',
      );

  static String get subscription => RemainingSurface.trNow(
        'mini_bot.copy.subscription',
        '구독 관리 화면으로 이동할까요? \${subscriptionAmount}. '
            '이동만 하고, 구독이나 결제는 바꾸지 않아요.',
        {'subscriptionAmount': subscriptionAmount},
      );

  static String get coachPlusAmount {
    final monthly = CoachPlusPlan.monthly;
    final yearly = CoachPlusPlan.yearly;
    final monthLabel =
        RemainingSurface.trNow('shop.store_look.body.2', monthly.periodLabel);
    final yearLabel =
        RemainingSurface.trNow('shop.store_look.body.3', yearly.periodLabel);
    return '$monthLabel ${monthly.fallbackPriceLabel} · '
        '$yearLabel ${yearly.fallbackPriceLabel}';
  }

  static String get coachPlus => RemainingSurface.trNow(
        'mini_bot.copy.coach_plus',
        'Coach+ 안내를 열까요? 심박·상황에 맞춘 심층 코칭이에요. '
            '\${coachPlusAmount}. 이동만 하고, 여기서는 결제하지 않아요.',
        {'coachPlusAmount': coachPlusAmount},
      );

  static String get battlePass => RemainingSurface.trNow(
        'mini_bot.copy.battle_pass',
        '배틀런 패스 화면으로 이동할까요? \${battlePassAmount}. '
            '여기서는 패스를 구매하지 않아요. 보상 화면만 열어요.',
        {'battlePassAmount': battlePassAmount},
      );

  static String get cancelled =>
      RemainingSurface.trNow('mini_bot.copy.cancelled', '알겠어요. 이동은 취소했어요.');

  static String get unknown => RemainingSurface.trNow(
        'mini_bot.copy.unknown',
        '그 말은 아직 연결되지 않았어요. '
            '앱 소개, 챌린지 로비, 후원, 스폰서, 러너 후원, 챌린지 참가, '
            '다이아 교환, 심폐소생권, 세이프가드, 구독, Coach+, 배틀패스 중에서 말해 주세요.',
      );

  static String get micDenied => RemainingSurface.trNow(
        'mini_bot.copy.mic_denied',
        '마이크 권한이 없어 음성을 듣지 못했어요. '
            '한글로 입력하거나 아래 버튼을 눌러 주세요.',
      );

  static String get sttUnavailable => RemainingSurface.trNow(
        'mini_bot.copy.stt_unavailable',
        '지금은 음성 인식을 쓸 수 없어요. '
            '한글로 입력하거나 아래 버튼을 눌러 주세요.',
      );

  static String get sttEmpty => RemainingSurface.trNow('mini_bot.copy.stt_empty',
      '말씀을 알아듣지 못했어요. 다시 말하거나 한글로 입력해 주세요.');

  static String get listening =>
      RemainingSurface.trNow('mini_bot.copy.listening', '듣는 중이에요. 말씀해 주세요.');

  static String executed(MiniBotDestination destination) {
    return switch (destination) {
      MiniBotDestination.beginnerRoom => RemainingSurface.trNow(
        'mini_bot.copy.run_beginner',
        '초보 1km 챌린지로 이동할게요. 참가 확정은 그 화면에서 해 주세요. '
            '여기서는 참가되지 않아요.',
      ),
      MiniBotDestination.challengeLobby => RemainingSurface.trNow(
        'mini_bot.copy.run_lobby',
        '챌린지 로비로 이동할게요.',
      ),
      MiniBotDestination.cprStore => RemainingSurface.trNow(
        'mini_bot.copy.run_cpr',
        '상점 아이템 화면으로 이동할게요. '
          '기록 심폐소생권을 눌러 구매해 주세요. 여기서는 결제되지 않아요.',
      ),
      MiniBotDestination.safeGuardStore => RemainingSurface.trNow(
        'mini_bot.copy.run_safe_guard',
        '상점 아이템 화면으로 이동할게요. '
          '세이프 가드를 눌러 구매해 주세요. 여기서는 결제되지 않아요.',
      ),
      MiniBotDestination.donateStore => RemainingSurface.trNow(
        'mini_bot.copy.run_donate',
        '상점 기부 펀딩으로 이동할게요. '
          '기부 버튼으로 직접 눌러 주세요. 여기서는 기부되지 않아요.',
      ),
      MiniBotDestination.shareCharge => RemainingSurface.trNow(
        'mini_bot.copy.run_charge',
        '다이아 교환소로 이동할게요. '
          '교환은 그 화면에서 직접 해 주세요. 여기서는 결제되지 않아요.',
      ),
      MiniBotDestination.personalSponsor => RemainingSurface.trNow(
        'mini_bot.copy.run_sponsor',
        '러너 후원 화면으로 이동할게요. '
            '후원 버튼으로 직접 확정해 주세요. 여기서는 후원되지 않아요.',
      ),
      MiniBotDestination.brandSponsor => RemainingSurface.trNow(
        'mini_bot.copy.run_brand',
        '브랜드 스폰서 챌린지로 이동할게요. '
          '참가는 그 화면에서 직접 해 주세요. 여기서는 참가되지 않아요.',
      ),
      MiniBotDestination.subscription => RemainingSurface.trNow(
        'mini_bot.copy.run_subscription',
        '구독 관리 화면으로 이동할게요. 여기서는 구독을 바꾸지 않아요.',
      ),
      MiniBotDestination.coachPlus => RemainingSurface.trNow(
        'mini_bot.copy.run_coach_plus',
        'Coach+ 안내를 열게요. '
            '월간·연간은 그 화면에서 직접 골라 주세요. 여기서는 결제되지 않아요.',
      ),
      MiniBotDestination.battlePass => RemainingSurface.trNow(
        'mini_bot.copy.run_battle_pass',
        '배틀런 패스 화면으로 이동할게요. 여기서는 패스를 구매하지 않아요.',
      ),
      MiniBotDestination.none => cancelled,
    };
  }
}

abstract final class MiniBotInterpreter {
  static MiniBotRead interpret(
    String raw, {
    CompanyTournamentConfig? prizeConfig,
  }) {
    final text = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) {
      return MiniBotRead(
        intent: MiniBotIntent.unknown,
        destination: MiniBotDestination.none,
        reply: MiniBotCopy.unknown,
        needsConfirm: false,
      );
    }

    if (_hasSafeGuard(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.openSafeGuard,
        destination: MiniBotDestination.safeGuardStore,
        reply: MiniBotCopy.safeGuard,
        needsConfirm: true,
      );
    }

    if (_hasCpr(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.openCprTicket,
        destination: MiniBotDestination.cprStore,
        reply: MiniBotCopy.cpr,
        needsConfirm: true,
      );
    }

    if (_hasBattlePass(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.battlePass,
        destination: MiniBotDestination.battlePass,
        reply: MiniBotCopy.battlePass,
        needsConfirm: true,
      );
    }

    if (_hasCoachPlus(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.coachPlus,
        destination: MiniBotDestination.coachPlus,
        reply: MiniBotCopy.coachPlus,
        needsConfirm: true,
      );
    }

    if (_hasSubscription(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.subscription,
        destination: MiniBotDestination.subscription,
        reply: MiniBotCopy.subscription,
        needsConfirm: true,
      );
    }

    if (_hasRunnerSponsor(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.sponsorRunner,
        destination: MiniBotDestination.personalSponsor,
        reply: MiniBotCopy.sponsor,
        needsConfirm: true,
      );
    }

    if (_hasBrandSponsor(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.brandSponsor,
        destination: MiniBotDestination.none,
        reply: MiniBotCopy.brand,
        needsConfirm: false,
      );
    }

    if (_any(text, _wCharge)) {
      return MiniBotRead(
        intent: MiniBotIntent.chargeShare,
        destination: MiniBotDestination.shareCharge,
        reply: MiniBotCopy.charge,
        needsConfirm: true,
      );
    }

    if (_any(text, _wPrize)) {
      return MiniBotRead(
        intent: MiniBotIntent.joinChallenge,
        destination: MiniBotDestination.challengeLobby,
        reply: MiniBotCopy.prizeRace(prizeConfig),
        needsConfirm: true,
      );
    }

    final hasBeginner = _any(text, _wBeginner);
    final hasLobby = _any(text, _wLobby);
    if (hasLobby && !hasBeginner) {
      return MiniBotRead(
        intent: MiniBotIntent.joinChallenge,
        destination: MiniBotDestination.challengeLobby,
        reply: MiniBotCopy.joinLobby,
        needsConfirm: true,
      );
    }

    if (_hasDonate(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.donate,
        destination: MiniBotDestination.donateStore,
        reply: MiniBotCopy.donate,
        needsConfirm: true,
      );
    }

    final hasJoin = _any(text, _wJoin);
    final hasChallenge = _any(text, _wChallenge);
    final hasIntro = _hasIntro(text);
    if (hasBeginner || hasJoin || (hasChallenge && !hasIntro)) {
      return MiniBotRead(
        intent: MiniBotIntent.joinChallenge,
        destination: MiniBotDestination.beginnerRoom,
        reply: MiniBotCopy.joinBeginner,
        needsConfirm: true,
      );
    }

    if (hasIntro || text.contains('sharerun') || text.contains('쉐어런')) {
      return MiniBotRead(
        intent: MiniBotIntent.appIntro,
        destination: MiniBotDestination.none,
        reply: MiniBotCopy.intro,
        needsConfirm: false,
      );
    }

    return MiniBotRead(
      intent: MiniBotIntent.unknown,
      destination: MiniBotDestination.none,
      reply: MiniBotCopy.unknown,
      needsConfirm: false,
    );
  }

  /// 11개 언어로 쓴 말에서 찾을 낱말. 소문자 기준이고, 어느 언어든 하나만 들어 있으면 맞는 것으로 본다.
  static bool _any(String text, List<String> words) {
    for (final word in words) {
      if (text.contains(word)) return true;
    }
    return false;
  }

  static const _wSafeGuard = [
    '세이프가드', '세이프 가드', 'safeguard', 'safe guard', 'セーフガード', '安全守護', '安全守护',
    'salvaguarda', 'salva-vidas', 'garde-fou', 'เซฟการ์ด', //
  ];
  static const _wCpr = [
    '심폐', '소생', 'cpr', '蘇生', '复活', '復活', 'reanima', 'ressuscit', 'wiederbeleb',
    'réanim', 'hồi sinh', 'กู้สตรีค', 'ตั๋วกู้', 'resusit', //
  ];
  static const _wBattlePass = [
    '배틀패스', '배틀 패스', '배틀런', 'battle pass', 'battlepass', 'battle run', 'バトルパス',
    'バトルラン', '通行證', '通行证', 'pase de batalla', 'passe de batalha', 'pass battle',
    'เบทเทิล', 'แบทเทิล', //
  ];
  static const _wCoachPlus = [
    'coach', '코칭', '코치', '심박', 'コーチ', '教練', '教练', 'entrenad', 'treinad',
    'entraîneur', 'huấn luyện', 'โค้ช', 'pelatih', 'heart rate', '心拍', '心率', //
  ];
  static const _wSubscription = [
    '구독', '멤버십', 'subscri', 'membership', 'サブスク', '購読', '訂閱', '订阅', 'suscrip',
    'assinatura', 'abonnement', 'đăng ký gói', 'สมาชิก', 'langganan', //
  ];
  static const _wBrand = [
    '브랜드', '스폰서', 'brand', 'sponsor', 'ブランド', 'スポンサー', '品牌', '贊助商', '赞助商',
    'patrocinador', 'marque', 'marke', 'thương hiệu', 'nhà tài trợ', 'แบรนด์', 'สปอนเซอร์',
    'merek', //
  ];
  static const _wRunnerSponsor = [
    '천사', 'angel', 'runner support', 'support a runner', 'sponsor a runner', 'ランナー支援',
    'ランナー応援', '跑者贊助', '跑者赞助', '天使', 'apoyo a corredor', 'patrocinar a un corredor',
    'apoio a corredor', 'läufer-sponsoring', 'unterstütze einen läufer', 'soutien aux coureurs',
    'parrainer un coureur', 'ủng hộ người chạy', 'tài trợ người chạy', 'สนับสนุนนักวิ่ง',
    'dukung pelari', 'sponsor pelari', //
  ];
  static const _wDonate = [
    '후원', '기부', '펀딩', '유니세프', 'donat', 'charity', 'crowdfund', '寄付', '捐款', '捐赠',
    '捐贈', 'donación', 'doação', 'doação', 'spende', 'dons', 'quyên góp', 'บริจาค', 'donasi', //
  ];
  static const _wCharge = [
    '충전', '교환', 'exchange', 'top up', 'top-up', 'recharge', 'チャージ', '交換', '兌換', '兑换',
    '充值', 'canje', 'canjear', 'recarga', 'troca', 'tausch', 'échange', 'đổi dia', 'nạp', 'แลก',
    'เติม', 'tukar', 'isi ulang', //
  ];
  static const _wPrize = [
    '상금', 'prize', '賞金', '獎金', '奖金', 'premio', 'prêmio', 'preisgeld', 'gewinn', 'cagnotte',
    'giải thưởng', 'tiền thưởng', 'เงินรางวัล', 'hadiah', //
  ];
  static const _wBeginner = [
    '초보', '1km', '1 km', 'beginner', 'novice', '初心者', '初學', '初学', 'principiante', 'iniciante',
    'anfänger', 'débutant', 'người mới', 'มือใหม่', 'pemula', //
  ];
  static const _wLobby = [
    '로비', 'lobby', 'ロビー', '大廳', '大厅', 'vestíbulo', 'sảnh', 'ล็อบบี้', 'lobi', //
  ];
  static const _wJoin = [
    '참가', '레이스', '입장', '들어가', 'join', 'enter', 'participate', 'race', '参加', 'レース',
    '報名', '参赛', '參加', 'unirse', 'participar', 'inscri', 'teilnehmen', 'mitmachen', 'rejoindre',
    'participer', 'tham gia', 'เข้าร่วม', 'สมัคร', 'ikut', 'daftar', //
  ];
  static const _wChallenge = [
    '챌린지', '대회', '도전', 'challenge', 'tournament', 'event', 'チャレンジ', '大会', '挑戰', '挑战',
    '賽事', 'reto', 'desafio', 'herausforderung', 'défi', 'thử thách', 'ชาเลนจ์', 'tantangan', //
  ];
  static const _wIntro = [
    '소개', '뭐야', '뭐니', '무엇', '어떤 앱', 'what is', 'what’s', 'what\'s', 'introduce', 'explain',
    '설명해', '紹介', '説明', 'について', '介紹', '介绍', '什麼', '什么', 'qué es', 'que es', 'o que é',
    'was ist', 'erklär', 'qu’est', 'c’est quoi', 'présente', 'là gì', 'giới thiệu', 'คืออะไร',
    'แนะนำ', 'apa itu', 'jelaskan', 'perkenalan', //
  ];

  static bool _hasSafeGuard(String text) => _any(text, _wSafeGuard);

  static bool _hasCpr(String text) => _any(text, _wCpr);

  static bool _hasBattlePass(String text) => _any(text, _wBattlePass);

  static bool _hasCoachPlus(String text) => _any(text, _wCoachPlus);

  static bool _hasSubscription(String text) =>
      _any(text, _wSubscription) ||
      (text.contains('정기') && text.contains('후원'));

  static bool _hasRunnerSponsor(String text) =>
      _any(text, _wRunnerSponsor) ||
      (text.contains('러너') && text.contains('후원'));

  /// `스폰서` alone is the brand screen. Runner phrases are matched first.
  static bool _hasBrandSponsor(String text) => _any(text, _wBrand);

  static bool _hasDonate(String text) => _any(text, _wDonate);

  static bool _hasIntro(String text) => _any(text, _wIntro);
}

String _grouped(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
