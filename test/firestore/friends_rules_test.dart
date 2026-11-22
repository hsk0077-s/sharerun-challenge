import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The friend collections are server-written. Only a signed-in user may read
/// their own friend list; invites, day counters and blocks are closed.
void main() {
  late String rules;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
  });

  String block(String header) =>
      rules.split(header).last.split('match /').first;

  test('the four friend match blocks exist', () {
    expect(rules, contains('match /friendInvites/{token}'));
    expect(rules, contains('match /friendInviteDays/{dayId}'));
    expect(rules, contains('match /users/{uid}/friends/{friendUid}'));
    expect(rules, contains('match /users/{uid}/blocks/{blockedUid}'));
  });

  test('invites, day counters and blocks are closed to every client', () {
    for (final header in [
      'match /friendInvites/{token}',
      'match /friendInviteDays/{dayId}',
      'match /users/{uid}/blocks/{blockedUid}',
    ]) {
      final body = block(header);
      expect(body, contains('allow read, write: if false'), reason: header);
      expect(body.contains('if true'), isFalse, reason: header);
    }
  });

  test('friends can be read only by their owner and nobody can write', () {
    final body = block('match /users/{uid}/friends/{friendUid}');
    expect(
      body,
      contains('allow read: if signedIn() && request.auth.uid == uid'),
    );
    expect(body, contains('allow write: if false'));
    expect(body.contains('allow create'), isFalse);
    expect(body.contains('allow update'), isFalse);
    expect(body.contains('allow delete'), isFalse);
  });

  test('every friend rule denies writes', () {
    for (final header in [
      'match /friendInvites/{token}',
      'match /friendInviteDays/{dayId}',
      'match /users/{uid}/friends/{friendUid}',
      'match /users/{uid}/blocks/{blockedUid}',
    ]) {
      expect(block(header), contains('if false'), reason: header);
      expect(
        RegExp(r'allow\s+(write|create|update|delete)[^;]*:\s*if\s+(?!false)')
            .hasMatch(block(header)),
        isFalse,
        reason: header,
      );
    }
  });
}
