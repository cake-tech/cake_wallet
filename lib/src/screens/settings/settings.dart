import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_version_cell.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:cake_wallet/view_model/settings/version_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/settings/settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/link_list_item.dart';
import 'package:cake_wallet/view_model/settings/picker_list_item.dart';
import 'package:cake_wallet/view_model/settings/regular_list_item.dart';
import 'package:cake_wallet/view_model/settings/switcher_list_item.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_link_provider_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class SettingsPage extends BasePage {
  SettingsPage(this.settingsViewModel);

  final SettingsViewModel settingsViewModel;

  @override
  String get title => S.current.settings_title;

  @override
  Widget body(BuildContext context) {
    return Observer(builder: (_) {
      final sections = settingsViewModel.getSections();
      return SectionStandardList(
          sectionCount: sections.length,
          itemCounter: (int sectionIndex) {
            if (sectionIndex < sections.length) {
              return sections[sectionIndex].length;
            }

            return 0;
          },
          itemBuilder: (_, sectionIndex, itemIndex) {
            final item = sections[sectionIndex][itemIndex];

            if (item is PickerListItem) {
              return Observer(builder: (_) {
                return SettingsPickerCell<dynamic>(
                  displayItem: item.displayItem,
                  title: item.title,
                  selectedItem: item.selectedItem(),
                  items: item.items,
                  onItemSelected: (dynamic value) => item.onItemSelected(value),
                  images: item.images,
                  searchHintText: item.searchHintText,
                  isGridView: item.isGridView,
                  matchingCriteria: (dynamic value, String searchText) =>
                      item.matchingCriteria(value, searchText),
                );
              });
            }

            if (item is SwitcherListItem) {
              return Observer(builder: (_) {
                return SettingsSwitcherCell(
                    title: item.title,
                    value: item.value(),
                    onValueChange: item.onValueChange);
              });
            }

            if (item is RegularListItem) {
              return SettingsCellWithArrow(
                  title: item.title, handler: item.handler);
            }

            if (item is LinkListItem) {
              return SettingsLinkProviderCell(
                  title: item.title,
                  icon: item.icon,
                  link: item.link,
                  linkTitle: item.linkTitle);
            }

            if (item is VersionListItem) {
              return Observer(builder: (_) {
                return SettingsVersionCell(
                    title:
                    S.of(context).version(settingsViewModel.currentVersion));
              });
            }

            if (item is ChoicesListItem) {
              return SettingsChoicesCell(item);
            }

            return Container();
          });
    });
  }
}
