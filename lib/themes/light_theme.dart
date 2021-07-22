import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class LightTheme extends ThemeBase {
  LightTheme({@required int raw}) : super(raw: raw);

  @override
  String get title => S.current.light_theme;

  @override
  ThemeType get type => ThemeType.light;

  @override
  ThemeData get themeData => ThemeData(
      fontFamily: 'Lato',
      brightness: Brightness.light,
      backgroundColor: Colors.white,
      accentColor: Colors.white, // first gradient color
      scaffoldBackgroundColor: Colors.white, // second gradient color
      primaryColor: Colors.white, // third gradient color
      buttonColor: Palette.blueAlice, // action buttons on dashboard page
      indicatorColor: PaletteDark.darkCyanBlue.withOpacity(0.67), // page indicator
      hoverColor: Palette.darkBlueCraiola, // amount hint text (receive page)
      dividerColor: Palette.paleBlue,
      hintColor: Palette.gray,
      textTheme: TextTheme(
          title: TextStyle(
            color: Palette.darkBlueCraiola, // sync_indicator text
            backgroundColor: Palette.blueAlice, // synced sync_indicator
            decorationColor: Palette.blueAlice.withOpacity(0.75), // not synced sync_indicator
          ),
          caption: TextStyle(
            color: Palette.shineOrange, // not synced light
            decorationColor: PaletteDark.wildBlue, // filter icon
          ),
          overline: TextStyle(
              color: Palette.blueAlice, // filter button
              backgroundColor: PaletteDark.darkCyanBlue, // date section row
              decorationColor: Palette.blueAlice // icons (transaction and trade rows)
          ),
          subhead: TextStyle(
            color: Palette.blueAlice, // address button border
            decorationColor: PaletteDark.lightBlueGrey, // copy button (qr widget)
          ),
          headline: TextStyle(
            color: Colors.white, // qr code
            decorationColor: Palette.darkBlueCraiola, // bottom border of amount (receive page)
          ),
          display1: TextStyle(
            color: PaletteDark.lightBlueGrey, // icons color (receive page)
            decorationColor: Palette.moderateLavender, // icons background (receive page)
          ),
          display2: TextStyle(
              color: Palette.darkBlueCraiola, // text color of tiles (receive page)
              decorationColor: Palette.blueAlice // background of tiles (receive page)
          ),
          display3: TextStyle(
              color: Colors.white, // text color of current tile (receive page),
              //decorationColor: Palette.blueCraiola // background of current tile (receive page)
              decorationColor: Palette.blueCraiola // background of current tile (receive page)
          ),
          display4: TextStyle(
              color: Palette.violetBlue, // text color of tiles (account list)
              decorationColor: Colors.white // background of tiles (account list)
          ),
          subtitle: TextStyle(
              color: Palette.protectiveBlue, // text color of current tile (account list)
              decorationColor: Colors.white // background of current tile (account list)
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
            decorationColor: PaletteDark.darkCyanBlue, // placeholder
          ),
          subhead: TextStyle(
              color: Palette.blueCraiola, // first gradient color (send page)
              decorationColor: Palette.blueGreyCraiola // second gradient color (send page)
          ),
          headline: TextStyle(
            color: Colors.white.withOpacity(0.5), // text field border color (send page)
            decorationColor: Colors.white.withOpacity(0.5), // text field hint color (send page)
          ),
          display1: TextStyle(
              color: Colors.white.withOpacity(0.2), // text field button color (send page)
              decorationColor: Colors.white // text field button icon color (send page)
          ),
          display2: TextStyle(
              color: Colors.white.withOpacity(0.5), // estimated fee (send page)
              backgroundColor: PaletteDark.darkCyanBlue.withOpacity(0.67), // dot color for indicator on send page
              decorationColor: Palette.moderateLavender // template dotted border (send page)
          ),
          display3: TextStyle(
              color: Palette.darkBlueCraiola, // template new text (send page)
              backgroundColor: PaletteDark.darkNightBlue, // active dot color for indicator on send page
              decorationColor: Palette.blueAlice // template background color (send page)
          ),
          display4: TextStyle(
              color: Palette.darkBlueCraiola, // template title (send page)
              backgroundColor: Colors.black, // icon color on order row (moonpay)
              decorationColor: Palette.niagara // receive amount text (exchange page)
          ),
          subtitle: TextStyle(
              color: Palette.blueCraiola, // first gradient color top panel (exchange page)
              decorationColor: Palette.blueGreyCraiola // second gradient color top panel (exchange page)
          ),
          body1: TextStyle(
              color: Palette.blueCraiola.withOpacity(0.7), // first gradient color bottom panel (exchange page)
              decorationColor: Palette.blueGreyCraiola.withOpacity(0.7), // second gradient color bottom panel (exchange page)
              backgroundColor: Palette.protectiveBlue // alert right button text
          ),
          body2: TextStyle(
              color: Colors.white.withOpacity(0.5), // text field border on top panel (exchange page)
              decorationColor: Colors.white.withOpacity(0.5), // text field border on bottom panel (exchange page)
              backgroundColor: Palette.brightOrange // alert left button text
          )
      ),
      focusColor: Colors.white.withOpacity(0.2), // text field button (exchange page)
      accentTextTheme: TextTheme(
        title: TextStyle(
            color: Colors.white, // picker background
            backgroundColor: Palette.periwinkleCraiola, // picker divider
            decorationColor: Colors.white // dialog background
        ),
        caption: TextStyle(
          color: Palette.blueAlice, // container (confirm exchange)
          backgroundColor: Palette.blueAlice, // button background (confirm exchange)
          decorationColor: Palette.darkBlueCraiola, // text color (information page)
        ),
        subtitle: TextStyle(
            color: Palette.darkBlueCraiola, // QR code (exchange trade page)
            backgroundColor: Palette.wildPeriwinkle, // divider (exchange trade page)
            decorationColor: Palette.protectiveBlue // crete new wallet button background (wallet list page)
        ),
        headline: TextStyle(
            color: Palette.moderateLavender, // first gradient color of wallet action buttons (wallet list page)
            backgroundColor: Palette.moderateLavender, // second gradient color of wallet action buttons (wallet list page)
            decorationColor: Colors.white // restore wallet button text color (wallet list page)
        ),
        subhead: TextStyle(
            color: Palette.darkGray, // titles color (filter widget)
            backgroundColor: Palette.periwinkle, // divider color (filter widget)
            decorationColor: Colors.white // checkbox background (filter widget)
        ),
        overline: TextStyle(
          color: Palette.wildPeriwinkle, // checkbox bounds (filter widget)
          decorationColor: Colors.white, // menu subname
        ),
        display1: TextStyle(
            color: Palette.blueCraiola, // first gradient color (menu header)
            decorationColor: Palette.blueGreyCraiola, // second gradient color(menu header)
            backgroundColor: PaletteDark.darkNightBlue // active dot color
        ),
        display2: TextStyle(
            color: Palette.shadowWhite, // action button color (address text field)
            decorationColor: Palette.darkGray, // hint text (seed widget)
            backgroundColor: Palette.darkBlueCraiola.withOpacity(0.67) // text on balance page
        ),
        display3: TextStyle(
            color: Palette.darkGray, // hint text (new wallet page)
            decorationColor: Palette.periwinkleCraiola, // underline (new wallet page)
            backgroundColor: Palette.darkBlueCraiola // menu, icons, balance (dashboard page)
        ),
        display4: TextStyle(
            color: Palette.darkGray, // switch background (settings page)
            backgroundColor: Colors.black, // icon color on support page (moonpay, github)
            decorationColor: Colors.white.withOpacity(0.4) // hint text (exchange page)
        ),
        body1: TextStyle(
            color: Palette.darkGray, // indicators (PIN code)
            decorationColor: Palette.darkGray, // switch (PIN code)
            backgroundColor: Colors.white // alert right button
        ),
        body2: TextStyle(
            color: Palette.protectiveBlue, // primary buttons
            decorationColor: Colors.white, // alert left button,
            backgroundColor: Palette.dullGray // keyboard bar color
        ),
      ),
      cardColor: Palette.protectiveBlue // bottom button (action list)
  );
}