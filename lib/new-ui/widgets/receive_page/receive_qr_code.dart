import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../src/screens/receive/widgets/qr_image.dart';

class ReceiveQrCode extends StatelessWidget {
  ReceiveQrCode({
    super.key,
    required this.onTap,
    required this.largeQrMode,
    required this.addressListViewModel,
  });

  final VoidCallback onTap;
  final bool largeQrMode;
  final WalletAddressListViewModel addressListViewModel;

  static const double largeQrModeBottomPadding = 70;
  final bool isLightMode = !(getIt.get<ThemeStore>().currentTheme.isDark);

  @override
  Widget build(BuildContext context) {
    final double targetY = largeQrMode ? 60 : 0;
    final double resolvedSize = MediaQuery.of(context).size.width * (largeQrMode ? 0.85 : 0.5);
    final hasPayjoin = addressListViewModel.isPayjoinAvailable &&
        addressListViewModel.wallet.type == WalletType.bitcoin &&
        !addressListViewModel.isLightning &&
        !addressListViewModel.isSilentPayments;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: largeQrMode ? 1 : 0,
            child: SvgPicture.asset(
              isLightMode
                  ? "assets/new-ui/cakewallet-wordmark-light.svg"
                  : "assets/new-ui/cakewallet-wordmark.svg",
              height: 45,
            )),
        GestureDetector(
          onTap: onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: targetY),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      width: resolvedSize,
                      height: resolvedSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            color: hasPayjoin && !largeQrMode
                                ? Theme.of(context).colorScheme.surfaceContainer
                                : Colors.transparent),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LayoutBuilder(
                                builder: (context, constraints) => Observer(
                                    builder: (_) => QrImage(
                                        data: addressListViewModel.uri.toString(),
                                        embeddedImagePath:
                                        addressListViewModel.tokenCurrency != null
                                            ? addressListViewModel.tokenCurrency == CryptoCurrency.btcln
                                                ? addressListViewModel.qrImage
                                                : addressListViewModel.tokenCurrency!.iconPath
                                            : addressListViewModel.qrImage,
                                        size: constraints.maxWidth)))),
                      ),
                    ),
                    if (hasPayjoin)
                      Opacity(
                          opacity: largeQrMode ? 0 : 1,
                          child: Container(
                            width:resolvedSize,
                              decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.vertical(bottom: Radius.circular(8)),
                                  color: Theme.of(context).colorScheme.surfaceContainer),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    SvgPicture.asset("assets/new-ui/payjoin.svg"),
                                    Text(S.of(context).payjoin_enabled)
                                  ],
                                ),
                              ))),
                    AnimatedSize(
                        duration: Duration(milliseconds: 300),
                        // curve: Curves.easeOutCubic,
                        child: SizedBox(height: largeQrMode ? largeQrModeBottomPadding : 0))
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
