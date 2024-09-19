import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/grouped_wallet_expansion_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/view_model/wallet_groups_display_view_model.dart';
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
            Text(
              S.current.chooseWalletToShareSeedWith,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: walletGroupsDisplayViewModel.wallets.length,
                itemBuilder: (context, index) {
                  return Observer(builder: (context) {
                    final group = walletGroupsDisplayViewModel.wallets[index];
                    final groupNames = walletGroupsDisplayViewModel.groupNames[index];
                    return GroupedWalletExpansionTile(
                      leadingWidget: Icon(Icons.account_balance_wallet_outlined, size: 28),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      title: groupNames,
                      childWallets: group.wallets.map((walletInfo) {
                        return walletGroupsDisplayViewModel
                            .convertWalletInfoToWalletListItem(walletInfo);
                      }).toList(),
                      isSelected: walletGroupsDisplayViewModel.selectedWalletGroup == group,
                      onTitleTapped: () => walletGroupsDisplayViewModel.selectWalletGroup(group),
                      onChildItemTapped: (_) => walletGroupsDisplayViewModel.selectWalletGroup(group),
                    );
                  });
                },
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
                  isDisabled: (walletGroupsDisplayViewModel.selectedWalletGroup == null &&
                          !walletGroupsDisplayViewModel.useNewSeed) ||
                      (walletGroupsDisplayViewModel.selectedWalletGroup != null &&
                          walletGroupsDisplayViewModel.useNewSeed),
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
    if (walletGroupsDisplayViewModel.useNewSeed) {
      Navigator.of(context).pushNamed(
        Routes.newWallet,
        arguments: NewWalletArguments(type: walletGroupsDisplayViewModel.type),
      );
    } else {
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
}
