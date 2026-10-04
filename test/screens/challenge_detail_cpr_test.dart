import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/shop/providers/server_shop_inventory_provider.dart';
import 'package:share_run_challenge/screens/challenge_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDetail(
    WidgetTester tester, {
    required int cprCount,
  }) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverShopInventoryProvider.overrideWith(
            (ref) => Stream.value(ServerShopInventory(cprCount: cprCount)),
          ),
        ],
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const ChallengeDetailScreen(
            roomId: RouteNames.beginner1kmRoomId,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('1km challenge shows the server CPR count', (tester) async {
    await pumpDetail(tester, cprCount: 2);

    expect(find.text('1km 초보 챌린지'), findsOneWidget);
    expect(find.text('심폐소생권 보유: 2/3'), findsNothing);
    expect(find.text('심폐소생권 사용 · 보유 2/3'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('use-record_cpr_ticket')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('CPR use is disabled with a shop hint at zero', (tester) async {
    await pumpDetail(tester, cprCount: 0);

    expect(find.text('심폐소생권 보유: 0/3'), findsNothing);
    expect(find.text('심폐소생권 사용 · 상점에서 구매'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('use-record_cpr_ticket')),
          )
          .onPressed,
      isNull,
    );
  });
}
