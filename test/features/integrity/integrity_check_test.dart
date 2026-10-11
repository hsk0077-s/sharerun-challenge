import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/integrity/integrity_check.dart';

void main() {
  final now = DateTime(2026, 10, 11, 12);

  test('the first run checks once', () {
    expect(integrityCheckDue(null, now), isTrue);
  });

  test('a check within 24 hours is not repeated', () {
    final last = now.subtract(const Duration(hours: 23)).millisecondsSinceEpoch;
    expect(integrityCheckDue(last, now), isFalse);
  });

  test('after 24 hours it checks again', () {
    final last = now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch;
    expect(integrityCheckDue(last, now), isTrue);
  });

  test('a clock set backwards does not block checks forever', () {
    final last = now.add(const Duration(days: 3)).millisecondsSinceEpoch;
    expect(integrityCheckDue(last, now), isTrue);
  });
}
