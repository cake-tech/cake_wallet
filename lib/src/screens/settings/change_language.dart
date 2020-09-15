import 'package:cake_wallet/src/screens/settings/widgets/language_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/language.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';

class ChangeLanguage extends BasePage {
  @override
  String get title => S.current.settings_change_language;

  @override
  Widget body(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);
    final currentLanguage = Provider.of<Language>(context);

    return Container(
        padding: EdgeInsets.only(top: 10.0),
        child: SectionStandardList(
          sectionCount: 1,
          context: context,
          itemCounter: (int sectionIndex) => languages.values.length,
          itemBuilder: (_, sectionIndex, index) {
            final item = languages.values.elementAt(index);
            final code = languages.keys.elementAt(index);

            final isCurrent = settingsStore.languageCode == null
                ? false
                : code == settingsStore.languageCode;

            return LanguageRow(
              title: item,
              isSelected: isCurrent,
              handler: (context) async {
                if (!isCurrent) {
                  await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertWithTwoActions(
                            alertTitle: S.of(context).change_language,
                            alertContent: S.of(context).change_language_to(item),
                            rightButtonText: S.of(context).change,
                            leftButtonText: S.of(context).cancel,
                            actionRightButton: () {
                              settingsStore.saveLanguageCode(
                                  languageCode: code);
                              currentLanguage.setCurrentLanguage(code);
                              Navigator.of(context).pop();
                            },
                            actionLeftButton: () => Navigator.of(context).pop()
                        );
                      });
                }
              },
            );
          },
        )
    );
  }
}
