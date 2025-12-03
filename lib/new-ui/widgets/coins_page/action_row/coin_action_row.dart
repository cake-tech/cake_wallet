import 'package:cake_wallet/core/open_crypto_pay/open_cryptopay_service.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/new-ui/pages/send_page.dart';
import 'package:cake_wallet/new-ui/pages/swap_page.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../pages/receive_page.dart';
import '../../../pages/scan_page.dart';
import 'coin_action_button.dart';

class CoinActionRow extends StatelessWidget {
  const CoinActionRow({super.key, this.lightningMode = false});

  final bool lightningMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: MediaQuery.of(context).size.width * 0.05,
        children: [
          CoinActionButton(
            icon: SvgPicture.asset("assets/new-ui/send.svg"),
            label: "Send",
            action: () {
              if (FeatureFlag.hasNewUiExtraPages) {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SendPage(),
                );
              } else {
                Map<String, dynamic>? args;
                if (lightningMode) args = {'coinTypeToSpendFrom' : UnspentCoinType.lightning};
                Navigator.of(context).pushNamed(Routes.send, arguments: args);
              }
            },
          ),
          CoinActionButton(
            icon: SvgPicture.asset("assets/new-ui/receive.svg"),
            label: "Receive",
            action: () {
              if (FeatureFlag.hasNewUiExtraPages) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.9,
                    child: ReceivePage(),
                  ),
                );
              } else {
                Navigator.of(context).pushNamed(Routes.receive);
              }
            },
          ),
          CoinActionButton(
            icon: SvgPicture.asset("assets/new-ui/exchange.svg"),
            label: "Swap",
            action: () {
              if (FeatureFlag.hasNewUiExtraPages) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.9,
                    child: SwapPage(),
                  ),
                );
              } else {
                Navigator.of(context).pushNamed(Routes.exchange);
              }
            },
          ),
          CoinActionButton(
            icon: SvgPicture.asset("assets/new-ui/scan.svg"),
            label: "Scan",
            action: () => _onPressedScan(context),
          ),
        ],
      ),
    );
  }

  Future<void> _onPressedScan(BuildContext context) async {
    if (FeatureFlag.hasNewUiExtraPages) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.9,
          child: ScanPage(),
        ),
      );
    } else {
      final code = await presentQRScanner(context);

      if (code == null || code.isEmpty) return;

      if (SendViewModelBase.isLightningInvoice(code) ||
          OpenCryptoPayService.isOpenCryptoPayQR(code)) {
        Navigator.of(context).pushNamed(Routes.send,
            arguments: {"paymentRequest": PaymentRequest(code, "", "", "", "")});
        return;
      }

      final uri = Uri.tryParse(code);
      if (uri == null) return;
      rootKey.currentState?.handleDeepLinking(uri);
    };
  }
}
