import 'package:flutter/material.dart';

/// 네이버가 배포한 공식 "네이버 로그인" 버튼 이미지(한글, 초록색, 가운데 정렬형)를 그대로 쓴다.
/// 공식 이미지는 가로 368, 세로 48(논리 픽셀)이다. 모양과 색, 글자를 바꾸지 않고 자리에
/// 맞게 같은 비율로만 줄인다. 가장 큰 크기(368)보다는 키우지 않는다.
class NaverLoginButton extends StatelessWidget {
  const NaverLoginButton({
    super.key,
    required this.onPressed,
    this.busy = false,
  });

  final VoidCallback onPressed;

  /// 로그인 중. 눌러도 반응하지 않고 흐리게 보인다.
  final bool busy;

  static const imageKey = Key('naver-login-button-image');

  static const double officialWidth = 368;
  static const double officialHeight = 48;

  /// 자리 너비 [available]에 맞춘 버튼 너비. 공식 크기보다 커지지 않는다.
  static double widthFor(double available) =>
      available < officialWidth ? available : officialWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : officialWidth;
        final width = widthFor(available);
        return Center(
          child: Semantics(
            button: true,
            enabled: !busy,
            label: '네이버 로그인',
            excludeSemantics: true,
            child: Opacity(
              opacity: busy ? 0.6 : 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: busy ? null : onPressed,
                child: SizedBox(
                  width: width,
                  // 이미지가 읽히기 전에도 자리가 흔들리지 않게 공식 비율로 미리 잡는다.
                  height: width * officialHeight / officialWidth,
                  child: Image.asset(
                    'assets/images/naver/naver_login_kr.png',
                    key: imageKey,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
