import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/friends/cheer_format.dart';
import 'package:share_run_challenge/features/friends/cheers_models.dart';

void main() {
  test('runs parse with every field', () {
    final runs = FriendRun.listFromJson({
      'runs': [
        {
          'activity_id': 'r1',
          'friend_uid': 'u1',
          'nickname': 'Mina',
          'distance_km': 5.2,
          'duration_seconds': 1805,
          'kst_date': '2026-11-22',
          'my_reaction': 'fire',
        },
      ],
    });

    expect(runs, hasLength(1));
    expect(runs.single.activityId, 'r1');
    expect(runs.single.friendUid, 'u1');
    expect(runs.single.nickname, 'Mina');
    expect(runs.single.distanceKm, 5.2);
    expect(runs.single.durationSeconds, 1805);
    expect(runs.single.kstDate, '2026-11-22');
    expect(runs.single.myReaction, CheerReaction.fire);
    expect(runs.single.cheered, isTrue);
  });

  test('a run with no reaction is not cheered; an integer distance parses', () {
    final run = FriendRun.tryParse({
      'activity_id': 'r1',
      'friend_uid': 'u1',
      'nickname': '',
      'distance_km': 5,
      'duration_seconds': 60,
      'kst_date': '2026-11-22',
      'my_reaction': null,
    })!;

    expect(run.cheered, isFalse);
    expect(run.myReaction, isNull);
    expect(run.nickname, '');
    expect(run.distanceKm, 5.0);
  });

  test('a reaction from a newer server still counts as already cheered', () {
    final run = FriendRun.tryParse({
      'activity_id': 'r1',
      'friend_uid': 'u1',
      'my_reaction': 'confetti',
    })!;

    expect(run.cheered, isTrue);
    expect(run.myReaction, isNull);
  });

  test('rows without an id and a missing list are skipped, not thrown', () {
    expect(FriendRun.listFromJson({}), isEmpty);
    expect(FriendRun.listFromJson({'runs': 'nope'}), isEmpty);
    expect(
      FriendRun.listFromJson({
        'runs': [
          {'friend_uid': 'u1'},
          'text',
          null,
          {'activity_id': 'r1', 'friend_uid': 'u1'},
        ],
      }),
      hasLength(1),
    );
  });

  test('inbox parses, allows an empty nickname and a null created_at', () {
    final inbox = CheerInbox.fromJson({
      'cheers': [
        {
          'from_uid': 'u1',
          'nickname': '',
          'activity_id': 'r1',
          'reaction': 'heart',
          'created_at': null,
        },
        {
          'from_uid': 'u2',
          'nickname': 'Jun',
          'activity_id': 'r2',
          'reaction': 'clap',
          'created_at': '2026-11-22T01:00:00+00:00',
        },
      ],
      'unread_count': 3,
    });

    expect(inbox.unreadCount, 3);
    expect(inbox.cheers, hasLength(2));
    expect(inbox.cheers[0].nickname, '');
    expect(inbox.cheers[0].createdAt, isNull);
    expect(inbox.cheers[0].reaction, CheerReaction.heart);
    expect(inbox.cheers[1].createdAt, DateTime.utc(2026, 11, 22, 1));
  });

  test('an unknown reaction skips only that row', () {
    final inbox = CheerInbox.fromJson({
      'cheers': [
        {'from_uid': 'u1', 'reaction': 'confetti'},
        {'from_uid': 'u2', 'reaction': 'thumbs'},
        {'from_uid': 'u3'},
      ],
      'unread_count': 2,
    });

    expect(inbox.cheers.map((c) => c.fromUid), ['u2']);
  });

  test('settings parse and tolerate bad data', () {
    final settings = CheerSettings.fromJson({
      'mute_all': true,
      'muted_friends': ['u1', 3, 'u2'],
    });
    expect(settings.muteAll, isTrue);
    expect(settings.mutedFriends, ['u1', 'u2']);

    final empty = CheerSettings.fromJson({});
    expect(empty.muteAll, isFalse);
    expect(empty.mutedFriends, isEmpty);
  });

  test('the five reactions carry the wire words and emoji', () {
    expect(CheerReaction.values.map((r) => r.wire),
        ['clap', 'fire', 'muscle', 'heart', 'thumbs']);
    expect(CheerReaction.values.map((r) => r.emoji),
        ['👏', '🔥', '💪', '❤️', '👍']);
    expect(CheerReaction.fromWire('muscle'), CheerReaction.muscle);
    expect(CheerReaction.fromWire(null), isNull);
    expect(CheerReaction.fromWire('CLAP'), isNull);
  });

  test('distance and time formats', () {
    expect(formatCheerDistanceKm(5.2), '5.20');
    expect(formatCheerDuration(59), '0:59');
    expect(formatCheerDuration(1805), '30:05');
    expect(formatCheerDuration(3600), '1:00:00');
    expect(formatCheerDuration(3725), '1:02:05');
    expect(formatCheerDuration(-4), '0:00');
  });

  test('Korea time day and date parsing', () {
    // 16:00 UTC on the 21st is already the 22nd in Korea.
    expect(kstDay(DateTime.utc(2026, 11, 21, 16)), DateTime(2026, 11, 22));
    expect(kstDay(DateTime.utc(2026, 11, 21, 14)), DateTime(2026, 11, 21));
    expect(parseKstDate('2026-11-22'), DateTime(2026, 11, 22));
    expect(parseKstDate('22/11/2026'), isNull);
    expect(parseKstDate(''), isNull);
  });
}
