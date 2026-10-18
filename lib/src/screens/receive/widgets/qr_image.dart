import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;

class QrImage extends StatelessWidget {
  QrImage({
    required this.data,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.size = 100.0,
    this.version,
    this.errorCorrectionLevel = qr.QrErrorCorrectLevel.H,
    this.embeddedImagePath,
    this.badgeImageOnEmbeddedImagePath,
    this.semanticsLabel,
  });

  final double? size;
  final Color foregroundColor;
  final Color backgroundColor;
  final String data;
  final int? version;
  final int errorCorrectionLevel;
  final String? embeddedImagePath;
  final String? badgeImageOnEmbeddedImagePath;

  /// Accessible name announced for the code itself. Defaults to a generic
  /// localized "QR code" so the code is always discoverable; pass a more
  /// specific label when the host screen knows what the code encodes.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final imagePath = embeddedImagePath ?? 'assets/images/qr-cake.png';
    final qrSize = size ?? 100.0;
    final logoSize = qrSize * 0.30;

    final centerImage = TokenImageWidget(
      imageUrl: imagePath,
      size: logoSize * 0.8,
    );

    Widget centerImageToUse;
    if (badgeImageOnEmbeddedImagePath != null) {
      centerImageToUse = Stack(
        children: [
          centerImage,
          Positioned(
            bottom: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomRight,
              child: CakeImageWidget(
                imageUrl: badgeImageOnEmbeddedImagePath!,
                width: 24,
                height: 24,
              ),
            ),
          ),
        ],
      );
    } else {
      centerImageToUse = centerImage;
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        qr.QrImageView(
          data: data,
          errorCorrectionLevel: errorCorrectionLevel,
          version: version ?? qr.QrVersions.auto,
          size: qrSize,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.all(12.0),
          // The package default is a hardcoded English "qr code"; use the
          // localized string so the code is announced in the user's language.
          semanticsLabel: semanticsLabel ?? S.of(context).scan_qr_code,
        ),
        // The embedded logo and its badge are purely decorative — the node
        // above already announces the code — so keep them out of the tree.
        ExcludeSemantics(child: centerImageToUse),
      ],
    );
  }
}
