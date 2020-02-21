import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/language.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

const Map<String, String> _languages = {
  'en': 'English',
  'uk': 'Українська (Ukrainian)',
  'ru': 'Русский (Russian)',
  'es': 'Español (Spanish)',
  'ja': '日本 (Japanese)',
  'ko': '한국어 (Korean)',
  'hi': 'हिंदी (Hindi)',
  'de': 'Deutsch (German)',
  'zh': '中文 (Chinese)',
  'pt': 'Português (Portuguese)',
  'pl': 'Polski (Polish)',
  'nl': 'Nederlands (Dutch)'
};

class ChangeLanguage extends BasePage {
  @override
  String get title => S.current.settings_change_language;

  @override
  Widget body(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);
    final currentLanguage = Provider.of<Language>(context);

    final currentColor = Theme.of(context).selectedRowColor;
    final notCurrentColor = Theme.of(context).accentTextTheme.subhead.backgroundColor;

    return Container(
        padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
        child: ListView.builder(
          itemCount: _languages.values.length,
          itemBuilder: (BuildContext context, int index) {
            final isCurrent = settingsStore.languageCode == null
                ? false
                : _languages.keys.elementAt(index) ==
                    settingsStore.languageCode;

            return Container(
              margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
              color: isCurrent ? currentColor : notCurrentColor,
              child: ListTile(
                title: Text(
                  _languages.values.elementAt(index),
                  style: TextStyle(
                      fontSize: 16.0,
                      color: Theme.of(context).primaryTextTheme.title.color),
                ),
                onTap: () async {
                  if (!isCurrent) {
                    await showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              S.of(context).change_language,
                              textAlign: TextAlign.center,
                            ),
                            content: Text(
                              S.of(context).change_language_to(
                                  _languages.values.elementAt(index)),
                              textAlign: TextAlign.center,
                            ),
                            actions: <Widget>[
                              FlatButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(S.of(context).cancel)),
                              FlatButton(
                                  onPressed: () {
                                    settingsStore.saveLanguageCode(
                                        languageCode:
                                            _languages.keys.elementAt(index));
                                    currentLanguage.setCurrentLanguage(
                                        _languages.keys.elementAt(index));
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(S.of(context).change)),
                            ],
                          );
                        });
                  }
                },
              ),
            );
          },
        ));
  }
}
