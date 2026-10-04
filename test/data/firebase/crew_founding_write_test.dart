import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/firebase/crew_founding_write.dart';
import 'package:share_run_challenge/features/wallet/src_wallet_payment_system.dart';

void main() {
  const crewId = 'Abcdefghij0123456789';

  test('founding cost matches the Crew tab constant', () {
    expect(
      CrewFoundingWrite.shareCost,
      SrcWalletPaymentSystem.crewCreateShareCost,
    );
  });

  test('clients cannot debit SHARE in rules to found a crew', () {
    final rules = File('firestore.rules').readAsStringSync();
    expect(rules.contains('validCrewFoundingDebit'), isFalse);
    expect(rules, contains('match /crews/{crewId}'));
    final crew = rules.split('match /crews/{crewId}').last.split('match /').first;
    expect(crew, contains('allow create, update, delete: if false'));
  });

  test('user merge is an absolute SHARE int plus the new crew id', () {
    expect(
      CrewFoundingWrite.shareAfter(availableShare: 40000, shareCost: 30000),
      10000,
    );
    expect(
      CrewFoundingWrite.shareAfter(availableShare: 30000, shareCost: 30000),
      0,
    );
    expect(
      CrewFoundingWrite.shareAfter(availableShare: 29999, shareCost: 30000),
      isNull,
    );
    expect(
      CrewFoundingWrite.shareAfter(availableShare: 999999, shareCost: 1000),
      isNull,
    );

    final fields = CrewFoundingWrite.userMergeFields(
      shareAfter: 10000,
      crewId: crewId,
    );
    expect(fields.keys, CrewFoundingWrite.userMergeKeys);
    expect(fields['wallet.shareBalance'], 10000);
    expect(fields['ownedCrewId'], crewId);
    expect(fields.containsKey('wallet.shareBalance'), isTrue);
    expect(CrewFoundingWrite.isCrewId(crewId), isTrue);
    expect(CrewFoundingWrite.isCrewId('short'), isFalse);
    expect(CrewFoundingWrite.isCrewId('bad/id00000000000000'), isFalse);
  });

  test('crew doc is the screen name and a 1-member founding receipt', () {
    final crew = CrewFoundingWrite.crewFields(
      name: '서울 나이트 러너스 🌙',
      ownerUid: 'user-1',
      shareCost: CrewFoundingWrite.shareCost,
    );
    expect(crew, {
      'name': '서울 나이트 러너스 🌙',
      'ownerUid': 'user-1',
      'totalValue': 0,
      'memberCount': 1,
      'shareCost': 30000,
    });
    expect(
      () => CrewFoundingWrite.crewFields(
        name: '   ',
        ownerUid: 'user-1',
        shareCost: 30000,
      ),
      throwsArgumentError,
    );
  });

  test('repository no longer debits crew founding with FieldValue.increment', () {
    final source = File('lib/data/repositories/crew_repository.dart')
        .readAsStringSync();
    expect(source.contains('debitShareInTransaction'), isFalse);
    expect(source.contains('FieldValue.increment'), isFalse);
    expect(source.contains('CrewFoundingWrite.userMergeFields'), isTrue);
    expect(source.contains('tx.update'), isTrue);
  });
}
