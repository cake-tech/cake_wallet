import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/faq/faq_item.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/store/settings_store.dart';

class FaqPage extends BasePage {
  FaqPage(this.settingsStore);

  final SettingsStore settingsStore;

  @override
  String get title => S.current.faq;

  String get path => 'assets/faq/faq_' + settingsStore.languageCode + '.json';

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 12, left: 24),
      child: FutureBuilder(
        builder: (context, snapshot) {
          final faqItems = jsonDecode(snapshot.data.toString()) as List;

          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                StandardListSeparator(),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final title = faqItems[index]["question"].toString();
                    final text = faqItems[index]["answer"].toString();

                    return FAQItem(title, text);
                  },
                  separatorBuilder: (_, __) => StandardListSeparator(),
                  itemCount: faqItems?.length ?? 0,
                )
              ],
            ),
          );
        },
        future: rootBundle.loadString(path),
      ),
    );
  }
}
