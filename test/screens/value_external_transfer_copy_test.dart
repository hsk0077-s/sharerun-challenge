import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/screens/store_screen.dart';
import 'package:share_run_challenge/screens/web3_wallet_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('external VALUE transfer copy does not look live', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const StoreScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.storeValueDetailTitle), findsOneWidget);
    expect(find.text(AppStrings.storeValueDetailBody), findsOneWidget);
    expect(find.text(AppStrings.storeValueExternalTransfer), findsOneWidget);
    expect(find.text('VALUE 토큰 상세'), findsNothing);
    expect(find.text('외부 지갑 전송 (보안 승인)'), findsNothing);
    expect(find.textContaining('특정금융정보법'), findsNothing);
    expect(find.textContaining('전송 가능합니다'), findsNothing);

    await tester.tap(find.text(AppStrings.storeValueExternalTransfer));
    await tester.pumpAndSettle();

    expect(find.text('특금법 보안 승인'), findsNothing);
    expect(find.text('이해하고 전송 화면으로'), findsNothing);
    expect(find.text(AppStrings.web3WalletPendingNote), findsOneWidget);
    expect(find.text(AppStrings.storeValueTransferApprove), findsOneWidget);

    await tester.tap(find.text(AppStrings.storeValueTransferApprove));
    await tester.pumpAndSettle();

    expect(find.byType(Web3WalletScreen), findsOneWidget);
    expect(find.text(AppStrings.web3WalletPendingNote), findsOneWidget);
    expect(find.textContaining('보유 밸류(VALUE):'), findsOneWidget);
    expect(find.text(AppStrings.web3WalletTransferCta), findsOneWidget);
    expect(find.text('지갑 연결 및 토큰 전송'), findsNothing);
    expect(find.textContaining('MetaMask'), findsNothing);
    expect(find.textContaining('0x1A2b'), findsNothing);
    expect(find.textContaining('연동 완료'), findsNothing);
    expect(find.textContaining('가스비'), findsNothing);
    expect(find.textContaining('999,990'), findsNothing);
  });
}
