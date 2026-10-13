import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('the app key in the manifest is the one the app starts Kakao with', () {
    final main = File('lib/main.dart').readAsStringSync();
    final key =
        RegExp(r"nativeAppKey: '([0-9a-f]+)'").firstMatch(main)!.group(1);
    expect(key, isNotNull);
    expect(manifest, contains('android:scheme="kakao$key"'));
  });

  test('the main screen can be opened by the Kakao "자세히 보기" link', () {
    // 카카오톡 공유 메시지의 "자세히 보기"는 kakao{앱키}://kakaolink 주소로 앱을 연다.
    // 받아 줄 입구가 없으면 눌러도 아무 일도 일어나지 않는다.
    final main = File('lib/main.dart').readAsStringSync();
    final key =
        RegExp(r"nativeAppKey: '([0-9a-f]+)'").firstMatch(main)!.group(1)!;
    final mainActivity = manifest.substring(
      manifest.indexOf('android:name=".MainActivity"'),
      manifest.indexOf(
          '</activity>', manifest.indexOf('android:name=".MainActivity"')),
    );
    expect(mainActivity, contains('android:scheme="kakao$key"'));
    expect(mainActivity, contains('android:host="kakaolink"'));
    expect(mainActivity, contains('android.intent.category.BROWSABLE'));
    // 주소는 앱만 열고 화면 이동에는 쓰지 않는다.
    expect(mainActivity, contains('flutter_deeplinking_enabled'));
  });
}
