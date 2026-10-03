import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/profile/avatar_choice.dart';
import 'package:share_run_challenge/features/profile/avatar_choice_provider.dart';
import 'package:share_run_challenge/features/profile/user_profile_notifier.dart';
import 'package:share_run_challenge/features/profile/widgets/angel_tier_widgets.dart';
import 'package:share_run_challenge/features/profile/widgets/gender_profile_avatar.dart';
import 'package:share_run_challenge/screens/personal_sponsor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wing asset path and hole geometry', () {
    expect(AngelTier.preAngel.wingAssetPath, isNull);

    for (final tier in const [
      AngelTier.cupid,
      AngelTier.guardian,
      AngelTier.archangel,
    ]) {
      expect(tier.wingAssetPath, 'assets/images/wings/wing_${tier.code}.png');
      expect(tier.wingHoleCenterX, 0.5);
      expect(tier.wingHoleCenterY, 0.5);
      expect(tier.wingHoleDiameter, closeTo(0.30, 0.0001));
    }

    for (final tier in const [AngelTier.cherubim, AngelTier.seraphim]) {
      expect(tier.wingAssetPath, 'assets/images/wings/wing_${tier.code}.png');
      expect(tier.wingHoleCenterX, 0.5);
      expect(tier.wingHoleCenterY, closeTo(0.535, 0.0001));
      expect(tier.wingHoleDiameter, closeTo(0.205, 0.0001));
    }
  });

  test('layout fits the avatar into the hole and clamps width', () {
    final cupid = AngelWingAvatar.layoutFor(
      tier: AngelTier.cupid,
      avatarSize: 72,
      maxWidth: 360,
    );
    expect(cupid.avatar, 72);
    expect(cupid.width, closeTo(72 / 0.30, 0.01));
    expect(
      cupid.height,
      closeTo(cupid.width * AngelWingAvatar.wingHeightOverWidth, 0.01),
    );

    // 360dp phone with 20px page padding on each side.
    const padded = 360.0 - 40;
    final seraphim = AngelWingAvatar.layoutFor(
      tier: AngelTier.seraphim,
      avatarSize: 72,
      maxWidth: padded,
    );
    expect(seraphim.width, padded);
    expect(seraphim.avatar, lessThan(72));
    expect(seraphim.avatar, closeTo(padded * 0.205, 0.01));

    final preAngel = AngelWingAvatar.layoutFor(
      tier: AngelTier.preAngel,
      avatarSize: 72,
      maxWidth: 360,
    );
    expect(preAngel.width, 72);
    expect(preAngel.height, 72);
  });

  testWidgets('pre-angel shows the photo and no wing plate', (tester) async {
    await _pumpAvatar(tester, tier: AngelTier.preAngel, maxWidth: 360);

    expect(find.byType(GenderProfileAvatar), findsOneWidget);
    expect(_wingImages(), findsNothing);
    expect(tester.getSize(find.byType(GenderProfileAvatar)).width, 72);
  });

  testWidgets('photo sits in the hole and stays above the wing', (
    tester,
  ) async {
    await _pumpAvatar(tester, tier: AngelTier.cupid, maxWidth: 360);

    final wing = tester.getRect(_wingImages());
    final avatar = tester.getRect(find.byType(GenderProfileAvatar));
    expect(wing.width, closeTo(72 / 0.30, 0.5));
    expect(avatar.width, closeTo(72, 0.5));
    expect(avatar.center.dx, closeTo(wing.left + wing.width * 0.5, 0.6));
    expect(avatar.center.dy, closeTo(wing.top + wing.height * 0.5, 0.6));
    expect(wing.contains(avatar.center), isTrue);

    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(AngelWingAvatar),
        matching: find.byType(Stack),
      ),
    );
    expect(stack.clipBehavior, Clip.none);
    expect(
      (stack.children.last as Positioned).child,
      isA<GenderProfileAvatar>(),
    );

    final wingImage = tester.widget<Image>(_wingImages());
    expect(wingImage.errorBuilder, isNotNull);
    expect(
      find.descendant(of: find.byType(IgnorePointer), matching: _wingImages()),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.descendant(
          of: find.byType(AngelWingAvatar),
          matching: find.byType(IgnorePointer),
        ),
        matching: find.byType(GenderProfileAvatar),
      ),
      findsNothing,
    );

    final wingHit = tester.hitTestOnBinding(
      wing.centerLeft + const Offset(6, 0),
    );
    expect(wingHit.path.where((entry) => entry.target is RenderImage), isEmpty);

    final avatarHit = tester.hitTestOnBinding(avatar.center);
    expect(
      avatarHit.path.where((entry) => entry.target is RenderImage),
      isNotEmpty,
    );
  });

  testWidgets('cherubim hole is lower so the halo stays above the photo', (
    tester,
  ) async {
    await _pumpAvatar(tester, tier: AngelTier.cherubim, maxWidth: 400);

    final wing = tester.getRect(_wingImages());
    final avatar = tester.getRect(find.byType(GenderProfileAvatar));
    expect(avatar.width, closeTo(wing.width * 0.205, 0.6));
    expect(avatar.center.dx, closeTo(wing.left + wing.width * 0.5, 0.6));
    expect(avatar.center.dy, closeTo(wing.top + wing.height * 0.535, 0.6));
    expect(avatar.top, greaterThan(wing.top));
  });

  testWidgets('top tiers shrink to the screen on a 360dp phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpAvatar(
      tester,
      tier: AngelTier.seraphim,
      avatarSize: 88,
      maxWidth: 800,
    );

    final wing = tester.getSize(
      find.descendant(
        of: find.byType(AngelWingAvatar),
        matching: find.byType(Stack),
      ),
    );
    expect(wing.width, lessThanOrEqualTo(360));
    expect(wing.width, closeTo(360, 0.5));
    final avatar = tester.getSize(find.byType(GenderProfileAvatar));
    expect(avatar.width, lessThan(88));
    expect(avatar.width, closeTo(wing.width * 0.205, 0.6));
  });

  testWidgets('chronicle card uses the photo wings, not the chibi mascot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scope(count: 100, child: const Scaffold(body: AngelChronicleCard())),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AngelMascot), findsNothing);
    expect(find.byType(AngelWingAvatar), findsOneWidget);
    expect(find.byType(GenderProfileAvatar), findsOneWidget);
    expect(_wingImages(), findsOneWidget);
    expect(
      tester.widget<Image>(_wingImages()).image,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'assetName',
        AngelTier.seraphim.wingAssetPath,
      ),
    );

    final wing = tester.getSize(
      find.descendant(
        of: find.byType(AngelWingAvatar),
        matching: find.byType(Stack),
      ),
    );
    final avatar = tester.getSize(find.byType(GenderProfileAvatar));
    expect(wing.width, lessThanOrEqualTo(360));
    expect(avatar.width, lessThan(72));
    expect(avatar.width, closeTo(wing.width * 0.205, 0.8));
    expect(find.textContaining('세라핌'), findsOneWidget);
  });

  testWidgets('sponsor header keeps the photo on top of the wing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scope(count: 100, child: const PersonalSponsorScreen()),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AngelMascot), findsNothing);
    expect(find.byType(AngelWingAvatar), findsOneWidget);
    expect(_chibiImages(), findsNothing);

    final wing = tester.getRect(_wingImages());
    final avatar = tester.getRect(find.byType(GenderProfileAvatar));
    expect(wing.width, lessThanOrEqualTo(320));
    expect(avatar.width, lessThan(72));
    expect(avatar.center.dx, closeTo(wing.center.dx, 0.6));
    expect(wing.contains(avatar.center), isTrue);
    expect(
      tester
          .widget<Stack>(
            find.descendant(
              of: find.byType(AngelWingAvatar),
              matching: find.byType(Stack),
            ),
          )
          .children
          .last,
      isA<Positioned>().having(
        (positioned) => positioned.child,
        'child',
        isA<GenderProfileAvatar>(),
      ),
    );
  });

  testWidgets('celebration dialog keeps top-tier wings inside a 360dp phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scope(
        count: 100,
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) {
                      return const AlertDialog(
                        content: AngelWingAvatar(
                          tier: AngelTier.seraphim,
                          avatarSize: 88,
                        ),
                      );
                    },
                  );
                },
                child: const Text('celebrate'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('celebrate'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final wing = tester.getSize(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Stack),
      ),
    );
    final avatar = tester.getSize(find.byType(GenderProfileAvatar));
    expect(wing.width, lessThanOrEqualTo(360));
    expect(
      avatar.width,
      closeTo(wing.width * AngelTier.seraphim.wingHoleDiameter, 0.8),
    );
    expect(
      tester.getRect(find.byType(GenderProfileAvatar)).center.dy,
      closeTo(
        tester.getRect(_wingImages()).top +
            tester.getRect(_wingImages()).height * 0.535,
        0.8,
      ),
    );
  });

  testWidgets('AngelMascot remains for the book and hall of fame', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AngelMascot(tier: AngelTier.preAngel, size: 88)),
      ),
    );
    await tester.pump();

    expect(find.byType(AngelMascot), findsOneWidget);
    expect(find.byType(AngelWingAvatar), findsNothing);
    expect(_chibiImages(), findsOneWidget);
  });
}

Finder _wingImages() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Image) return false;
    final provider = widget.image;
    return provider is AssetImage &&
        provider.assetName.startsWith('assets/images/wings/');
  });
}

Finder _chibiImages() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Image) return false;
    final provider = widget.image;
    return provider is AssetImage && provider.assetName.contains('chibi_');
  });
}

class _DonationProfile extends UserProfileNotifier {
  _DonationProfile(this.count);

  final int count;

  @override
  UserProfile build() {
    return UserModel.dashboardDefault(uid: 'angel-test')
        .copyWith(donationCount: count, nickname: '테스터');
  }
}

class _FixedAvatar extends AvatarChoiceNotifier {
  @override
  AvatarChoice build() => const AvatarChoice(presetId: AvatarChoice.maleId);
}

Widget _scope({required int count, required Widget child}) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith(() => _DonationProfile(count)),
      userNicknameProvider.overrideWith((ref) => '테스터'),
      avatarChoiceProvider.overrideWith(_FixedAvatar.new),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SrcTheme.light,
      home: child,
    ),
  );
}

Future<void> _pumpAvatar(
  WidgetTester tester, {
  required AngelTier tier,
  required double maxWidth,
  double avatarSize = 72,
}) async {
  await tester.pumpWidget(
    _scope(
      count: 0,
      child: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: AngelWingAvatar(tier: tier, avatarSize: avatarSize),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
