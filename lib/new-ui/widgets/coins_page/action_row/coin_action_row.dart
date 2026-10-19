import "package:cake_wallet/core/links/link_service.dart";
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/send_page.dart';
import 'package:cake_wallet/new-ui/pages/swap_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../../pages/receive_page.dart';
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
            key: ValueKey("home_page_send_button_key"),
            icon: CakeImageWidget(
              imageUrl: "assets/new-ui/send.svg",
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
            label: S.of(context).send,
            action: () {
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
            },
          ),
          CoinActionButton(
            key: ValueKey("home_page_receive_button_key"),
            icon: CakeImageWidget(
              imageUrl: "assets/new-ui/receive.svg",
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
            label: S.of(context).receive,
            action: () async {
                final page = getIt.get<NewReceivePage>(param1: lightningMode);
                CupertinoScaffold.showCupertinoModalBottomSheet(
                  context: context,
                  barrierColor: Colors.black.withAlpha(60),
                  builder: (context) {
                    return Material(child: ModalNavigator(parentContext: context, rootPage: page));
                  },
                );
            },
          ),
          if (showSwap)
            CoinActionButton(
              key: ValueKey("home_page_swap_button_key"),
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
                  CupertinoScaffold.showCupertinoModalBottomSheet(
                    context: context,
                    barrierColor: Colors.black.withAlpha(85),
                    builder: (context) => Material(
                        child: ModalNavigator(
                      rootPage: page,
                      parentContext: context,
                    )),
                  );
              },
            ),
          CoinActionButton(
            key: ValueKey("home_page_scan_button_key"),
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
    if (await presentQRScanner(context, showHelp: true) case final String code) {
      if (Uri.tryParse(code) case final Uri uri) {
        await getIt.get<LinkService>().handle(uri);
      }
    }
  }
}
