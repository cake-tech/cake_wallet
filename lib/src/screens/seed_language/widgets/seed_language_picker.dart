import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';
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
  'Spanish'
];

enum Places { topLeft, topRight, bottomLeft, bottomRight, inside }

class SeedLanguagePicker extends StatefulWidget {
  SeedLanguagePicker({Key key, this.selected = defaultSeedLanguage})
      : super(key: key);

  final String selected;

  @override
  SeedLanguagePickerState createState() =>
      SeedLanguagePickerState(selected: selected);
}

class SeedLanguagePickerState extends State<SeedLanguagePicker> {
  SeedLanguagePickerState({this.selected});

  String selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            decoration: BoxDecoration(
                color: PaletteDark.darkNightBlue.withOpacity(0.75)),
            child: Center(
              child: Column(
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
                          decoration: TextDecoration.none,
                          color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: GestureDetector(
                      onTap: () => null,
                      child: Container(
                        height: 300,
                        width: 300,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                            color: Theme.of(context).dividerColor),
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                          children: List.generate(9, (index) {
                            if (index == 8) {
                              return gridTile(
                                  isCurrent: false,
                                  place: Places.bottomRight,
                                  image: null,
                                  text: '',
                                  onTap: null);
                            } else {
                              final code = languageCodes[index];
                              final flag = flagImages[index];
                              final isCurrent =
                                  index == seedLanguages.indexOf(selected);

                              if (index == 0) {
                                return gridTile(
                                    isCurrent: isCurrent,
                                    place: Places.topLeft,
                                    image: flag,
                                    text: code,
                                    onTap: () {
                                      selected = seedLanguages[index];
                                      Navigator.of(context).pop(selected);
                                    });
                              }

                              if (index == 2) {
                                return gridTile(
                                    isCurrent: isCurrent,
                                    place: Places.topRight,
                                    image: flag,
                                    text: code,
                                    onTap: () {
                                      selected = seedLanguages[index];
                                      Navigator.of(context).pop(selected);
                                    });
                              }

                              if (index == 6) {
                                return gridTile(
                                    isCurrent: isCurrent,
                                    place: Places.bottomLeft,
                                    image: flag,
                                    text: code,
                                    onTap: () {
                                      selected = seedLanguages[index];
                                      Navigator.of(context).pop(selected);
                                    });
                              }

                              return gridTile(
                                  isCurrent: isCurrent,
                                  place: Places.inside,
                                  image: flag,
                                  text: code,
                                  onTap: () {
                                    selected = seedLanguages[index];
                                    Navigator.of(context).pop(selected);
                                  });
                            }
                          }),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget gridTile(
      {@required bool isCurrent,
      @required Places place,
      @required Image image,
      @required String text,
      @required VoidCallback onTap}) {
    BorderRadius borderRadius;
    final color = isCurrent
        ? Theme.of(context).accentTextTheme.subtitle.decorationColor
        : Theme.of(context).primaryTextTheme.display1.color;
    final textColor = isCurrent
        ? Colors.blue
        : Theme.of(context).primaryTextTheme.title.color;

    switch (place) {
      case Places.topLeft:
        borderRadius = BorderRadius.only(topLeft: Radius.circular(14));
        break;
      case Places.topRight:
        borderRadius = BorderRadius.only(topRight: Radius.circular(14));
        break;
      case Places.bottomLeft:
        borderRadius = BorderRadius.only(bottomLeft: Radius.circular(14));
        break;
      case Places.bottomRight:
        borderRadius = BorderRadius.only(bottomRight: Radius.circular(14));
        break;
      case Places.inside:
        borderRadius = BorderRadius.all(Radius.circular(0));
        break;
    }

    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: borderRadius, color: color),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                image != null ? image : Offstage(),
                Padding(
                  padding: image != null
                      ? EdgeInsets.only(left: 10)
                      : EdgeInsets.only(left: 0),
                  child: Text(
                    text,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
