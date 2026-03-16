import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/settings/connection_sync_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DomainLookupsPage extends BasePage {
  DomainLookupsPage(this._connectionsSyncViewModel);

  @override
  String get title => S.current.domain_looks_up;

  final ConnectionSyncViewModel _connectionsSyncViewModel;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Observer(builder: (_) {
        return Container(
          padding: EdgeInsets.only(top: 10),
          child: Column(
            children: [
              SettingsSwitcherCell(
                  title: 'Twitter',
                  value: _connectionsSyncViewModel.lookupTwitter,
                  onValueChange: (_, bool value) => _connectionsSyncViewModel.setLookupsTwitter(value)),
              SettingsSwitcherCell(
                  title: 'Mastodon',
                  value: _connectionsSyncViewModel.looksUpMastodon,
                  onValueChange: (_, bool value) => _connectionsSyncViewModel.setLookupsMastodon(value)),
              SettingsSwitcherCell(
                  title: 'Yat service',
                  value: _connectionsSyncViewModel.looksUpYatService,
                  onValueChange: (_, bool value) => _connectionsSyncViewModel.setLookupsYatService(value)),
              SettingsSwitcherCell(
                  title: 'Unstoppable Domains',
                  value: _connectionsSyncViewModel.looksUpUnstoppableDomains,
                  onValueChange: (_, bool value) => _connectionsSyncViewModel.setLookupsUnstoppableDomains(value)),
              SettingsSwitcherCell(
                  title: 'OpenAlias',
                  value: _connectionsSyncViewModel.looksUpOpenAlias,
                  onValueChange: (_, bool value) => _connectionsSyncViewModel.setLookupsOpenAlias(value)),
              SettingsSwitcherCell(
                  title: 'Ethereum Name Service',
                  value: _connectionsSyncViewModel.looksUpENS,
                  onValueChange: (_, bool value) => _connectionsSyncViewModel.setLookupsENS(value)),
              SettingsSwitcherCell(
                  title: '.well-known',
                  value: _connectionsSyncViewModel.looksUpWellKnown,
                  onValueChange: (_, bool value) => _connectionsSyncViewModel.setLookupsWellKnown(value)),
              SettingsSwitcherCell(
                  title: 'Zano Aliases',
                  value: _connectionsSyncViewModel.lookupsZanoAlias,
                  onValueChange: (_, bool value) => _connectionsSyncViewModel.setLookupsZanoAlias(value)),

              //if (!isHaven) it does not work correctly
            ],
          ),
        );
      }),
    );
  }
}
