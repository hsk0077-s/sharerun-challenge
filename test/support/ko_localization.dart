import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';

/// Locale arguments for a test `MaterialApp`.
///
/// Screens read their text through `RemainingSurface.tr(context, ...)`, which
/// follows the `Localizations` of the tree. A bare `MaterialApp` resolves to
/// `en_US`, so those screens render English and a test that looks for Korean
/// text finds nothing. The Korean Material/Widgets/Cupertino delegates are
/// needed too, or dialogs and buttons throw for the `ko` locale.
///
/// ```dart
/// MaterialApp(
///   locale: koTestLocale,
///   supportedLocales: koTestSupportedLocales,
///   localizationsDelegates: koTestDelegates,
///   home: const MyScreen(),
/// )
/// ```
const koTestLocale = Locale('ko', 'KR');

/// Same list the app ships, so a `ko` locale is always among them.
const koTestSupportedLocales = ShareRunLocalizations.supportedLocales;

const koTestDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
