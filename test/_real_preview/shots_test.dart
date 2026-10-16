
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:share_run_challenge/screens/main_dashboard_screen.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/currency_badge.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/donation/today_donation.dart';
import 'package:share_run_challenge/features/home/home_cards.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/profile/widgets/retention_widgets.dart';
import 'package:share_run_challenge/features/stamp/providers/stamp_tour_enabled_provider.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/features/tournaments/providers/local_joined_ids_provider.dart';
import 'package:share_run_challenge/screens/home_screen.dart';
import 'package:share_run_challenge/screens/main_dashboard_screen.dart';
import 'package:share_run_challenge/screens/my_page_screen.dart';
import 'package:share_run_challenge/screens/my_wallet_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = WalletModel(
  shareBalance: 90000,
  diamondBalance: 5,
  valueTokenBalance: 5200,
  totalDonationValue: 0,
);

const _room = TournamentModel(
  id: 'rookie-3k',
  title: 'Rookie 3K UNICEF Run',
  targetDistanceKm: 3,
  entryFeeShare: 100,
  winnerRewardValue: 500,
  donationValue: 200,
  minParticipantsBep: 10,
  maxParticipants: 100,
  participantCount: 4,
  requiredTier: 1,
  status: TournamentStatus.recruiting,
  sponsorName: 'UNICEF Partner',
);

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(_wallet);
}

Widget _scopedApp({required Widget home, UserModel? profileOverride}) {
  final profile = profileOverride ??
      UserModel.dashboardDefault(uid: 'test-home').copyWith(nickname: '테스트러너');
  return ProviderScope(
    overrides: [
      todayDonationLoaderProvider.overrideWithValue(
        () async => const TodayDonation(todayWon: 300, capReached: false),
      ),
      needsNicknameSetupProvider.overrideWith((ref) => false),
      userNicknameProvider.overrideWith((ref) => '테스트러너'),
      activeUserProfileProvider.overrideWith(
        (ref) => Stream<UserModel>.value(profile),
      ),
      activeWalletProvider.overrideWith(
        (ref) => Stream<WalletModel>.value(_wallet),
      ),
      walletProvider.overrideWith(_SeededWalletNotifier.new),
      recentActivitiesProvider.overrideWith(
        (ref) => Stream.value(const []),
      ),
      tournamentRoomsProvider.overrideWith(
        (ref) => Stream<List<TournamentModel>>.value(const [_room]),
      ),
      activeUserTierProvider.overrideWith((ref) => Stream<int>.value(1)),
      effectiveJoinedTournamentIdsProvider.overrideWith((ref) => <String>{}),
      retentionDailyKmProvider.overrideWith((ref) => 1.5),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SrcTheme.light,
      home: home,
    ),
  );
}

Future<void> _loadFonts() async {
  final pre = FontLoader('Pretendard');
  for (final f in ['Regular', 'SemiBold', 'Black']) {
    pre.addFont(File('assets/fonts/Pretendard-$f.otf').readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await pre.load();
  final mi = FontLoader('MaterialIcons')
    ..addFont(File('/tmp/claude-0/-home-user-sharerun-challenge/d7f3a010-4692-5bb3-9ad8-360e45a88df3/scratchpad/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytes().then((b) => ByteData.view(b.buffer)));
  await mi.load();
}

Future<void> _precacheAll(WidgetTester tester) async {
  await tester.runAsync(() async {
    final ctx = tester.element(find.byType(Scaffold).first);
    for (final dir in ['assets/images/characters', 'assets/images']) {
      for (final f in Directory(dir).listSync()) {
        if (f is File && (f.path.endsWith('.png') || f.path.endsWith('.jpg') || f.path.endsWith('.jpeg'))) {
          try { await precacheImage(AssetImage(f.path), ctx); } catch (_) {}
        }
      }
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('z_home', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(1170, 4500);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: _scopedApp(home: const MainDashboardScreen())));
    await tester.pump();
    await _precacheAll(tester);
    for (var i = 0; i < 8; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    Future<void> shot(String n) async {
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1.0);
        final d = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${Platform.environment['PREVIEW_OUT']}/$n.png').writeAsBytesSync(d!.buffer.asUint8List());
      });
    }
    await shot('z_home');
    final ex = tester.takeException();
    if (ex != null) { File('${Platform.environment['PREVIEW_OUT']}/z_home.err').writeAsStringSync(ex.toString()); }
  });
}
