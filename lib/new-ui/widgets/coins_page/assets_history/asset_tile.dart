import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/asset_details_modal.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/string_parsing.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AssetTile extends StatelessWidget {
  const AssetTile(
      {super.key,
      required this.balance,
      required this.chainIconPath,
      this.showSecondary = false,
      this.title,
      this.trailingText,
      this.modalMode = AssetDetailsModalModes.normal,
      required this.wallet, required this.showSwap});

  final BalanceRecord balance;
  final bool showSecondary;
  final bool showSwap;
  final String chainIconPath;
  final String? title;
  final String? trailingText;
  final AssetDetailsModalModes modalMode;
  final WalletBase wallet;

  @override
  Widget build(BuildContext context) {
    final iconPath = _getIconPath();

    return GestureDetector(
      onTap: (){
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return AssetDetailsModal(
                showSwap: showSwap,
                asset: balance.asset,
                title: title ?? balance.asset.fullName ?? balance.asset.name,
                chainTitle: _getChainTitle(),
                subtitle: trailingText ?? "",
                amount: showSecondary ? balance.secondAvailableBalance : balance.availableBalance,
                currencyTitle: balance.asset.title,
                fiatAmount: showSecondary
                    ? balance.fiatSecondAvailableBalance
                    : balance.fiatAvailableBalance,
                iconPath: balance.asset.iconPath ?? "",
                chainIconPath: chainIconPath,
                mode: modalMode,
                wallet: wallet,
              );
            });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
        child: Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surfaceContainerHigh,
                Theme.of(context).colorScheme.surfaceContainer,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20)),
            border: Border.all(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 45,
                          height: 45,
                          child: Stack(
                            children: [
                              if((iconPath).isNotEmpty)
                              Image.asset(iconPath)
                              else
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(99999)),
                                  child: Center(
                                      child: Text(
                                    balance.asset.name.substring(0, 2),
                                    style: TextStyle(
                                        fontSize: 20, color: Theme.of(context).colorScheme.onPrimary),
                                  )),
                                ),
                              if (chainIconPath.isNotEmpty)
                                Align(
                                    alignment: Alignment.bottomRight,
                                    child: Container(
                                        decoration: ShapeDecoration(
                                            shape: RoundedSuperellipseBorder(
                                                borderRadius: BorderRadius.circular(5),side: BorderSide(color: Colors.black)),
                                            color: Colors.white),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: SvgPicture.asset(
                                            chainIconPath,
                                            width: 12,
                                            height: 12,
                                            colorFilter:
                                                ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                          ),
                                        )))
                            ],
                          )),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Column(
                          spacing: 4.0,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 4,
                              children: [
                                Text(
                                  title ?? balance.asset.fullName ?? balance.asset.name,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if(trailingText != null)
                                Text(
                                  trailingText!,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                   "${showSecondary ?balance.secondAvailableBalance: balance.availableBalance} ${balance.formattedAssetTitle.safeSubString(0, 6)}",
                                  maxLines:1,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  showSecondary ? balance.fiatSecondAvailableBalance : balance.fiatAvailableBalance,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getChainTitle() {
    try {
      return CryptoCurrency.fromString(wallet.currency.tag ??wallet.currency.title).title;
    } catch(e) {
      return wallet.currency.title;
    }
  }

  String _getIconPath() {
    if(balance.asset == CryptoCurrency.baseEth)
      return "assets/images/crypto/ethereum.webp";

    return balance.asset.iconPath ?? "";
  }
}
