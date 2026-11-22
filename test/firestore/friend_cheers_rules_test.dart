import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The friend-cheer collections are read and written by the server only. No
/// client may read or write any of them, so the app uses the server API.
void main() {
  late String rules;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
  });

  String block(String header) =>
      rules.split(header).last.split('match /').first;

  const headers = [
    'match /friendCheers/{cheerId}',
    'match /friendCheerPairDays/{pairDayId}',
    'match /friendCheerDays/{dayId}',
    'match /cheerSettings/{uid}',
    'match /users/{uid}/friendRuns/{activityId}',
    'match /users/{uid}/cheersInbox/{cheerId}',
  ];

  test('the six friend-cheer match blocks exist', () {
    for (final header in headers) {
      expect(rules, contains(header));
    }
  });

  test('every friend-cheer collection is closed to reads and writes', () {
    for (final header in headers) {
      final body = block(header);
      expect(body, contains('allow read, write: if false'), reason: header);
      expect(body.contains('if true'), isFalse, reason: header);
      expect(body.contains('signedIn()'), isFalse, reason: header);
      expect(body.contains('request.auth'), isFalse, reason: header);
    }
  });

  test('no friend-cheer rule allows anything but false', () {
    for (final header in headers) {
      expect(
        RegExp(r'allow\s+[a-z, ]+:\s*if\s+(?!false)').hasMatch(block(header)),
        isFalse,
        reason: header,
      );
    }
  });

  test('the friend rules from before are unchanged', () {
    expect(
      block('match /users/{uid}/friends/{friendUid}'),
      contains('allow read: if signedIn() && request.auth.uid == uid'),
    );
    expect(
      block('match /users/{uid}/blocks/{blockedUid}'),
      contains('allow read, write: if false'),
    );
  });
}
