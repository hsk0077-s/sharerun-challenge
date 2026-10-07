import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/shop/providers/server_shop_inventory_provider.dart';
import 'package:share_run_challenge/features/shop/widgets/server_item_use_button.dart';

void main() {
  testWidgets('use button shows the server quantity and does not spend at 0',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverShopInventoryProvider.overrideWith(
            (ref) => Stream.value(
              const ServerShopInventory(cprCount: 2, ghostPaceCount: 0),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ServerItemUseButton(
                  itemId: ServerShopInventory.cprId,
                  label: '기록 심폐소생권',
                ),
                ServerItemUseButton(
                  itemId: ServerShopInventory.ghostPaceId,
                  label: '고스트 페이스 매칭',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('기록 심폐소생권 · 보유 2'), findsOneWidget);
    expect(find.text('고스트 페이스 매칭 · 보유 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('use-ghost_pace_match')));
    await tester.pump();

    expect(find.text('고스트 페이스 매칭 보유량이 없습니다.'), findsOneWidget);
    expect(find.text('고스트 페이스 매칭 · 보유 0'), findsOneWidget);
  });

  testWidgets('empty hint disables the button and keeps the server count',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverShopInventoryProvider.overrideWith(
            (ref) => Stream.value(const ServerShopInventory(cprCount: 0)),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ServerItemUseButton(
              itemId: ServerShopInventory.cprId,
              label: '심폐소생권 사용',
              emptyHint: '상점에서 구매',
              maxUses: 3,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('심폐소생권 사용 · 상점에서 구매'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.byKey(const Key('use-record_cpr_ticket')),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(const Key('use-record_cpr_ticket')));
    await tester.pump();
    expect(find.text('심폐소생권 사용 보유량이 없습니다.'), findsNothing);
  });

  testWidgets('owned count on the button is the server quantity over the cap',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverShopInventoryProvider.overrideWith(
            (ref) => Stream.value(const ServerShopInventory(cprCount: 2)),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ServerItemUseButton(
              itemId: ServerShopInventory.cprId,
              label: '심폐소생권 사용',
              emptyHint: '상점에서 구매',
              maxUses: 3,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('심폐소생권 사용 · 보유 2/3'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.byKey(const Key('use-record_cpr_ticket')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
      'three confirmed uses stop the button and do not change the count',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverShopInventoryProvider.overrideWith(
            (ref) => Stream.value(const ServerShopInventory(cprCount: 5)),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ServerItemUseButton(
              itemId: ServerShopInventory.cprId,
              label: '심폐소생권 사용',
              emptyHint: '상점에서 구매',
              maxUses: 3,
              spend: (_) async {
                calls += 1;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('use-record_cpr_ticket')));
      await tester.pump();
    }

    expect(calls, 3);
    expect(find.text('심폐소생권 사용 · 보유 5/3'), findsNothing);
    expect(find.text('심폐소생권 사용 · 보유 3/3'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('use-record_cpr_ticket')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('use-record_cpr_ticket')));
    await tester.pump();
    expect(calls, 3);
  });
}
