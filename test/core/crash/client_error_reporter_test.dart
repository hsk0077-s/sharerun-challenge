import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/crash/client_error_reporter.dart';

void main() {
  late List<Map<String, Object?>> sent;

  setUp(() {
    ClientErrorReporter.debugReset();
    ClientErrorReporter.debugEnabled = true;
    sent = [];
    ClientErrorReporter.sender = ({
      required String message,
      required String stack,
      required bool fatal,
    }) async {
      sent.add({'message': message, 'stack': stack, 'fatal': fatal});
    };
  });

  tearDown(ClientErrorReporter.debugReset);

  test('sends the error with its stack and the fatal flag', () async {
    await ClientErrorReporter.report(
      StateError('boom'),
      StackTrace.fromString('#0 main (a.dart:1)'),
      fatal: true,
    );
    expect(sent, hasLength(1));
    expect(sent.single['message'], contains('boom'));
    expect(sent.single['stack'], contains('a.dart:1'));
    expect(sent.single['fatal'], isTrue);
  });

  test('the same error is sent once per run', () async {
    final stack = StackTrace.fromString('#0 main (a.dart:1)');
    await ClientErrorReporter.report(StateError('boom'), stack);
    await ClientErrorReporter.report(StateError('boom'), stack);
    expect(sent, hasLength(1));
  });

  test('stops after ${ClientErrorReporter.maxPerSession} reports', () async {
    for (var i = 0; i < 25; i++) {
      await ClientErrorReporter.report(StateError('error $i'), null);
    }
    expect(sent, hasLength(ClientErrorReporter.maxPerSession));
  });

  test('does nothing before sign-in and never throws when sending fails',
      () async {
    ClientErrorReporter.sender = null;
    await ClientErrorReporter.report(StateError('early'), null);
    expect(sent, isEmpty);

    ClientErrorReporter.sender = ({
      required String message,
      required String stack,
      required bool fatal,
    }) async =>
        throw StateError('network down');
    await ClientErrorReporter.report(StateError('later'), null);
  });

  test('is off in debug builds unless a test turns it on', () async {
    ClientErrorReporter.debugEnabled = false;
    await ClientErrorReporter.report(StateError('dev'), null);
    expect(sent, isEmpty);
  });
}
