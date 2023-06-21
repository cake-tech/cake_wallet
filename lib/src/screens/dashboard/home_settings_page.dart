import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
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

  // TODO: add localization
  @override
  String? get title => "S.current.home_screen_settings";

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Observer(
            builder: (_) => SettingsPickerCell<SortBalanceBy>(
              title: "S.current.sort_by",
              items: SortBalanceBy.values,
              selectedItem: _homeSettingsViewModel.sortBalanceBy,
              onItemSelected: _homeSettingsViewModel.setSortBalanceBy,
            ),
          ),
          Row(
            children: [
              TextFormField(
                controller: _searchController,
                style: TextStyle(color: Theme.of(context).primaryTextTheme.titleLarge!.color!),
                decoration: InputDecoration(
                  hintText: "S.of(context).search_token",
                  prefixIcon: Image.asset("assets/images/search_icon.png"),
                  filled: true,
                  fillColor: Theme.of(context).accentTextTheme.displaySmall!.color!,
                  alignLabelWithHint: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                style: IconButton.styleFrom(
                  shape: CircleBorder(),
                  backgroundColor: Theme.of(context).accentTextTheme.bodySmall!.color!,
                ),
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).primaryTextTheme.titleLarge!.color!,
                  size: 22.0,
                ),
              ),
            ],
          ),
          ListView.builder(
            itemCount: _homeSettingsViewModel.tokens.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return SettingsSwitcherCell(
                title: _homeSettingsViewModel.tokens[index],
                value: false,
                onValueChange: (_, bool value) {},
              );
            },
          ),
        ],
      ),
    );
  }
}
