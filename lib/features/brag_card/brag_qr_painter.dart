import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

import 'brag_card_links.dart';

/// Our own QR drawing on top of the pure Dart `qr` package (no QR widget
/// package). White plate, black square modules, four-module quiet zone on
/// every side, error correction M.
///
/// Every module is a whole number of pixels on the 1080×1920 card and
/// anti-aliasing is off, so module edges stay sharp when the picture is
/// scaled down by a chat app.
abstract final class BragQr {
  /// Error correction level M.
  static const errorCorrectLevel = QrErrorCorrectLevel.M;

  /// Quiet zone in modules, each side. The QR standard asks for 4.
  static const quietZoneModules = 4;

  /// One module in card pixels (card is 1080 wide). 6px (at least 5px).
  static const modulePixels = 6;

  /// The QR for [bragCardInstallUrl]. Built once.
  static final QrCode code = QrCode.fromData(
    data: bragCardInstallUrl,
    errorCorrectLevel: errorCorrectLevel,
  );

  static int get moduleCount => code.moduleCount;

  /// Side of the white plate, quiet zone included, in card pixels.
  static int get plateSide => (moduleCount + quietZoneModules * 2) * modulePixels;
}

class BragQrPainter extends CustomPainter {
  const BragQrPainter(this.qr);

  final QrCode qr;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = BragQr.modulePixels;
    const quiet = BragQr.quietZoneModules;
    final image = QrImage(qr);
    final side = ((qr.moduleCount + quiet * 2) * cell).toDouble();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..isAntiAlias = false,
    );
    final dark = Paint()
      ..color = const Color(0xFF000000)
      ..isAntiAlias = false;
    for (var row = 0; row < qr.moduleCount; row++) {
      for (var col = 0; col < qr.moduleCount; col++) {
        if (!image.isDark(row, col)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            ((col + quiet) * cell).toDouble(),
            ((row + quiet) * cell).toDouble(),
            cell.toDouble(),
            cell.toDouble(),
          ),
          dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BragQrPainter oldDelegate) =>
      oldDelegate.qr != qr;
}
