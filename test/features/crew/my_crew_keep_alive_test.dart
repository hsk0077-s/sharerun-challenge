import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/crew/crew_membership.dart';

void main() {
  test('my crew stays loaded after the crew tab closes (no flicker on reopen)',
      () async {
    final container = ProviderContainer(
      overrides: [crewApiProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);

    final sub = container.listen(myCrewProvider, (_, __) {});
    await container.read(myCrewProvider.future);
    sub.close();
    await Future<void>.delayed(Duration.zero);

    expect(container.exists(myCrewProvider), isTrue);
    expect(container.read(myCrewProvider).hasValue, isTrue);
  });
}
