import 'package:flutter_test/flutter_test.dart';

/// 화면 그림(골든) 비교 테스트. 그림은 글꼴 렌더링이 다른 컴퓨터에서 조금씩 달라져서
/// 윈도우에서 만든 그림은 CI(리눅스)에서 항상 어긋난다. 그래서 `golden` 태그를 붙여
/// CI는 `flutter test --exclude-tags golden`으로 건너뛰고, 내 PC에서는 `flutter test`로
/// 그대로 비교한다. 그림을 새로 만들 때: `flutter test --update-goldens --tags golden`.
void goldenTest(String description, WidgetTesterCallback callback) {
  testWidgets(description, callback, tags: const ['golden']);
}
