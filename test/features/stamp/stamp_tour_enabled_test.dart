import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/stamp/providers/stamp_tour_enabled_provider.dart';

void main() {
  test('stamp tour stays hidden unless config enabled is exactly true', () {
    expect(stampTourEnabledFrom(null), isFalse);
    expect(stampTourEnabledFrom(const {}), isFalse);
    expect(stampTourEnabledFrom(const {'landmarks': []}), isFalse);
    expect(stampTourEnabledFrom(const {'enabled': false}), isFalse);
    expect(stampTourEnabledFrom(const {'enabled': 'true'}), isFalse);
    expect(stampTourEnabledFrom(const {'enabled': 1}), isFalse);
    expect(stampTourEnabledFrom(const {'enabled': true}), isTrue);
  });
}
