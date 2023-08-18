
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/intl.dart' as intl;

// #docregion Date
const yoLocaleDatePatterns = {
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
const yoDateSymbols = {
  'NAME': 'yo',
  'ERAS': <dynamic>[
    'f.Sk.',
    'e.Lk.',
  ],
// #enddocregion Date2
  'ERANAMES': <dynamic>[
    'Ṣaaju Kristi',
    'Lẹhin Kristi',
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
    'januárì',
    'feburárì',
    'màársì',
    'éfrílù',
    'méè',
    'júùnù',
    'júùlù',
    'ágústà',
    'sètẹ̀mbà',
    'ọkùtọ̀bà',
    'nọvẹ̀mbà',
    'dẹsẹ̀mbà',
  ],
  'STANDALONEMONTHS': <dynamic>[
    'januárì',
    'feburárì',
    'màársì',
    'éfrílù',
    'méè',
    'júùnù',
    'júùlù',
    'ágústà',
    'sètẹ̀mbà',
    'ọkùtọ̀bà',
    'nọvẹ̀mbà',
    'dẹsẹ̀mbà',
  ],
  'SHORTMONTHS': <dynamic>[
    'jan.',
    'feb.',
    'mar.',
    'ápr.',
    'mẹ̀',
    'jún.',
    'júl.',
    'ágú.',
    'sẹ̀p.',
    'ọkù.',
    'nọv.',
    'dẹs.',
  ],
  'STANDALONESHORTMONTHS': <dynamic>[
    'jan',
    'feb',
    'mar',
    'ápr',
    'mẹ̀',
    'jún',
    'júl',
    'ágú',
    'sẹ̀p',
    'ọkù',
    'nọv',
    'dẹs',
  ],
  'WEEKDAYS': <dynamic>[
    'ọjọ́ Ajé',
    'ọjọ́ Ìsẹ́gun',
    'ọjọ́ Ìsẹ́gun-Etì',
    'ọjọ́ Ìsẹ́gun-Ọ̀rú',
    'ọjọ́ Àìkú',
    'ọjọ́ Jíń',
    'ọjọ́ Àbámẹ́ta',
  ],
  'STANDALONEWEEKDAYS': <dynamic>[
'Ọjọ́ Ajé',
'Ọjọ́ Ìsẹ́gun',
'Ọjọ́ Ìsẹ́gun-Ẹtì',
'Ọjọ́ Ìsẹ́gun-Ọ̀rú',
'Ọjọ́ Àìkú',
'Ọjọ́ Jímọ̀',
'Ọjọ́ Àbámẹ́ta',
],
'SHORTWEEKDAYS': <dynamic>[
'Ajé',
'Ìsẹ́gun',
'Ìsẹ́gun-Ẹtì',
'Ìsẹ́gun-Ọ̀rú',
'Àìkú',
'Jímọ̀',
'Àbámẹ́ta',
],
'STANDALONESHORTWEEKDAYS': <dynamic>[
'Ajé',
'Ìsẹ́gun',
'Ìsẹ́gun-Ẹtì',
'Ìsẹ́gun-Ọ̀rú',
'Àìkú',
'Jímọ̀',
'Àbámẹ́ta',
],
'NARROWWEEKDAYS': <dynamic>[
'A',
'A',
'Ì',
'A',
'À',
'J',
'À',
],
'STANDALONENARROWWEEKDAYS': <dynamic>[
'A',
'A',
'Ì',
'A',
'À',
'J',
'À',
],
'SHORTQUARTERS': <dynamic>[
'K1',
'K2',
'K3',
'K4',
],
'QUARTERS': <dynamic>[
'1. kwata',
'2. kwata',
'3. kwata',
'4. kwata',
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
class _YoMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _YoMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'yo';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    final String localeName = intl.Intl.canonicalizedLocale(locale.toString());

    // The locale (in this case `yo`) needs to be initialized into the custom
    // date symbols and patterns setup that Flutter uses.
    date_symbol_data_custom.initializeDateFormattingCustom(
      locale: localeName,
      patterns: yoLocaleDatePatterns,
      symbols: intl.DateSymbols.deserializeFromMap(yoDateSymbols),
    );

    return SynchronousFuture<MaterialLocalizations>(
      YoMaterialLocalizations(
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
  bool shouldReload(_YoMaterialLocalizationsDelegate old) => false;
}

// #enddocregion Delegate
class YoMaterialLocalizations extends GlobalMaterialLocalizations {
  const YoMaterialLocalizations({
    super.localeName = 'yo',
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
String get moreButtonTooltip => r'Kò sí ìròhùn tí ó múni';

@override
String get aboutListTileTitleRaw => r'Fun Àpótí àwọn $applicationname';

@override
String get alertDialogLabel => r'Ìròhùn Àlàyé';

// #enddocregion Getters

@override
String get anteMeridiemAbbreviation => r'AM';

@override
String get backButtonTooltip => r'Fíran';

@override
String get cancelButtonLabel => r'FAGILE';

@override
String get closeButtonLabel => r'KÚ';

@override
String get closeButtonTooltip => r'Kú';

@override
String get collapsedIconTapHint => r'Tá';

@override
String get continueButtonLabel => r'TÓ WÁ';

@override
String get copyButtonLabel => r'DÚPLÍKÉTÍ';

@override
String get cutButtonLabel => r'TÒ';

@override
String get deleteButtonTooltip => r'Máa kú';

@override
String get dialogLabel => r'Ìròhùn';

@override
String get drawerLabel => r'Àgbèjọ àwọn àpọ̀tí';

@override
String get expandedIconTapHint => r'Tá';

@override
String get firstPageTooltip => r'Ojú ewe';

@override
String get hideAccountsLabel => r'Fí èrò àpótí wáyé sílẹ̀';

@override
String get lastPageTooltip => r'Ojú ayé';

@override
String get licensesPageTitle => r'Ìròhùn Ọdún';

@override
String get modalBarrierDismissLabel => r'Sọ';

@override
String get nextMonthTooltip => r'Oṣù kọja';

@override
String get nextPageTooltip => r'Ojú ọjọ́ kẹta';

@override
String get okButtonLabel => r'Ò daájú';
@override
// A custom drawer tooltip message.
String get openAppDrawerTooltip => r'Aya ntọju Iwe Awọn Aka';

// #docregion Raw
@override
String get pageRowsInfoTitleRaw => r'$firstRow–$lastRow lati $rowCount';

@override
String get pageRowsInfoTitleApproximateRaw => r'$firstRow–$lastRow lati kiakia $rowCount';
// #enddocregion Raw

@override
String get pasteButtonLabel => r'TÌ';

@override
String get popupMenuLabel => r'Meniu Pop-up';

@override
String get menuBarMenuLabel => r'Meniu Akọkọ';

@override
String get postMeridiemAbbreviation => r'PM';

@override
String get previousMonthTooltip => r'Oṣu Kanakana';

@override
String get previousPageTooltip => r'Ojú ewé akọkọ kan';

@override
String get refreshIndicatorSemanticLabel => r'Gbiyanju';

@override
String? get remainingTextFieldCharacterCountFew => null;

@override
String? get remainingTextFieldCharacterCountMany => null;

@override
String get remainingTextFieldCharacterCountOne => r'1 àmì báálẹ̀';

@override
String get remainingTextFieldCharacterCountOther => r'$remainingCount àmì báálẹ̀';

@override
String? get remainingTextFieldCharacterCountTwo => null;

@override
String get remainingTextFieldCharacterCountZero => r'Kò sí ìwọlé létà láti ń ṣe';

@override
String get reorderItemDown => r'Jù sí ilẹ';

@override
String get reorderItemLeft => r'Jù sí àrà';

@override
String get reorderItemRight => r'Jù sí òtútù';

@override
String get reorderItemToEnd => r'Jù sí ìbẹ̀jì';

@override
String get reorderItemToStart => r'Jù sí àkọ́kọ́';

@override
String get reorderItemUp => r'Jù sí ọ̀rùn';

@override
String get rowsPerPageTitle => r'Ìlò Fún àwọn Ìtọ́kasíwájú:';

@override
ScriptCategory get scriptCategory => ScriptCategory.englishLike;

@override
String get searchFieldLabel => 'Ṣẹda';

@override
String get selectAllButtonLabel => 'FADỌHỌN DỌFÚN GBÁJÚMỌ̀';

@override
String? get selectedRowCountTitleFew => null;

@override
String? get selectedRowCountTitleMany => null;

@override
String get selectedRowCountTitleOne => '1 káyé';

@override
String get selectedRowCountTitleOther => r'$selectedRowCount káyé';

@override
String? get selectedRowCountTitleTwo => null;

@override
String get selectedRowCountTitleZero => 'Kò sí káyé ti o wọlé';

@override
String get showAccountsLabel => 'Fi iyipada mu kọ';

@override
String get showMenuTooltip => 'Fi Meniu mu kọ';

@override
String get signedInLabel => 'Ọ̀nà';

@override
String get tabLabelRaw => r'Àwọn tabin $tabIndex lati $tabCount';
  
  @override
TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.h_colon_mm_space_a;

@override
String get timePickerHourModeAnnouncement => 'Tuntun waqtu lọ';

@override
String get timePickerMinuteModeAnnouncement => 'Tuntun daɗi minti';

@override
String get viewLicensesButtonLabel => 'WO NIKI';

@override
List<String> get narrowWeekdays => const <String>['L', 'L', 'A', 'O', 'Ọ', 'Ẹ', 'Ẹ'];

@override
int get firstDayOfWeekIndex => 0;

static const LocalizationsDelegate<MaterialLocalizations> delegate =
_YoMaterialLocalizationsDelegate();

@override
String get calendarModeButtonLabel => 'Tọ́rọ̀ kálẹ̀ndà';

@override
String get dateHelpText => 'mm/dd/yyyy';

@override
String get dateInputLabel => 'Firanṣẹ̀ Ọjọ́';

@override
String get dateOutOfRangeLabel => 'Nínú iwọ̀ lọ́wọ́';

@override
String get datePickerHelpText => 'WÁSÍ';

@override
String get dateRangeEndDateSemanticLabelRaw => r'Ọjọ́ tuntun to ṣà';

@override
String get dateRangeEndLabel => 'Ọjọ́ tuntun to ṣà';

@override
String get dateRangePickerHelpText => 'WÁSÍ ÌGBÀ';

@override
String get dateRangeStartDateSemanticLabelRaw => 'Ọjọ́ tuntun ti dá';

@override
String get dateRangeStartLabel => 'Ọjọ́ tuntun ti dá';

@override
String get dateSeparator => '/';

@override
String get dialModeButtonLabel => 'Tọ́rọ̀ wakati';

@override
String get inputDateModeButtonLabel => 'Tọ́rọ̀ firanṣẹ̀ ọjọ́';

@override
String get inputTimeModeButtonLabel => 'Tọ́rọ̀ wakati bayi lọ́wọ́';

@override
String get invalidDateFormatLabel => 'Akọ́kọ́tọ́ tó jẹ́kúnrin';

@override
String get invalidDateRangeLabel => 'Àmì jẹ́ káàkiri lẹ́yìn ilé';

@override
String get invalidTimeLabel => 'Akọ́kọ́tọ́ àkójọ ìwádìí';

@override
String get licensesPackageDetailTextOther => r'$licenseCount àwọn níkí';

@override
String get saveButtonLabel => 'TÙN DÁRA';

@override
String get selectYearSemanticsLabel => 'Fọ́ọ̀ shẹ́kàrà';

@override
String get timePickerDialHelpText => 'WÁSÍ WÁKÀTÌ';

@override
String get timePickerHourLabel => 'Wákàtì àṣà';

@override
String get timePickerInputHelpText => 'Shìgárà wákàtì';

@override
String get timePickerMinuteLabel => 'Mìntì';

@override
String get unspecifiedDate => 'Ọjọ̀kúnrin';

@override
String get unspecifiedDateRange => 'Ọjọ̀kúnrin àdáyọ̀';

@override
String get keyboardKeyAlt => 'Alt';

@override
String get keyboardKeyAltGraph => 'AltGraph';

@override
String get keyboardKeyBackspace => 'Báckspàcè';

@override
String get keyboardKeyCapsLock => 'Caps Lock';

@override
String get keyboardKeyChannelDown => 'Báyàkàmmàlàsàké';

@override
String get keyboardKeyChannelUp => 'Yíkàmmàlàsàké';

@override
String get keyboardKeyControl => 'Kọ́ntírọ̀l';

@override
String get keyboardKeyDelete => 'Shápè';

@override
String get keyboardKeyEject => 'Èjẹ̀tì';

@override
String get keyboardKeyEnd => 'Tàbí';

@override
String get keyboardKeyEscape => 'Tòkè';

  @override
String get keyboardKeyFn => 'Fn';

@override
String get keyboardKeyHome => 'Ile';

@override
String get keyboardKeyInsert => 'Fi sori';

@override
String get keyboardKeyMeta => 'Meta';

@override
String get keyboardKeyMetaMacOs => 'Amfani pẹlu Command';

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

class _YoCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _YoCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'yo';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    final String localeName = intl.Intl.canonicalizedLocale(locale.toString());

    // The locale (in this case `yo`) needs to be initialized into the custom =>> `yo`
    // date symbols and patterns setup that Flutter uses.
    date_symbol_data_custom.initializeDateFormattingCustom(
      locale: localeName,
      patterns: yoLocaleDatePatterns,
      symbols: intl.DateSymbols.deserializeFromMap(yoDateSymbols),
    );

    return SynchronousFuture<CupertinoLocalizations>(
      YoCupertinoLocalizations(
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
  bool shouldReload(_YoCupertinoLocalizationsDelegate old) => false;
}
// #enddocregion Delegate

/// A custom set of localizations for the 'nn' locale. In this example, only =>> `yo`
/// the value for openAppDrawerTooltip was modified to use a custom message as
/// an example. Everything else uses the American English (en_US) messages
/// and formatting.
class YoCupertinoLocalizations extends GlobalCupertinoLocalizations {
  const YoCupertinoLocalizations({
    super.localeName = 'yo',
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
String get alertDialogLabel => 'Àdàkárò';

@override
String get anteMeridiemAbbreviation => 'AM';

@override
String get copyButtonLabel => 'Kòpy';

@override
String get cutButtonLabel => 'Kọ́t';

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
String? get datePickerMinuteSemanticsLabelOne => '1 wakati';

@override
String get datePickerMinuteSemanticsLabelOther => r'$minute wakati';

@override
String? get datePickerMinuteSemanticsLabelTwo => null;

@override
String? get datePickerMinuteSemanticsLabelZero => null;

@override
String get modalBarrierDismissLabel => 'Búta';

@override
String get pasteButtonLabel => 'Tẹ́ẹ́';

@override
String get postMeridiemAbbreviation => 'PM';

@override
String get searchTextFieldPlaceholderLabel => 'Wúró àtúntà';

@override
String get selectAllButtonLabel => 'Fírànsé gbógbo';

@override
String get tabSemanticsLabelRaw => r'Tab $tabIndex nínú $tabCount';

@override
String? get timerPickerHourLabelFew => null;

@override
String? get timerPickerHourLabelMany => null;

@override
String? get timerPickerHourLabelOne => 'òǹdì';

@override
String get timerPickerHourLabelOther => 'òǹdì';

@override
String? get timerPickerHourLabelTwo => null;

@override
String? get timerPickerHourLabelZero => null;

@override
String? get timerPickerMinuteLabelFew => null;

@override
String? get timerPickerMinuteLabelMany => null;

@override
String? get timerPickerMinuteLabelOne => 'wakati.';

@override
String get timerPickerMinuteLabelOther => 'wakati.';

@override
String? get timerPickerMinuteLabelTwo => null;

@override
String? get timerPickerMinuteLabelZero => null;

@override
String? get timerPickerSecondLabelFew => null;

@override
String? get timerPickerSecondLabelMany => null;

@override
String? get timerPickerSecondLabelOne => 'dákìkà.';

@override
String get timerPickerSecondLabelOther => 'dákìkà.';

@override
String? get timerPickerSecondLabelTwo => null;

@override
String? get timerPickerSecondLabelZero => null;

@override
String get todayLabel => 'Oyọ';

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _YoCupertinoLocalizationsDelegate();

  @override
  String get noSpellCheckReplacementsLabel => "";
}
