import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/firebase/crew_founding_write.dart';
import 'package:share_run_challenge/features/wallet/src_wallet_payment_system.dart';

void main() {
  const crewId = 'Abcdefghij0123456789';

  test('founding cost matches the Crew tab constant and firestore.rules', () {
    expect(
      CrewFoundingWrite.shareCost,
      SrcWalletPaymentSystem.crewCreateShareCost,
    );

    final rules = File('firestore.rules').readAsStringSync();
    expect(rules, contains('function validCrewFoundingDebit(uid)'));
    expect(rules, contains('if validCrewFoundingDebit(uid)'));
    expect(rules, contains('match /crews/{crewId}'));
    final founding = rules.split('function validCrewFoundingDebit(uid)').last;
    final foundingBody = founding.split('match /admins/').first;
    expect(foundingBody.contains('incomingShare()'), isFalse);
    expect(foundingBody.contains('incomingDiamond()'), isFalse);
    expect(foundingBody.contains('incomingValue()'), isFalse);
    expect(
      foundingBody,
      contains(
        'request.resource.data.wallet.shareBalance == resourceShare() - ${CrewFoundingWrite.shareCost}',
      ),
    );
    expect(
      foundingBody,
      contains('request.resource.data.wallet.diamondBalance'),
    );
    expect(
      foundingBody,
      contains('== resource.data.wallet.diamondBalance'),
    );
    expect(
      rules,
      contains('request.resource.data.shareCost == ${CrewFoundingWrite.shareCost}'),
    );
    expect(rules, contains("matches('^[A-Za-z0-9]{20}\$')"));
  });

  test('user merge is an absolute SHARE int plus the new crew id', () {
    expect(
      CrewFoundingWrite.shareAfter(availableShare: 60000, shareCost: 50000),
      10000,
    );
    expect(
      CrewFoundingWrite.shareAfter(availableShare: 50000, shareCost: 50000),
      0,
    );
    expect(
      CrewFoundingWrite.shareAfter(availableShare: 49999, shareCost: 50000),
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
      'shareCost': 50000,
    });
    expect(
      () => CrewFoundingWrite.crewFields(
        name: '   ',
        ownerUid: 'user-1',
        shareCost: 50000,
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
