import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';

void main() {
  test('a set server nickname wins over this phone', () {
    expect(
      displayedAccountNickname(
        profileNickname: '서버이름',
        persistedNickname: '폰이름',
        persistedReady: true,
        controllerNickname: '컨트롤러',
      ),
      '서버이름',
    );
  });

  test('phone name shows only until the server name exists', () {
    expect(
      displayedAccountNickname(
        profileNickname: '달리기부자45',
        persistedNickname: '폰이름',
        persistedReady: true,
        controllerNickname: '',
      ),
      '폰이름',
    );
    expect(
      displayedAccountNickname(
        profileNickname: '',
        persistedNickname: '',
        persistedReady: false,
        controllerNickname: '입력중',
      ),
      '입력중',
    );
  });
}
