import 'dart:async';

import 'package:bbqrdart/bbqrdart.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ur/widgets/urqr.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/animated_ur_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class AnimatedURPage extends BasePage {
  final bool isAll;
  AnimatedURPage(
    this.animatedURmodel, {
    required Map<String, String> this.urQr,
    this.isAll = false,
  }) {
    if (urQr.keys.first.startsWith("export-outputs") &&
        animatedURmodel.wallet.type == WalletType.monero) {
      if (animatedURmodel.wallet.type == WalletType.monero) {
        urQr = monero!.exportOutputsUR(animatedURmodel.wallet);
      } else {
        throw UnimplementedError("unable to handle UR: ${urQr.keys.first}");
      }
    }
    for (var key in urQr.keys) {
      if (key.isEmpty || urQr[key]!.isEmpty) {
        urQr.remove(key);
        continue;
      }
      urQr[key] = urQr[key]!.trim();
    }
  }

  Map<String, String> urQr = {};

  final AnimatedURModel animatedURmodel;

  String get urQrType {
    if (urQr.values.first.trim().substring(0, 2) == BBQR.header) {
      return BBQR.header;
    }
    if (urQr.isEmpty) return "unknown";
    final first = urQr.values.first.trim().split("\n")[0];
    return first.split('/')[0];
  }

  @override
  Widget body(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: URQR(
            urqr: urQr,
            walletType: animatedURmodel.wallet.type,
          ),
        ),
        if (["ur:xmr-txunsigned", "ur:xmr-output", "ur:psbt", BBQR.header]
            .contains(urQrType)) ...{
          Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.maxFinite,
              child: PrimaryButton(
                onPressed: () => _continue(context),
                text: "Scan QR Code",
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        },
      ],
    );
  }

  Future<void> _continue(BuildContext context) async {
    try {
      switch (urQrType) {
        case "ur:xmr-txunsigned": // ur:xmr-txsigned
          final ur = await presentQRScanner(context);
          if (ur == null) return;
          final result =
              await monero!.commitTransactionUR(animatedURmodel.wallet, ur);
          if (result) {
            Navigator.of(context).pop(true);
          }
          break;
        case "ur:xmr-output": // xmr-keyimage
          final ur = await presentQRScanner(context);
          if (ur == null) return;
          final result =
              await monero!.importKeyImagesUR(animatedURmodel.wallet, ur);
          if (result) {
            Navigator.of(context).pop(true);
          }
          break;
        case "ur:psbt": // psbt
          final ur = await presentQRScanner(context);
          if (ur == null) return;
          await bitcoin!
              .commitPsbtUR(animatedURmodel.wallet, ur.trim().split("\n"));
          Navigator.of(context).pop(true);
        default:
          throw UnimplementedError("unable to handle UR: ${urQrType}");
      }
    } catch (e) {
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: S.of(context).error,
                alertContent: e.toString(),
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.pop(context, true));
          });
    }
  }
}