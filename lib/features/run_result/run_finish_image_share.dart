import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// PNG capture plus Instagram Stories, TikTok, and the system sheet.
///
/// The image is the run poster only. No invite copy is attached.
abstract final class RunFinishImageShare {
  static const channelName = 'share_run/finish_image_share';
  static const channel = MethodChannel(channelName);

  static const instagramLabel = 'Instagram 스토리';
  static const tiktokLabel = 'TikTok';
  static const moreLabel = '더보기';
  static const captureFailedMessage = '공유 이미지를 만들지 못했어요.';
  static const instagramFailedMessage = 'Instagram 스토리로 공유하지 못했어요.';
  static const subject = '쉐어 런 완주';

  static const instagramButtonKey = Key('run-finish-instagram');
  static const tiktokButtonKey = Key('run-finish-tiktok');
  static const moreButtonKey = Key('run-finish-more');
  static const captureKey = Key('run-finish-capture');

  @visibleForTesting
  static Future<bool> Function()? debugInstagramInstalled;

  @visibleForTesting
  static Future<bool> Function()? debugTikTokInstalled;

  @visibleForTesting
  static Future<bool> Function(String path)? debugInstagramShare;

  @visibleForTesting
  static Future<bool> Function(String path)? debugTikTokShare;

  @visibleForTesting
  static Future<ShareResult> Function(ShareParams params)? debugSystemShare;

  @visibleForTesting
  static Future<File> Function(GlobalKey key)? debugCaptureOverride;

  static Future<bool> instagramInstalled() async {
    final hook = debugInstagramInstalled;
    if (hook != null) return hook();
    try {
      return await channel.invokeMethod<bool>('instagramInstalled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> tiktokInstalled() async {
    final hook = debugTikTokInstalled;
    if (hook != null) return hook();
    try {
      return await channel.invokeMethod<bool>('tiktokInstalled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// True when Instagram accepted the story image.
  static Future<bool> shareInstagramStory(String path) async {
    final hook = debugInstagramShare;
    if (hook != null) return hook(path);
    try {
      return await channel.invokeMethod<bool>('shareInstagramStory', {
            'path': path,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// True when the image was handed to TikTok. False means use the system sheet.
  static Future<bool> shareTikTok(String path) async {
    final hook = debugTikTokShare;
    if (hook != null) return hook(path);
    try {
      return await channel.invokeMethod<bool>('shareTikTok', {'path': path}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<ShareResult> shareImageFile({
    required String path,
    Rect? sharePositionOrigin,
  }) {
    final params = ShareParams(
      files: [
        XFile(path, mimeType: 'image/png', name: 'share_run_finish.png'),
      ],
      subject: subject,
      title: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
    final send = debugSystemShare ?? SharePlus.instance.share;
    return send(params);
  }

  static Future<File> capture(GlobalKey key) async {
    final hook = debugCaptureOverride;
    if (hook != null) return hook(key);
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('share card is not laid out');
    }
    // toImage's future never completes under the widget-test scheduler.
    // toImageSync rasterizes on the raster thread and returns immediately.
    final image = boundary.toImageSync(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('png encode failed');
      }
      final file = File(
        '${Directory.systemTemp.path}/share_run_finish_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      return file;
    } finally {
      image.dispose();
    }
  }
}
