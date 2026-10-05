import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/models/company_tournament_config.dart';

/// Live `config/company_tournament` from Jena. Room documents are not the fee.
final companyTournamentConfigProvider =
    FutureProvider<CompanyTournamentConfig>((ref) async {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid;
  if (uid == null || uid.isEmpty) {
    return const CompanyTournamentConfig(tiers: {});
  }
  try {
    return await ref
        .read(securedActionApiClientProvider)
        .fetchCompanyTournamentConfig();
  } catch (error) {
    debugPrint('company tournament config: $error');
    return const CompanyTournamentConfig(tiers: {});
  }
});

/// Asks the server to grant the one signup ticket if it is still missing.
final signupFreeTicketGrantProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid;
  if (uid == null || uid.isEmpty) return;
  try {
    await ref.read(securedActionApiClientProvider).ensureSignupFreeTicket();
  } catch (error) {
    debugPrint('signup free ticket: $error');
  }
});
