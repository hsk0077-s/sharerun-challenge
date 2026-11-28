import 'package:flutter/widgets.dart';

import '../../l10n/remaining_surface.dart';
import '../api/api_exception.dart';

/// Copy for a toast, snackbar, dialog, or inline error.
///
/// [ApiException.userMessage] is shown when the server detail already has a
/// sentence for the user. Every other error shows [ko], which keeps the
/// original lead and asks the user to try again. The raw exception is logged
/// only.
String userVisibleFailure(
  BuildContext? context,
  Object error, {
  required String key,
  required String ko,
}) {
  if (error is ApiException) {
    debugPrint('[$key] HTTP ${error.statusCode} ${error.detail}');
    return error.userMessage;
  }
  debugPrint('[$key] $error');
  return RemainingSurface.tr(context, key, ko);
}
