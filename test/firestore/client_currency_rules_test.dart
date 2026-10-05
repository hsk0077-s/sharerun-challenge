import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String rules;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
  });

  test('clients cannot write a 1,000,000 debug wallet', () {
    expect(rules.contains('validDebugTestWalletGrant'), isFalse);
    expect(rules.contains('validDebugShareSpend'), isFalse);
    expect(rules.contains('validDebugShopCurrencySpend'), isFalse);
    expect(rules.contains('1000000'), isFalse);
    expect(rules, contains('function clientCurrencyAffected()'));
    expect(rules, contains('&& !clientCurrencyAffected()'));
    expect(rules, contains('request.resource.data.wallet.shareBalance == 0'));
  });

  test('currency and config docs are not client-writable', () {
    expect(_writesDenied(rules, 'match /walletTransactions/{txId}'), isTrue);
    expect(_writesDenied(rules, 'match /shopInventory/{itemId}'), isTrue);
    expect(_writesDenied(rules, 'match /prizeTickets/{ticketId}'), isTrue);
    expect(_writesDenied(rules, 'match /donationLedger/{entryId}'), isTrue);
    expect(_writesDenied(rules, 'match /donationPools/{poolId}'), isTrue);
    expect(_writesDenied(rules, 'match /wallet_transactions/{txId}'), isTrue);

    final config = rules
        .split('match /config/{docId}')
        .last
        .split('match /stampLandmarks/')
        .first;
    expect(config, contains('allow read:'));
    expect(config, contains('allow write: if false'));
    expect(config.contains('allow write: if isAdmin()'), isFalse);
  });
}

bool _writesDenied(String rules, String matchHeader) {
  final body = rules.split(matchHeader).last.split('match /').first;
  return body.contains('allow create, update, delete: if false') ||
      body.contains('allow read, write: if false');
}
