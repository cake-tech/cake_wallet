import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class FaqPage extends BasePage {
  @override
  String get title => S.current.faq;

  @override
  Widget body(BuildContext context) => FaqForm();
}

class FaqForm extends StatefulWidget {
  @override
  FaqFormState createState() => FaqFormState();
}

class FaqFormState extends State<FaqForm> {
  List<Icon> icons;
  List<Color> colors;
  bool isLoaded = false;

  @override
  Widget build(BuildContext context) {
    final addIcon = Icon(Icons.add, color: Theme.of(context).primaryTextTheme.title.color);
    final removeIcon = Icon(Icons.remove, color: Colors.green);

    return Container(
      padding: EdgeInsets.only(top: 12),
      child: Container(
        color: Theme.of(context).accentTextTheme.headline.color,
        child: FutureBuilder(
          builder: (context, snapshot) {
            final faqItems = jsonDecode(snapshot.data.toString()) as List;

            if (snapshot.hasData) {
              setIconsAndColors(context, faqItems.length, addIcon);
            }

            return SingleChildScrollView(
              child: ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  final itemTitle = faqItems[index]["question"].toString();
                  final itemChild = faqItems[index]["answer"].toString();

                  return ExpansionTile(
                    title: Padding(
                      padding: EdgeInsets.only(left: 8, top: 12, bottom: 12),
                      child: Text(
                        itemTitle,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors[index]
                        ),
                      ),
                    ),
                    trailing: Padding(
                      padding: EdgeInsets.only(right: 24),
                      child: Container(
                        width: double.minPositive,
                        child: Center(
                            child: icons[index]
                        ),
                      ),
                    ),
                    backgroundColor: Theme.of(context).accentTextTheme.headline.backgroundColor,
                    onExpansionChanged: (value) {
                      setState(() {
                        if (value) {
                          icons[index] = removeIcon;
                          colors[index] = Colors.green;
                        } else {
                          icons[index] = addIcon;
                          colors[index] = Theme.of(context).primaryTextTheme.title.color;
                        }
                      });
                    },
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                              child: Container(
                                padding: EdgeInsets.only(
                                    left: 24.0,
                                    right: 24.0,
                                    bottom: 8
                                ),
                                child: Text(
                                  itemChild,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryTextTheme.title.color
                                  ),
                                ),
                              ))
                        ],
                      )
                    ],
                  );
                },
                separatorBuilder: (_, __) =>
                    Container(color: Theme.of(context).dividerColor, height: 1.0),
                itemCount: faqItems == null ? 0 : faqItems.length,
              ),
            );
          },
          future: rootBundle.loadString(getFaqPath(context)),
        ),
      ),
    );
  }

  void setIconsAndColors(BuildContext context, int index, Icon icon) {
    if (isLoaded) {
      return;
    }

    icons = List.generate(index, (int i) => icon);
    colors = List.generate(index, (int i) => Theme.of(context).primaryTextTheme.title.color);

    isLoaded = true;
  }

  String getFaqPath(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);

    switch (settingsStore.languageCode) {
      case 'en':
        return 'assets/faq/faq_en.json';
      case 'uk':
        return 'assets/faq/faq_uk.json';
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