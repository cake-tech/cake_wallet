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
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: FutureBuilder<List<TrocadorPartners>>(
        future: trocadorProvidersViewModel.fetchTrocadorPartners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            if (trocadorProvidersViewModel.providerStates.isNotEmpty) {
              return buildProvidersList();
            } else {
              return Center(child: Text('Error: ${snapshot.error.toString()}'));
            }
          } else if (snapshot.hasData) {
            final providers = snapshot.data!;
            return buildProvidersList(providers: providers);
          } else {
            return Center(child: Text('No providers found'));
          }
        },
      ),
    );
  }

  Widget buildProvidersList({List<TrocadorPartners>? providers}) {
    final providerStates = trocadorProvidersViewModel.providerStates;
    return ListView.builder(
      itemCount: providers?.length ?? providerStates.length,
      itemBuilder: (_, index) {
        final providerName = providers?[index].name ?? providerStates.keys.elementAt(index);
        return Observer(
          builder: (_) => SettingsSwitcherCell(
            title: providerName,
            value: providerStates[providerName] ?? true,
            onValueChange: (BuildContext _, bool value) {
              trocadorProvidersViewModel.toggleProviderState(providerName);
            },
          ),
        );
      },
    );
  }
}
