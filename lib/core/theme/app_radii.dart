import 'package:flutter/material.dart';

/// SRC corner-radius scale.
///
/// Derived from existing [AppShapes] (input 8, card 12, oauth 16, pill 30).
abstract final class AppRadii {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 30;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get pillAll => BorderRadius.circular(pill);

  static RoundedRectangleBorder get cardShape =>
      RoundedRectangleBorder(borderRadius: mdAll);

  static RoundedRectangleBorder get panelShape =>
      RoundedRectangleBorder(borderRadius: lgAll);

  static RoundedRectangleBorder get pillShape =>
      RoundedRectangleBorder(borderRadius: pillAll);
}
