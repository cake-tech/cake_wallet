import 'package:flutter/material.dart';
import 'palette.dart';

class Themes {

  static final ThemeData lightTheme = ThemeData(
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    backgroundColor: Colors.white,
    accentColor: Palette.blueCraiola, // first gradient color
    scaffoldBackgroundColor: Palette.pinkFlamingo, // second gradient color
    primaryColor: Palette.redHat, // third gradient color
    buttonColor: Colors.white.withOpacity(0.2), // action buttons on dashboard page
    indicatorColor: Colors.white.withOpacity(0.5), // page indicator
    hoverColor: Colors.white, // amount hint text (receive page)
    dividerColor: Palette.paleBlue,
    hintColor: Palette.gray,
    textTheme: TextTheme(
      title: TextStyle(
        color: Colors.white, // sync_indicator text
        backgroundColor: Colors.white.withOpacity(0.2), // synced sync_indicator
        decorationColor: Colors.white.withOpacity(0.15), // not synced sync_indicator
      ),
      caption: TextStyle(
        color: Palette.shineOrange, // not synced light
        decorationColor: Colors.white, // filter icon
      ),
      overline: TextStyle(
        color: Colors.white.withOpacity(0.2), // filter button
        backgroundColor: Colors.white.withOpacity(0.5), // date section row
        decorationColor: Colors.white.withOpacity(0.2) // icons (transaction and trade rows)
      ),
      subhead: TextStyle(
        color: Colors.white.withOpacity(0.2), // address button border
        decorationColor: Colors.white.withOpacity(0.4), // copy button (qr widget)
      ),
      headline: TextStyle(
        color: Colors.white, // qr code
        decorationColor: Colors.white.withOpacity(0.5), // bottom border of amount (receive page)
      ),
      display1: TextStyle(
        color: PaletteDark.lightBlueGrey, // icons color (receive page)
        decorationColor: Palette.lavender, // icons background (receive page)
      ),
      display2: TextStyle(
        color: Palette.darkBlueCraiola, // text color of tiles (receive page)
        decorationColor: Colors.white // background of tiles (receive page)
      ),
      display3: TextStyle(
        color: Colors.white, // text color of current tile (receive page),
        decorationColor: Palette.blueCraiola // background of current tile (receive page)
      ),
      display4: TextStyle(
        color: Palette.violetBlue, // text color of tiles (account list)
        decorationColor: Colors.white // background of tiles (account list)
      ),
      subtitle: TextStyle(
        color: Colors.white, // text color of current tile (account list)
        decorationColor: Palette.blueCraiola // background of current tile (account list)
      ),
      body1: TextStyle(
        color: Palette.moderatePurpleBlue, // scrollbar thumb
        decorationColor: Palette.periwinkleCraiola // scrollbar background
      ),
      body2: TextStyle(
        color: Palette.moderateLavender, // menu header
        decorationColor: Colors.white, // menu background
      )
    ),
    primaryTextTheme: TextTheme(
      title: TextStyle(
        color: Palette.darkBlueCraiola, // title color
        backgroundColor: Palette.wildPeriwinkle // textfield underline
      ),
      caption: TextStyle(
        color: PaletteDark.pigeonBlue, // secondary text
        decorationColor: Palette.wildLavender // menu divider
      ),
      overline: TextStyle(
        color: Palette.darkGray, // transaction/trade details titles
        decorationColor: Colors.white.withOpacity(0.5), // placeholder
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
    ),



    focusColor: Colors.white, // wallet card border

    cardColor: Palette.blueAlice,
    cardTheme: CardTheme(
      color: Colors.white, // synced card start
    ),


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
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    backgroundColor: PaletteDark.backgroundColor,
    accentColor: PaletteDark.backgroundColor, // first gradient color
    scaffoldBackgroundColor: PaletteDark.backgroundColor, // second gradient color
    primaryColor: PaletteDark.backgroundColor, // third gradient color
    buttonColor: PaletteDark.nightBlue, // action buttons on dashboard page
    indicatorColor: PaletteDark.cyanBlue, // page indicator
    hoverColor: PaletteDark.cyanBlue, // amount hint text (receive page)
    dividerColor: PaletteDark.dividerColor,
    hintColor: PaletteDark.pigeonBlue, // menu
    textTheme: TextTheme(
      title: TextStyle(
        color: PaletteDark.wildBlue, // sync_indicator text
        backgroundColor: PaletteDark.lightNightBlue, // synced sync_indicator
        decorationColor: PaletteDark.oceanBlue // not synced sync_indicator
      ),
      caption: TextStyle(
        color: PaletteDark.orangeYellow, // not synced light
        decorationColor: PaletteDark.wildBlue, // filter icon
      ),
      overline: TextStyle(
        color: PaletteDark.oceanBlue, // filter button
        backgroundColor: PaletteDark.darkCyanBlue, // date section row
        decorationColor: PaletteDark.wildNightBlue // icons (transaction and trade rows)
      ),
      subhead: TextStyle(
        color: PaletteDark.nightBlue, // address button border
        decorationColor: PaletteDark.lightBlueGrey, // copy button (qr widget)
      ),
      headline: TextStyle(
        color: PaletteDark.lightBlueGrey, // qr code
        decorationColor: PaletteDark.darkGrey, // bottom border of amount (receive page)
      ),
      display1: TextStyle(
        color: Colors.white, // icons color (receive page)
        decorationColor: PaletteDark.distantNightBlue, // icons background (receive page)
      ),
      display2: TextStyle(
        color: Colors.white, // text color of tiles (receive page)
        decorationColor: PaletteDark.nightBlue // background of tiles (receive page)
      ),
      display3: TextStyle(
        color: Colors.blue, // text color of current tile (receive page)
        decorationColor: PaletteDark.lightOceanBlue // background of current tile (receive page)
      ),
      display4: TextStyle(
        color: Colors.white, // text color of tiles (account list)
        decorationColor: PaletteDark.darkOceanBlue // background of tiles (account list)
      ),
      subtitle: TextStyle(
        color: Palette.blueCraiola, // text color of current tile (account list)
        decorationColor: PaletteDark.darkNightBlue // background of current tile (account list)
      ),
      body1: TextStyle(
        color: PaletteDark.wildBlueGrey, // scrollbar thumb
        decorationColor: PaletteDark.violetBlue // scrollbar background
      ),
      body2: TextStyle(
        color: PaletteDark.deepPurpleBlue, // menu header
        decorationColor: PaletteDark.deepPurpleBlue, // menu background
      )
    ),
    primaryTextTheme: TextTheme(
      title: TextStyle(
        color: Colors.white, // title color
        backgroundColor: PaletteDark.darkOceanBlue // textfield underline
      ),
      caption: TextStyle(
        color: PaletteDark.darkCyanBlue, // secondary text
        decorationColor: PaletteDark.darkOceanBlue // menu divider
      ),
      overline: TextStyle(
        color: PaletteDark.lightBlueGrey, // transaction/trade details titles
        decorationColor: Colors.grey, // placeholder
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
    ),



    focusColor: PaletteDark.lightDistantBlue, // wallet card border
    cardColor: PaletteDark.darkNightBlue,
    cardTheme: CardTheme(
      color: PaletteDark.moderateBlue, // synced card start
    ),



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