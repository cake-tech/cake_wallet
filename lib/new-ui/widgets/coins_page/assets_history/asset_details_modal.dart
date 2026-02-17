import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/receive_page.dart';
import 'package:cake_wallet/new-ui/pages/send_page.dart';
import 'package:cake_wallet/new-ui/pages/swap_page.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

enum AssetDetailsModalModes { normal, ltcTransparent, ltcPrivate }

class AssetDetailsModal extends StatelessWidget {
  const AssetDetailsModal(
      {super.key,
      required this.title,
      required this.chainTitle,
      required this.subtitle,
      required this.amount,
      required this.currencyTitle,
      required this.fiatAmount,
      required this.iconPath,
      required this.chainIconPath,
      required this.mode,
      required this.wallet, required this.showSwap, this.asset});

  final String title;
  final CryptoCurrency? asset;
  final String chainTitle;
  final String subtitle;
  final String amount;
  final String currencyTitle;
  final String fiatAmount;
  final String iconPath;
  final String chainIconPath;
  final WalletBase wallet;
  final bool showSwap;
  final AssetDetailsModalModes mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalTopBar(
            title: "",
            trailingIcon: Icon(Icons.close),
            onTrailingPressed: Navigator.of(context).pop,
          ),
          SafeArea(
            child: Column(
              spacing: 24,
              children: [
                Column(
                  spacing: 15,
                  children: [
                    SizedBox(
                      width: 75,
                      height: 75,
                      child: Stack(
                        children: [
                          if(iconPath.isNotEmpty)
                          Image.asset(iconPath, width: 75, height: 75)
                          else
                          Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(99999)),
                            child: Center(
                                child: Text(
                                  title.substring(0, 2),
                                  style: TextStyle(
                                      fontSize: 28, color: Theme.of(context).colorScheme.onPrimary),
                                )),
                          ),
                          if (chainIconPath.isNotEmpty)
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                    decoration: ShapeDecoration(
                                        shape: RoundedSuperellipseBorder(
                                            borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.black)),
                                        color: Colors.white),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: SvgPicture.asset(
                                        chainIconPath,
                                        width: 18,
                                        height: 18,
                                        colorFilter:
                                        ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                      ),
                                    )))
                        ],
                      ),
                    ),
                    Column(
                      spacing: 4,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(999999999)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                                child: Text(
                                  chainTitle,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ),
                            )
                          ],
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                      ],
                    )
                  ],
                ),
                Container(
                  height: 1,
                  width: MediaQuery.of(context).size.width * 0.8,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                ),
                Column(
                  spacing: 4,
                  children: [
                    Row(
                      spacing: 4,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          amount,
                          style: TextStyle(fontSize: 28),
                        ),
                        Text(currencyTitle,
                            style: TextStyle(
                                fontSize: 28,
                                color: Theme.of(context).colorScheme.onSurfaceVariant))
                      ],
                    ),
                    Text(
                      fiatAmount,
                      style: TextStyle(
                          fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    )
                  ],
                ),
                SizedBox(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 20,
                  children: [
                    if (mode == AssetDetailsModalModes.ltcTransparent)
                      AssetDetailsModalBottomButton(
                          iconPath: "assets/new-ui/mask.svg",
                          title: S.of(context).mask,
                          onPressed: () {
                            Navigator.of(context).pop();
                            depositToL2(context);
                          }),
                    if (mode == AssetDetailsModalModes.ltcPrivate)
                      AssetDetailsModalBottomButton(
                          iconPath: "assets/new-ui/unmask.svg",
                          title: S.of(context).unmask,
                          onPressed: () {
                            Navigator.of(context).pop();
                            withdrawFromL2(context);
                          }),
                    AssetDetailsModalBottomButton(
                        iconPath: "assets/new-ui/send.svg",
                        title: S.of(context).send,
                        onPressed: () => openPage<NewSendPage>(context,
                            param1: SendPageParams(initialCurrency: asset))),
                    AssetDetailsModalBottomButton(
                        iconPath: "assets/new-ui/receive.svg",
                        title: S.of(context).receive,
                        onPressed: () async {
                          if (mode == AssetDetailsModalModes.ltcPrivate) {
                            await bitcoin!.setAddressType(
                                wallet,
                                bitcoin!
                                    .getOptionToType(bitcoin!.getLitecoinMwebReceivePageOption()));
                          }
                          openPage<NewReceivePage>(context, param2: asset);
                        }),
                    if(showSwap)
                    AssetDetailsModalBottomButton(
                        iconPath: "assets/new-ui/exchange.svg",
                        title: S.of(context).swap,
                          onPressed: () => openPage<NewSwapPage>(context, param2: asset)),
                  ],
                ),
                SizedBox()
              ],
            ),
          )
        ],
      ),
    );
  }

  void openPage<T extends Object>(BuildContext context, {dynamic param1, dynamic param2}) {
    final page = getIt.get<T>(param1: param1, param2: param2);
    showCupertinoModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withAlpha(60),
      builder: (context) {
        return Material(child: ModalNavigator(parentContext: context, rootPage: page as Widget));
      },
    );
  }

  Future<void> depositToL2(BuildContext context) async {
    PaymentRequest? paymentRequest = null;

    final depositAddress = bitcoin!.getUnusedMwebAddress(wallet);
    if ((depositAddress?.isNotEmpty ?? false)) {
      paymentRequest = PaymentRequest.fromUri(Uri.parse("litecoin:$depositAddress"));
    }

    final page = getIt.get<NewSendPage>(
        param1: SendPageParams(
      initialPaymentRequest: paymentRequest,
      unspentCoinType: UnspentCoinType.nonMweb,
      mode: SendPageModes.mwebDeposit,
    ));
    showCupertinoModalBottomSheet(
        context: context,
        barrierColor: Colors.black.withAlpha(128),
        builder: (context) {
          return FractionallySizedBox(
              heightFactor: 0.65,
              child: ModalNavigator(parentContext: context, rootPage: Material(child: page)));
        });
  }

  Future<void> withdrawFromL2(BuildContext context) async {
    PaymentRequest? paymentRequest = null;
    UnspentCoinType unspentCoinType = UnspentCoinType.any;
    final withdrawAddress = bitcoin!.getUnusedSegwitAddress(wallet);

    if ((withdrawAddress?.isNotEmpty ?? false)) {
      paymentRequest = PaymentRequest.fromUri(Uri.parse("litecoin:$withdrawAddress"));
    }
    unspentCoinType = UnspentCoinType.mweb;

    final page = getIt.get<NewSendPage>(
        param1: SendPageParams(
      initialPaymentRequest: paymentRequest,
      unspentCoinType: unspentCoinType,
      mode: SendPageModes.mwebWithdrawal,
    ));
    showCupertinoModalBottomSheet(
        context: context,
        barrierColor: Colors.black.withAlpha(128),
        builder: (context) {
          return FractionallySizedBox(
              heightFactor: 0.65,
              child: ModalNavigator(parentContext: context, rootPage: Material(child: page)));
        });
  }
}

class AssetDetailsModalBottomButton extends StatelessWidget {
  const AssetDetailsModalBottomButton(
      {super.key, required this.iconPath, required this.title, required this.onPressed});

  final String iconPath;
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        ModernButton.svg(
          onPressed: onPressed,
          svgPath: iconPath,
          size: 60,
          iconSize: 32,
        ),
        Text(title)
      ],
    );
  }
}
