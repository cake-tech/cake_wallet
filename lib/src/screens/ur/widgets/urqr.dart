
import 'dart:async';

import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/screens/ur/widgets/qr_format_info_bottom_sheet.dart';
import 'package:cake_wallet/src/screens/ur/widgets/qr_selection_dialog.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

class URQR extends StatefulWidget {
  URQR({super.key, required this.urqr, required this.walletType});

  final Map<String, String> urqr;
  final WalletType walletType;
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

  late String selected =
      (widget.urqr.isEmpty) ? "unknown" : widget.urqr.keys.first;
  int selectedInt = 0;

  List<String> get frames {
    return widget.urqr[selected]?.split("\n") ?? [];
  }

  late String nextLabel =
      widget.urqr.keys.toList()[(selectedInt + 1) % widget.urqr.length];

  void next() {
    final keys = widget.urqr.keys.toList();
    setState(() {
      selectedInt++;
      nextLabel = keys[(selectedInt + 1) % keys.length];
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              child: QrImage(
                data: frames[frame % frames.length],
                version: -1,
                size: null,
              ),
            ),
          ),
        ),
        if (widget.urqr.values.length > 1)
          widget.walletType == WalletType.monero
              ? _legacySwitch(context)
              : _newSwitch(context),
        if (FeatureFlag.hasDevOptions) ...{
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text:
                      """Current frame (${frame % frames.length}): ${frames[frame % frames.length]},
All frames:
 - ${frames.join("\n - ")}"""));
            },
            child: Text("[dev] copy debug info"),
          ),
        }
      ],
    );
  }

  Widget _legacySwitch(BuildContext context) {
    return SizedBox(
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
    );
  }

  Widget _newSwitch(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code,
                color: Theme.of(context).colorScheme.primary, size: 24),
            SizedBox(width: 4),
            Text("QR Code Format",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
          ],
        ),
        SizedBox(height: 16),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showFormatSelectionDialog(context),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_getCurrentFormatName().startsWith('Cupcake'))
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SvgPicture.asset(
                            'assets/images/cupcake.svg',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCurrentFormatName(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _getCurrentFormatSubtitle(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showInfoDialog(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "What's this for?",
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
      ],
    );
  }

  String _getCurrentFormatName() {
    if (widget.urqr.isEmpty) return "Unknown";
    final currentKey =
        widget.urqr.keys.elementAt(selectedInt % widget.urqr.length);
    return currentKey.split(' ')[0];
  }

  String _getCurrentFormatSubtitle() {
    if (widget.urqr.isEmpty) return "";
    final currentKey =
        widget.urqr.keys.elementAt(selectedInt % widget.urqr.length);
    return currentKey.substring(currentKey.indexOf(' ') + 1);
  }

  Future<void> _showFormatSelectionDialog(BuildContext context) async {
    if (widget.urqr.length <= 1) return;

    final keys = widget.urqr.keys.toList();

    await showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return QRFormatSelectionDialog(
            formats: keys,
            currentIndex: selectedInt,
            onFormatSelected: (index) {
              Navigator.pop(context);
              setState(() {
                selectedInt = index;
                selected = keys[index];
                nextLabel = keys[(index + 1) % keys.length];
              });
            },
          );
        });
  }

  Future<void> _showInfoDialog(BuildContext context) async {
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return QRFormatInfoBottomSheet();
        });
  }
}
