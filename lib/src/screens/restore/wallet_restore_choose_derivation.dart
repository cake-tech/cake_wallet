import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/view_model/wallet_restore_choose_derivation_view_model.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class WalletRestoreChooseDerivationPage extends BasePage {
  WalletRestoreChooseDerivationPage(this.walletRestoreChooseDerivationViewModel) {}

  @override
  Widget middle(BuildContext context) => Observer(
      builder: (_) => Text(
            "change me",
            style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
                color: titleColor ?? Theme.of(context).primaryTextTheme!.titleLarge!.color!),
          ));

  final WalletRestoreChooseDerivationViewModel walletRestoreChooseDerivationViewModel;
  DerivationType derivationType = DerivationType.unknown;

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) => FutureBuilder<List<Derivation>>(
        future: walletRestoreChooseDerivationViewModel.derivations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Show loading spinner while waiting
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}'); // Show error if any
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No derivations available'); // Show message if no derivations are available
          } else {
            return ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              separatorBuilder: (_, __) => Container(padding: EdgeInsets.only(bottom: 8)),
              itemCount: snapshot.data!.length,
              itemBuilder: (__, index) {
                final derivation = snapshot.data![index];
                return InkWell(
                  onTap: () async {
                    Navigator.pop(context, derivation.derivationType);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 16, right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(
                        color: getIt.get<SettingsStore>().currentTheme.type == ThemeType.bright
                            ? Color.fromRGBO(255, 255, 255, 0.2)
                            : Colors.transparent,
                        width: 1,
                      ),
                      color: Theme.of(context).textTheme.titleLarge!.backgroundColor!,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            derivation.address,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w400,
                              color:
                                  Theme.of(context).accentTextTheme.displayMedium!.backgroundColor!,
                              height: 1,
                            ),
                          ),
                          Text(
                            "${S.current.confirmed}: ${derivation.balance}",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w400,
                              color:
                                  Theme.of(context).accentTextTheme.displayMedium!.backgroundColor!,
                              height: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
