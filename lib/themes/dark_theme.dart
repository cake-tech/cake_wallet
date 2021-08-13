import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class DarkTheme extends ThemeBase {
  DarkTheme({@required int raw}) : super(raw: raw);

  @override
  String get title => S.current.dark_theme;

  @override
  ThemeType get type => ThemeType.dark;

  @override
  ThemeData get themeData => ThemeData(
      fontFamily: 'Lato',
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
              color: Palette.blueCraiola, // text color of current tile (receive page)
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
              color: PaletteDark.darkNightBlue, // first gradient color (send page)
              decorationColor: PaletteDark.darkNightBlue // second gradient color (send page)
          ),
          headline: TextStyle(
            color: PaletteDark.lightVioletBlue, // text field border color (send page)
            decorationColor: PaletteDark.darkCyanBlue, // text field hint color (send page)
          ),
          display1: TextStyle(
              color: PaletteDark.buttonNightBlue, // text field button color (send page)
              decorationColor: PaletteDark.gray // text field button icon color (send page)
          ),
          display2: TextStyle(
              color: Colors.white, // estimated fee (send page)
              backgroundColor: PaletteDark.cyanBlue, // dot color for indicator on send page
              decorationColor: PaletteDark.darkCyanBlue // template dotted border (send page)
          ),
          display3: TextStyle(
              color: PaletteDark.darkCyanBlue, // template new text (send page)
              backgroundColor: Colors.white, // active dot color for indicator on send page
              decorationColor: PaletteDark.darkVioletBlue // template background color (send page)
          ),
          display4: TextStyle(
              color: PaletteDark.cyanBlue, // template title (send page)
              backgroundColor: Colors.white, // icon color on order row (moonpay)
              decorationColor: PaletteDark.darkCyanBlue // receive amount text (exchange page)
          ),
          subtitle: TextStyle(
              color: PaletteDark.wildVioletBlue, // first gradient color top panel (exchange page)
              decorationColor: PaletteDark.wildVioletBlue // second gradient color top panel (exchange page)
          ),
          body1: TextStyle(
              color: PaletteDark.darkNightBlue, // first gradient color bottom panel (exchange page)
              decorationColor: PaletteDark.darkNightBlue, // second gradient color bottom panel (exchange page)
              backgroundColor: Palette.blueCraiola // alert right button text
          ),
          body2: TextStyle(
              color: PaletteDark.blueGrey, // text field border on top panel (exchange page)
              decorationColor: PaletteDark.moderateVioletBlue, // text field border on bottom panel (exchange page)
              backgroundColor: Palette.alizarinRed // alert left button text
          )
      ),
      focusColor: PaletteDark.moderateBlue, // text field button (exchange page)
      accentTextTheme: TextTheme(
        title: TextStyle(
            color: PaletteDark.nightBlue, // picker background
            backgroundColor: PaletteDark.dividerColor, // picker divider
            decorationColor: PaletteDark.darkNightBlue // dialog background
        ),
        caption: TextStyle(
          color: PaletteDark.nightBlue, // container (confirm exchange)
          backgroundColor: PaletteDark.deepVioletBlue, // button background (confirm exchange)
          decorationColor: Palette.darkLavender, // text color (information page)
        ),
        subtitle: TextStyle(
          //color: PaletteDark.lightBlueGrey, // QR code (exchange trade page)
            color: Colors.white, // QR code (exchange trade page)
            backgroundColor: PaletteDark.deepVioletBlue, // divider (exchange trade page)
            decorationColor: Colors.white // crete new wallet button background (wallet list page)
        ),
        headline: TextStyle(
            color: PaletteDark.distantBlue, // first gradient color of wallet action buttons (wallet list page)
            backgroundColor: PaletteDark.distantNightBlue, // second gradient color of wallet action buttons (wallet list page)
            decorationColor: Palette.darkBlueCraiola // restore wallet button text color (wallet list page)
        ),
        subhead: TextStyle(
            color: Colors.white, // titles color (filter widget)
            backgroundColor: PaletteDark.darkOceanBlue, // divider color (filter widget)
            decorationColor: PaletteDark.wildVioletBlue.withOpacity(0.3) // checkbox background (filter widget)
        ),
        overline: TextStyle(
          color: PaletteDark.wildVioletBlue, // checkbox bounds (filter widget)
          decorationColor: PaletteDark.darkCyanBlue, // menu subname
        ),
        display1: TextStyle(
            color: PaletteDark.deepPurpleBlue, // first gradient color (menu header)
            decorationColor: PaletteDark.deepPurpleBlue, // second gradient color(menu header)
            backgroundColor: Colors.white // active dot color
        ),
        display2: TextStyle(
            color: PaletteDark.nightBlue, // action button color (address text field)
            decorationColor: PaletteDark.darkCyanBlue, // hint text (seed widget)
            backgroundColor: PaletteDark.cyanBlue // text on balance page
        ),
        display3: TextStyle(
            color: PaletteDark.cyanBlue, // hint text (new wallet page)
            decorationColor: PaletteDark.darkGrey, // underline (new wallet page)
            backgroundColor: Colors.white // menu, icons, balance (dashboard page)
        ),
        display4: TextStyle(
            color: PaletteDark.deepVioletBlue, // switch background (settings page)
            backgroundColor: Colors.white, // icon color on support page (moonpay, github)
            decorationColor: PaletteDark.lightBlueGrey // hint text (exchange page)
        ),
        body1: TextStyle(
            color: PaletteDark.indicatorVioletBlue, // indicators (PIN code)
            decorationColor: PaletteDark.lightPurpleBlue, // switch (PIN code)
            backgroundColor: PaletteDark.darkNightBlue // alert right button
        ),
        body2: TextStyle(
            color: Palette.blueCraiola, // primary buttons
            decorationColor: PaletteDark.darkNightBlue, // alert left button
            backgroundColor: PaletteDark.granite // keyboard bar color
        ),
      ),
      cardColor: PaletteDark.darkNightBlue // bottom button (action list)
  );
}