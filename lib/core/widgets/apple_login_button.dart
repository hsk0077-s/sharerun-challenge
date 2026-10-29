import 'package:flutter/material.dart';

import '../../l10n/remaining_surface.dart';

/// 애플 로그인 버튼. 애플 디자인 규칙대로 검은 배경에 흰 애플 로고와 흰 글자를 쓰고,
/// 로그인 화면의 다른 소셜 버튼과 높이(44)와 모서리를 맞춘다.
/// 아직 애플 로그인은 준비 중이라 눌렀을 때 하는 일은 호출하는 쪽이 정한다.
class AppleLoginButton extends StatelessWidget {
  const AppleLoginButton({
    super.key,
    required this.onPressed,
    this.label,
  });

  final VoidCallback onPressed;
  final String? label;

  static const buttonKey = Key('apple-login-button');
  static const double height = 44;
  static const double radius = 12;

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = label ??
        RemainingSurface.tr(
          context,
          'widget.apple_login_button.button',
          'Apple로 계속하기',
        );
    return Semantics(
      button: true,
      label: resolvedLabel,
      excludeSemantics: true,
      child: Material(
        key: buttonKey,
        color: Colors.black,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apple, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  resolvedLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
