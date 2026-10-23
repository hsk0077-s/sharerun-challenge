import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/data/api/secured_action_api_client.dart';
import 'package:share_run_challenge/data/models/pedometer_harvest_result.dart';
import 'package:share_run_challenge/features/crew/crew_emblem.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/crew/crew_membership.dart';
import 'package:share_run_challenge/features/crew/crew_ranking.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/crew_room_screen.dart';
import 'package:share_run_challenge/screens/running_crew_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SeededWallet extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(const WalletModel(
        shareBalance: 90000,
        diamondBalance: 5,
        valueTokenBalance: 100,
        totalDonationValue: 0,
      ));
}

/// 서버 대신 메모리에서 가입·탈퇴를 흉내 낸다.
class _FakeApi extends Fake implements SecuredActionApiClient {
  _FakeApi(
      {this.myRole,
      this.joinMode = 'open',
      this.renameCost = 0,
      this.rejected = false});

  String? myRole;
  String joinMode;
  int renameCost;
  bool rejected;
  String pending = '';
  final calls = <String>[];

  CrewSummary get _crew => CrewSummary(
        id: 'c1',
        name: '새벽러너',
        emblem: 'shield:g_wolf:rays:navy:white',
        memberCount: 12,
        maxMembers: 100,
        totalDistanceKm: 321,
        joinMode: joinMode,
        nameChanges: renameCost == 0 ? 0 : 1,
        renameCostDia: renameCost,
        rejected: rejected,
      );

  @override
  Future<CrewListResult> listCrews(String query) async {
    calls.add('list:$query');
    return CrewListResult(
      crews:
          query.isNotEmpty && !_crew.name.contains(query) ? const [] : [_crew],
      pendingCrewId: pending,
    );
  }

  @override
  Future<MyCrew?> myCrew() async => myRole == null
      ? null
      : MyCrew(
          crew: _crew,
          role: myRole!,
          pendingRequests: myRole == 'member' ? 0 : 1,
          members: const [
            CrewMember(uid: 'u1', nickname: '대장', role: 'leader'),
            CrewMember(uid: 'u2', nickname: '러너2', role: 'member'),
            CrewMember(uid: 'u3', nickname: '러너3', role: 'sub'),
          ],
        );

  @override
  Future<CrewRanking> crewRanking() async => const CrewRanking(
        month: '2026-10',
        minMembers: 5,
        rankedCrews: 3,
        top: [],
        mine: CrewRankRow(
          rank: 2,
          name: '새벽러너',
          averageKm: 8.44,
          distanceKm: 101.3,
          memberCount: 12,
        ),
        myDistanceKm: 101.3,
        myMemberCount: 12,
        myEligible: true,
        bestRank: 4,
      );

  @override
  Future<String> joinCrew(String crewId) async {
    calls.add('join:$crewId');
    if (joinMode == 'approval') {
      pending = crewId;
      return 'requested';
    }
    myRole = 'member';
    return 'joined';
  }

  @override
  Future<void> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    calls.add('report:$targetType:$targetId:$reason');
  }

  @override
  Future<void> cancelCrewRequest() async {
    calls.add('cancel');
    pending = '';
  }

  @override
  Future<void> setCrewJoinMode(String mode) async {
    calls.add('mode:$mode');
    joinMode = mode;
  }

  @override
  Future<List<CrewJoinRequest>> crewJoinRequests() async =>
      const [CrewJoinRequest(uid: 'u9', nickname: '신청자')];

  @override
  Future<void> decideCrewRequest(String uid, {required bool approve}) async {
    calls.add('decide:$uid:$approve');
  }

  @override
  Future<void> kickCrewMember(String uid) async {
    calls.add('kick:$uid');
  }

  @override
  Future<void> transferCrew(String uid) async {
    calls.add('transfer:$uid');
  }

  String? foundName;

  @override
  Future<PedometerHarvestResult> foundCrew(
    String name, {
    required String payWith,
    String? emblem,
  }) async {
    calls.add('found:$name:$payWith');
    foundName = name;
    myRole = 'leader';
    return const PedometerHarvestResult(
      status: 'created',
      shareBalance: 90000,
      diamondBalance: 0,
      valueTokenBalance: 100,
    );
  }

  @override
  Future<int?> renameCrew(String name) async {
    calls.add('rename:$name');
    return 200;
  }

  @override
  Future<void> disbandCrew() async {
    calls.add('disband');
    myRole = null;
  }

  @override
  Future<void> leaveCrew() async {
    calls.add('leave');
    myRole = null;
  }

  @override
  Future<void> setCrewRole(String uid, String role) async {
    calls.add('role:$uid:$role');
  }
}

Future<void> _pump(WidgetTester tester, _FakeApi api) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletProvider.overrideWith(_SeededWallet.new),
        recentActivitiesProvider.overrideWith((ref) => Stream.value(const [])),
        crewApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp(
        theme: SrcTheme.light,
        home: const RunningCrewScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without a crew: the list shows real crews and joining works',
      (tester) async {
    final api = _FakeApi();
    await _pump(tester, api);

    expect(find.text('새벽러너'), findsOneWidget);
    expect(find.text('12/100명 · 자유 가입'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('crew-join-c1')));
    await tester.tap(find.byKey(const Key('crew-join-c1')));
    await tester.pumpAndSettle();
    expect(find.text('"새벽러너" 크루에 가입할까요?'), findsOneWidget);
    await tester.tap(find.text('가입').last);
    await tester.pumpAndSettle();

    expect(api.calls, contains('join:c1'));
    // 가입한 뒤에는 내 크루 화면이 되고 가입 버튼은 사라진다.
    expect(find.byKey(const Key('crew-join-c1')), findsNothing);
    expect(find.text('12/100'), findsOneWidget);
  });

  testWidgets('a member can leave; the leader has no leave button',
      (tester) async {
    final api = _FakeApi(myRole: 'member');
    await _pump(tester, api);
    expect(find.text('크루 나가기'), findsOneWidget);
    await tester.ensureVisible(find.text('크루 나가기'));
    await tester.tap(find.text('크루 나가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나가기'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('leave'));
    expect(find.text('크루 나가기'), findsNothing);

    final leader = _FakeApi(myRole: 'leader');
    await _pump(tester, leader);
    expect(find.text('크루 나가기'), findsNothing);
    expect(find.text('크루원 보기'), findsOneWidget);
  });

  testWidgets('the leader can appoint a sub-leader from the member list',
      (tester) async {
    final api = _FakeApi(myRole: 'leader');
    await _pump(tester, api);
    await tester.ensureVisible(find.text('크루원 보기'));
    await tester.tap(find.text('크루원 보기'));
    await tester.pumpAndSettle();
    expect(find.text('러너2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('crew-member-menu-u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crew-role-u2')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('role:u2:sub'));
  });

  testWidgets('a member can report another member and the crew name',
      (tester) async {
    final api = _FakeApi(myRole: 'member');
    await _pump(tester, api);
    await tester.ensureVisible(find.text('크루원 보기'));
    await tester.tap(find.text('크루원 보기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('crew-member-menu-u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crew-member-report-u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-reason-offensive_name')));
    await tester.pumpAndSettle();

    expect(api.calls, contains('report:user:u2:offensive_name'));
  });

  testWidgets('a crew in the search list can be reported', (tester) async {
    final api = _FakeApi();
    await _pump(tester, api);
    await tester.ensureVisible(find.byKey(const Key('crew-report-c1')));
    await tester.tap(find.byKey(const Key('crew-report-c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-reason-spam')));
    await tester.pumpAndSettle();

    expect(api.calls, contains('report:crew:c1:spam'));
  });

  testWidgets('a plain member sees the list but no appoint buttons',
      (tester) async {
    final api = _FakeApi(myRole: 'member');
    await _pump(tester, api);
    await tester.ensureVisible(find.text('크루원 보기'));
    await tester.tap(find.text('크루원 보기'));
    await tester.pumpAndSettle();
    expect(find.text('러너2'), findsOneWidget);
    // 일반 크루원에게는 메뉴가 잠겨 있다.
    await tester.tap(find.byKey(const Key('crew-member-menu-u2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crew-role-u2')), findsNothing);
    expect(find.byKey(const Key('crew-kick-u2')), findsNothing);
  });

  testWidgets('approval crew: the button says apply, and can be cancelled',
      (tester) async {
    final api = _FakeApi(joinMode: 'approval');
    await _pump(tester, api);
    expect(find.text('가입 신청'), findsOneWidget);
    expect(find.textContaining('승인 가입'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('crew-join-c1')));
    await tester.tap(find.byKey(const Key('crew-join-c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('신청').last);
    await tester.pumpAndSettle();
    expect(api.calls, contains('join:c1'));
    expect(find.text('신청 취소'), findsOneWidget);

    await tester.tap(find.text('신청 취소'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('cancel'));
    expect(find.text('신청 취소'), findsNothing);
  });

  testWidgets('the leader picks the join mode and decides requests',
      (tester) async {
    final api = _FakeApi(myRole: 'leader');
    await _pump(tester, api);
    await tester.ensureVisible(find.text('가입 방식'));
    await tester.tap(find.text('가입 방식'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crew-mode-approval')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('mode:approval'));

    expect(find.text('가입 신청 1건'), findsOneWidget);
    await tester.ensureVisible(find.text('가입 신청 1건'));
    await tester.tap(find.text('가입 신청 1건'));
    await tester.pumpAndSettle();
    expect(find.text('신청자'), findsOneWidget);
    await tester.tap(find.byKey(const Key('crew-approve-u9')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('decide:u9:true'));
  });

  testWidgets('a plain member does not see request or disband lines',
      (tester) async {
    await _pump(tester, _FakeApi(myRole: 'member'));
    expect(find.textContaining('가입 신청'), findsNothing);
    expect(find.text('가입 방식'), findsNothing);
    expect(find.text('크루 없애기'), findsNothing);
  });

  testWidgets('disbanding explains that the leader leaves too, then does it',
      (tester) async {
    final api = _FakeApi(myRole: 'leader');
    await _pump(tester, api);
    await tester.ensureVisible(find.text('크루 없애기'));
    await tester.tap(find.text('크루 없애기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('크루장인 나도 함께 크루에서 나와요'), findsOneWidget);
    expect(find.textContaining('먼저 "크루원 보기"에서 크루장을 넘겨'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '크루 없애기'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('disband'));
    // 크루가 없어지면 크루 관리 줄도 없다.
    expect(find.text('크루원 보기'), findsNothing);
  });

  testWidgets('leader removes a member and hands the crew over',
      (tester) async {
    final api = _FakeApi(myRole: 'leader');
    await _pump(tester, api);
    await tester.ensureVisible(find.text('크루원 보기'));
    await tester.tap(find.text('크루원 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crew-member-menu-u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crew-kick-u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '내보내기'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('kick:u2'));

    await tester.tap(find.text('크루원 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crew-member-menu-u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crew-transfer-u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '넘기기'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('transfer:u2'));
  });

  testWidgets('a sub-leader can remove a member but not another sub-leader',
      (tester) async {
    final api = _FakeApi(myRole: 'sub');
    await _pump(tester, api);
    await tester.ensureVisible(find.text('크루원 보기'));
    await tester.tap(find.text('크루원 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crew-member-menu-u2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crew-kick-u2')), findsOneWidget);
    expect(find.byKey(const Key('crew-transfer-u2')), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    // 다른 부크루장(u3)의 메뉴는 잠겨 있다.
    await tester.tap(find.byKey(const Key('crew-member-menu-u3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crew-kick-u3')), findsNothing);
  });

  testWidgets('a real crew shows its own name and no sample progress',
      (tester) async {
    await _pump(tester, _FakeApi(myRole: 'leader'));
    expect(find.text('새벽러너'), findsWidgets);
    expect(find.text('이번 주 대항전'), findsNothing);
    expect(find.text('45/50'), findsNothing);
    expect(find.text('12/100'), findsOneWidget);
    expect(find.text('321km'), findsOneWidget);
  });

  testWidgets('a real crew shows this month rank and its best ever',
      (tester) async {
    await _pump(tester, _FakeApi(myRole: 'leader'));
    expect(find.byKey(const Key('crew-rank-line')), findsOneWidget);
    expect(find.text('이번 달 2위 · 1인 평균 8.4km'), findsOneWidget);
    expect(find.text('역대 최고 4위'), findsOneWidget);
  });

  testWidgets('the crew room shows the real crew, its members and no sample',
      (tester) async {
    await _pump(tester, _FakeApi(myRole: 'leader'));
    await tester.tap(find.text('크루 룸 입장하기'));
    await tester.pumpAndSettle();
    expect(find.text('크루 룸'), findsOneWidget);
    expect(find.text('새벽러너'), findsWidgets);
    expect(find.text('12/100'), findsWidgets);
    expect(find.byKey(CrewRoomScreen.preparingKey), findsOneWidget);
    expect(find.textContaining('인천 논현'), findsNothing);
    expect(find.textContaining('120 / 200'), findsNothing);
  });

  testWidgets('creating a crew asks for its name and sends exactly that',
      (tester) async {
    final api = _FakeApi();
    await _pump(tester, api);
    await tester.ensureVisible(find.text('크루 만들기').first);
    await tester.tap(find.text('크루 만들기').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.doneKey));
    await tester.tap(find.byKey(CrewEmblemPicker.doneKey));
    await tester.pumpAndSettle();

    // 이름 창: 두 글자가 되기 전에는 다음으로 갈 수 없다.
    FilledButton ok() =>
        tester.widget<FilledButton>(find.byKey(const Key('crew-name-ok')));
    expect(ok().onPressed, isNull);
    await tester.enterText(find.byKey(const Key('crew-name-field')), '가');
    await tester.pump();
    expect(ok().onPressed, isNull);
    await tester.enterText(
        find.byKey(const Key('crew-name-field')), '  한강 새벽러너  ');
    await tester.pump();
    expect(ok().onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('crew-name-ok')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('50 DIA'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('found:한강 새벽러너:dia'));
    expect(api.foundName, isNot(contains('인천 논현')));
  });

  testWidgets('cancelling the name creates nothing', (tester) async {
    final api = _FakeApi();
    await _pump(tester, api);
    await tester.ensureVisible(find.text('크루 만들기').first);
    await tester.tap(find.text('크루 만들기').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.doneKey));
    await tester.tap(find.byKey(CrewEmblemPicker.doneKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(api.calls.where((c) => c.startsWith('found')), isEmpty);
  });

  testWidgets('the first rename is free: no price question, just the new name',
      (tester) async {
    final api = _FakeApi(myRole: 'leader');
    await _pump(tester, api);
    expect(find.text('처음 한 번은 무료'), findsOneWidget);
    await tester.ensureVisible(find.text('크루 이름 바꾸기'));
    await tester.tap(find.text('크루 이름 바꾸기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crew-name-note')), findsOneWidget);
    expect(find.text('처음 한 번은 무료예요.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('crew-name-field')), '한강 새벽러너');
    await tester.pump();
    await tester.tap(find.byKey(const Key('crew-name-ok')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('rename:한강 새벽러너'));
    expect(find.textContaining('DIA 내고 바꾸기'), findsNothing);
  });

  testWidgets('a later rename shows 300 DIA and asks before charging',
      (tester) async {
    final api = _FakeApi(myRole: 'leader', renameCost: 300);
    await _pump(tester, api);
    expect(find.text('300 DIA'), findsOneWidget);
    await tester.ensureVisible(find.text('크루 이름 바꾸기'));
    await tester.tap(find.text('크루 이름 바꾸기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('crew-name-field')), '서울 밤 러너');
    await tester.pump();
    await tester.tap(find.byKey(const Key('crew-name-ok')));
    await tester.pumpAndSettle();
    expect(api.calls.where((c) => c.startsWith('rename')), isEmpty);
    expect(
        find.textContaining('300 DIA가 들어요. 보너스 DIA를 먼저 써요.'), findsOneWidget);
    await tester.tap(find.text('300 DIA 내고 바꾸기'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('rename:서울 밤 러너'));
  });

  testWidgets('declining the price keeps the old name', (tester) async {
    final api = _FakeApi(myRole: 'leader', renameCost: 300);
    await _pump(tester, api);
    await tester.ensureVisible(find.text('크루 이름 바꾸기'));
    await tester.tap(find.text('크루 이름 바꾸기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('crew-name-field')), '서울 밤 러너');
    await tester.pump();
    await tester.tap(find.byKey(const Key('crew-name-ok')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(api.calls.where((c) => c.startsWith('rename')), isEmpty);
  });

  testWidgets('only the leader sees the rename line', (tester) async {
    await _pump(tester, _FakeApi(myRole: 'sub'));
    expect(find.text('크루 이름 바꾸기'), findsNothing);
  });

  testWidgets('a crew that turned me down shows a disabled button',
      (tester) async {
    final api = _FakeApi(rejected: true);
    await _pump(tester, api);
    final button =
        tester.widget<FilledButton>(find.byKey(const Key('crew-join-c1')));
    expect(button.onPressed, isNull);
    expect(find.text('가입 불가'), findsOneWidget);
  });
}
