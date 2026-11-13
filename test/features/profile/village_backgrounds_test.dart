import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/profile/village_backgrounds.dart';
import 'package:share_run_challenge/features/profile/village_scene.dart';

void main() {
  test('six village backgrounds exist, are WebP and each stays under 500 KB', () {
    expect(VillageBackgrounds.all, hasLength(6));
    expect(VillageBackgrounds.all.toSet(), hasLength(6));
    for (final path in VillageBackgrounds.all) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      expect(path, endsWith('.webp'));
      expect(file.lengthSync(), lessThan(500 * 1024), reason: path);
      final head = file.openSync().readSync(12);
      // WebP: "RIFF" .... "WEBP"
      expect(String.fromCharCodes(head.sublist(0, 4)), 'RIFF', reason: path);
      expect(String.fromCharCodes(head.sublist(8, 12)), 'WEBP', reason: path);
    }
  });

  test('the folder is registered in pubspec.yaml', () {
    expect(File('pubspec.yaml').readAsStringSync(),
        contains('- ${VillageBackgrounds.dir}'));
  });

  test('they stay apart from the my-tab villages the old picker reads by itself', () {
    expect(VillageBackgrounds.dir.startsWith(villageAssetDir), isFalse);
    for (final path in VillageBackgrounds.all) {
      expect(path.startsWith(villageAssetDir), isFalse);
    }
  });
}
