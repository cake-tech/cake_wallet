import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/language.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';

class ChangeLanguage extends BasePage {
  @override
  String get title => S.current.settings_change_language;

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  Widget body(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);
    final currentLanguage = Provider.of<Language>(context);

    final currentColor = Colors.green;
    final notCurrentColor = Colors.white;

    final shortDivider = Container(
      height: 1,
      padding: EdgeInsets.only(left: 24),
      color: PaletteDark.menuList,
      child: Container(
        height: 1,
        color: PaletteDark.mainBackgroundColor,
      ),
    );

    final longDivider = Container(
      height: 1,
      color: PaletteDark.mainBackgroundColor,
    );

    return Container(
        color: PaletteDark.historyPanel,
        padding: EdgeInsets.only(top: 10.0),
        child: ListView.builder(
          itemCount: languages.values.length,
          itemBuilder: (BuildContext context, int index) {
            final item = languages.values.elementAt(index);
            final code = languages.keys.elementAt(index);

            final isCurrent = settingsStore.languageCode == null
                ? false
                : code == settingsStore.languageCode;

            return Column(
              children: <Widget>[
                index == 0 ? longDivider : Offstage(),
                Container(
                  padding: EdgeInsets.only(top: 4, bottom: 4),
                  color: PaletteDark.menuList,
                  child: ListTile(
                    contentPadding: EdgeInsets.only(left: 24, right: 24),
                    title: Text(
                      item,
                      style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? currentColor : notCurrentColor
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.done, color: currentColor)
                        : Offstage(),
                    onTap: () async {
                      if (!isCurrent) {
                        await showDialog<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertWithTwoActions(
                                  alertTitle: S.of(context).change_language,
                                  alertContent: S.of(context).change_language_to(item),
                                  leftButtonText: S.of(context).change,
                                  rightButtonText: S.of(context).cancel,
                                  actionLeftButton: () {
                                    settingsStore.saveLanguageCode(
                                        languageCode: code);
                                    currentLanguage.setCurrentLanguage(code);
                                    Navigator.of(context).pop();
                                  },
                                  actionRightButton: () => Navigator.of(context).pop()
                              );
                            });
                      }
                    },
                  ),
                ),
                item == languages.values.last
                    ? longDivider
                    : shortDivider
              ],
            );
          },
        )
    );
  }
}
