import 'package:cake_wallet/src/screens/settings/widgets/language_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/language_service.dart';

// import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';

class LanguageListPage extends BasePage {
  LanguageListPage(this.settingsStore);

  final SettingsStore settingsStore;

  @override
  String get title => S.current.settings_change_language;

  @override
  Widget body(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 10.0),
        child: SectionStandardList(
          sectionCount: 1,
          context: context,
          itemCounter: (int sectionIndex) => LanguageService.list.values.length,
          itemBuilder: (_, sectionIndex, index) {
            return Observer(builder: (BuildContext context) {
              final item = LanguageService.list.values.elementAt(index);
              final code = LanguageService.list.keys.elementAt(index);
              final isCurrent = code == settingsStore.languageCode ?? false;

              return LanguageRow(
                title: item,
                isSelected: isCurrent,
                handler: (context) async {
                  if (!isCurrent) {
                    await showPopUp<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertWithTwoActions(
                              alertTitle: S.of(context).change_language,
                              alertContent:
                                  S.of(context).change_language_to(item),
                              rightButtonText: S.of(context).change,
                              leftButtonText: S.of(context).cancel,
                              actionRightButton: () {
                                settingsStore.languageCode = code;
                                Navigator.of(context).pop();
                              },
                              actionLeftButton: () =>
                                  Navigator.of(context).pop());
                        });
                  }
                },
              );
            });
          },
        ));

    return null;
  }
}
