import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../data/models/share_to_dia_view.dart';

typedef ShareToDiaQuote = Future<ShareToDiaView> Function();
typedef ShareToDiaExchange = Future<ShareToDiaView> Function(int diaAmount);

final shareToDiaQuoteProvider = Provider<ShareToDiaQuote>((ref) {
  return () => ref.read(securedActionApiClientProvider).quoteShareToDia();
});

final shareToDiaExchangeProvider = Provider<ShareToDiaExchange>((ref) {
  return (diaAmount) =>
      ref.read(securedActionApiClientProvider).exchangeShareToDia(diaAmount);
});
