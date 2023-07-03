import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/light_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class BrightTheme extends LightTheme {
  BrightTheme({required int raw}) : super(raw: raw);

  @override
  String get title => S.current.bright_theme;
  @override
  ThemeType get type => ThemeType.bright;
  @override
  Color get primaryColor => Palette.moderateSlateBlue;
  @override
  Color get containerColor => Palette.moderateLavender;

  @override
  DashboardPageTheme get pageGradientTheme => super.pageGradientTheme.copyWith(
      firstGradientBackgroundColor: Palette.blueCraiola,
      secondGradientBackgroundColor: Palette.pinkFlamingo,
      thirdGradientBackgroundColor: Palette.redHat,
      textColor: Colors.white);

  @override
  SyncIndicatorTheme get syncIndicatorStyle =>
      super.syncIndicatorStyle.copyWith(
          textColor: Colors.white,
          syncedBackgroundColor: Colors.white.withOpacity(0.2),
          notSyncedBackgroundColor: Colors.white.withOpacity(0.15));

  @override
  ExchangePageTheme get exchangePageTheme => super.exchangePageTheme.copyWith(
      secondGradientBottomPanelColor: Palette.pinkFlamingo.withOpacity(0.7),
      firstGradientBottomPanelColor: Palette.blueCraiola.withOpacity(0.7),
      secondGradientTopPanelColor: Palette.pinkFlamingo,
      firstGradientTopPanelColor: Palette.blueCraiola);

  @override
  ThemeData get themeData => super.themeData.copyWith(
      indicatorColor: Colors.white.withOpacity(0.5), // page indicator
      hoverColor: Colors.white, // amount hint text (receive page)
      dividerColor: Palette.paleBlue,
      hintColor: Palette.gray,
      textTheme: TextTheme(
          bodySmall: TextStyle(
            decorationColor: Colors.white, // filter icon
          ),
          labelSmall: TextStyle(
              color: Colors.white.withOpacity(0.2), // filter button
              backgroundColor:
                  Colors.white.withOpacity(0.5), // date section row
              decorationColor: Colors.white
                  .withOpacity(0.2) // icons (transaction and trade rows)
              ),
          // subhead -> titleMedium
          titleMedium: TextStyle(
            color: Colors.white.withOpacity(0.2), // address button border
            decorationColor:
                Colors.white.withOpacity(0.4), // copy button (qr widget)
          ),
          // headline -> headlineSmall
          headlineSmall: TextStyle(
            color: Colors.white, // qr code
            decorationColor: Colors.white
                .withOpacity(0.5), // bottom border of amount (receive page)
          ),
          // display1 -> headlineMedium
          headlineMedium: TextStyle(
            color: PaletteDark.lightBlueGrey, // icons color (receive page)
            decorationColor:
                Palette.lavender, // icons background (receive page)
          ),
          // display2 -> displaySmall
          displaySmall: TextStyle(
              color:
                  Palette.darkBlueCraiola, // text color of tiles (receive page)
              decorationColor:
                  Colors.white // background of tiles (receive page)
              ),
          // display3 -> displayMedium
          displayMedium: TextStyle(
              color: Colors.white, // text color of current tile (receive page),
              //decorationColor: Palette.blueCraiola // background of current tile (receive page)
              decorationColor: Palette
                  .moderateSlateBlue // background of current tile (receive page)
              ),
          // display4 -> displayLarge
          displayLarge: TextStyle(
              color: Palette.violetBlue, // text color of tiles (account list)
              decorationColor:
                  Colors.white // background of tiles (account list)
              ),
          // body2 -> bodyLarge
          bodyLarge: TextStyle(
            color: Palette.moderateLavender, // menu header
            decorationColor: Colors.white, // menu background
          )),
      primaryTextTheme: TextTheme(
          titleLarge: TextStyle(
              color: Palette.darkBlueCraiola, // title color
              backgroundColor: Palette.wildPeriwinkle // textfield underline
              ),
          bodySmall: TextStyle(
              color: PaletteDark.pigeonBlue, // secondary text
              decorationColor: Palette.wildLavender // menu divider
              ),
          labelSmall: TextStyle(
            color: Palette.darkGray, // transaction/trade details titles
            decorationColor: Colors.white.withOpacity(0.5), // placeholder
          ),
          // subhead -> titleMedium
          titleMedium: TextStyle(
              color: Palette.blueCraiola, // first gradient color (send page)
              decorationColor:
                  Palette.pinkFlamingo // second gradient color (send page)
              ),
          // headline -> headlineSmall
          headlineSmall: TextStyle(
            color: Colors.white
                .withOpacity(0.5), // text field border color (send page)
            decorationColor: Colors.white
                .withOpacity(0.5), // text field hint color (send page)
          ),
          // display1 -> headlineMedium
          headlineMedium: TextStyle(
              color: Colors.white
                  .withOpacity(0.2), // text field button color (send page)
              decorationColor:
                  Colors.white // text field button icon color (send page)
              ),
          // display2 -> displaySmall
          displaySmall: TextStyle(
              color: Colors.white.withOpacity(0.5), // estimated fee (send page)
              backgroundColor: PaletteDark.darkCyanBlue
                  .withOpacity(0.67), // dot color for indicator on send page
              decorationColor:
                  Palette.shadowWhite // template dotted border (send page)
              ),
          // display3 -> displayMedium
          displayMedium: TextStyle(
              color: Palette.darkBlueCraiola, // template new text (send page)
              backgroundColor: PaletteDark
                  .darkNightBlue, // active dot color for indicator on send page
              decorationColor:
                  Palette.shadowWhite // template background color (send page)
              ),
          // display4 -> displayLarge
          displayLarge: TextStyle(
            color: Palette.darkBlueCraiola, // template title (send page)
            backgroundColor: Colors.white, // icon color on order row (moonpay)
          ),
          // body2 -> bodyLarge
          bodyLarge: TextStyle(
              backgroundColor: Palette.brightOrange // alert left button text
              )),
      accentTextTheme: TextTheme(
        // title -> titleLarge
        titleLarge: TextStyle(
          backgroundColor: Palette.periwinkleCraiola, // picker divider
        ),
        bodySmall: TextStyle(
          decorationColor:
              Palette.darkBlueCraiola, // text color (information page)
        ),
        // subtitle -> titleSmall
        titleSmall: TextStyle(
            //decorationColor: Palette.blueCraiola // crete new wallet button background (wallet list page)
            decorationColor: Palette
                .moderateSlateBlue // crete new wallet button background (wallet list page)
            ),
        // headline -> headlineSmall
        headlineSmall: TextStyle(
            color: Palette
                .moderateLavender, // first gradient color of wallet action buttons (wallet list page)
            decorationColor: Colors
                .white // restore wallet button text color (wallet list page)
            ),
        // subhead -> titleMedium
        titleMedium: TextStyle(
            color: Palette.darkGray, // titles color (filter widget)
            backgroundColor:
                Palette.periwinkle, // divider color (filter widget)
            decorationColor: Colors.white // checkbox background (filter widget)
            ),
        labelSmall: TextStyle(
          color: Palette.wildPeriwinkle, // checkbox bounds (filter widget)
          decorationColor: Colors.white, // menu subname
        ),
        // display1 -> headlineMedium
        headlineMedium: TextStyle(
            color: Palette.blueCraiola, // first gradient color (menu header)
            decorationColor:
                Palette.pinkFlamingo, // second gradient color(menu header)
            backgroundColor: Colors.white // active dot color
            ),
        // display2 -> displaySmall
        displaySmall: TextStyle(
            color:
                Palette.shadowWhite, // action button color (address text field)
            decorationColor: Palette.darkGray, // hint text (seed widget)
            backgroundColor:
                Colors.white.withOpacity(0.5) // text on balance page
            ),
        // display3 -> displayMedium
        displayMedium: TextStyle(
            color: Palette.darkGray, // hint text (new wallet page)
            decorationColor:
                Palette.periwinkleCraiola, // underline (new wallet page)
            ),
      ));
}
