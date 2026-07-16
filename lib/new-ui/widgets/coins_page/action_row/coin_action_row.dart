import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/open_crypto_pay/open_cryptopay_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/send_page.dart';
import 'package:cake_wallet/new-ui/pages/swap_page.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/lnurl.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../../pages/receive_page.dart';
import 'coin_action_button.dart';

class CoinActionRow extends StatelessWidget {
  const CoinActionRow(
      {super.key, this.lightningMode = false, this.showSwap = true, required this.walletType});

  final bool lightningMode;
  final bool showSwap;
  final WalletType walletType;

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
            icon: CakeImageWidget(
              imageUrl: "assets/new-ui/send.svg",
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
            label: S.of(context).send,
            action: () {
              if (FeatureFlag.hasNewUiExtraPages) {
                final sendPage = getIt.get<NewSendPage>(
                  param1: SendPageParams(
                    unspentCoinType:
                        lightningMode ? UnspentCoinType.lightning : UnspentCoinType.nonMweb,
                  ),
                );

                CupertinoScaffold.showCupertinoModalBottomSheet(
                  context: context,
                  isDismissible: true,
                  barrierColor: Colors.black.withAlpha(60),
                  builder: (context) {
                    return Material(
                      child: ModalNavigator(
                        rootPage: sendPage,
                        parentContext: context,
                      ),
                    );
                  },
                );
              } else {
                Map<String, dynamic>? args;
                if (lightningMode) args = {'coinTypeToSpendFrom': UnspentCoinType.lightning};
                Navigator.of(context).pushNamed(Routes.send, arguments: args);
              }
            },
          ),
          CoinActionButton(
            icon: CakeImageWidget(
              imageUrl: "assets/new-ui/receive.svg",
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
            label: S.of(context).receive,
            action: () async {
              if (FeatureFlag.hasNewUiExtraPages) {
                final page = getIt.get<NewReceivePage>(param1: lightningMode);
                CupertinoScaffold.showCupertinoModalBottomSheet(
                  context: context,
                  barrierColor: Colors.black.withAlpha(60),
                  builder: (context) {
                    return Material(child: ModalNavigator(parentContext: context, rootPage: page));
                  },
                );
              } else {
                // ToDo: (Konsti) refactor as part of the derivation PR (I hate myself for it)
                if (lightningMode) {
                  await getIt<WalletAddressListViewModel>().setAddressType(
                      bitcoin!.getOptionToType(bitcoin!.getBitcoinLightningReceivePageOption()));
                } else {
                  await getIt<WalletAddressListViewModel>().setAddressType(
                      bitcoin!.getOptionToType(bitcoin!.getBitcoinSegwitPageOption()));
                }
                Navigator.of(context).pushNamed(Routes.addressPage);
              }
            },
          ),
          if (showSwap)
            CoinActionButton(
              icon: CakeImageWidget(
                imageUrl: "assets/new-ui/exchange.svg",
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              label: S.of(context).swap,
              action: () {
                final page =
                    getIt.get<NewSwapPage>(param2: lightningMode ? CryptoCurrency.btcln : null);
                if (FeatureFlag.hasNewUiExtraPages) {
                  CupertinoScaffold.showCupertinoModalBottomSheet(
                    context: context,
                    barrierColor: Colors.black.withAlpha(85),
                    builder: (context) => Material(
                        child: ModalNavigator(
                      rootPage: page,
                      parentContext: context,
                    )),
                  );
                } else {
                  Navigator.of(context).pushNamed(Routes.exchange);
                }
              },
            ),
          CoinActionButton(
            icon: CakeImageWidget(
              imageUrl: "assets/new-ui/scan.svg",
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
            label: S.of(context).scan,
            action: () => _onPressedScan(context),
          ),
        ],
      ),
    );
  }

  Future<void> _onPressedScan(BuildContext context) async {
    final code = await presentQRScanner(context, showHelp: true);

    if (code == null || code.isEmpty) return;

    late final PaymentRequest req;
    var unspentCoinType = UnspentCoinType.any;
    if (SendViewModelBase.isNonZeroAmountLightningInvoice(code)) {
      unspentCoinType = UnspentCoinType.lightning;
      final amount = getBolt11Amount(code)?.toString() ?? "0";
      req = PaymentRequest(code, amount, "", "", "");
    } else if (SendViewModelBase.isLnurlInvoice(code)) {
      unspentCoinType = UnspentCoinType.lightning;
      final amount = (await LNURL.getPayRequestAmount(code))?.toString() ?? "0";
      req = PaymentRequest(code, amount, "", "", "");
    } else if (OpenCryptoPayService.isOpenCryptoPayQR(code)) {
      req = PaymentRequest(code, "", "", "", "");
    } else if (Uri.tryParse(code)?.scheme == "wc") {
      if (!isWalletConnectCompatibleChain(walletType)) {
        showPopUp<void>(
            context: context,
            builder: (context) => AlertWithOneAction(
                alertTitle: "WalletConnect",
                alertContent:
                    S.of(context).switchToWCCompatibleWallet(walletConnectCompatibleChainsLabel()),
                buttonText: "OK",
                buttonAction: Navigator.of(context).pop));
        return;
      }

      Navigator.of(context)
          .pushNamed(Routes.walletConnectConnectionsListing, arguments: Uri.parse(code));
      return;
    } else if (["http", "https", "tcp"].contains(Uri.tryParse(code)?.scheme)) {
      Navigator.of(context).pushNamed(Routes.newNode,
          arguments: {"editingNode": Node.fromUri(Uri.parse(code), walletType)});
      return;
    } else {
      final uri = Uri.tryParse(code);
      if (uri == null) return;
      req = PaymentRequest.fromUri(uri);
    }

    final sendPage = getIt.get<NewSendPage>(
      param1: SendPageParams(
        initialPaymentRequest: req,
        unspentCoinType: unspentCoinType,
      ),
    );

    CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withAlpha(60),
      builder: (context) => Material(
        child: ModalNavigator(
          rootPage: sendPage,
          parentContext: context,
        ),
      ),
    );
  }
}
