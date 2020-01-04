import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class FaqPage extends BasePage {
  String get title => S.current.faq;

  @override
  Widget body(BuildContext context) {

    return FutureBuilder(
      builder: (context, snapshot) {
        var faqItems = json.decode(snapshot.data.toString());

        return ListView.separated(
          itemBuilder: (BuildContext context, int index) {
            final itemTitle = faqItems[index]["question"];
            final itemChild = faqItems[index]["answer"];

            return ExpansionTile(
              title: Text(
                  itemTitle
              ),
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                        child: Container(
                          padding: EdgeInsets.only(
                              left: 15.0,
                              right: 15.0
                          ),
                          child: Text(
                            itemChild,
                          ),
                        )
                    )
                  ],
                )
              ],
            );
          },
          separatorBuilder: (_, __) => Divider(
            color: Theme.of(context).dividerTheme.color,
            height: 1.0,
          ),
          itemCount: faqItems == null ? 0 : faqItems.length,
        );
      },
      future: rootBundle.loadString(getFaqPath(context)),
    );
  }

  String getFaqPath(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);

    switch (settingsStore.languageCode) {
      case 'en':
        return 'assets/faq/faq_en.json';
      case 'ru':
        return 'assets/faq/faq_ru.json';
      case 'es':
        return 'assets/faq/faq_es.json';
      case 'ja':
        return 'assets/faq/faq_ja.json';
      case 'ko':
        return 'assets/faq/faq_ko.json';
      case 'hi':
        return 'assets/faq/faq_hi.json';
      case 'de':
        return 'assets/faq/faq_de.json';
      case 'zh':
        return 'assets/faq/faq_zh.json';
      case 'pt':
        return 'assets/faq/faq_pt.json';
      case 'pl':
        return 'assets/faq/faq_pl.json';
      case 'nl':
        return 'assets/faq/faq_nl.json';
      default:
        return 'assets/faq/faq_en.json';
    }
  }

}