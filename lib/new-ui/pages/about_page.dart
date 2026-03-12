import 'dart:math';

import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

// written by people who happened to read my slack message in 2025
// whoever works on this codebase in the future, feel free to add your own mark here
const List<String> aboutPageEasterEggs = [
  "Designed in (S)pain",
  "Proudly managing over 🤷‍♂️ XMR",
  "The cake is not a lie 🍰",
  "I don’t play soccer because I enjoy the sport. I’m just doing it for kicks.",
  "Markets in red? Big deal.\nWhat color is the grass outside?",
  "Conquered Web3, now working on Web6-7",
  "Proud owner of none of your funds\n(we are not impressed)",
  "*writing down my seedphrase*\ncake cake cake cake cake cake cake ca...",
  "Don't forget to actually use your crypto to pay for stuff in the real world 🙂",
  "A chain of blocks? That's preposterous!",
  "IOU a hug <3",
  "Warning: up to 4.8% programmed by cats",
  "We love collecting your data <3\nWe're just really incompetent at it"
];

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, required this.appVersion});

  final String appVersion;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const int easterEggTreshold = 5;
  String _bottomText = S.current.payment_made_easy;
  int _easterEggCounter = 0;

  void _easterEgg() {
    _easterEggCounter++;
    if(_easterEggCounter == easterEggTreshold) {
      setState(() {
        _bottomText = aboutPageEasterEggs.elementAt(Random().nextInt(aboutPageEasterEggs.length));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(children: [
          ModalTopBar(
            title: S.of(context).about,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Column(
            children: [
              Column(
                spacing: 16,
                children: [
                  SizedBox(),
                  GestureDetector(
                    onTap: _easterEgg,
                    child: SvgPicture.asset(
                      "assets/new-ui/cake_squircle_icon.svg",
                      width: 128,
                      height: 128,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        "Cake Wallet",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
                      ),
                      Text(widget.appVersion,
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurfaceVariant))
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Wrap(
                      children: [
                        Text(
                          _bottomText,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: NewListSections(sections: {
                  "": [
                    ListItemRegularRow(
                        keyValue: "official website",
                        label: "Official Website",
                        onTap: () => launchUrl(Uri.https("cakewallet.com")),
                        trailingIconPath: "assets/new-ui/link_arrow.svg",
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        trailingIconSize: 10),
                    ListItemRegularRow(
                        keyValue: "docs",
                        label: "Cake Docs",
                        onTap: () => launchUrl(Uri.https("docs.cakewallet.com")),
                        trailingIconPath: "assets/new-ui/link_arrow.svg",
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        trailingIconSize: 10)
                  ],
                  "2": [
                    ListItemRegularRow(
                        keyValue: "gh",
                        label: "GitHub",
                        onTap: () => launchUrl(Uri.https("github.com", "cake-tech")),
                        trailingIconPath: "assets/new-ui/link_arrow.svg",
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        trailingIconSize: 10),
                    ListItemRegularRow(
                        keyValue: "twitter",
                        label: "X (Twitter)",
                        onTap: () => launchUrl(Uri.https("twitter.com", "cakewallet")),
                        trailingIconPath: "assets/new-ui/link_arrow.svg",
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        trailingIconSize: 10),
                    ListItemRegularRow(
                        keyValue: "tg",
                        label: "Telegram",
                        onTap: () => launchUrl(Uri.https("t.me", "cakewallet")),
                        trailingIconPath: "assets/new-ui/link_arrow.svg",
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        trailingIconSize: 10)
                  ]
                }),
              )
            ],
          )
        ]));
  }
}
