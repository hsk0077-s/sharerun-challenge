import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/widgets/src_logo_header.dart';
import '../../l10n/remaining_surface.dart';
import 'brag_card_links.dart';

/// Colors the shared frame needs. Each card maps its own palette onto this.
class BragCardInk {
  const BragCardInk({
    required this.title,
    required this.caption,
    required this.hairline,
  });

  /// App name and the footer line.
  final Color title;

  /// Small secondary text and the logo outline.
  final Color caption;

  /// Thin divider above the footer.
  final Color hairline;
}

/// Size rules shared by every brag card.
abstract final class BragCardSpec {
  static const canvasWidth = 1080.0;
  static const canvasHeight = 1920.0;

  /// Story apps cover about the top and bottom 250px. Nothing important
  /// (name, QR, record) goes into these bands.
  static const storySafeInset = 280.0;

  static const sidePadding = 76.0;
  static const bodyWidth = canvasWidth - sidePadding * 2;

  static const fontFamily = 'ShareRunCard';

  static const logoKey = Key('brag-card-logo');
  static const appNameKey = Key('brag-card-app-name');
  static const footerKey = Key('brag-card-footer');
  static const footerLineKey = Key('brag-card-footer-line');
  static const qrKey = Key('brag-card-qr');

  static String get appName => RemainingSurface.trNow('brand.name', '쉐어런');

  static String get scanLine => RemainingSurface.trNow(
        'brag_card.footer.scan',
        'QR을 찍어 쉐어런을 시작해요',
      );

  static String get plainLine => RemainingSurface.trNow(
        'brag_card.footer.plain',
        '쉐어런과 함께 달려요',
      );

  static String get qrSwitchLabel => RemainingSurface.trNow(
        'brag_card.qr_switch',
        'QR 넣기',
      );
}

/// Head, body, foot of every brag card. 1080×1920 with a 280px safe band at
/// the top and bottom.
///
/// - head: ShareRun logo and name
/// - body: this record or this arrival stamp (needs a bounded height)
/// - foot: install QR and one short line
class BragCardLayout extends StatelessWidget {
  const BragCardLayout({
    required this.ink,
    required this.body,
    required this.showQr,
    this.logoKey = BragCardSpec.logoKey,
    this.appNameKey = BragCardSpec.appNameKey,
    super.key,
  });

  final BragCardInk ink;
  final Widget body;
  final bool showQr;
  final Key logoKey;
  final Key appNameKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BragCardSpec.sidePadding,
        BragCardSpec.storySafeInset,
        BragCardSpec.sidePadding,
        BragCardSpec.storySafeInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BragCardHeader(ink: ink, logoKey: logoKey, appNameKey: appNameKey),
          const SizedBox(height: 28),
          Expanded(child: body),
          const SizedBox(height: 24),
          BragCardFooter(ink: ink, showQr: showQr),
        ],
      ),
    );
  }
}

/// ShareRun logo and name.
///
/// Art slot: the logo is the existing [SRCLogoHeader.assetPath] image. The
/// final drawing replaces that one file; no code change is needed.
class BragCardHeader extends StatelessWidget {
  const BragCardHeader({
    required this.ink,
    this.logoKey = BragCardSpec.logoKey,
    this.appNameKey = BragCardSpec.appNameKey,
    super.key,
  });

  final BragCardInk ink;
  final Key logoKey;
  final Key appNameKey;

  @override
  Widget build(BuildContext context) {
    final name = BragCardSpec.appName;
    return Row(
      children: [
        DecoratedBox(
          key: logoKey,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: ink.caption.withValues(alpha: 0.85),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              SRCLogoHeader.assetPath,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox(width: 76, height: 76),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                key: appNameKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: BragCardSpec.fontFamily,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: ink.title,
                  height: 1.35,
                ),
              ),
              // English name is already "ShareRun"; do not print it twice.
              if (name != 'ShareRun') ...[
                const SizedBox(height: 6),
                Text(
                  'ShareRun',
                  style: TextStyle(
                    fontFamily: BragCardSpec.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.4,
                    color: ink.caption,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Install QR and one short line. With [showQr] false only the line shows.
class BragCardFooter extends StatelessWidget {
  const BragCardFooter({required this.ink, required this.showQr, super.key});

  static const qrSize = 200.0;

  final BragCardInk ink;
  final bool showQr;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: BragCardSpec.footerKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: ink.hairline),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showQr) ...[
              const BragCardQr(size: qrSize),
              const SizedBox(width: 32),
            ],
            Expanded(
              child: Text(
                showQr ? BragCardSpec.scanLine : BragCardSpec.plainLine,
                key: BragCardSpec.footerLineKey,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: BragCardSpec.fontFamily,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: ink.title,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// QR that opens the Play Store listing. It holds [bragCardInstallUrl] only.
///
/// White plate with a quiet zone so a camera can read it on any card color.
/// Error correction L keeps the code coarse and easy to scan from a story.
class BragCardQr extends StatelessWidget {
  const BragCardQr({required this.size, super.key});

  /// Outer size, including the white quiet zone.
  final double size;

  static const _quietZone = 14.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: BragCardSpec.qrKey,
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_quietZone),
          child: QrImageView(
            data: bragCardInstallUrl,
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.L,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
            gapless: true,
          ),
        ),
      ),
    );
  }
}
