import 'package:share_run_challenge/app/router/route_names.dart';

/// Application entry route — set during [main] after auto-login bootstrap.
abstract final class AppConfig {
  static String initialRoute = RouteNames.login;
}
