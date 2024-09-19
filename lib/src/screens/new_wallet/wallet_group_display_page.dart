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
                child: Column(
                  children: [
                    ...walletGroupsDisplayViewModel.multiWalletGroups.map(
                      (walletGroup) {
                        return Observer(builder: (context) {
                          final index =
                              walletGroupsDisplayViewModel.multiWalletGroups.indexOf(walletGroup);
                          final group = walletGroupsDisplayViewModel.multiWalletGroups[index];
                          final groupName =
                              group.groupName ?? '${S.of(context).wallet_group} ${index + 1}';
                          return GroupedWalletExpansionTile(
                            leadingWidget: Icon(Icons.account_balance_wallet_outlined, size: 28),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            title: groupName,
                            childWallets: group.wallets.map((walletInfo) {
                              return walletGroupsDisplayViewModel
                                  .convertWalletInfoToWalletListItem(walletInfo);
                            }).toList(),
                            isSelected: walletGroupsDisplayViewModel.selectedWalletGroup == group,
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
                          final index =
                              walletGroupsDisplayViewModel.singleWalletsList.indexOf(singleWallet);
                          final wallet = walletGroupsDisplayViewModel.singleWalletsList[index];
                          return GroupedWalletExpansionTile(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            title: wallet.name,
                            isSelected: walletGroupsDisplayViewModel.selectedSingleWallet == wallet,
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
                ),
              ),
            ),
            Observer(
              builder: (context) {
                return LoadingPrimaryButton(
                  isLoading: walletGroupsDisplayViewModel.isFetchingMnemonic,
                  onPressed: () => onTypeSelected(context),
                  text: S.of(context).seed_language_next,
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  isDisabled: walletGroupsDisplayViewModel.selectedWalletGroup == null &&
                      walletGroupsDisplayViewModel.selectedSingleWallet == null,
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
