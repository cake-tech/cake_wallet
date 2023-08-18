import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/intl.dart' as intl;

// #docregion Date
const haLocaleDatePatterns = {
  'd': 'd.',
  'E': 'ccc',
  'EEEE': 'cccc',
  'LLL': 'LLL',
// #enddocregion Date
  'LLLL': 'LLLL',
  'M': 'L.',
  'Md': 'd.M.',
  'MEd': 'EEE d.M.',
  'MMM': 'LLL',
  'MMMd': 'd. MMM',
  'MMMEd': 'EEE d. MMM',
  'MMMM': 'LLLL',
  'MMMMd': 'd. MMMM',
  'MMMMEEEEd': 'EEEE d. MMMM',
  'QQQ': 'QQQ',
  'QQQQ': 'QQQQ',
  'y': 'y',
  'yM': 'M.y',
  'yMd': 'd.M.y',
  'yMEd': 'EEE d.MM.y',
  'yMMM': 'MMM y',
  'yMMMd': 'd. MMM y',
  'yMMMEd': 'EEE d. MMM y',
  'yMMMM': 'MMMM y',
  'yMMMMd': 'd. MMMM y',
  'yMMMMEEEEd': 'EEEE d. MMMM y',
  'yQQQ': 'QQQ y',
  'yQQQQ': 'QQQQ y',
  'H': 'HH',
  'Hm': 'HH:mm',
  'Hms': 'HH:mm:ss',
  'j': 'HH',
  'jm': 'HH:mm',
  'jms': 'HH:mm:ss',
  'jmv': 'HH:mm v',
  'jmz': 'HH:mm z',
  'jz': 'HH z',
  'm': 'm',
  'ms': 'mm:ss',
  's': 's',
  'v': 'v',
  'z': 'z',
  'zzzz': 'zzzz',
  'ZZZZ': 'ZZZZ',
};

// #docregion Date2
const haDateSymbols = {
  'NAME': 'ha',
  'ERAS': <dynamic>[
    'f.Kr.',
    'e.Kr.',
  ],
// #enddocregion Date2
  'ERANAMES': <dynamic>[
    'kafin Kristi',
    'bayan Kristi',
  ],
  'NARROWMONTHS': <dynamic>[
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ],
  'STANDALONENARROWMONTHS': <dynamic>[
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ],
  'MONTHS': <dynamic>[
    'janairu',
    'faburairu',
    'maris',
    'afrilu',
    'mayu',
    'yuni',
    'yuli',
    'agusta',
    'satumba',
    'oktoba',
    'nuwamba',
    'disamba',
  ],
  'STANDALONEMONTHS': <dynamic>[
    'janairu',
    'faburairu',
    'maris',
    'afrilu',
    'mayu',
    'yuni',
    'yuli',
    'agusta',
    'satumba',
    'oktoba',
    'nuwamba',
    'disamba',
  ],
  'SHORTMONTHS': <dynamic>[
    'jan.',
    'feb.',
    'mar.',
    'apr.',
    'mai',
    'jun.',
    'jul.',
    'aug.',
    'sep.',
    'okt.',
    'nov.',
    'des.',
  ],
  'STANDALONESHORTMONTHS': <dynamic>[
    'jan',
    'feb',
    'mar',
    'apr',
    'mai',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'des',
  ],
  'WEEKDAYS': <dynamic>[
    'lahadi',
    'litinin',
    'talata',
    'laraba',
    'alhamis',
    'jummaʼa',
    'asabar',
  ],
  'STANDALONEWEEKDAYS': <dynamic>[
    'lahadi',
    'litinin',
    'talata',
    'laraba',
    'alhamis',
    'jummaʼa',
    'asabar',
  ],
  'SHORTWEEKDAYS': <dynamic>[
    'lah.',
    'lit.',
    'tal.',
    'lar.',
    'alh.',
    'jum.',
    'asa.',
  ],
  'STANDALONESHORTWEEKDAYS': <dynamic>[
    'lah.',
    'lit.',
    'tal.',
    'lar.',
    'alh.',
    'jum.',
    'asa.',
  ],
  'NARROWWEEKDAYS': <dynamic>[
    'L',
    'L',
    'T',
    'L',
    'A',
    'J',
    'A',
  ],
  'STANDALONENARROWWEEKDAYS': <dynamic>[
    'L',
    'L',
    'T',
    'L',
    'A',
    'J',
    'A',
  ],
  'SHORTQUARTERS': <dynamic>[
    'K1',
    'K2',
    'K3',
    'K4',
  ],
  'QUARTERS': <dynamic>[
    '1. quarter',
    '2. quarter',
    '3. quarter',
    '4. quarter',
  ],
  'AMPMS': <dynamic>[
    'a.m.',
    'p.m.',
  ],
  'DATEFORMATS': <dynamic>[
    'EEEE d. MMMM y',
    'd. MMMM y',
    'd. MMM y',
    'dd.MM.y',
  ],
  'TIMEFORMATS': <dynamic>[
    'HH:mm:ss zzzz',
    'HH:mm:ss z',
    'HH:mm:ss',
    'HH:mm',
  ],
  'AVAILABLEFORMATS': null,
  'FIRSTDAYOFWEEK': 0,
  'WEEKENDRANGE': <dynamic>[
    5,
    6,
  ],
  'FIRSTWEEKCUTOFFDAY': 3,
  'DATETIMEFORMATS': <dynamic>[
    '{1} {0}',
    '{1} \'kl\'. {0}',
    '{1}, {0}',
    '{1}, {0}',
  ],
};

// #docregion Delegate
class _HaMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _HaMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ha';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    final String localeName = intl.Intl.canonicalizedLocale(locale.toString());

    // The locale (in this case `ha`) needs to be initialized into the custom
    // date symbols and patterns setup that Flutter uses.
    date_symbol_data_custom.initializeDateFormattingCustom(
      locale: localeName,
      patterns: haLocaleDatePatterns,
      symbols: intl.DateSymbols.deserializeFromMap(haDateSymbols),
    );

    return SynchronousFuture<MaterialLocalizations>(
      HaMaterialLocalizations(
        localeName: localeName,
        // The `intl` library's NumberFormat class is generated from CLDR data
        // (see https://github.com/dart-lang/intl/blob/master/lib/number_symbols_data.dart).
        // Unfortunately, there is no way to use a locale that isn't defined in
        // this map and the only way to work around this is to use a listed
        // locale's NumberFormat symbols. So, here we use the number formats
        // for 'en_US' instead.
        decimalFormat: intl.NumberFormat('#,##0.###', 'en_US'),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', 'en_US'),
        // DateFormat here will use the symbols and patterns provided in the
        // `date_symbol_data_custom.initializeDateFormattingCustom` call above.
        // However, an alternative is to simply use a supported locale's
        // DateFormat symbols, similar to NumberFormat above.
        fullYearFormat: intl.DateFormat('y', localeName),
        compactDateFormat: intl.DateFormat('yMd', localeName),
        shortDateFormat: intl.DateFormat('yMMMd', localeName),
        mediumDateFormat: intl.DateFormat('EEE, MMM d', localeName),
        longDateFormat: intl.DateFormat('EEEE, MMMM d, y', localeName),
        yearMonthFormat: intl.DateFormat('MMMM y', localeName),
        shortMonthDayFormat: intl.DateFormat('MMM d', localeName),
      ),
    );
  }

  @override
  bool shouldReload(_HaMaterialLocalizationsDelegate old) => false;
}

// #enddocregion Delegate
class HaMaterialLocalizations extends GlobalMaterialLocalizations {
  const HaMaterialLocalizations({
    super.localeName = 'ha',
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

// #docregion Getters
  @override
  String get moreButtonTooltip => r'Zaɓi';

  @override
  String get aboutListTileTitleRaw => r'Dake ɓoye $applicationname';

  @override
  String get alertDialogLabel => r'Alert';

// #enddocregion Getters

  @override
  String get anteMeridiemAbbreviation => r'AM';

  @override
  String get backButtonTooltip => r'Farawa';

  @override
  String get cancelButtonLabel => r'KANƘO';

  @override
  String get closeButtonLabel => r'SHIGA';

  @override
  String get closeButtonTooltip => r'Shiga';

  @override
  String get collapsedIconTapHint => r'Fara';

  @override
  String get continueButtonLabel => r'CI GABA';

  @override
  String get copyButtonLabel => r'KOPIYA';

  @override
  String get cutButtonLabel => r'ƘIRƘIRI';

  @override
  String get deleteButtonTooltip => r'Kashe';

  @override
  String get dialogLabel => r'Dialog';

  @override
  String get drawerLabel => r'Meniyar tebur';

  @override
  String get expandedIconTapHint => r'Faɗa';

  @override
  String get firstPageTooltip => r'Ta baya';

  @override
  String get hideAccountsLabel => r'Soke akaunti';

  @override
  String get lastPageTooltip => r'Ta gaba';

  @override
  String get licensesPageTitle => r'Lisansu';

  @override
  String get modalBarrierDismissLabel => r'So';

  @override
  String get nextMonthTooltip => r'Watan gobe';

  @override
  String get nextPageTooltip => r'Wani babban daidaita';

  @override
  String get okButtonLabel => r'OK';

  @override
  // A custom drawer tooltip message.
  String get openAppDrawerTooltip => r'Taƙaitacciyar Menu na Nauyi';

// #docregion Raw
  @override
  String get pageRowsInfoTitleRaw => r'$firstRow–$lastRow daga $rowCount';

  @override
  String get pageRowsInfoTitleApproximateRaw => r'$firstRow–$lastRow daga takwas $rowCount';
// #enddocregion Raw

  @override
  String get pasteButtonLabel => r'BANDA';

  @override
  String get popupMenuLabel => r'Meniyar Kasuwa';

  @override
  String get menuBarMenuLabel => r'Gargajiya na menu';

  @override
  String get postMeridiemAbbreviation => r'PM';

  @override
  String get previousMonthTooltip => r'Watan gabas';

  @override
  String get previousPageTooltip => r'Wani babban hanya';

  @override
  String get refreshIndicatorSemanticLabel => r'Nada';

  @override
  String? get remainingTextFieldCharacterCountFew => null;

  @override
  String? get remainingTextFieldCharacterCountMany => null;

  @override
  String get remainingTextFieldCharacterCountOne => r'1 haruffa baki';

  @override
  String get remainingTextFieldCharacterCountOther => r'$remainingCount haruffa baki';

  @override
  String? get remainingTextFieldCharacterCountTwo => null;

  @override
  String get remainingTextFieldCharacterCountZero => r'Ba a nan rubutu sosai';

  @override
  String get reorderItemDown => r'A sake ƙasa';

  @override
  String get reorderItemLeft => r'A sake hagu';

  @override
  String get reorderItemRight => r'A sake dama';

  @override
  String get reorderItemToEnd => r'A sake zuwa tamu';

  @override
  String get reorderItemToStart => r'A sake zuwa farko';

  @override
  String get reorderItemUp => r'A sake sama';

  @override
  String get rowsPerPageTitle => r'Lambar Fasali:';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.englishLike;

  @override
  String get searchFieldLabel => 'Binciken';

  @override
  String get selectAllButtonLabel => 'DUBA DUK';

  @override
  String? get selectedRowCountTitleFew => null;

  @override
  String? get selectedRowCountTitleMany => null;

  @override
  String get selectedRowCountTitleOne => '1 kaya';

  @override
  String get selectedRowCountTitleOther => r'$selectedRowCount kayayyaki';

  @override
  String? get selectedRowCountTitleTwo => null;

  @override
  String get selectedRowCountTitleZero => 'Babu kaya da aka zabi';

  @override
  String get showAccountsLabel => 'Nuna Hisobin';

  @override
  String get showMenuTooltip => 'Nuna Menu';

  @override
  String get signedInLabel => 'Kasance';

  @override
  String get tabLabelRaw => r'Tabin $tabIndex daga $tabCount';

  @override
  TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.h_colon_mm_space_a;

  @override
  String get timePickerHourModeAnnouncement => 'Zaɓi saʼoɗin lokaci';

  @override
  String get timePickerMinuteModeAnnouncement => 'Zaɓi minti';

  @override
  String get viewLicensesButtonLabel => 'DUBA LAYINSU';

  @override
  List<String> get narrowWeekdays => const <String>['L', 'L', 'M', 'K', 'J', 'A', 'A'];

  @override
  int get firstDayOfWeekIndex => 0;

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _HaMaterialLocalizationsDelegate();

  @override
  String get calendarModeButtonLabel => 'Canza zuwa kalendar';

  @override
  String get dateHelpText => 'mm/dd/yyyy';

  @override
  String get dateInputLabel => 'Shigar Daƙin';

  @override
  String get dateOutOfRangeLabel => 'A cikin jerin';

  @override
  String get datePickerHelpText => 'ZAƘA TALATA';

  @override
  String get dateRangeEndDateSemanticLabelRaw => r'Aikin da ya ƙarshe $fullDate';

  @override
  String get dateRangeEndLabel => 'Aikin da ya ƙarshe';

  @override
  String get dateRangePickerHelpText => 'ZAƘA HALIN RANAR';

  @override
  String get dateRangeStartDateSemanticLabelRaw => 'Aikin da ya gabata \$fullDate';

  @override
  String get dateRangeStartLabel => 'Aikin da ya gabata';

  @override
  String get dateSeparator => '/';

  @override
  String get dialModeButtonLabel => 'Canza zuwa jerin';

  @override
  String get inputDateModeButtonLabel => 'Canza zuwa shigar';

  @override
  String get inputTimeModeButtonLabel => 'Canza zuwa jerin bayanin rubutu';

  @override
  String get invalidDateFormatLabel => 'Tarihin ba daidai ba';

  @override
  String get invalidDateRangeLabel => 'Siffar saƙo ba tare da hukunci ba';

  @override
  String get invalidTimeLabel => 'Kasancewa aikin lokaci mai kyau';

  @override
  String get licensesPackageDetailTextOther => r'$licenseCount layinsu';

  @override
  String get saveButtonLabel => 'Aji';

  @override
  String get selectYearSemanticsLabel => 'Zaɓi shekara';

  @override
  String get timePickerDialHelpText => 'ZAƘA LOKACI';

  @override
  String get timePickerHourLabel => 'Auren lokaci';

  @override
  String get timePickerInputHelpText => 'Shigar lokaci';

  @override
  String get timePickerMinuteLabel => 'Minti';

  @override
  String get unspecifiedDate => 'Ranar';

  @override
  String get unspecifiedDateRange => 'Ranar Ayyuka';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyAltGraph => 'AltGraph';

  @override
  String get keyboardKeyBackspace => 'BayaRubuta';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyChannelDown => 'BayaKammalaSake';

  @override
  String get keyboardKeyChannelUp => 'YiKammalaSake';

  @override
  String get keyboardKeyControl => 'Tsara';

  @override
  String get keyboardKeyDelete => 'Share';

  @override
  String get keyboardKeyEject => 'Eject';

  @override
  String get keyboardKeyEnd => 'Tare';

  @override
  String get keyboardKeyEscape => 'Goge';

  @override
  String get keyboardKeyFn => 'Fn';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Shirya';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaMacOs => 'Amfani da Command';

  @override
  String get keyboardKeyMetaWindows => 'Windows';

  @override
  String get keyboardKeyNumLock => 'Num Lock';

  @override
  String get keyboardKeyNumpad0 => 'Numpad 0';

  @override
  String get keyboardKeyNumpad1 => 'Numpad 1';

  @override
  String get keyboardKeyNumpad2 => 'Numpad 2';

  @override
  String get keyboardKeyNumpad3 => 'Numpad 3';

  @override
  String get keyboardKeyNumpad4 => 'Numpad 4';

  @override
  String get keyboardKeyNumpad5 => 'Numpad 5';

  @override
  String get keyboardKeyNumpad6 => 'Numpad 6';

  @override
  String get keyboardKeyNumpad7 => 'Numpad 7';

  @override
  String get keyboardKeyNumpad8 => 'Numpad 8';

  @override
  String get keyboardKeyNumpad9 => 'Numpad 9';

  @override
  String get keyboardKeyNumpadAdd => 'Numpad +';

  @override
  String get keyboardKeyNumpadComma => 'Numpad ,';

  @override
  String get keyboardKeyNumpadDecimal => 'Numpad .';

  @override
  String get keyboardKeyNumpadDivide => 'Numpad /';

  @override
  String get keyboardKeyNumpadEnter => 'Numpad Enter';

  @override
  String get keyboardKeyNumpadEqual => 'Numpad =';

  @override
  String get keyboardKeyNumpadMultiply => 'Numpad *';

  @override
  String get keyboardKeyNumpadParenLeft => 'Numpad (';

  @override
  String get keyboardKeyNumpadParenRight => 'Numpad )';

  @override
  String get keyboardKeyNumpadSubtract => 'Numpad -';

  @override
  String get keyboardKeyPageDown => 'Page Down';

  @override
  String get keyboardKeyPageUp => 'Page Up';

  @override
  String get keyboardKeyPower => 'Power';

  @override
  String get keyboardKeyPowerOff => 'Power Off';

  @override
  String get keyboardKeyPrintScreen => 'Print Screen';

  @override
  String get keyboardKeyScrollLock => 'Scroll Lock';

  @override
  String get keyboardKeySelect => 'Zabi';

  @override
  String get keyboardKeySpace => 'Space';

  @override
  String get bottomSheetLabel => "Bottom Sheet";

  @override
  String get currentDateLabel => "Current Date";

  @override
  String get keyboardKeyShift => "Shift";

  @override
  String get scrimLabel => "Scrim";

  @override
  String get scrimOnTapHintRaw => "Scrip on Tap";
}

/// Cupertino Support
/// Strings Copied from "https://github.com/flutter/flutter/blob/master/packages/flutter_localizations/lib/src/l10n/generated_cupertino_localizations.dart"

class _HaCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _HaCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ha';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    final String localeName = intl.Intl.canonicalizedLocale(locale.toString());

    // The locale (in this case `ha`) needs to be initialized into the custom =>> `ha`
    // date symbols and patterns setup that Flutter uses.
    date_symbol_data_custom.initializeDateFormattingCustom(
      locale: localeName,
      patterns: haLocaleDatePatterns,
      symbols: intl.DateSymbols.deserializeFromMap(haDateSymbols),
    );

    return SynchronousFuture<CupertinoLocalizations>(
      HaCupertinoLocalizations(
        localeName: localeName,
        // The `intl` library's NumberFormat class is generated from CLDR data
        // (see https://github.com/dart-lang/intl/blob/master/lib/number_symbols_data.dart).
        // Unfortunately, there is no way to use a locale that isn't defined in
        // this map and the only way to work around this is to use a listed
        // locale's NumberFormat symbols. So, here we use the number formats
        // for 'en_US' instead.
        decimalFormat: intl.NumberFormat('#,##0.###', 'en_US'),
        // DateFormat here will use the symbols and patterns provided in the
        // `date_symbol_data_custom.initializeDateFormattingCustom` call above.
        // However, an alternative is to simply use a supported locale's
        // DateFormat symbols, similar to NumberFormat above.
        fullYearFormat: intl.DateFormat('y', localeName),
        mediumDateFormat: intl.DateFormat('EEE, MMM d', localeName),
        dayFormat: intl.DateFormat('d', localeName),
        doubleDigitMinuteFormat: intl.DateFormat('mm', localeName),
        singleDigitHourFormat: intl.DateFormat('j', localeName),
        singleDigitMinuteFormat: intl.DateFormat.m(localeName),
        singleDigitSecondFormat: intl.DateFormat.s(localeName),
      ),
    );
  }

  @override
  bool shouldReload(_HaCupertinoLocalizationsDelegate old) => false;
}
// #enddocregion Delegate

/// A custom set of localizations for the 'nn' locale. In this example, only =>> `ha`
/// the value for openAppDrawerTooltip was modified to use a custom message as
/// an example. Everything else uses the American English (en_US) messages
/// and formatting.
class HaCupertinoLocalizations extends GlobalCupertinoLocalizations {
  const HaCupertinoLocalizations({
    super.localeName = 'ha',
    required super.fullYearFormat,
    required super.mediumDateFormat,
    required super.decimalFormat,
    required super.dayFormat,
    required super.singleDigitHourFormat,
    required super.singleDigitMinuteFormat,
    required super.doubleDigitMinuteFormat,
    required super.singleDigitSecondFormat,
  });

  @override
  String get alertDialogLabel => 'Fadakarwa';

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get copyButtonLabel => 'Kwafa';

  @override
  String get cutButtonLabel => 'yanke';

  @override
  String get datePickerDateOrderString => 'mdy';

  @override
  String get datePickerDateTimeOrderString => 'date_time_dayPeriod';

  @override
  String? get datePickerHourSemanticsLabelFew => null;

  @override
  String? get datePickerHourSemanticsLabelMany => null;

  @override
  String? get datePickerHourSemanticsLabelOne => r"$hour o'clock";

  @override
  String get datePickerHourSemanticsLabelOther => r"$hour o'clock";

  @override
  String? get datePickerHourSemanticsLabelTwo => null;

  @override
  String? get datePickerHourSemanticsLabelZero => null;

  @override
  String? get datePickerMinuteSemanticsLabelFew => null;

  @override
  String? get datePickerMinuteSemanticsLabelMany => null;

  @override
  String? get datePickerMinuteSemanticsLabelOne => '1 minti';

  @override
  String get datePickerMinuteSemanticsLabelOther => r'$minute minti';

  @override
  String? get datePickerMinuteSemanticsLabelTwo => null;

  @override
  String? get datePickerMinuteSemanticsLabelZero => null;

  @override
  String get modalBarrierDismissLabel => 'Korar';

  @override
  String get pasteButtonLabel => 'Liƙa';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get searchTextFieldPlaceholderLabel => 'Bincika';

  @override
  String get selectAllButtonLabel => 'Zaɓi Duk';

  @override
  String get tabSemanticsLabelRaw => r'Tab $tabIndex cikin $tabCount';

  @override
  String? get timerPickerHourLabelFew => null;

  @override
  String? get timerPickerHourLabelMany => null;

  @override
  String? get timerPickerHourLabelOne => 'awa';

  @override
  String get timerPickerHourLabelOther => 'awa';

  @override
  String? get timerPickerHourLabelTwo => null;

  @override
  String? get timerPickerHourLabelZero => null;

  @override
  String? get timerPickerMinuteLabelFew => null;

  @override
  String? get timerPickerMinuteLabelMany => null;

  @override
  String? get timerPickerMinuteLabelOne => 'minti.';

  @override
  String get timerPickerMinuteLabelOther => 'minti.';

  @override
  String? get timerPickerMinuteLabelTwo => null;

  @override
  String? get timerPickerMinuteLabelZero => null;

  @override
  String? get timerPickerSecondLabelFew => null;

  @override
  String? get timerPickerSecondLabelMany => null;

  @override
  String? get timerPickerSecondLabelOne => 'dakika.';

  @override
  String get timerPickerSecondLabelOther => 'dakika.';

  @override
  String? get timerPickerSecondLabelTwo => null;

  @override
  String? get timerPickerSecondLabelZero => null;

  @override
  String get todayLabel => 'Yau';

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _HaCupertinoLocalizationsDelegate();

  @override
  String get noSpellCheckReplacementsLabel => "";
}
