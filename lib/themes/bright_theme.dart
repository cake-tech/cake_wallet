import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class BrightTheme extends ThemeBase {
  BrightTheme({@required int raw}) : super(raw: raw);

  @override
  String get title => S.current.bright_theme;

  @override
  ThemeType get type => ThemeType.bright;

  @override
  ThemeData get themeData => ThemeData(
      fontFamily: 'Lato',
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
              //decorationColor: Palette.blueCraiola // background of current tile (receive page)
              decorationColor: Palette.moderateSlateBlue // background of current tile (receive page)
          ),
          display4: TextStyle(
              color: Palette.violetBlue, // text color of tiles (account list)
              decorationColor: Colors.white // background of tiles (account list)
          ),
          subtitle: TextStyle(
              color: Palette.moderateSlateBlue, // text color of current tile (account list)
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
            decorationColor: Colors.white.withOpacity(0.5), // placeholder
          ),
          subhead: TextStyle(
              color: Palette.blueCraiola, // first gradient color (send page)
              decorationColor: Palette.pinkFlamingo // second gradient color (send page)
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
              decorationColor: Palette.shadowWhite // template dotted border (send page)
          ),
          display3: TextStyle(
              color: Palette.darkBlueCraiola, // template new text (send page)
              backgroundColor: PaletteDark.darkNightBlue, // active dot color for indicator on send page
              decorationColor: Palette.shadowWhite // template background color (send page)
          ),
          display4: TextStyle(
              color: Palette.darkBlueCraiola, // template title (send page)
              backgroundColor: Colors.white, // icon color on order row (moonpay)
              decorationColor: Palette.niagara // receive amount text (exchange page)
          ),
          subtitle: TextStyle(
              color: Palette.blueCraiola, // first gradient color top panel (exchange page)
              decorationColor: Palette.pinkFlamingo // second gradient color top panel (exchange page)
          ),
          body1: TextStyle(
              color: Palette.blueCraiola.withOpacity(0.7), // first gradient color bottom panel (exchange page)
              decorationColor: Palette.pinkFlamingo.withOpacity(0.7), // second gradient color bottom panel (exchange page)
              backgroundColor: Palette.moderateSlateBlue // alert right button text
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
          color: Palette.moderateLavender, // container (confirm exchange)
          backgroundColor: Palette.moderateLavender, // button background (confirm exchange)
          decorationColor: Palette.darkBlueCraiola, // text color (information page)
        ),
        subtitle: TextStyle(
            color: Palette.darkBlueCraiola, // QR code (exchange trade page)
            backgroundColor: Palette.wildPeriwinkle, // divider (exchange trade page)
            //decorationColor: Palette.blueCraiola // crete new wallet button background (wallet list page)
            decorationColor: Palette.moderateSlateBlue // crete new wallet button background (wallet list page)
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
            decorationColor: Palette.pinkFlamingo, // second gradient color(menu header)
            backgroundColor: Colors.white // active dot color
        ),
        display2: TextStyle(
            color: Palette.shadowWhite, // action button color (address text field)
            decorationColor: Palette.darkGray, // hint text (seed widget)
            backgroundColor: Colors.white.withOpacity(0.5) // text on balance page
        ),
        display3: TextStyle(
            color: Palette.darkGray, // hint text (new wallet page)
            decorationColor: Palette.periwinkleCraiola, // underline (new wallet page)
            backgroundColor: Colors.white // menu, icons, balance (dashboard page)
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
            color: Palette.moderateSlateBlue, // primary buttons
            decorationColor: Colors.white, // alert left button,
            backgroundColor: Palette.dullGray // keyboard bar color
        ),
      ),
      cardColor: Palette.moderateSlateBlue // bottom button (action list)
  );
}