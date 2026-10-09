import 'package:share_run_challenge/app/router/route_names.dart';

/// Application entry route — set during [main] after auto-login bootstrap.
abstract final class AppConfig {
  static String initialRoute = RouteNames.login;

  /// 첫 설치라서 소개 3장을 먼저 보여 줄지. [main]에서 정한다.
  static bool showIntro = false;
}
