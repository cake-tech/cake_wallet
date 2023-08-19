import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_link_provider_cell.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/themes/extensions/support_page_theme.dart';
import 'package:cake_wallet/view_model/settings/link_list_item.dart';
import 'package:cake_wallet/view_model/settings/regular_list_item.dart';
import 'package:cake_wallet/view_model/support_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';

class SupportOtherLinksPage extends BasePage {
  SupportOtherLinksPage(this.supportViewModel);

  final SupportViewModel supportViewModel;

  @override
  String get title => S.current.settings_support;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget body(BuildContext context) {
    final iconColor = Theme.of(context).extension<SupportPageTheme>()!.iconColor;

    return Container(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: SectionStandardList(
              sectionCount: 1,
              itemCounter: (int _) => supportViewModel.items.length,
              itemBuilder: (_, index) {
                final item = supportViewModel.items[index];

                if (item is RegularListItem) {
                  return SettingsCellWithArrow(title: item.title, handler: item.handler);
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
              }),
        ),
      ),
    );
  }
}
