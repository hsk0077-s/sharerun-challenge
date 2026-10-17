import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/data/api/secured_action_api_client.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/crew/crew_membership.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
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
  _FakeApi({this.myRole});

  String? myRole;
  final calls = <String>[];

  static const _crew = CrewSummary(
    id: 'c1',
    name: '새벽러너',
    emblem: 'shield:g_wolf:rays:navy:white',
    memberCount: 12,
    maxMembers: 100,
    totalDistanceKm: 321,
  );

  @override
  Future<List<CrewSummary>> listCrews(String query) async {
    calls.add('list:$query');
    return query.isNotEmpty && !_crew.name.contains(query) ? const [] : [_crew];
  }

  @override
  Future<MyCrew?> myCrew() async => myRole == null
      ? null
      : MyCrew(
          crew: _crew,
          role: myRole!,
          members: const [
            CrewMember(uid: 'u1', nickname: '대장', role: 'leader'),
            CrewMember(uid: 'u2', nickname: '러너2', role: 'member'),
          ],
        );

  @override
  Future<void> joinCrew(String crewId) async {
    calls.add('join:$crewId');
    myRole = 'member';
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
    expect(find.text('12/100명'), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('crew-role-u2')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('role:u2:sub'));
  });

  testWidgets('a plain member sees the list but no appoint buttons',
      (tester) async {
    final api = _FakeApi(myRole: 'member');
    await _pump(tester, api);
    await tester.ensureVisible(find.text('크루원 보기'));
    await tester.tap(find.text('크루원 보기'));
    await tester.pumpAndSettle();
    expect(find.text('러너2'), findsOneWidget);
    expect(find.byKey(const Key('crew-role-u2')), findsNothing);
  });
}
