abstract final class LegalConstants {
  static const shareRefundButtonLabel = '결제 취소 (현금 환불)';

  /// Legally separated from general ToS — explicit opt-in for biometric data.
  static const healthDataConsentLabel = '[선택] 건강정보(심박수) 수집 및 이용 동의';
  static const healthDataConsentTitle = '건강정보 수집 동의 (선택 · 별도)';

  @Deprecated('Use healthDataConsentLabel')
  static const sensitiveDataConsentLabel = healthDataConsentLabel;

  static const termsOfServiceTitle = '서비스 이용약관 (필수)';
  static const privacyPolicyTitle = '개인정보 처리방침 (필수)';
  static const pushNotificationsTitle = '마케팅·활동 알림 (선택)';

  static const termsOfServiceSummary =
      'SRC는 검증된 러닝 활동, 대회 참가, 기부형 리워드를 제공합니다. '
      '부정 러닝·결제 어뷰징은 계정 제한 대상이 될 수 있습니다.';

  static const privacyPolicySummary =
      '계정 식별 정보, 러닝 검증 결과, 결제 의도 기록을 서비스 제공 목적으로 처리합니다. '
      '심박·케이던스 원시 데이터는 Jena 검증 직후 즉시 폐기됩니다.';

  static const healthDataConsentSummary =
      '스마트워치·HealthKit·Health Connect를 통해 심박수·케이던스를 읽어 '
      'Jena AI 러닝 검증에만 사용합니다. 동의하지 않아도 앱 이용은 가능하나, '
      '워치 연동 및 검증된 러닝 채굴은 제한됩니다. '
      '원시 심박 배열은 서버 DB에 저장되지 않으며 검증 직후 메모리에서 즉시 파기됩니다.';

  static const pushNotificationsSummary =
      '대회 모집, 검증 결과, 리워드·기부 알림을 푸시로 받을 수 있습니다. '
      '언제든 MyPage에서 변경할 수 있습니다.';

  static const ephemeralSensorPolicy =
      'Heart-rate and cadence arrays are ephemeral: validated in memory, then destroyed. '
      'Only jenaVerified summary fields are persisted.';
}