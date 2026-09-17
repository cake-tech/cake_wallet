import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class NodeSharePage extends StatelessWidget {
  const NodeSharePage({super.key, required this.uri, required this.currency});

  final Uri uri;
  final CryptoCurrency currency;

  @override
  Widget build(BuildContext context) {
    final qrSize = MediaQuery.of(context).size.width * 0.786;
    final padding = 16.0;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            ModalTopBar(
              title: S.of(context).share,
              leadingIcon: Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: Navigator.of(context).pop,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 40,
                children: [
                  QrImage(
                    size: qrSize - padding * 2,
                    embeddedImagePath: "assets/new-ui/node-qr-icon.svg",
                    badgeImageOnEmbeddedImagePath: currency.iconPath,
                    data: uri.toString(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36.0),
                    child: Text(S.of(context).node_share_desc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
