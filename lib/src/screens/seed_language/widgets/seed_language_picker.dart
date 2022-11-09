import 'dart:ui';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';

List<Image> flagImages = [
  Image.asset('assets/images/usa.png'),
  Image.asset('assets/images/china.png'),
  Image.asset('assets/images/holland.png'),
  Image.asset('assets/images/germany.png'),
  Image.asset('assets/images/japan.png'),
  Image.asset('assets/images/portugal.png'),
  Image.asset('assets/images/russia.png'),
  Image.asset('assets/images/spain.png'),
  Image.asset('assets/images/france.png'),
  Image.asset('assets/images/italy.png'),
];

const List<String> languageCodes = [
  'Eng',
  'Chi',
  'Ned',
  'Ger',
  'Jap',
  'Por',
  'Rus',
  'Esp',
  'Fre',
  'Ita',
];

const defaultSeedLanguage = 'English';

const List<String> seedLanguages = [
  defaultSeedLanguage,
  'Chinese (simplified)',
  'Dutch',
  'German',
  'Japanese',
  'Portuguese',
  'Russian',
  'Spanish',
  'French',
  'Italian',
];

enum Places { topLeft, topRight, bottomLeft, bottomRight, inside }

class SeedLanguagePicker extends StatefulWidget {
  SeedLanguagePicker({
    Key? key,
    this.selected = defaultSeedLanguage})
      : super(key: key);

  final String selected;

  @override
  SeedLanguagePickerState createState() =>
      SeedLanguagePickerState(selected: selected);
}

class SeedLanguagePickerState extends State<SeedLanguagePicker> {
  SeedLanguagePickerState({required this.selected});

  final closeButton = Image.asset('assets/images/close.png');
  String selected;

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
        child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 24, right: 24),
              child: Text(
                S.of(context).seed_choose,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                    decoration: TextDecoration.none,
                    color: Colors.white),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                child: Container(
                  height: 300,
                  width: 300,
                  color:
                      Theme.of(context).accentTextTheme!.headline6!.backgroundColor!,
                  child: GridView.count(
                    padding: EdgeInsets.all(0),
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    childAspectRatio: 4 / 3,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                    children: List.generate(11, (index) {
                      if (index == 10) {
                        return gridTile(
                            isCurrent: false,
                            image: null,
                            text: '',
                            onTap: () {});
                      }

                      final code = languageCodes[index];
                      final flag = flagImages[index];
                      final isCurrent =
                          index == seedLanguages.indexOf(selected);

                      return gridTile(
                          isCurrent: isCurrent,
                          image: flag,
                          text: code,
                          onTap: () {
                            selected = seedLanguages[index];
                            Navigator.of(context).pop(selected);
                          });
                    }),
                  ),
                ),
              ),
            )
          ],
        ),
        AlertCloseButton(image: closeButton)
      ],
    ));
  }

  Widget gridTile(
      {required bool isCurrent,
      required String text,
      required VoidCallback onTap,
      Image? image}) {
    final color = isCurrent
        ? Theme.of(context).textTheme!.bodyText1!.color!
        : Theme.of(context).accentTextTheme!.headline6!.color!;
    final textColor = isCurrent
        ? Palette.blueCraiola
        : Theme.of(context).primaryTextTheme!.headline6!.color!;

    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(10),
          color: color,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                image ?? Offstage(),
                Padding(
                  padding: image != null
                      ? EdgeInsets.only(left: 10)
                      : EdgeInsets.only(left: 0),
                  child: Text(
                    text,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                        decoration: TextDecoration.none,
                        color: textColor),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
