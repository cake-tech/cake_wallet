import 'package:flutter/material.dart';
import 'palette.dart';

class Themes {

  static final ThemeData lightTheme = ThemeData(
    fontFamily: 'Avenir Next',
    brightness: Brightness.light,
    backgroundColor: Colors.white,
    focusColor: Colors.white, // wallet card border
    hintColor: Colors.white, // menu
    scaffoldBackgroundColor: Palette.blueAlice, // gradient background start
    primaryColor: Palette.lightBlue, // gradient background end
    cardColor: Palette.blueAlice,
    cardTheme: CardTheme(
      color: Colors.white, // synced card start
    ),
    hoverColor: Colors.white, // synced card end
    primaryTextTheme: TextTheme(
      title: TextStyle(
        color: Palette.oceanBlue, // primary text
        backgroundColor: Colors.white // selectButton text
      ),
      caption: TextStyle(
        color: Palette.lightBlueGrey, // secondary text
      ),
      overline: TextStyle(
        color: Palette.lavender // address field in the wallet card
      ),
      subhead: TextStyle(
        color: Colors.white.withOpacity(0.5) // send, exchange, buy buttons on dashboard page
      ),
      headline: TextStyle(
        color: Palette.lightBlueGrey // historyPanelText
      ),
      display1: TextStyle(
        color: Colors.white // menuList
      ),
      display2: TextStyle(
        color: Palette.lavender // menuHeader
      ),
      display3: TextStyle(
        color: Palette.lavender // historyPanelButton
      ),
      display4: TextStyle(
        color: Palette.oceanBlue // QR code
      ),
//      headline1: TextStyle(color: Palette.nightBlue)
    ),
    dividerColor: Palette.eee,
    accentTextTheme: TextTheme(
      title: TextStyle(
        color: Palette.darkLavender, // top panel
        backgroundColor: Palette.lavender, // bottom panel
        decorationColor: PaletteDark.distantBlue // select button background color
      ),
      caption: TextStyle(
        color: Palette.blue, // current wallet label
        backgroundColor: Colors.white, // gradient start, wallet label
        decorationColor: Palette.lavender, // gradient end, wallet label
      ),
      subtitle: TextStyle(
        color: Palette.lightBlueGrey, // border color,  wallet label
        backgroundColor: Palette.lavender, // address field, wallet card
        decorationColor: Palette.darkLavender // selected item
      ),
      headline: TextStyle(
        color: Palette.darkLavender, // faq background
        backgroundColor: Palette.lavender // faq extension
      )
    ),
  );


  static final ThemeData darkTheme = ThemeData(
    fontFamily: 'Avenir Next',
    brightness: Brightness.dark,
    backgroundColor: PaletteDark.darkNightBlue,
    focusColor: PaletteDark.lightDistantBlue, // wallet card border
    hintColor: PaletteDark.gray, // menu
    scaffoldBackgroundColor: PaletteDark.distantBlue, // gradient background start
    primaryColor: PaletteDark.distantBlue, // gradient background end
    cardColor: PaletteDark.darkNightBlue,
    cardTheme: CardTheme(
      color: PaletteDark.moderateBlue, // synced card start
    ),
    hoverColor: PaletteDark.nightBlue, // synced card end
    primaryTextTheme: TextTheme(
      title: TextStyle(
        color: Colors.white,
        backgroundColor: PaletteDark.moderatePurpleBlue // selectButton text
      ),
      caption: TextStyle(
        color: PaletteDark.gray,
      ),
      overline: TextStyle(
        color: PaletteDark.lightDistantBlue // address field in the wallet card
      ),
      subhead: TextStyle(
        color: PaletteDark.lightDistantBlue // send, exchange, buy buttons on dashboard page
      ),
      headline: TextStyle(
        color: PaletteDark.pigeonBlue // historyPanelText
      ),
      display1: TextStyle(
        color: PaletteDark.lightNightBlue // menuList
      ),
      display2: TextStyle(
        color: PaletteDark.headerNightBlue // menuHeader
      ),
      display3: TextStyle(
        color: PaletteDark.moderateNightBlue // historyPanelButton
      ),
      display4: TextStyle(
        color: PaletteDark.gray // QR code
      ),
//        headline5: TextStyle(color: PaletteDark.gray)
    ),
    dividerColor: PaletteDark.distantBlue,
    accentTextTheme: TextTheme(
      title: TextStyle(
        color: PaletteDark.moderateBlue, // top panel
        backgroundColor: PaletteDark.lightNightBlue, // bottom panel
        decorationColor: Colors.white // select button background color
      ),
      caption: TextStyle(
        color: Colors.white, // current wallet label
        backgroundColor: PaletteDark.distantBlue, // gradient start, wallet label
        decorationColor: PaletteDark.nightBlue, // gradient end, wallet label
      ),
      subtitle: TextStyle(
        color: PaletteDark.darkNightBlue, // border color,  wallet label
        backgroundColor: PaletteDark.violetBlue, // address field, wallet card
        decorationColor: PaletteDark.headerNightBlue // selected item
      ),
      headline: TextStyle(
        color: PaletteDark.lightNightBlue, // faq background
        backgroundColor: PaletteDark.headerNightBlue // faq extension
      )
    ),
  );

}