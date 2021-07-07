import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_link_provider_cell.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/view_model/settings/link_list_item.dart';
import 'package:cake_wallet/view_model/settings/regular_list_item.dart';
import 'package:cake_wallet/view_model/support_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';

class SupportPage extends BasePage {
  SupportPage(this.supportViewModel);

  final SupportViewModel supportViewModel;

  @override
  String get title => S.current.settings_support;

  @override
  Widget body(BuildContext context) {
    final iconColor =
        Theme.of(context).accentTextTheme.display4.backgroundColor;

    return SectionStandardList(
        sectionCount: 1,
        itemCounter: (int _) => supportViewModel.items.length,
        itemBuilder: (_, __, index) {
          final item = supportViewModel.items[index];

          if (item is RegularListItem) {
            return SettingsCellWithArrow(
                title: item.title, handler: item.handler);
          }

          if (item is LinkListItem) {
            return SettingsLinkProviderCell(
                title: item.title,
                icon: item.icon,
                iconColor: item.hasIconColor ? iconColor : null,
                link: item.link,
                linkTitle: item.linkTitle);
          }

          return Container();
        });
  }

}