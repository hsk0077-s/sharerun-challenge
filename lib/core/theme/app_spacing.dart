/// SRC spacing scale (4pt grid).
///
/// Prefer these over ad-hoc padding. Login-specific gaps stay on [AppShapes].
///
/// 4의 배수 간격. 화면별 예외(로그인 목업)는 [AppShapes]에 남깁니다.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Horizontal page inset — matches existing terms / dashboard padding.
  static const double page = 20;
}
