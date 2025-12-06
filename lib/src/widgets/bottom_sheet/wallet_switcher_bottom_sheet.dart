import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_switcher_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class WalletSwitcherBottomSheet extends BaseBottomSheet {
  WalletSwitcherBottomSheet({
    Key? key,
    required this.viewModel,
    this.filterWalletType,
    this.subtitle,
    this.onWalletSelected,
  }) : super(
          titleText: S.current.select_a_wallet,
          footerType: FooterType.none,
          maxHeight: 900,
        );

  final WalletSwitcherViewModel viewModel;
  final WalletType? filterWalletType;
  final String? subtitle;
  final Function(WalletInfo)? onWalletSelected;

  @override
  Widget contentWidget(BuildContext context) {
    return _WalletSwitcherContent(
      viewModel: viewModel,
      filterWalletType: filterWalletType,
      subtitle: subtitle,
      onWalletSelected: onWalletSelected,
    );
  }
}

class _WalletSwitcherContent extends StatelessWidget {
  const _WalletSwitcherContent({
    required this.viewModel,
    this.filterWalletType,
    this.subtitle,
    this.onWalletSelected,
  });

  final WalletSwitcherViewModel viewModel;
  final WalletType? filterWalletType;
  final String? subtitle;
  final Function(WalletInfo)? onWalletSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: viewModel.getWallets(filterWalletType),
      builder: (context, snapshot) => Observer(
        builder: (_) {
          final List<WalletInfo> wallets = (snapshot.data ?? []);

          if (viewModel.isProcessing) {
            return Container(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          return Container(
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StandardList(
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];

                      return InkWell(
                        onTap: () {
                          viewModel.selectWallet(wallet);
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Image.asset(
                                walletTypeToCryptoCurrency(
                                  wallet.type,
                                  chainId: wallet.type == WalletType.evm
                                      ? evm!.getChainIdByWalletType(wallet.type)
                                      : null,
                                ).iconPath!,
                                width: 32,
                                height: 32,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                wallet.name,
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      letterSpacing: 0.0,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
