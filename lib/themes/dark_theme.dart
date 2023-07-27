import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class DarkTheme extends ThemeBase {
  DarkTheme({required int raw}) : super(raw: raw);

  @override
  String get title => S.current.dark_theme;

  @override
  ThemeType get type => ThemeType.dark;

  ThemeData theme = ThemeData(
      fontFamily: 'Lato',
      brightness: Brightness.dark,
      scaffoldBackgroundColor:
          PaletteDark.backgroundColor, // second gradient color
      primaryColor: PaletteDark.backgroundColor, // third gradient color
      indicatorColor: PaletteDark.cyanBlue, // page indicator
      hoverColor: PaletteDark.cyanBlue, // amount hint text (receive page)
      dividerColor: PaletteDark.dividerColor,
      hintColor: PaletteDark.pigeonBlue, // menu
      textTheme: TextTheme(
          // title -> titleLarge
          titleLarge: TextStyle(
              color: PaletteDark.wildBlue, // sync_indicator text
              backgroundColor:
                  PaletteDark.lightNightBlue, // synced sync_indicator
              decorationColor:
                  PaletteDark.oceanBlue // not synced sync_indicator
              ),
          bodySmall: TextStyle(
            color: PaletteDark.orangeYellow, // not synced light
            decorationColor: PaletteDark.wildBlue, // filter icon
          ),
          labelSmall: TextStyle(
              color: PaletteDark.oceanBlue, // filter button
              backgroundColor: PaletteDark.darkCyanBlue, // date section row
              decorationColor: PaletteDark
                  .wildNightBlue // icons (transaction and trade rows)
              ),
          // subhead -> titleMedium
          titleMedium: TextStyle(
            color: PaletteDark.nightBlue, // address button border
            decorationColor: PaletteDark.lightBlueGrey, // copy button (qr widget)
          ),
          // headline -> headlineSmall
          headlineSmall: TextStyle(
            color: PaletteDark.lightBlueGrey, // qr code
            decorationColor: PaletteDark.darkGrey, // bottom border of amount (receive page)
          ),
          // display1 -> headlineMedium
          headlineMedium: TextStyle(
            color: Colors.white, // icons color (receive page)
            decorationColor: PaletteDark.distantNightBlue, // icons background (receive page)
          ),
          // display2 -> displaySmall
          displaySmall: TextStyle(
              color: Colors.white, // text color of tiles (receive page)
              decorationColor:
                  PaletteDark.nightBlue // background of tiles (receive page)
              ),
          // display3 -> displayMedium
          displayMedium: TextStyle(
              color: Palette
                  .blueCraiola, // text color of current tile (receive page)
              decorationColor: PaletteDark
                  .lightOceanBlue // background of current tile (receive page)
              ),
          // display4 -> displayLarge
          displayLarge: TextStyle(
              color: Colors.white, // text color of tiles (account list)
              decorationColor: PaletteDark
                  .darkOceanBlue // background of tiles (account list)
              ),
          // subtitle -> titleSmall
          titleSmall: TextStyle(
              color: Palette
                  .blueCraiola, // text color of current tile (account list)
              decorationColor: PaletteDark
                  .darkNightBlue // background of current tile (account list)
              ),
          // body1 -> bodyMedium
          bodyMedium: TextStyle(
              color: PaletteDark.wildBlueGrey, // scrollbar thumb
              decorationColor: PaletteDark.violetBlue // scrollbar background
              ),
          // body2 -> bodyLarge
          bodyLarge: TextStyle(
            color: PaletteDark.deepPurpleBlue, // menu header
            decorationColor: PaletteDark.deepPurpleBlue, // menu background
          )
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(PaletteDark.wildBlueGrey),
        trackColor: MaterialStateProperty.all(PaletteDark.violetBlue),
        radius: Radius.circular(3),
        thickness: MaterialStateProperty.all(6),
        thumbVisibility: MaterialStateProperty.all(true),
        crossAxisMargin: 6,
      ),
      primaryTextTheme: TextTheme(
          // title -> titleLarge
          titleLarge: TextStyle(
              color: Colors.white, // title color
              backgroundColor: PaletteDark.darkOceanBlue // textfield underline
              ),
          bodySmall: TextStyle(
              color: PaletteDark.darkCyanBlue, // secondary text
              decorationColor: PaletteDark.darkOceanBlue // menu divider
              ),
          labelSmall: TextStyle(
            color:
                PaletteDark.lightBlueGrey, // transaction/trade details titles
            decorationColor: Colors.grey, // placeholder
          ),
          // subhead -> titleMedium
          titleMedium: TextStyle(
              color:
                  PaletteDark.darkNightBlue, // first gradient color (send page)
              decorationColor:
                  PaletteDark.darkNightBlue // second gradient color (send page)
              ),
          // headline -> headlineSmall
          headlineSmall: TextStyle(
            color: PaletteDark
                .lightVioletBlue, // text field border color (send page)
            decorationColor:
                PaletteDark.darkCyanBlue, // text field hint color (send page)
          ),
          // display1 -> headlineMedium
          headlineMedium: TextStyle(
              color: PaletteDark
                  .buttonNightBlue, // text field button color (send page)
              decorationColor:
                  PaletteDark.gray // text field button icon color (send page)
              ),
          // display2 -> displaySmall
          displaySmall: TextStyle(
              color: Colors.white, // estimated fee (send page)
              backgroundColor:
                  PaletteDark.cyanBlue, // dot color for indicator on send page
              decorationColor:
                  PaletteDark.darkCyanBlue // template dotted border (send page)
              ),
          // display3 -> displayMedium
          displayMedium: TextStyle(
              color: PaletteDark.darkCyanBlue, // template new text (send page)
              backgroundColor:
                  Colors.white, // active dot color for indicator on send page
              decorationColor: PaletteDark
                  .darkVioletBlue // template background color (send page)
              ),
          // display4 -> displayLarge
          displayLarge: TextStyle(
              color: PaletteDark.cyanBlue, // template title (send page)
              backgroundColor:
                  Colors.white, // icon color on order row (moonpay)
              decorationColor: PaletteDark
                  .darkCyanBlue // receive amount text (exchange page)
              ),
          // subtitle -> titleSmall
          titleSmall: TextStyle(
              color: PaletteDark
                  .wildVioletBlue, // first gradient color top panel (exchange page)
              decorationColor: PaletteDark
                  .wildVioletBlue // second gradient color top panel (exchange page)
              ),
          // body1 -> bodyMedium
          bodyMedium: TextStyle(
              color: PaletteDark
                  .darkNightBlue, // first gradient color bottom panel (exchange page)
              decorationColor: PaletteDark
                  .darkNightBlue, // second gradient color bottom panel (exchange page)
              backgroundColor: Palette.blueCraiola // alert right button text
              ),
          // body2 -> bodyLarge
          bodyLarge: TextStyle(
              color: PaletteDark
                  .blueGrey, // text field border on top panel (exchange page)
              decorationColor: PaletteDark
                  .moderateVioletBlue, // text field border on bottom panel (exchange page)
              backgroundColor: Palette.alizarinRed // alert left button text
          )
      ),
      focusColor: PaletteDark.moderateBlue, // text field button (exchange page)
      accentTextTheme: TextTheme(
        // title -> titleLarge
        titleLarge: TextStyle(
            color: PaletteDark.nightBlue, // picker background
            backgroundColor: PaletteDark.dividerColor, // picker divider
            decorationColor: PaletteDark.darkNightBlue // dialog background
            ),
        bodySmall: TextStyle(
          color: PaletteDark.nightBlue, // container (confirm exchange)
          backgroundColor: PaletteDark.deepVioletBlue, // button background (confirm exchange)
          decorationColor: Palette.darkLavender, // text color (information page)
        ),
        // subtitle -> titleSmall
        titleSmall: TextStyle(
            //color: PaletteDark.lightBlueGrey, // QR code (exchange trade page)
            color: Colors.white, // QR code (exchange trade page)
            backgroundColor:
                PaletteDark.deepVioletBlue, // divider (exchange trade page)
            decorationColor: Colors
                .white // crete new wallet button background (wallet list page)
            ),
        // headline -> headlineSmall
        headlineSmall: TextStyle(
            color: PaletteDark
                .distantBlue, // first gradient color of wallet action buttons (wallet list page)
            backgroundColor: PaletteDark
                .distantNightBlue, // second gradient color of wallet action buttons (wallet list page)
            decorationColor: Palette
                .darkBlueCraiola // restore wallet button text color (wallet list page)
            ),
        // subhead -> titleMedium
        titleMedium: TextStyle(
            color: Colors.white, // titles color (filter widget)
            backgroundColor:
                PaletteDark.darkOceanBlue, // divider color (filter widget)
            decorationColor: PaletteDark.wildVioletBlue
                .withOpacity(0.3) // checkbox background (filter widget)
            ),
        labelSmall: TextStyle(
          color: PaletteDark.wildVioletBlue, // checkbox bounds (filter widget)
          decorationColor: PaletteDark.darkCyanBlue, // menu subname
        ),
        // display1 -> headlineMedium
        headlineMedium: TextStyle(
            color: PaletteDark
                .deepPurpleBlue, // first gradient color (menu header)
            decorationColor: PaletteDark
                .deepPurpleBlue, // second gradient color(menu header)
            backgroundColor: Colors.white // active dot color
            ),
        // display2 -> displaySmall
        displaySmall: TextStyle(
            color: PaletteDark
                .nightBlue, // action button color (address text field)
            decorationColor:
                PaletteDark.darkCyanBlue, // hint text (seed widget)
            backgroundColor: PaletteDark.cyanBlue // text on balance page
            ),
        // display3 -> displayMedium
        displayMedium: TextStyle(
            color: PaletteDark.cyanBlue, // hint text (new wallet page)
            decorationColor:
                PaletteDark.darkGrey, // underline (new wallet page)
            backgroundColor:
                Colors.white // menu, icons, balance (dashboard page)
            ),
        // display4 -> displayLarge
        displayLarge: TextStyle(
            color:
                PaletteDark.deepVioletBlue, // switch background (settings page)
            backgroundColor:
                Colors.white, // icon color on support page (moonpay, github)
            decorationColor:
                PaletteDark.lightBlueGrey // hint text (exchange page)
            ),
        // body1 -> bodyMedium
        bodyMedium: TextStyle(
            color: PaletteDark.indicatorVioletBlue, // indicators (PIN code)
            decorationColor: PaletteDark.lightPurpleBlue, // switch (PIN code)
            backgroundColor: PaletteDark.darkNightBlue // alert right button
            ),
        // body2 -> bodyLarge
        bodyLarge: TextStyle(
            color: Palette.blueCraiola, // primary buttons
            decorationColor: PaletteDark.darkNightBlue, // alert left button
            backgroundColor: PaletteDark.granite // keyboard bar color
        ),
      ),
      cardColor: PaletteDark.darkNightBlue // bottom button (action list)
      );

  @override
  ThemeData get themeData => theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
          background: PaletteDark.backgroundColor,
          secondary: PaletteDark.backgroundColor));
}
