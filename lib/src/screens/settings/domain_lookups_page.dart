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
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsTwitter(value)),
              SettingsSwitcherCell(
                  title: 'Mastodon',
                  value: _connectionsSyncViewModel.looksUpMastodon,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsMastodon(value)),
              SettingsSwitcherCell(
                  title: 'Yat service',
                  value: _connectionsSyncViewModel.looksUpYatService,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsYatService(value)),
              SettingsSwitcherCell(
                  title: 'Unstoppable Domains',
                  value: _connectionsSyncViewModel.looksUpUnstoppableDomains,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsUnstoppableDomains(value)),
              SettingsSwitcherCell(
                  title: 'OpenAlias',
                  value: _connectionsSyncViewModel.looksUpOpenAlias,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsOpenAlias(value)),
              SettingsSwitcherCell(
                  title: 'Ethereum Name Service',
                  value: _connectionsSyncViewModel.looksUpENS,
                  onValueChange: (_, bool value) => _connectionsSyncViewModel.setLookupsENS(value)),
              SettingsSwitcherCell(
                  title: 'Zcash Names',
                  value: _connectionsSyncViewModel.lookupsZcashNames,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsZcashNames(value)),
              SettingsSwitcherCell(
                  title: 'Zcash Addresses',
                  value: _connectionsSyncViewModel.lookupsZcashAddress,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsZcashAddress(value)),
              SettingsSwitcherCell(
                  title: '.well-known',
                  value: _connectionsSyncViewModel.looksUpWellKnown,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsWellKnown(value)),
              SettingsSwitcherCell(
                  title: 'Zano Aliases',
                  value: _connectionsSyncViewModel.lookupsZanoAlias,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsZanoAlias(value)),
              SettingsSwitcherCell(
                  title: 'BIP353',
                  value: _connectionsSyncViewModel.lookupsBip353,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsBip353(value)),
              SettingsSwitcherCell(
                  title: 'FIO',
                  value: _connectionsSyncViewModel.lookupsFio,
                  onValueChange: (_, bool value) => _connectionsSyncViewModel.setLookupsFio(value)),
              SettingsSwitcherCell(
                  title: 'LNURL Pay',
                  value: _connectionsSyncViewModel.lookupsLNUrlPay,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsLNUrlPay(value)),
              SettingsSwitcherCell(
                  title: 'ThorChain',
                  value: _connectionsSyncViewModel.lookupsThorChain,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsThorChain(value)),
              SettingsSwitcherCell(
                  title: 'Nostr',
                  value: _connectionsSyncViewModel.lookupsNostr,
                  onValueChange: (_, bool value) =>
                      _connectionsSyncViewModel.setLookupsNostr(value)),
            ],
          ),
        );
      }),
    );
  }
}
