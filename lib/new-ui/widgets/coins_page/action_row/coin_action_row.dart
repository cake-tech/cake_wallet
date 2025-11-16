import 'package:cake_wallet/new-ui/pages/send_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../pages/receive_page.dart';
import '../../../pages/scan_page.dart';
import 'coin_action_button.dart';

class CoinActionRow extends StatelessWidget {
  const CoinActionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 24.0,
        children: [
          CoinActionButton(
            icon: SvgPicture.asset("assets/new-ui/send.svg"),
            label: "Send",
            action: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SendPage(),
              );
            },
          ),
          CoinActionButton(
            icon: SvgPicture.asset("assets/new-ui/receive.svg"),
            label: "Receive",
            action: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => FractionallySizedBox(
                  heightFactor: 0.9,
                  child: ReceivePage(),
                ),
              );
            },
          ),
          CoinActionButton(
            icon: SvgPicture.asset("assets/new-ui/exchange.svg"),
            label: "Swap",
            action: () {},
          ),
          CoinActionButton(
            icon: SvgPicture.asset("assets/new-ui/scan.svg"),
            label: "Scan",
            action: () {
              showModalBottomSheet(
                context: context,

                builder: (context) => ScanPage(),
              );
            },
          ),
        ],
      ),
    );
  }
}
