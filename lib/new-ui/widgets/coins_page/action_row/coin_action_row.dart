import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/open_crypto_pay/open_cryptopay_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/send_page.dart';
import 'package:cake_wallet/new-ui/pages/swap_page.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../../pages/receive_page.dart';
import '../../../pages/scan_page.dart';
import 'coin_action_button.dart';

class CoinActionRow extends StatelessWidget {
  const CoinActionRow({super.key, this.lightningMode = false, this.showSwap = true});

  final bool lightningMode;
  final bool showSwap;

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
            icon: SvgPicture.asset(
              "assets/new-ui/send.svg",
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
                        lightningMode ? UnspentCoinType.lightning : UnspentCoinType.any,
                  ),
                );

                CupertinoScaffold.showCupertinoModalBottomSheet(
                  context: context,
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
                if (lightningMode) args = {'coinTypeToSpendFrom' : UnspentCoinType.lightning};
                Navigator.of(context).pushNamed(Routes.send, arguments: args);
              }
            },
          ),
          CoinActionButton(
            icon: SvgPicture.asset(
              "assets/new-ui/receive.svg",
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
                      return Material(child: ModalNavigator(parentContext:context,rootPage: page));
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
              icon: SvgPicture.asset(
                "assets/new-ui/exchange.svg",
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              label: S.of(context).swap,
              action: () {
                final page = getIt.get<NewSwapPage>();
                if (FeatureFlag.hasNewUiExtraPages) {
                  CupertinoScaffold.showCupertinoModalBottomSheet(
                    context: context,
                    barrierColor: Colors.black.withAlpha(85),
                    builder: (context) => FractionallySizedBox(
                        heightFactor: 0.97,
                        child: Material(
                            child: ModalNavigator(
                          rootPage: page,
                          parentContext: context,
                        ))),
                  );
                } else {
                  Navigator.of(context).pushNamed(Routes.exchange);
                }
              },
            ),
          CoinActionButton(
            icon: SvgPicture.asset(
              "assets/new-ui/scan.svg",
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
            label: "Scan",
            action: () => _onPressedScan(context),
          ),
        ],
      ),
    );
  }

  Future<void> _onPressedScan(BuildContext context) async {
    if (false && FeatureFlag.hasNewUiExtraPages) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.9,
          child: ScanPage(),
        ),
      );
    } else {
      final code = await presentQRScanner(context);

      if (code == null || code.isEmpty) return;

      late final PaymentRequest req;
      if (SendViewModelBase.isNonZeroAmountLightningInvoice(code) ||
          OpenCryptoPayService.isOpenCryptoPayQR(code)) {
        req = PaymentRequest(code, "", "", "", "");
      } else {
        final uri = Uri.tryParse(code);
        if (uri == null) return;
        req = PaymentRequest.fromUri(uri);
      }

      final sendPage = getIt.get<NewSendPage>(
        param1: SendPageParams(initialPaymentRequest: req),
      );

      CupertinoScaffold.showCupertinoModalBottomSheet(
        context: context,
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
    }
    ;
  }
}
