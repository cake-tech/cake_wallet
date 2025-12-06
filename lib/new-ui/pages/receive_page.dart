import 'package:cake_wallet/new-ui/widgets/receive_page/receive_amount_input.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_qr_code.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_seed_type_selector.dart';
import 'package:flutter/material.dart';

import '../widgets/receive_page/receive_seed_widget.dart';
import '../widgets/receive_page/receive_top_bar.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  bool _largeQrMode = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceBright,
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(height: 12),
            ModalTopBar(
                title: "Receive",
                leadingIcon: Icon(Icons.close),
                trailingIcon: Icon(Icons.share),
                onLeadingPressed: () => Navigator.of(context).pop(),
                onTrailingPressed: () {}),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: [
                  ReceiveQrCode(
                    onTap: () {
                      setState(() {
                        _largeQrMode = !_largeQrMode;
                      });
                    },
                    largeQrMode: _largeQrMode,
                  ),
                  ReceiveSeedTypeSelector(),
                  ReceiveSeedWidget(),
                  ReceiveAmountInput(largeQrMode: _largeQrMode),
                  ReceiveBottomButtons(largeQrMode: _largeQrMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
