import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/dashboard/home_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class HomeSettingsPage extends BasePage {
  HomeSettingsPage(this._homeSettingsViewModel);

  final HomeSettingsViewModel _homeSettingsViewModel;

  final TextEditingController _searchController = TextEditingController();

  @override
  String? get title => S.current.home_screen_settings;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Observer(
            builder: (_) => SettingsPickerCell<SortBalanceBy>(
              title: S.current.sort_by,
              items: SortBalanceBy.values,
              selectedItem: _homeSettingsViewModel.sortBalanceBy,
              onItemSelected: _homeSettingsViewModel.setSortBalanceBy,
            ),
          ),
          Divider(color: Theme.of(context).primaryTextTheme.bodySmall!.decorationColor!),
          Observer(
            builder: (_) => SettingsSwitcherCell(
              title: S.of(context).pin_at_top(_homeSettingsViewModel.nativeToken),
              value: _homeSettingsViewModel.pinNativeToken,
              onValueChange: (_, bool value) {
                _homeSettingsViewModel.setPinNativeToken(value);
              },
            ),
          ),
          Divider(color: Theme.of(context).primaryTextTheme.bodySmall!.decorationColor!),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: TextFormField(
                    controller: _searchController,
                    style: TextStyle(color: Theme.of(context).primaryTextTheme.titleLarge!.color!),
                    decoration: InputDecoration(
                      hintText: S.of(context).search_add_token,
                      prefixIcon: Image.asset("assets/images/search_icon.png"),
                      filled: true,
                      fillColor: Theme.of(context).accentTextTheme.displaySmall!.color!,
                      alignLabelWithHint: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),
              ),
              RawMaterialButton(
                onPressed: () async {
                  Navigator.pushNamed(context, Routes.editToken,
                      arguments: {'homeSettingsViewModel': _homeSettingsViewModel});
                },
                elevation: 0,
                fillColor: Theme.of(context).accentTextTheme.bodySmall!.color!,
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).primaryTextTheme.titleLarge!.color!,
                  size: 22.0,
                ),
                padding: EdgeInsets.all(12),
                shape: CircleBorder(),
                splashColor: Theme.of(context).accentTextTheme.bodySmall!.color!,
              ),
            ],
          ),
          Observer(
            builder: (_) => ListView.builder(
              itemCount: _homeSettingsViewModel.tokens.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Observer(
                    builder: (_) => SettingsSwitcherCell(
                      title: _homeSettingsViewModel.tokens[index],
                      value: false,
                      onValueChange: (_, bool value) {},
                      decoration: BoxDecoration(
                        color: Theme.of(context).accentTextTheme.bodySmall!.color!,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
