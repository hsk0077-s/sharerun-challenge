import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/router/main_shell_routes.dart';
import 'package:share_run_challenge/core/navigation/open_popup_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every real tab branch has the popup tracker', () {
    final shell = buildMainShellAndDetailRoutes().first as StatefulShellRoute;
    expect(shell.branches.length, 5);
    for (final branch in shell.branches) {
      expect(
        branch.observers?.whereType<OpenPopupTracker>().length,
        1,
        reason: 'branch ${branch.defaultRoute?.path}',
      );
    }
  });
}
