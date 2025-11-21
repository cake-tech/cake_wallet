import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/new-ui/pages/send_page.dart';
import 'package:cake_wallet/new-ui/pages/swap_page.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:cake_wallet/new-ui/pages/receive_page.dart';
import 'package:cake_wallet/new-ui/pages/scan_page.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/action_row/coin_action_button.dart';

class CoinAction {
  final String label;
  final SvgPicture icon;
  final Widget page;
  final Function(BuildContext context) legacyAction;

  static final actions = [
    CoinAction("Send", SvgPicture.asset("assets/new-ui/send.svg"), getIt.get<NewSendPage>(),
        (context) {
      Navigator.of(context).pushNamed(Routes.send);
    }),
    CoinAction(
        "Receive", SvgPicture.asset("assets/new-ui/receive.svg"), getIt.get<NewReceivePage>(),
        (context) {
      Navigator.of(context).pushNamed(Routes.receive);
    }),
    CoinAction("Swap", SvgPicture.asset("assets/new-ui/exchange.svg"), getIt.get<NewSwapPage>(),
        (context) {
      Navigator.of(context).pushNamed(Routes.exchange);
    }),
    CoinAction("Scan", SvgPicture.asset("assets/new-ui/scan.svg"), getIt.get<NewScanPage>(),
        (context) async {
      final code = await presentQRScanner(context);

      if (code == null) return;
      if (code.isEmpty) return;
      final uri = Uri.parse(code);
      rootKey.currentState?.handleDeepLinking(uri);
    }),
  ];

  CoinAction(this.label, this.icon, this.page, this.legacyAction);
}

class CoinActionRow extends StatelessWidget {
  const CoinActionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: MediaQuery.of(context).size.width * 0.05,
        children: [
          for (var action in CoinAction.actions)
            CoinActionButton(
              icon: action.icon,
              label: action.label,
              action: () {
                if (FeatureFlag.hasNewUiExtraPages) {
                  showBottomSheet(context, action.page);
                } else {
                  action.legacyAction(context);
                }
              },
            )
        ],
      ),
    );
  }

  void showBottomSheet(BuildContext context, Widget page) {
    showCupertinoModalBottomSheet(context: context, builder: (context) => Material(child: page));
  }
}
