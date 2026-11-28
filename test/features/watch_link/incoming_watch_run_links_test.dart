import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/watch_link/incoming_watch_run_links.dart';
import 'package:share_run_challenge/features/watch_link/watch_run_link.dart';
import 'package:share_run_challenge/features/watch_link/watch_shop_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(watchRunLinksChannel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('getInitialLink returns the link the native side kept', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getInitialLink');
      return 'sharerun://run/act_42';
    });
    expect(await IncomingWatchRunLinks().getInitialLink(), 'sharerun://run/act_42');
  });

  test('getInitialLink is null when the native side has none or is missing', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    expect(await IncomingWatchRunLinks().getInitialLink(), isNull);
    messenger.setMockMethodCallHandler(channel, null);
    expect(await IncomingWatchRunLinks().getInitialLink(), isNull);
  });

  test('onLink from the native side reaches the listener; blanks do not', () async {
    final links = IncomingWatchRunLinks();
    final seen = <String>[];
    links.listen(seen.add);
    const codec = StandardMethodCodec();
    Future<void> send(Object? arg) => messenger.handlePlatformMessage(
          watchRunLinksChannel,
          codec.encodeMethodCall(MethodCall('onLink', arg)),
          (_) {},
        );
    await send('sharerun://shop');
    await send('  ');
    await send(7);
    expect(seen, ['sharerun://shop']);
    links.dispose();
  });

  test('links in the form iOS passes (URL.absoluteString) open the same screens', () {
    // iOS hands over URL.absoluteString, Android Uri.toString(): the same text.
    expect(WatchShopLink.parse('sharerun://shop')!.location,
        const WatchShopLink().location);
    expect(WatchRunLink.parse('sharerun://run/act_42')!.location,
        const WatchRunLink(activityId: 'act_42').location);
    expect(WatchRunLink.parse('sharerun://run?id=act_42')!.location,
        const WatchRunLink(activityId: 'act_42').location);
  });

  group('iOS native side (source check; no Mac here)', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final app = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final scene = File('ios/Runner/SceneDelegate.swift').readAsStringSync();

    test('Info.plist registers the sharerun scheme exactly once', () {
      expect(RegExp(r'<string>sharerun</string>').allMatches(plist).length, 1);
      // The existing schemes stay.
      for (final s in [
        'kakaoc45c63710e60f98b3fe617ae0b75c274',
        'com.googleusercontent.apps.',
        '<string>sharerunchallenge</string>',
      ]) {
        expect(plist.contains(s), isTrue, reason: s);
      }
    });

    test('AppDelegate answers getInitialLink and sends onLink on share_run/links', () {
      expect(app.contains('name: "share_run/links"'), isTrue);
      expect(app.contains('call.method == "getInitialLink"'), isTrue);
      expect(app.contains('invokeMethod("onLink", arguments: link)'), isTrue);
      expect(app.contains('static let scheme = "sharerun"'), isTrue);
      expect(app.contains('ShareRunLinks.shared.attach(messenger:'), isTrue);
    });

    test('SceneDelegate forwards links at cold start and while open', () {
      expect(scene.contains('willConnectTo session: UISceneSession'), isTrue);
      expect(scene.contains('connectionOptions.urlContexts'), isTrue);
      expect(scene.contains('openURLContexts URLContexts'), isTrue);
      expect(
          RegExp(r'ShareRunLinks\.shared\.receive\(context\.url\)').allMatches(scene).length,
          2);
      // Other links still reach the plugins (Kakao, Google sign-in).
      expect(scene.contains('super.scene(scene, openURLContexts: URLContexts)'), isTrue);
      expect(
          scene.contains('super.scene(scene, willConnectTo: session, options: connectionOptions)'),
          isTrue);
    });
  });
}
