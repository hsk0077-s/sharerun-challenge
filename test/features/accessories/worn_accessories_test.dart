import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/accessories/accessory_catalog.dart';
import 'package:share_run_challenge/features/accessories/accessory_inventory.dart';

void main() {
  final ready = accessoryCatalog.firstWhere((a) => a.ready);

  test('입고 있고 산 소품만 마스코트에 입힌다', () {
    final inventory = AccessoryInventory(
      owned: {ready.id},
      worn: {ready.slot.name: ready.id},
    );
    expect(wornFrom(inventory), {ready});
  });

  test('샀지만 벗은 소품, 입었다고 적혔지만 갖고 있지 않은 소품은 입히지 않는다', () {
    expect(wornFrom(AccessoryInventory(owned: {ready.id})), isEmpty);
    expect(
      wornFrom(AccessoryInventory(worn: {ready.slot.name: ready.id})),
      isEmpty,
    );
  });

  test('카탈로그에 없는 id는 무시한다', () {
    expect(
      wornFrom(const AccessoryInventory(owned: {'nope'}, worn: {'head': 'nope'})),
      isEmpty,
    );
  });
}
