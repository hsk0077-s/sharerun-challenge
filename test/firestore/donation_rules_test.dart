import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// donationExecutions: signed-in users read, nobody writes from a client.
/// storage.rules: only admins upload donation proof pictures.
void main() {
  late String rules;
  late String storage;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
    storage = File('storage.rules').readAsStringSync();
  });

  String block(String source, String header) =>
      source.split(header).last.split('match /').first;

  test('donationExecutions can be read by a signed-in user and never written',
      () {
    final body = block(rules, 'match /donationExecutions/{month}');
    expect(body, contains('allow read: if signedIn() || isAdmin()'));
    expect(body, contains('allow create, update, delete: if false'));
    expect(body.contains('if true'), isFalse);
    expect(
      RegExp(r'allow\s+(write|create|update|delete)[^;]*:\s*if\s+(?!false)')
          .hasMatch(body),
      isFalse,
    );
  });

  test('the month totals rule is unchanged', () {
    final body = block(rules, 'match /donationMonthTotals/{month}');
    expect(body, contains('allow read: if signedIn() || isAdmin()'));
    expect(body, contains('allow create, update, delete: if false'));
  });

  test('storage: only admins upload a picture under donation-receipts', () {
    expect(storage, contains('match /donation-receipts/{month}/{file}'));
    final body = block(storage, 'match /donation-receipts/{month}/{file}');
    expect(body, contains('allow read: if signedIn()'));
    expect(body, contains('allow create, update: if isAdmin()'));
    expect(body, contains("contentType.matches('image/.*')"));
    expect(body, contains('request.resource.size < 10 * 1024 * 1024'));
    expect(body, contains('allow delete: if false'));
  });

  test('storage: everything else is closed', () {
    expect(storage, contains('match /{allPaths=**}'));
    final tail = storage.split('match /{allPaths=**}').last;
    expect(tail, contains('allow read, write: if false'));
    expect(storage.contains('allow write: if true'), isFalse);
    expect(storage.contains('allow read, write: if true'), isFalse);
  });

  test('firebase.json points storage at storage.rules', () {
    expect(File('firebase.json').readAsStringSync(),
        contains('"rules": "storage.rules"'));
  });
}
