// 코치 문구를 음성 파일(mp3)로 만든다. 한 번만 실행하면 된다.
//
// 준비: gcloud 로그인이 되어 있어야 한다.  gcloud auth login
// 먼저 두 개만 시험:
//   dart run tool/build_coach_voice.dart --model <모델 이름> --limit 2
// 전부 만들기:
//   dart run tool/build_coach_voice.dart --model <모델 이름>
//
// 모델 이름은 콘솔 데모의 "Show request"에 나오는 modelName 값이다.
// 이미 있는 파일은 다시 만들지 않는다. 문구가 바뀐 것만 새로 만든다. (--force로 전부 다시)
// 결과: assets/voice/<해시>.mp3 와 assets/voice/manifest.json
import 'dart:convert';
import 'dart:io';

import 'package:share_run_challenge/features/voice_coaching/voice_cue_files.dart';

const _defaultPrompt =
    'Read aloud in an energetic, upbeat, cheerful tone, like a friendly running coach.';

Future<void> main(List<String> args) async {
  final options = _parse(args);
  final model = options['model'];
  if (model == null || model.isEmpty) {
    stderr.writeln('--model <모델 이름>이 필요해요. (콘솔 데모의 Show request에서 확인)');
    exit(64);
  }
  final voice = options['voice'] ?? 'Leda';
  final language = options['language'] ?? 'ko-KR';
  final project = options['project'] ?? 'share-run-challenge';
  final prompt = options['prompt'] ?? _defaultPrompt;
  final limit = int.tryParse(options['limit'] ?? '') ?? 1 << 30;
  final force = options.containsKey('force');
  final encoding = options['encoding'] ?? 'MP3';

  final dir = Directory('assets/voice')..createSync(recursive: true);
  final token = await _accessToken();
  final client = HttpClient();

  final texts = coachCueTexts();
  final done = <String>{};
  var made = 0;
  for (final text in texts) {
    final name = voiceFileNameFor(text);
    final file = File('${dir.path}/$name');
    if (file.existsSync() && !force) {
      done.add(name);
      continue;
    }
    if (made >= limit) continue;
    stdout.writeln('만드는 중 (${made + 1}): $text');
    final bytes = await _synthesize(
      client,
      token: token,
      project: project,
      body: {
        'input': {'text': text, 'prompt': prompt},
        'voice': {
          'languageCode': language,
          'name': voice,
          'modelName': model,
        },
        'audioConfig': {'audioEncoding': encoding},
      },
    );
    file.writeAsBytesSync(bytes);
    done.add(name);
    made++;
  }
  client.close();

  // 목록에는 지금 폴더에 실제로 있는 파일만 적는다.
  final present = [
    for (final text in texts)
      if (File('${dir.path}/${voiceFileNameFor(text)}').existsSync())
        voiceFileNameFor(text),
  ];
  File('${dir.path}/manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'files': present})}\n',
  );
  stdout.writeln(
    '끝났어요. 새로 만든 파일 $made개, 목록에 있는 파일 ${present.length}/${texts.length}개.',
  );
  if (present.length < texts.length) {
    stdout.writeln('아직 안 만든 문구가 남았어요. 같은 명령을 --limit 없이 다시 실행해 주세요.');
  }
}

Map<String, String> _parse(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;
    final key = arg.substring(2);
    final hasValue = i + 1 < args.length && !args[i + 1].startsWith('--');
    out[key] = hasValue ? args[++i] : '';
  }
  return out;
}

Future<String> _accessToken() async {
  final result = await Process.run(
    'gcloud',
    ['auth', 'print-access-token'],
    runInShell: true,
  );
  final token = '${result.stdout}'.trim();
  if (result.exitCode != 0 || token.isEmpty) {
    stderr.writeln('gcloud 로그인이 필요해요. 먼저 gcloud auth login 을 실행해 주세요.');
    stderr.writeln('${result.stderr}');
    exit(65);
  }
  return token;
}

Future<List<int>> _synthesize(
  HttpClient client, {
  required String token,
  required String project,
  required Map<String, Object?> body,
}) async {
  final request = await client.postUrl(
    Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize'),
  );
  request.headers
    ..set('Authorization', 'Bearer $token')
    ..set('x-goog-user-project', project)
    ..set('Content-Type', 'application/json; charset=utf-8');
  request.add(utf8.encode(jsonEncode(body)));
  final response = await request.close();
  final text = await utf8.decodeStream(response);
  if (response.statusCode != 200) {
    stderr.writeln('음성 만들기 실패 (${response.statusCode}): $text');
    exit(66);
  }
  final json = jsonDecode(text);
  final audio = json is Map ? json['audioContent'] : null;
  if (audio is! String || audio.isEmpty) {
    stderr.writeln('응답에 음성이 없어요: $text');
    exit(67);
  }
  return base64Decode(audio);
}
