import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/entities/sort_balance_types.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/view_model/dashboard/home_settings_view_model.dart";
import "package:flutter/material.dart";

class SortBalanceByPage extends BasePage {
  SortBalanceByPage(this._homeSettingsViewModel);

  final HomeSettingsViewModel _homeSettingsViewModel;

  @override
  String? get title => S.current.sort_by;

  @override
  Widget body(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: NewListSections(
          sections: {
            "": [
              for (final sortBalanceBy in SortBalanceBy.values)
                ListItemRegularRow(
                  keyValue: sortBalanceBy.name,
                  label: sortBalanceBy.toString(),
                  showArrow: false,
                  trailingWidget: SizedBox.square(
                    dimension: 24,
                    child: sortBalanceBy == _homeSettingsViewModel.sortBalanceBy
                        ? Icon(Icons.check, size: 20, color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  onTap: () {
                    _homeSettingsViewModel.setSortBalanceBy(sortBalanceBy);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          },
        ),
      );
}
