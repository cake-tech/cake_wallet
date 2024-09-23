import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/grouped_wallet_expansion_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/wallet_groups_display_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../themes/extensions/cake_text_theme.dart';

class WalletGroupsDisplayPage extends BasePage {
  WalletGroupsDisplayPage(this.walletGroupsDisplayViewModel);

  final WalletGroupsDisplayViewModel walletGroupsDisplayViewModel;

  final walletTypeImage = Image.asset('assets/images/wallet_type.png');
  final walletTypeLightImage = Image.asset('assets/images/wallet_type_light.png');

  @override
  String get title => S.current.wallet_group;

  @override
  Widget body(BuildContext context) => WalletGroupsDisplayBody(
        walletGroupsDisplayViewModel: walletGroupsDisplayViewModel,
      );
}

class WalletGroupsDisplayBody extends StatelessWidget {
  WalletGroupsDisplayBody({required this.walletGroupsDisplayViewModel});

  final WalletGroupsDisplayViewModel walletGroupsDisplayViewModel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Observer(
                  builder: (context) {
                    return Column(
                      children: [
                        if (walletGroupsDisplayViewModel.hasNoFilteredWallet) ...{
                          WalletGroupEmptyStateWidget(),
                        },
                        ...walletGroupsDisplayViewModel.multiWalletGroups.map(
                          (walletGroup) {
                            return Observer(builder: (context) {
                              final index = walletGroupsDisplayViewModel.multiWalletGroups
                                  .indexOf(walletGroup);
                              final group = walletGroupsDisplayViewModel.multiWalletGroups[index];
                              final groupName =
                                  group.groupName ?? '${S.of(context).wallet_group} ${index + 1}';
                              return GroupedWalletExpansionTile(
                                leadingWidget:
                                    Icon(Icons.account_balance_wallet_outlined, size: 28),
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                title: groupName,
                                childWallets: group.wallets.map((walletInfo) {
                                  return walletGroupsDisplayViewModel
                                      .convertWalletInfoToWalletListItem(walletInfo);
                                }).toList(),
                                isSelected:
                                    walletGroupsDisplayViewModel.selectedWalletGroup == group,
                                onTitleTapped: () =>
                                    walletGroupsDisplayViewModel.selectWalletGroup(group),
                                onChildItemTapped: (_) =>
                                    walletGroupsDisplayViewModel.selectWalletGroup(group),
                              );
                            });
                          },
                        ).toList(),
                        ...walletGroupsDisplayViewModel.singleWalletsList.map((singleWallet) {
                          return Observer(
                            builder: (context) {
                              final index = walletGroupsDisplayViewModel.singleWalletsList
                                  .indexOf(singleWallet);
                              final wallet = walletGroupsDisplayViewModel.singleWalletsList[index];
                              return GroupedWalletExpansionTile(
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                title: wallet.name,
                                isSelected:
                                    walletGroupsDisplayViewModel.selectedSingleWallet == wallet,
                                leadingWidget: Image.asset(
                                  walletTypeToCryptoCurrency(wallet.type).iconPath!,
                                  width: 32,
                                  height: 32,
                                ),
                                onTitleTapped: () =>
                                    walletGroupsDisplayViewModel.selectSingleWallet(wallet),
                              );
                            },
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ),
            Observer(
              builder: (context) {
                return LoadingPrimaryButton(
                  isLoading: walletGroupsDisplayViewModel.isFetchingMnemonic,
                  onPressed: () {
                    if (walletGroupsDisplayViewModel.hasNoFilteredWallet) {
                      Navigator.of(context).pushNamed(
                        Routes.newWallet,
                        arguments: NewWalletArguments(type: walletGroupsDisplayViewModel.type),
                      );
                    } else {
                      onTypeSelected(context);
                    }
                  },
                  text: walletGroupsDisplayViewModel.hasNoFilteredWallet
                      ? S.of(context).create_new_seed
                      : S.of(context).seed_language_next,
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  isDisabled: !walletGroupsDisplayViewModel.hasNoFilteredWallet
                      ? (walletGroupsDisplayViewModel.selectedWalletGroup == null &&
                          walletGroupsDisplayViewModel.selectedSingleWallet == null)
                      : false,
                );
              },
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> onTypeSelected(BuildContext context) async {
    final mnemonic = await walletGroupsDisplayViewModel.getSelectedWalletMnemonic();
    Navigator.of(context).pushNamed(
      Routes.newWallet,
      arguments: NewWalletArguments(
        type: walletGroupsDisplayViewModel.type,
        mnemonic: mnemonic,
        parentAddress: walletGroupsDisplayViewModel.parentAddress,
        isChildWallet: true,
      ),
    );
  }
}

class WalletGroupEmptyStateWidget extends StatelessWidget {
  const WalletGroupEmptyStateWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/wallet_group.png',
          scale: 0.8,
        ),
        SizedBox(height: 32),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${S.of(context).wallet_group_empty_state_text_one} ',
              ),
              TextSpan(
                text: '${S.of(context).create_new_seed} ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: S.of(context).wallet_group_empty_state_text_two),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            height: 1.5,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}
