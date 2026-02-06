import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:flutter/material.dart';
import "package:cw_core/wallet_type.dart";

class L2SendExternalModal extends StatefulWidget {
  const L2SendExternalModal({super.key, required this.sendViewModel});

  final SendViewModel sendViewModel;

  @override
  State<L2SendExternalModal> createState() => _L2SendExternalModalState();
}

class _L2SendExternalModalState extends State<L2SendExternalModal> {
  PaymentURI? uri;
  bool largeQrMode = false;
  static const warningTextColor = Color(0xFFFFB84E);
  static const warningBackgroundColor = Color(0xFF8E5800);

  @override
  void initState() {
    super.initState();
    () async {
      if(widget.sendViewModel.wallet.type == WalletType.bitcoin) {
        await bitcoin!.setAddressType(widget.sendViewModel.wallet,
            bitcoin!.getOptionToType(bitcoin!.getBitcoinLightningReceivePageOption()));
      }
      final newUri = await widget.sendViewModel.wallet.walletAddresses
          .getPaymentRequestUri(widget.sendViewModel.outputs.first.cryptoAmount);
      setState(() {
        uri = newUri;
      });
    }.call();
  }

  @override
  Widget build(BuildContext context) {
    final output = widget.sendViewModel.outputs.first;
    if (uri == null) return SizedBox.shrink();
    final resolvedSize = MediaQuery.of(context).size.width * (largeQrMode ? 0.8 : 0.54);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTopBar(
                title: "",
                leadingWidget: Row(
                  children: [Text(S.of(context).bitcoin_lightning_deposit)],
                ),
                trailingIcon: Icon(Icons.close),
                onTrailingPressed: Navigator.of(context).pop,
              ),
              Column(
                spacing: 24,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 12,
                    children: [
                      Text(
                        S.of(context).send_exactly,
                        style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500),
                      ),
                      Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              spacing: 8,
                              children: [
                                Text(
                                  output.cryptoAmount,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.primary),
                                ),
                                Text(
                                  widget.sendViewModel.currency.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.primary),
                                ),
                              ],
                            ),
                          )),
                      Text("${S.of(context).to}:",
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500))
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        largeQrMode = !largeQrMode;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      width: resolvedSize,
                      height: resolvedSize,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: QrImage(
                          embeddedImagePath: widget.sendViewModel.currency.iconPath,
                          data: uri.toString(),
                        ),
                      ),
                    ),
                  ),
                  AddressFormatter.buildSegmentedAddress(
                      address: output.address,
                      evenTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      textAlign: TextAlign.center),
                  SizedBox(),
                  Container(
                      decoration: BoxDecoration(
                        color: warningBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          S.of(context).lightning_external_disclaimer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: warningTextColor, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      )),
                  NewPrimaryButton(
                      onPressed: Navigator.of(context).pop,
                      text: S.of(context).sent_the_funds,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      textColor: Theme.of(context).colorScheme.primary),
                  SizedBox()
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
