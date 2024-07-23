import 'dart:async';

import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';

// ur:xmr-txunsigned - unsigned transaction
//     should show a scanner afterwards.

class AnimatedURPage extends BasePage {
  AnimatedURPage({required this.urQr, required this.wallet});
  
  final String urQr;
  final WalletBase wallet;

  String get urQrType {
    final first = urQr.trim().split("\n")[0];
    return first.split('/')[0];
  }

  @override
  Widget body(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 64.0),
            child: URQR(
              frames: urQr.trim().split("\n"),
            ),
          ),
          Text(urQrType),
          if (urQrType == "ur:xmr-txunsigned")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.maxFinite,
                child: OutlinedButton(
                  onPressed: () => _continue(context),
                  child: Text("Continue"),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _continue(BuildContext context) async {
    final ur = await presentQRScanner(context);
    final result = await monero!.commitTransactionUR(wallet, ur);
    if (result) {
      Navigator.of(context).pop();
    }
  }
}

class URQR extends StatefulWidget {
  URQR({super.key, required this.frames});

  List<String> frames;

  @override
  // ignore: library_private_types_in_public_api
  _URQRState createState() => _URQRState();
}

const urFrameTime = 1000 ~/ 5;

class _URQRState extends State<URQR> {
  Timer? t;
  int frame = 0;
  @override
  void initState() {
    super.initState();
    setState(() {
      t = Timer.periodic(const Duration(milliseconds: urFrameTime), (timer) {
        _nextFrame();
      });
    });
  }

  void _nextFrame() {
    setState(() {
      frame++;
    });
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: QrImage(
            data: widget.frames[frame % widget.frames.length], version: -1,
            size: 400,
          ),
        ),
      ],
    );
  }
}