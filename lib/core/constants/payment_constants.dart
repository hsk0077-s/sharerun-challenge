import '../../core/config/app_env.dart';

abstract final class PaymentConstants {
  static const shareTopUpPath = '/share-top-up';
  static const sponsorPath = '/sponsor';

  static const shareTopUpAmountKrw = 10000;
  static const sponsorAmountOptionsShare = [1000, 3000, 5000];

  static String get pgBaseUrl => AppEnv.pgBaseUrl;
}
