import 'package:flutter/material.dart';
import 'palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/enumerable_item.dart';

class Themes extends EnumerableItem<int> with Serializable<int> {
  const Themes({String title, int raw})
      : super(title: title, raw: raw);

  static const all = [
    Themes.light,
    Themes.bright,
    Themes.dark,
  ];

  static const light = Themes(title: 'Light', raw: 0);
  static const bright = Themes(title: 'Bright', raw: 1);
  static const dark = Themes(title: 'Dark', raw: 2);

  static Themes deserialize({int raw}) {
    switch (raw) {
      case 0:
        return light;
      case 1:
        return bright;
      case 2:
        return dark;
      default:
        return null;
    }
  }

  ThemeData get themeData {
    switch (this) {
      case Themes.light:
        return lightTheme;
      case Themes.bright:
        return brightTheme;
      case Themes.dark:
        return darkTheme;
      default:
        return null;
    }
  }

  @override
  String toString() {
    switch (this) {
      case Themes.light:
        return S.current.light_theme;
      case Themes.bright:
        return S.current.bright_theme;
      case Themes.dark:
        return S.current.dark_theme;
      default:
        return '';
    }
  }

  static final ThemeData lightTheme = ThemeData(
      fontFamily: 'Lato',
      brightness: Brightness.light,
      backgroundColor: Colors.white,
      accentColor: Colors.white, // first gradient color
      scaffoldBackgroundColor: Colors.white, // second gradient color
      primaryColor: Colors.white, // third gradient color
      buttonColor: Palette.blueAlice, // action buttons on dashboard page
      indicatorColor: PaletteDark.darkCyanBlue, // page indicator
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
              decorationColor: Palette.moderateLavender // template dotted border (send page)
          ),
          display3: TextStyle(
              color: Palette.darkBlueCraiola, // template new text (send page)
              decorationColor: Palette.blueAlice // template background color (send page)
          ),
          display4: TextStyle(
              color: Palette.darkBlueCraiola, // template title (send page)
              decorationColor: Palette.niagara // receive amount text (exchange page)
          ),
          subtitle: TextStyle(
              color: Palette.blueCraiola, // first gradient color top panel (exchange page)
              decorationColor: Palette.blueGreyCraiola // second gradient color top panel (exchange page)
          ),
          body1: TextStyle(
              color: Palette.blueCraiola.withOpacity(0.7), // first gradient color bottom panel (exchange page)
              decorationColor: Palette.blueGreyCraiola.withOpacity(0.7) // second gradient color bottom panel (exchange page)
          ),
          body2: TextStyle(
            color: Colors.white.withOpacity(0.5), // text field border on top panel (exchange page)
            decorationColor: Colors.white.withOpacity(0.5), // text field border on bottom panel (exchange page)
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
            backgroundColor: Palette.darkBlueCraiola // text on balance page
        ),
        display3: TextStyle(
            color: Palette.darkGray, // hint text (new wallet page)
            decorationColor: Palette.periwinkleCraiola, // underline (new wallet page)
            backgroundColor: Palette.darkBlueCraiola // menu, icons, balance (dashboard page)
        ),
        display4: TextStyle(
          color: Palette.darkGray, // switch background (settings page)
          decorationColor: Colors.white.withOpacity(0.4) // hint text (exchange page)
        ),
        body1: TextStyle(
            color: Palette.darkGray, // indicators (PIN code)
            decorationColor: Palette.darkGray // switch (PIN code)
        ),
        body2: TextStyle(
            color: Palette.protectiveBlue, // primary buttons, alert right buttons
            decorationColor: Palette.brightOrange, // alert left button,
            backgroundColor: Palette.dullGray // keyboard bar color
        ),
      ),
      cardColor: Palette.protectiveBlue // bottom button (action list)
  );

  static final ThemeData brightTheme = ThemeData(
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
              decorationColor: Palette.shadowWhite // template dotted border (send page)
          ),
          display3: TextStyle(
              color: Palette.darkBlueCraiola, // template new text (send page)
              decorationColor: Palette.shadowWhite // template background color (send page)
          ),
          display4: TextStyle(
              color: Palette.darkBlueCraiola, // template title (send page)
              decorationColor: Palette.niagara // receive amount text (exchange page)
          ),
          subtitle: TextStyle(
              color: Palette.blueCraiola, // first gradient color top panel (exchange page)
              decorationColor: Palette.pinkFlamingo // second gradient color top panel (exchange page)
          ),
          body1: TextStyle(
              color: Palette.blueCraiola.withOpacity(0.7), // first gradient color bottom panel (exchange page)
              decorationColor: Palette.pinkFlamingo.withOpacity(0.7) // second gradient color bottom panel (exchange page)
          ),
          body2: TextStyle(
            color: Colors.white.withOpacity(0.5), // text field border on top panel (exchange page)
            decorationColor: Colors.white.withOpacity(0.5), // text field border on bottom panel (exchange page)
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
          decorationColor: Colors.white.withOpacity(0.4) // hint text (exchange page)
        ),
        body1: TextStyle(
            color: Palette.darkGray, // indicators (PIN code)
            decorationColor: Palette.darkGray // switch (PIN code)
        ),
        body2: TextStyle(
            color: Palette.moderateSlateBlue, // primary buttons, alert right buttons
            decorationColor: Palette.brightOrange, // alert left button,
            backgroundColor: Palette.dullGray // keyboard bar color
        ),
      ),
      cardColor: Palette.moderateSlateBlue // bottom button (action list)
  );

  static final ThemeData darkTheme = ThemeData(
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
              decorationColor: PaletteDark.darkCyanBlue // template dotted border (send page)
          ),
          display3: TextStyle(
              color: PaletteDark.darkCyanBlue, // template new text (send page)
              decorationColor: PaletteDark.darkVioletBlue // template background color (send page)
          ),
          display4: TextStyle(
              color: PaletteDark.cyanBlue, // template title (send page)
              decorationColor: PaletteDark.darkCyanBlue // receive amount text (exchange page)
          ),
          subtitle: TextStyle(
              color: PaletteDark.wildVioletBlue, // first gradient color top panel (exchange page)
              decorationColor: PaletteDark.wildVioletBlue // second gradient color top panel (exchange page)
          ),
          body1: TextStyle(
              color: PaletteDark.darkNightBlue, // first gradient color bottom panel (exchange page)
              decorationColor: PaletteDark.darkNightBlue // second gradient color bottom panel (exchange page)
          ),
          body2: TextStyle(
            color: PaletteDark.blueGrey, // text field border on top panel (exchange page)
            decorationColor: PaletteDark.moderateVioletBlue, // text field border on bottom panel (exchange page)
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
          decorationColor: PaletteDark.lightBlueGrey // hint text (exchange page)
        ),
        body1: TextStyle(
            color: PaletteDark.indicatorVioletBlue, // indicators (PIN code)
            decorationColor: PaletteDark.lightPurpleBlue // switch (PIN code)
        ),
        body2: TextStyle(
            color: Palette.blueCraiola, // primary buttons, alert right buttons
            decorationColor: Palette.alizarinRed, // alert left button
            backgroundColor: PaletteDark.granite // keyboard bar color
        ),
      ),
      cardColor: PaletteDark.darkNightBlue // bottom button (action list)
  );
}