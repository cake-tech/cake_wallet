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

List<String> languageCodes = [
  'Eng',
  'Chi',
  'Ned',
  'Ger',
  'Jap',
  'Por',
  'Rus',
  'Esp',
];

enum Places {topLeft, topRight, bottomLeft, bottomRight, inside}

class SeedLanguagePicker extends StatefulWidget {
  @override
  SeedLanguagePickerState createState() => SeedLanguagePickerState();
}

class SeedLanguagePickerState extends State<SeedLanguagePicker> {

  @override
  Widget build(BuildContext context) {
    final seedLanguageStore = Provider.of<SeedLanguageStore>(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            decoration: BoxDecoration(color: PaletteDark.historyPanel.withOpacity(0.75)),
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
                          color: Colors.white
                      ),
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
                          color: PaletteDark.walletCardSubAddressField
                        ),
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
                              final isCurrent = index == seedLanguages.indexOf(seedLanguageStore.selectedSeedLanguage);

                              if (index == 0) {
                                return gridTile(
                                  isCurrent: isCurrent,
                                  place: Places.topLeft,
                                  image: flag,
                                  text: code,
                                  onTap: () {
                                    seedLanguageStore.setSelectedSeedLanguage(seedLanguages[index]);
                                    Navigator.of(context).pop();
                                  }
                                );
                              }

                              if (index == 2) {
                                return gridTile(
                                  isCurrent: isCurrent,
                                  place: Places.topRight,
                                  image: flag,
                                  text: code,
                                  onTap: () {
                                    seedLanguageStore.setSelectedSeedLanguage(seedLanguages[index]);
                                    Navigator.of(context).pop();
                                  }
                                );
                              }

                              if (index == 6) {
                                return gridTile(
                                  isCurrent: isCurrent,
                                  place: Places.bottomLeft,
                                  image: flag,
                                  text: code,
                                  onTap: () {
                                    seedLanguageStore.setSelectedSeedLanguage(seedLanguages[index]);
                                    Navigator.of(context).pop();
                                  }
                                );
                              }

                              return gridTile(
                                isCurrent: isCurrent,
                                place: Places.inside,
                                image: flag,
                                text: code,
                                onTap: () {
                                  seedLanguageStore.setSelectedSeedLanguage(seedLanguages[index]);
                                  Navigator.of(context).pop();
                                }
                              );
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

  Widget gridTile({
    @required bool isCurrent,
    @required Places place,
    @required Image image,
    @required String text,
    @required VoidCallback onTap}) {

    BorderRadius borderRadius;
    final color = isCurrent ? PaletteDark.historyPanel : PaletteDark.menuList;
    final textColor = isCurrent ? Colors.blue : Colors.white;

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
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: color
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              image != null
              ? image
              : Offstage(),
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
                    color: textColor
                  ),
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}