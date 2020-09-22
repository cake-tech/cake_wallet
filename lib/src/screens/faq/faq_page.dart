import 'dart:convert';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/settings_store.dart';
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
    final removeIcon = Icon(Icons.remove, color: Palette.blueCraiola);

    return Container(
      padding: EdgeInsets.only(top: 12, left: 24),
      child: FutureBuilder(
        builder: (context, snapshot) {
          final faqItems = jsonDecode(snapshot.data.toString()) as List;

          if (snapshot.hasData) {
            setIconsAndColors(context, faqItems.length, addIcon);
          }

          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                StandardListSeparator(),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final itemTitle = faqItems[index]["question"].toString();
                    final itemChild = faqItems[index]["answer"].toString();

                    return ListTileTheme(
                      contentPadding: EdgeInsets.fromLTRB(0, 6, 24, 6),
                      child: ExpansionTile(
                        title: Text(
                          itemTitle,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colors[index]
                          ),
                        ),
                        trailing: icons[index],
                        onExpansionChanged: (value) {
                          setState(() {
                            if (value) {
                              icons[index] = removeIcon;
                              colors[index] = Palette.blueCraiola;
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
                                        right: 24.0,
                                    ),
                                    child: Text(
                                      itemChild,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          color: Theme.of(context).primaryTextTheme.title.color
                                      ),
                                    ),
                                  ))
                            ],
                          )
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) =>
                      StandardListSeparator(),
                  itemCount: faqItems == null ? 0 : faqItems.length,
                )
              ],
            ),
          );
        },
        future: rootBundle.loadString(getFaqPath(context)),
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
    // FIXME: FIXME
    // final settingsStore = Provider.of<SettingsStore>(context);
    //
    // switch (settingsStore.languageCode) {
    //   case 'en':
    //     return 'assets/faq/faq_en.json';
    //   case 'uk':
    //     return 'assets/faq/faq_uk.json';
    //   case 'ru':
    //     return 'assets/faq/faq_ru.json';
    //   case 'es':
    //     return 'assets/faq/faq_es.json';
    //   case 'ja':
    //     return 'assets/faq/faq_ja.json';
    //   case 'ko':
    //     return 'assets/faq/faq_ko.json';
    //   case 'hi':
    //     return 'assets/faq/faq_hi.json';
    //   case 'de':
    //     return 'assets/faq/faq_de.json';
    //   case 'zh':
    //     return 'assets/faq/faq_zh.json';
    //   case 'pt':
    //     return 'assets/faq/faq_pt.json';
    //   case 'pl':
    //     return 'assets/faq/faq_pl.json';
    //   case 'nl':
    //     return 'assets/faq/faq_nl.json';
    //   default:
    //     return 'assets/faq/faq_en.json';
    // }
    return '';
  }
}