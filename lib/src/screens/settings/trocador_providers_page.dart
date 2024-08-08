import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/settings/trocador_providers_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class TrocadorProvidersPage extends BasePage {
  TrocadorProvidersPage(this.trocadorProvidersViewModel);

  @override
  String get title => 'Trocador Providers';

  final TrocadorProvidersViewModel trocadorProvidersViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Observer(
        builder: (_) {
          if (trocadorProvidersViewModel.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          var providerStates = trocadorProvidersViewModel.providerStates;
          if (providerStates.isEmpty) {
            return Center(child: Text(S.of(context).no_providers_available));
          }
          return ListView.builder(
            itemCount: providerStates.length,
            itemBuilder: (_, index) {
              final providerName = providerStates.keys.elementAt(index);
              final providerEnabled = providerStates[providerName] ?? true;
              return SettingsSwitcherCell(
                title: providerName,
                value: providerEnabled,
                onValueChange: (BuildContext _, value) =>
                    trocadorProvidersViewModel.toggleProviderState(providerName),
              );
            },
          );
        },
      ),
    );
  }
}
