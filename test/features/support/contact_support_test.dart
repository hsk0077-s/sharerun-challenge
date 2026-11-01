import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/support/contact_support.dart';

void main() {
  group('buildContactMailto', () {
    final uri = buildContactMailto(
      subject: '쉐어런 문의',
      note: '아래는 정보예요',
      appVersion: '1.0.0+4',
      device: 'SM-S911N',
      os: 'Android 14',
      language: 'ja',
    );

    test('mailto 주소와 제목이 들어간다', () {
      expect(uri.scheme, 'mailto');
      expect(uri.path, supportEmail);
      expect(uri.queryParameters['subject'], '쉐어런 문의');
    });

    test('본문에 앱 버전·기기·OS·언어가 들어간다', () {
      final body = uri.queryParameters['body']!;
      expect(body, contains('App 1.0.0+4'));
      expect(body, contains('SM-S911N'));
      expect(body, contains('Android 14'));
      expect(body, contains('ja'));
    });
  });
}
