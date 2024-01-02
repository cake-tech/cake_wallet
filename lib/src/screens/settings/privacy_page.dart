import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:cake_wallet/view_model/settings/privacy_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PrivacyPage extends BasePage {
  PrivacyPage(this._privacySettingsViewModel);

  @override
  String get title => S.current.privacy_settings;

  final PrivacySettingsViewModel _privacySettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(top: 10),
        child: Observer(builder: (_) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsChoicesCell(
                ChoicesListItem<FiatApiMode>(
                  title: S.current.fiat_api,
                  items: FiatApiMode.all,
                  selectedItem: _privacySettingsViewModel.fiatApiMode,
                  onItemSelected: (FiatApiMode fiatApiMode) =>
                      _privacySettingsViewModel.setFiatMode(fiatApiMode),
                ),
              ),
              SettingsChoicesCell(
                ChoicesListItem<ExchangeApiMode>(
                  title: S.current.exchange,
                  items: ExchangeApiMode.all,
                  selectedItem: _privacySettingsViewModel.exchangeStatus,
                  onItemSelected: (ExchangeApiMode mode) =>
                      _privacySettingsViewModel.setExchangeApiMode(mode),
                ),
              ),
              SettingsSwitcherCell(
                  title: S.current.settings_save_recipient_address,
                  value: _privacySettingsViewModel.shouldSaveRecipientAddress,
                  onValueChange: (BuildContext _, bool value) {
                    _privacySettingsViewModel.setShouldSaveRecipientAddress(value);
                  }),
              if (_privacySettingsViewModel.isAutoGenerateSubaddressesVisible)
                SettingsSwitcherCell(
                  title: S.current.auto_generate_subaddresses,
                  value: _privacySettingsViewModel.isAutoGenerateSubaddressesEnabled,
                  onValueChange: (BuildContext _, bool value) {
                    _privacySettingsViewModel.setAutoGenerateSubaddresses(value);
                  },
                ),
              if (DeviceInfo.instance.isMobile)
                SettingsSwitcherCell(
                    title: S.current.prevent_screenshots,
                    value: _privacySettingsViewModel.isAppSecure,
                    onValueChange: (BuildContext _, bool value) {
                      _privacySettingsViewModel.setIsAppSecure(value);
                    }),
              SettingsSwitcherCell(
                  title: S.current.disable_buy,
                  value: _privacySettingsViewModel.disableBuy,
                  onValueChange: (BuildContext _, bool value) {
                    _privacySettingsViewModel.setDisableBuy(value);
                  }),
              SettingsSwitcherCell(
                  title: S.current.disable_sell,
                  value: _privacySettingsViewModel.disableSell,
                  onValueChange: (BuildContext _, bool value) {
                    _privacySettingsViewModel.setDisableSell(value);
                  }),
              if (_privacySettingsViewModel.canUseEtherscan)
                SettingsSwitcherCell(
                    title: S.current.etherscan_history,
                    value: _privacySettingsViewModel.useEtherscan,
                    onValueChange: (BuildContext _, bool value) {
                      _privacySettingsViewModel.setUseEtherscan(value);
                    }),
              if (_privacySettingsViewModel.canUsePolygonScan)
                SettingsSwitcherCell(
                  title: S.current.polygonscan_history,
                  value: _privacySettingsViewModel.usePolygonScan,
                  onValueChange: (BuildContext _, bool value) {
                    _privacySettingsViewModel.setUsePolygonScan(value);
                  },
                ),
              SettingsCellWithArrow(
                title: S.current.domain_looks_up,
                handler: (context) => Navigator.of(context).pushNamed(Routes.domainLookupsPage),
              ),
              SettingsCellWithArrow(
                title: 'Trocador providers',
                handler: (context) => Navigator.of(context).pushNamed(Routes.trocadorProvidersPage),
              ),
            ],
          );
        }),
      ),
    );
  }
}
