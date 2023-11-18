import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
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
    final availableProviders = TrocadorExchangeProvider.availableProviders;
    final providerStates = trocadorProvidersViewModel.providerStates;
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: ListView.builder(
        itemCount: availableProviders.length,
        itemBuilder: (_, index) {
          String provider = availableProviders[index];
          return Observer(
              builder: (_) => SettingsSwitcherCell(
                  title: provider,
                  value: providerStates[provider] ?? false,
                  onValueChange: (BuildContext _, bool value) {
                    trocadorProvidersViewModel.toggleProviderState(provider);
                  }));
        },
      ),
    );
  }
}
