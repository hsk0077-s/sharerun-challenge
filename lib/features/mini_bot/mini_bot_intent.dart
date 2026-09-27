/// Phase 4 mini-bot intents. Typed Korean in, confirm-before-navigate out.
///
/// Speech-to-text should call [MiniBotInterpreter.interpret] with the
/// recognized utterance. This file does not execute navigation or payment.
enum MiniBotIntent {
  appIntro,
  joinChallenge,
  openCprTicket,
  unknown,
}

enum MiniBotDestination {
  none,
  beginnerRoom,
  challengeLobby,
  cprStore,
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
}

abstract final class MiniBotPrompts {
  static const intro = '앱 소개';
  static const joinBeginner = '챌린지 참가';
  static const joinLobby = '챌린지 로비';
  static const cpr = '심폐소생권';
}

abstract final class MiniBotCopy {
  static const greeting =
      '안녕하세요. 쉐어런 미니봇이에요. 안내하고, 추천한 뒤, 확인받아야만 이동해요.';

  static const intro =
      '쉐어런은 함께 걷고 달리는 챌린지 앱이에요. '
      '홈에서 오늘 상태를 보고, 챌린지 로비나 초보 1km 방에서 레이스에 참가할 수 있어요. '
      '기록 심폐소생권은 상점 아이템에서 볼 수 있어요. '
      '저는 화면 이동만 돕고, 결제나 참가 확정은 하지 않아요.';

  static const joinBeginner =
      '초보 1km 챌린지 방으로 이동할까요? '
      '참가 버튼과 참가비는 그 화면에서 직접 확인해 주세요.';

  static const joinLobby =
      '챌린지 로비로 이동할까요? 로비에서 참가할 방을 고를 수 있어요.';

  static const cpr =
      '상점의 기록 심폐소생권(CPR) 칸으로 이동할까요? '
      '미니봇은 결제하지 않아요. 구매는 상점 화면에서 직접 해요.';

  static const cancelled = '알겠어요. 이동은 취소했어요.';

  static const unknown =
      '그 말은 아직 연결되지 않았어요. '
      '앱 소개, 챌린지 참가, 챌린지 로비, 심폐소생권 중에서 말해 주세요.';

  static const sttUnavailable =
      '음성 인식은 다음 단계에서 연결돼요. '
      '지금은 한글로 입력해 주세요. 말하기 버튼은 그 연결을 위한 자리예요.';

  static String executed(MiniBotDestination destination) {
    return switch (destination) {
      MiniBotDestination.beginnerRoom => '초보 1km 챌린지 방으로 이동할게요.',
      MiniBotDestination.challengeLobby => '챌린지 로비로 이동할게요.',
      MiniBotDestination.cprStore =>
        '상점 아이템 화면으로 이동할게요. '
            '기록 심폐소생권을 눌러 구매해 주세요. 여기서는 결제되지 않아요.',
      MiniBotDestination.none => cancelled,
    };
  }
}

abstract final class MiniBotInterpreter {
  static MiniBotRead interpret(String raw) {
    final text = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) {
      return const MiniBotRead(
        intent: MiniBotIntent.unknown,
        destination: MiniBotDestination.none,
        reply: MiniBotCopy.unknown,
        needsConfirm: false,
      );
    }

    final hasCpr = text.contains('심폐') ||
        text.contains('소생') ||
        text.contains('cpr');
    if (hasCpr) {
      return const MiniBotRead(
        intent: MiniBotIntent.openCprTicket,
        destination: MiniBotDestination.cprStore,
        reply: MiniBotCopy.cpr,
        needsConfirm: true,
      );
    }

    final hasBeginner = text.contains('초보') ||
        text.contains('1km') ||
        text.contains('1 km');
    final hasLobby = text.contains('로비');
    if (hasLobby && !hasBeginner) {
      return const MiniBotRead(
        intent: MiniBotIntent.joinChallenge,
        destination: MiniBotDestination.challengeLobby,
        reply: MiniBotCopy.joinLobby,
        needsConfirm: true,
      );
    }

    final hasJoin = text.contains('참가') ||
        text.contains('레이스') ||
        text.contains('입장') ||
        text.contains('들어가');
    final hasChallenge =
        text.contains('챌린지') || text.contains('대회') || text.contains('도전');
    final hasIntro = text.contains('소개') ||
        text.contains('뭐야') ||
        text.contains('뭐니') ||
        text.contains('무엇') ||
        text.contains('어떤 앱') ||
        text.contains('what is') ||
        text.contains('설명해');
    if (hasBeginner || hasJoin || (hasChallenge && !hasIntro)) {
      return const MiniBotRead(
        intent: MiniBotIntent.joinChallenge,
        destination: MiniBotDestination.beginnerRoom,
        reply: MiniBotCopy.joinBeginner,
        needsConfirm: true,
      );
    }

    if (hasIntro || text.contains('sharerun') || text.contains('쉐어런')) {
      return const MiniBotRead(
        intent: MiniBotIntent.appIntro,
        destination: MiniBotDestination.none,
        reply: MiniBotCopy.intro,
        needsConfirm: false,
      );
    }

    return const MiniBotRead(
      intent: MiniBotIntent.unknown,
      destination: MiniBotDestination.none,
      reply: MiniBotCopy.unknown,
      needsConfirm: false,
    );
  }
}
