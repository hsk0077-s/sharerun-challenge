import 'package:flutter/material.dart';

/// 카카오가 배포한 공식 "카카오 로그인" 버튼 이미지를 그대로 쓴다. 직접 그린 모양이나 색을
/// 쓰지 않는다. 공식 이미지는 높이가 46으로 같고 너비만 네 가지(112, 224, 336, 448)라서,
/// 자리 너비에 맞춰 비율을 지켜 늘이거나 줄였을 때 높이가 공식 높이(46)에 가장 가까워지는
/// 것을 고른다. 큰 이미지를 많이 줄이면 버튼 높이와 글자가 같이 작아지기 때문이다.
/// (예: 371 너비에 448짜리를 줄이면 높이 38, 336짜리를 늘리면 높이 약 51.)
class KakaoLoginButton extends StatelessWidget {
  const KakaoLoginButton({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.maxWidth,
  });

  final VoidCallback onPressed;

  /// 로그인 중. 눌러도 반응하지 않고 흐리게 보인다.
  final bool busy;

  /// 쓸 수 있는 너비를 직접 알려 준다. 주면 너비를 재는 틀(LayoutBuilder)을 쓰지 않는다.
  /// 높이를 맞추는 틀(IntrinsicHeight) 안에서는 LayoutBuilder가 디버그에서 오류를 내므로,
  /// 그런 곳에서는 반드시 이 값을 준다.
  final double? maxWidth;

  static const imageKey = Key('kakao-login-button-image');

  /// 공식 이미지의 높이(논리 픽셀). 네 가지 너비 모두 같다.
  static const double _height = 46;

  static const _variants = <(String, double)>[
    ('small', 112),
    ('medium', 224),
    ('large', 336),
    ('xlarge', 448),
  ];

  /// 가장 큰 공식 너비. 이보다 넓게는 늘이지 않는다.
  static const double maxButtonWidth = 448;

  /// 자리 너비 [available]에 맞췄을 때 높이가 공식 높이(46)에 가장 가까워지는 공식 이미지.
  static String variantFor(double available) {
    final width = available < maxButtonWidth ? available : maxButtonWidth;
    var best = _variants.first;
    var bestGap = double.infinity;
    for (final variant in _variants) {
      final gap = (width * _height / variant.$2 - _height).abs();
      if (gap < bestGap) {
        best = variant;
        bestGap = gap;
      }
    }
    return best.$1;
  }

  /// 자리 너비에 맞춘 버튼 너비. 공식 이미지의 비율을 지키므로 높이는 `너비 × 46 ÷ 이미지 너비`.
  static double widthFor(double available) =>
      available < maxButtonWidth ? available : maxButtonWidth;

  static double heightFor(double available) =>
      widthFor(available) * _height / widthOf(variantFor(available));

  static double widthOf(String variant) =>
      _variants.firstWhere((v) => v.$1 == variant).$2;

  @override
  Widget build(BuildContext context) {
    final fixed = maxWidth;
    if (fixed != null) return _button(fixed);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _variants.last.$2;
        return _button(available);
      },
    );
  }

  Widget _button(double available) {
    final variant = variantFor(available);
    final width = widthFor(available);
    return Center(
      child: Semantics(
        button: true,
        enabled: !busy,
        label: '카카오 로그인',
        excludeSemantics: true,
        child: Opacity(
          opacity: busy ? 0.6 : 1,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: busy ? null : onPressed,
            child: SizedBox(
              width: width,
              // 이미지가 읽히기 전에도 자리가 흔들리지 않게 공식 비율(높이 46)로 미리 잡는다.
              height: heightFor(available),
              child: Image.asset(
                'assets/images/kakao/kakao_login_kr_$variant.png',
                key: imageKey,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
