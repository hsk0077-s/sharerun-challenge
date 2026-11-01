import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/remaining_surface.dart';
import '../jena_validation/run_device_info.dart';

/// 이용자가 문제를 알릴 수 있는 공식 이메일. 스토어 설명문, 개인정보처리방침, 이용약관과 같다.
const supportEmail = 'src791004@gmail.com';

/// 메일 앱에 미리 채워 줄 제목과 본문 꼬리말을 만든다.
///
/// 본문 위쪽은 이용자가 쓰도록 비워 두고, 아래에 앱 버전·기기·언어를 한 줄 붙인다.
/// 이 줄은 원인을 찾는 데만 쓰고, 계정 정보(이메일, 닉네임, UID)는 넣지 않는다.
Uri buildContactMailto({
  required String subject,
  required String note,
  required String appVersion,
  required String device,
  required String os,
  required String language,
}) {
  final info = 'App $appVersion · $device · $os · $language';
  final body = '\n\n\n---\n$note\n$info\n';
  // mailto는 '+'를 공백으로 읽는 메일 앱이 있어 공백을 %20으로 직접 인코딩한다.
  String enc(String s) => Uri.encodeComponent(s);
  return Uri.parse('mailto:$supportEmail?subject=${enc(subject)}&body=${enc(body)}');
}

/// 설정의 "문의하기". 메일 앱을 열고, 열 수 없으면 주소를 복사해 알려 준다.
Future<void> openContactEmail(BuildContext context) async {
  var appVersion = '';
  var device = '';
  var os = '';
  try {
    appVersion = await readInstalledAppVersion();
  } catch (_) {}
  try {
    final phone = await readPhoneDevice();
    device = clipDeviceField(phone.model);
    os = clipDeviceField(phone.osVersion);
  } catch (_) {}
  final language = RemainingSurface.currentLocale.languageCode;
  final uri = buildContactMailto(
    subject: RemainingSurface.trNow('support.mail_subject', '쉐어런 문의'),
    note: RemainingSurface.trNow(
      'support.mail_note',
      '아래는 문제를 찾는 데 쓰는 정보예요. 지우셔도 돼요.',
    ),
    appVersion: appVersion.isEmpty ? RunDeviceInfo.fallbackAppVersion : appVersion,
    device: device.isEmpty ? '-' : device,
    os: os.isEmpty ? '-' : os,
    language: language,
  );
  var opened = false;
  try {
    opened = await launchUrl(uri);
  } catch (_) {}
  if (opened || !context.mounted) return;
  await Clipboard.setData(const ClipboardData(text: supportEmail));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        RemainingSurface.trNow(
          'support.copied',
          '메일 앱을 열 수 없어 이메일 주소를 복사했어요',
        ),
      ),
    ),
  );
}
