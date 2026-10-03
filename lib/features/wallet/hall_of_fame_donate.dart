import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../data/models/pedometer_harvest_result.dart';

typedef HallOfFameDonate = Future<PedometerHarvestResult> Function();

final hallOfFameDonateProvider = Provider<HallOfFameDonate>((ref) {
  return () => ref.read(securedActionApiClientProvider).donateHallOfFame();
});
