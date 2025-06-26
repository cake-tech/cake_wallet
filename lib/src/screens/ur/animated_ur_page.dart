import 'dart:async';

import 'package:bbqrdart/bbqrdart.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/clipboard_util.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/animated_ur_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ur:xmr-txunsigned - unsigned transaction
//     should show a scanner afterwards.

class AnimatedURPage extends BasePage {
  final bool isAll;
  AnimatedURPage(this.animatedURmodel, {
    required this.urQr,
    this.isAll = false,
  });

  late Map<String, String> urQr;

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
          padding: const EdgeInsets.only(top: 64.0),
          child: URQR(
            urqr: urQr,
          ),
        ),
        if (["ur:xmr-txunsigned", "ur:xmr-output", "ur:psbt", BBQR.header].contains(urQrType)) ...{
        SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.maxFinite,
              child: PrimaryButton(
                onPressed: () => _continue(context),
                text: "Continue",
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        },

        if (urQrType == "ur:xmr-output" && !isAll) ...{
          SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.maxFinite,
              child: PrimaryButton(
                onPressed: () => _exportAll(context),
                text: "Export all",
                color: Theme.of(context).colorScheme.secondary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        },
      ],
    );
  }

  void _exportAll(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          return AnimatedURPage(
            animatedURmodel,
            urQr: {
              "export-outputs-all": "export-outputs-all",
            },
            isAll: true,
          );
        },
      ),
    );
  }

  Future<void> _continue(BuildContext context) async {
    try {
    switch (urQrType) {
      case "ur:xmr-txunsigned": // ur:xmr-txsigned
        final ur = await presentQRScanner(context);
        if (ur == null) return;
        final result = await monero!.commitTransactionUR(animatedURmodel.wallet, ur);
        if (result) {
          Navigator.of(context).pop(true);
        }        
        break;
      case "ur:xmr-output": // xmr-keyimage
        final ur = await presentQRScanner(context);
        if (ur == null) return;
        final result = await monero!.importKeyImagesUR(animatedURmodel.wallet, ur);
        if (result) {
          Navigator.of(context).pop(true);
        }        
        break;
      case "ur:psbt": // psbt
        final ur = await presentQRScanner(context);
        if (ur == null) return;
        await bitcoin!.commitPsbtUR(animatedURmodel.wallet, ur.trim().split("\n"));
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

class URQR extends StatefulWidget {
  URQR({super.key, required this.urqr});

  final Map<String, String> urqr;

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

  late String selected = (widget.urqr.isEmpty) ? "unknown" : widget.urqr.keys.first;
  int selectedInt = 0;

  List<String> get frames {
    return widget.urqr[selected]?.split("\n") ?? [];
  }

  late String nextLabel = widget.urqr.keys.toList()[(selectedInt + 1) % widget.urqr.length] ;

  void next() {
    final keys = widget.urqr.keys.toList();
    selectedInt++;
    setState(() {
      nextLabel = keys[(selectedInt) % keys.length];
      selected = keys[(selectedInt) % keys.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: QrImage(
            data: frames[frame % frames.length],
            version: -1,
            size: 400,
          ),
        ),
        if (widget.urqr.values.length > 1)
          SizedBox(
            width: double.maxFinite,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.maxFinite,
                child: PrimaryButton(
                  onPressed: next,
                  text: nextLabel,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        if (FeatureFlag.hasDevOptions) ...{
          TextButton(
            onPressed: () { 
              Clipboard.setData(ClipboardData(text: """Current frame (${frame % frames.length}): ${frames[frame % frames.length]},
All frames:
 - ${frames.join("\n - ")}"""));
             },
            child: Text(frames[frame % frames.length]),
          ),
        }
      ],
    );
  }
}