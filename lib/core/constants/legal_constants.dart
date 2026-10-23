abstract final class LegalConstants {
  static const shareRefundButtonLabel = '결제 취소 (현금 환불)';

  /// Legally separated from general ToS — explicit opt-in for biometric data.
  static const healthDataConsentLabel = '[선택] 건강정보(심박수) 수집 및 이용 동의';
  static const healthDataConsentTitle = '건강정보 수집 동의 (선택 · 별도)';

  @Deprecated('Use healthDataConsentLabel')
  static const sensitiveDataConsentLabel = healthDataConsentLabel;

  /// Public pages (Firebase Hosting `web` target). Google Play lists the same
  /// addresses, so the in-app text and the store listing never differ.
  static const privacyPolicyUrl =
      'https://share-run-challenge.web.app/privacy.html';
  static const termsOfServiceUrl =
      'https://share-run-challenge.web.app/terms.html';
  static const accountDeletionUrl =
      'https://share-run-challenge.web.app/account-deletion.html';

  static const privacyPolicyLinkLabel = '개인정보 처리방침 전문 보기';
  static const termsOfServiceLinkLabel = '서비스 이용약관 전문 보기';

  /// 이미지 생성 서비스(Grok) 약관과 Brand Guidelines의 표기 요구에 따른 안내 문구.
  /// Brand Guidelines는 'Created with Grok'를 읽기 쉽게 보이라고 한다.
  static const aiGeneratedTitle = 'AI 생성 이미지 안내';
  static const aiGeneratedCredit = '일부 그림은 AI로 생성되었습니다. Created with Grok';

  static const termsOfServiceTitle = '서비스 이용약관 (필수)';
  static const privacyPolicyTitle = '개인정보 처리방침 (필수)';
  static const pushNotificationsTitle = '마케팅·활동 알림 (선택)';

  static const termsOfServiceSummary = '쉐어런은 검증된 러닝 활동과 대회 참가를 제공하며, 달린 거리에 따라 '
      '운영자 이름으로 기부가 이뤄집니다. '
      '부정 러닝·결제 어뷰징은 계정 제한 대상이 될 수 있습니다.';

  static const privacyPolicySummary =
      '계정 식별 정보, 러닝 검증 결과, 결제 의도 기록을 서비스 제공 목적으로 처리합니다. '
      '심박·케이던스 원시 데이터는 Jena 검증 직후 즉시 폐기됩니다. '
      '전체 내용은 개인정보 처리방침 전문에서 확인할 수 있습니다.';

  static const healthDataConsentSummary =
      '스마트워치·HealthKit·Health Connect를 통해 심박수·케이던스를 읽어 '
      '러닝 검증에만 사용합니다. 동의하지 않아도 앱 이용은 가능하나, '
      '워치 연동 및 검증된 러닝 땀방울 적립은 제한됩니다. '
      '원시 심박 배열은 서버 DB에 저장되지 않으며 검증 직후 메모리에서 즉시 파기됩니다.';

  static const pushNotificationsSummary =
      '대회 모집, 검증 결과, 리워드·기부 알림을 푸시로 받을 수 있습니다. '
      '언제든 MyPage에서 변경할 수 있습니다.';

  static const ephemeralSensorPolicy =
      '심박수·케이던스 원본 데이터는 기기 메모리에서 검증한 뒤 바로 폐기하며, '
      '검증 결과 요약만 저장합니다.';

  /// 건강·의료 면책. 심박 코칭과 건강정보 연동이 있는 앱이라 심사와 이용자 모두에게 분명히 알린다.
  static const healthDisclaimerTitle = '건강 정보 안내';
  static const healthDisclaimer = '쉐어런의 심박·케이던스·코칭 안내는 운동을 돕기 위한 참고 정보이며 '
      '의료 목적이 아닙니다. 질병의 진단·치료·예방을 대신하지 않습니다. '
      '가슴 통증, 어지러움 등 이상이 느껴지면 즉시 운동을 멈추고 의료진과 상담하세요.';

  /// 구독 구매 화면 고지. 자동 갱신과 해지 방법을 구매 버튼 옆에서 알린다.
  static const subscriptionTerms =
      'Coach+는 해지하기 전까지 선택한 주기(월·연)마다 Google Play 결제 수단으로 '
      '자동 갱신됩니다. Google Play 스토어 앱의 계정 > 결제 및 구독 > 구독에서 '
      '언제든 해지할 수 있으며, 해지해도 이미 결제한 기간이 끝날 때까지 이용할 수 있습니다.';
}
