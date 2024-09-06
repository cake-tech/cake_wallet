import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/grouped_wallet_expansion_tile.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/view_model/pre_existing_seeds_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PreExistingSeedsPage extends BasePage {
  PreExistingSeedsPage(this.preExistingSeedsViewModel);

  final PreExistingSeedsViewModel preExistingSeedsViewModel;

  final walletTypeImage = Image.asset('assets/images/wallet_type.png');
  final walletTypeLightImage = Image.asset('assets/images/wallet_type_light.png');

  @override
  String get title => S.current.preExistingSeeds;

  @override
  Widget body(BuildContext context) => PreExistingSeedBody(
        preExistingSeedsViewModel: preExistingSeedsViewModel,
      );
}

class PreExistingSeedBody extends StatelessWidget {
  PreExistingSeedBody({required this.preExistingSeedsViewModel});

  final PreExistingSeedsViewModel preExistingSeedsViewModel;

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
          Observer(
            builder: (context) {
              return Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      ...preExistingSeedsViewModel.wallets.map(
                        (group) {
                          return GroupedWalletExpansionTile(
                            leadingWidget: Image.asset(
                              walletTypeToCryptoCurrency(group.leadWallet!.type).iconPath!,
                              width: 32,
                              height: 32,
                            ),
                            title: group.leadWallet!.name,
                            childWallets: group.wallets.map((walletInfo) {
                              return preExistingSeedsViewModel
                                  .convertWalletInfoToWalletListItem(walletInfo);
                            }).toList(),
                            isSelected: preExistingSeedsViewModel.selectedWalletGroup == group,
                            onTitleTapped: () => preExistingSeedsViewModel.selectWalletGroup(group),
                            onChildItemTapped: (_) =>
                                preExistingSeedsViewModel.selectWalletGroup(group),
                          );
                        },
                      ).toList(),
                      SelectButton(
                        text: S.current.newSeed,
                        isSelected: preExistingSeedsViewModel.useNewSeed == true,
                        onTap: () => preExistingSeedsViewModel.selectNewSeed(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Observer(builder: (context) {
            return PrimaryButton(
              onPressed: () => onTypeSelected(context),
              text: S.of(context).seed_language_next,
              color: Theme.of(context).primaryColor,
              textColor: Colors.white,
              isDisabled: (preExistingSeedsViewModel.selectedWalletGroup == null &&
                      !preExistingSeedsViewModel.useNewSeed) ||
                  (preExistingSeedsViewModel.selectedWalletGroup != null &&
                      preExistingSeedsViewModel.useNewSeed),
            );
          }),
          SizedBox(height: 32),
        ],
      ),
    ));
  }

  Future<void> onTypeSelected(BuildContext context) async {
    if (preExistingSeedsViewModel.useNewSeed) {
      Navigator.of(context).pushNamed(
        Routes.newWallet,
        arguments: NewWalletArguments(type: preExistingSeedsViewModel.type),
      );
    } else {
      final mnemonic = await preExistingSeedsViewModel.getSelectedWalletMnemonic();
      Navigator.of(context).pushNamed(
        Routes.newWallet,
        arguments: NewWalletArguments(
          type: preExistingSeedsViewModel.type,
          mnemonic: mnemonic,
          parentAddress: preExistingSeedsViewModel.parentAddress,
          isChildWallet: true,
        ),
      );
    }
  }
}
