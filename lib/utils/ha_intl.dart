/// This File was Copied From Flutter example docs about adding new lang
/// https://github.com/flutter/website/blob/main/examples/internationalization/add_language/lib/nn_intl.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/intl.dart' as intl;

/// A custom set of date patterns for the `nn` locale. =>> `ha`
///
/// These are not accurate and are just a clone of the date patterns for the
/// `no` locale to demonstrate how one would write and use custom date patterns.
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

/// A custom set of date symbols for the `nn` locale. =>> `ha`
///
/// These are not accurate and are just a clone of the date symbols for the
/// `no` locale to demonstrate how one would write and use custom date symbols.
// #docregion Date2
const haDateSymbols = {
  'NAME': 'ha',
  'ERAS': <dynamic>[
    'f.Kr.',
    'e.Kr.',
  ],
// #enddocregion Date2
  'ERANAMES': <dynamic>[
    'Kafin Almasihu',
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
    'Janairu',
    'Fabrairu',
    'Maris',
    'Afrilu',
    'Mayu',
    'Yuni',
    'Yuli',
    'Agusta',
    'Satumba',
    'Oktoba',
    'Nuwamba',
    'Decemba',
  ],
  'STANDALONEMONTHS': <dynamic>[
    'Janairu',
    'Fabrairu',
    'Maris',
    'Afrilu',
    'Mayu',
    'Yuni',
    'Yuli',
    'Agusta',
    'Satumba',
    'Oktoba',
    'Nuwamba',
    'Decemba',
  ],
  'SHORTMONTHS': <dynamic>[
    'jan',
    'fab',
    'mar',
    'afr',
    'may',
    'yun',
    'yul',
    'agu',
    'sat',
    'okt',
    'nuw',
    'dec',
  ],
  'STANDALONESHORTMONTHS': <dynamic>[
    'jan',
    'fab',
    'mar',
    'afr',
    'may',
    'yun',
    'yul',
    'agu',
    'sat',
    'okt',
    'nuw',
    'dec',
  ],
  'WEEKDAYS': <dynamic>[
    'Lahadi',
    'Litinin',
    'Talata',
    'Laraba',
    'Alhamis',
    'Jumma\'a',
    'Asabar',
  ],
  'STANDALONEWEEKDAYS': <dynamic>[
    'Lahadi',
    'Litinin',
    'Talata',
    'Laraba',
    'Alhamis',
    'Jumma\'a',
    'Asabar',
  ],
  'SHORTWEEKDAYS': <dynamic>[
    'Lah',
    'Lit',
    'Tal',
    'Lar',
    'Alh',
    'Jum',
    'Asa',
  ],
  'STANDALONESHORTWEEKDAYS': <dynamic>[
    'Lah',
    'Lit',
    'Tal',
    'Lar',
    'Alh',
    'Jum',
    'Asa',
  ],
  'NARROWWEEKDAYS': <dynamic>[
    'La',
    'Li',
    'Ta',
    'La',
    'Al',
    'Ju',
    'As',
  ],
  'STANDALONENARROWWEEKDAYS': <dynamic>[
    'La',
    'Li',
    'Ta',
    'La',
    'Al',
    'Ju',
    'As',
  ],
  'SHORTQUARTERS': <dynamic>[
    'Q1',
    'Q2',
    'Q3',
    'Q4',
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
class _HaMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _HaMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ha';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    final String localeName = intl.Intl.canonicalizedLocale(locale.toString());

    // The locale (in this case `nn`) needs to be initialized into the custom =>> `ha`
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
        shortMonthDayFormat: intl.DateFormat('MMM d'),
      ),
    );
  }

  @override
  bool shouldReload(_HaMaterialLocalizationsDelegate old) => false;
}
// #enddocregion Delegate

/// A custom set of localizations for the 'nn' locale. In this example, only =>> `ha`
/// the value for openAppDrawerTooltip was modified to use a custom message as
/// an example. Everything else uses the American English (en_US) messages
/// and formatting.
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
  String get moreButtonTooltip => r'Kara';

  @override
  String get aboutListTileTitleRaw => r'Game da $applicationName';

  @override
  String get alertDialogLabel => r'Fadakarwa';

// #enddocregion Getters

  @override
  String get anteMeridiemAbbreviation => r'AM';

  @override
  String get backButtonTooltip => r'Baya';

  @override
  String get cancelButtonLabel => r'SOKE';

  @override
  String get closeButtonLabel => r'RUFE';

  @override
  String get closeButtonTooltip => r'Rufe';

  @override
  String get collapsedIconTapHint => r'Fadada';

  @override
  String get continueButtonLabel => r'CIGABA';

  @override
  String get copyButtonLabel => r'KOWA';

  @override
  String get cutButtonLabel => r'YANKE';

  @override
  String get deleteButtonTooltip => r'Share';

  @override
  String get dialogLabel => r'Magana';

  @override
  String get drawerLabel => r'Menu na kewayawa';

  @override
  String get expandedIconTapHint => r'Rushewa';

  @override
  String get firstPageTooltip => r'Shafin farko';

  @override
  String get hideAccountsLabel => r'Boye asusun';

  @override
  String get lastPageTooltip => r'Shafin karshe';

  @override
  String get licensesPageTitle => r'Lasisi';

  @override
  String get modalBarrierDismissLabel => r'Korar';

  @override
  String get nextMonthTooltip => r'Wata mai zuwa';

  @override
  String get nextPageTooltip => r'shafi na gaba';

  @override
  String get okButtonLabel => r'AK';

  @override
  // A custom drawer tooltip message.
  String get openAppDrawerTooltip => r'Tukwici na Menu Kewayawa na Musamman';

// #docregion Raw
  @override
  String get pageRowsInfoTitleRaw => r'$firstRow–$lastRow na $rowCount';

  @override
  String get pageRowsInfoTitleApproximateRaw =>
      r'$firstRow–$lastRow na game $rowCount';
// #enddocregion Raw

  @override
  String get pasteButtonLabel => r'liƙa';

  @override
  String get popupMenuLabel => r'Menu na Popup';

  @override
  String get menuBarMenuLabel => r'Menu Lakabi';

  @override
  String get postMeridiemAbbreviation => r'PM';

  @override
  String get previousMonthTooltip => r'Watan da ya gabata';

  @override
  String get previousPageTooltip => r'Shafin da ya gabata';

  @override
  String get refreshIndicatorSemanticLabel => r'Sake sabuntawa';

  @override
  String? get remainingTextFieldCharacterCountFew => null;

  @override
  String? get remainingTextFieldCharacterCountMany => null;

  @override
  String get remainingTextFieldCharacterCountOne => r'1 hali saura';

  @override
  String get remainingTextFieldCharacterCountOther =>
      r'$remainingCount haruffan da suka rage';

  @override
  String? get remainingTextFieldCharacterCountTwo => null;

  @override
  String get remainingTextFieldCharacterCountZero => r'Babu wasu haruffa da suka rage';

  @override
  String get reorderItemDown => r'Matsa ƙasa';

  @override
  String get reorderItemLeft => r'Matsa hagu';

  @override
  String get reorderItemRight => r'Matsa dama';

  @override
  String get reorderItemToEnd => r'Matsa zuwa ƙarshe';

  @override
  String get reorderItemToStart => r'Matsa zuwa farawa';

  @override
  String get reorderItemUp => r'Matsa sama';

  @override
  String get rowsPerPageTitle => r'Layukan kowane shafi:';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.englishLike;

  @override
  String get searchFieldLabel => r'Bincika';

  @override
  String get selectAllButtonLabel => r'ZABI DUKA';

  @override
  String? get selectedRowCountTitleFew => null;

  @override
  String? get selectedRowCountTitleMany => null;

  @override
  String get selectedRowCountTitleOne => r'1 abu zaba';

  @override
  String get selectedRowCountTitleOther => r'$selectedRowCount abubuwan da aka zaɓa';

  @override
  String? get selectedRowCountTitleTwo => null;

  @override
  String get selectedRowCountTitleZero => r'Babu abubuwan da aka zaɓa';

  @override
  String get showAccountsLabel => r'Nuna asusu';

  @override
  String get showMenuTooltip => r'Nuna menu';

  @override
  String get signedInLabel => r'An shiga';

  @override
  String get tabLabelRaw => r'Tab $tabIndex na $tabCount';

  @override
  TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.h_colon_mm_space_a;

  @override
  String get timePickerHourModeAnnouncement => r'Zaɓi awoyi';

  @override
  String get timePickerMinuteModeAnnouncement => r'Zaɓi mintuna';

  @override
  String get viewLicensesButtonLabel => r'DUBI LASIS';

  @override
  List<String> get narrowWeekdays =>
      const <String>['La', 'Li', 'Ta', 'La', 'Al', 'Ju', 'As'];

  @override
  int get firstDayOfWeekIndex => 0;

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _HaMaterialLocalizationsDelegate();

  @override
  String get calendarModeButtonLabel => r'Canja zuwa kalanda';

  @override
  String get dateHelpText => r'mm/dd/yyyy';

  @override
  String get dateInputLabel => r'Shigar Kwanan Wata';

  @override
  String get dateOutOfRangeLabel => r'Ban da iyaka.';

  @override
  String get datePickerHelpText => r'ZABEN RANAR';

  @override
  String get dateRangeEndDateSemanticLabelRaw => r'Kwanan Ƙarshen $fullDate';

  @override
  String get dateRangeEndLabel => r'Kwanan Ƙarshen';

  @override
  String get dateRangePickerHelpText => 'ZABEN WUTA';

  @override
  String get dateRangeStartDateSemanticLabelRaw => 'Ranar farawa \$fullDate';

  @override
  String get dateRangeStartLabel => 'Ranar farawa';

  @override
  String get dateSeparator => '/';

  @override
  String get dialModeButtonLabel => 'Canja zuwa yanayin zaɓin bugun kira';

  @override
  String get inputDateModeButtonLabel => 'Canja zuwa shigarwa';

  @override
  String get inputTimeModeButtonLabel => 'Canja zuwa yanayin shigar da rubutu';

  @override
  String get invalidDateFormatLabel => 'Tsarin mara inganci.';

  @override
  String get invalidDateRangeLabel => 'Kewayo mara inganci.';

  @override
  String get invalidTimeLabel => 'Shigar da ingantaccen lokaci';

  @override
  String get licensesPackageDetailTextOther => '\$licenseCount lasisi';

  @override
  String get saveButtonLabel => 'ACE';

  @override
  String get selectYearSemanticsLabel => 'Zaɓi shekara';

  @override
  String get timePickerDialHelpText => 'ZABEN LOKACI';

  @override
  String get timePickerHourLabel => 'SAA';

  @override
  String get timePickerInputHelpText => 'SHIGA LOKACI';

  @override
  String get timePickerMinuteLabel => 'Minti';

  @override
  String get unspecifiedDate => 'kwanan wata';

  @override
  String get unspecifiedDateRange => 'kwanan wata';

  @override
  String get keyboardKeyAlt => throw UnimplementedError();

  @override
  String get keyboardKeyAltGraph => throw UnimplementedError();

  @override
  String get keyboardKeyBackspace => throw UnimplementedError();

  @override
  String get keyboardKeyCapsLock => throw UnimplementedError();

  @override
  String get keyboardKeyChannelDown => throw UnimplementedError();

  @override
  String get keyboardKeyChannelUp => throw UnimplementedError();

  @override
  String get keyboardKeyControl => throw UnimplementedError();

  @override
  String get keyboardKeyDelete => throw UnimplementedError();

  String get keyboardKeyEisu => throw UnimplementedError();

  @override
  String get keyboardKeyEject => throw UnimplementedError();

  @override
  String get keyboardKeyEnd => throw UnimplementedError();

  @override
  String get keyboardKeyEscape => throw UnimplementedError();

  @override
  String get keyboardKeyFn => throw UnimplementedError();

  @override
  String get keyboardKeyHome => throw UnimplementedError();

  @override
  String get keyboardKeyInsert => throw UnimplementedError();

  @override
  String get keyboardKeyMeta => throw UnimplementedError();

  @override
  String get keyboardKeyMetaMacOs => throw UnimplementedError();

  @override
  String get keyboardKeyMetaWindows => throw UnimplementedError();

  @override
  String get keyboardKeyNumLock => throw UnimplementedError();

  @override
  String get keyboardKeyNumpad0 => throw UnimplementedError();

  @override
  String get keyboardKeyNumpad1 => throw UnimplementedError();

  @override
  String get keyboardKeyNumpad2 => throw UnimplementedError();

  @override
  String get keyboardKeyNumpad3 => throw UnimplementedError();

  @override
  String get keyboardKeyNumpad4 => throw UnimplementedError();

  @override
  String get keyboardKeyNumpad5 => throw UnimplementedError();

  @override
  String get keyboardKeyNumpad6 => throw UnimplementedError();

  @override
  String get keyboardKeyNumpad7 => throw UnimplementedError();

  @override
  String get keyboardKeyNumpad8 => throw UnimplementedError();

  @override
  String get keyboardKeyNumpad9 => throw UnimplementedError();

  @override
  String get keyboardKeyNumpadAdd => throw UnimplementedError();

  @override
  String get keyboardKeyNumpadComma => throw UnimplementedError();

  @override
  String get keyboardKeyNumpadDecimal => throw UnimplementedError();

  @override
  String get keyboardKeyNumpadDivide => throw UnimplementedError();

  @override
  String get keyboardKeyNumpadEnter => throw UnimplementedError();

  @override
  String get keyboardKeyNumpadEqual => throw UnimplementedError();

  @override
  String get keyboardKeyNumpadMultiply => throw UnimplementedError();

  @override
  String get keyboardKeyNumpadParenLeft => throw UnimplementedError();

  @override
  String get keyboardKeyNumpadParenRight => throw UnimplementedError();

  @override
  String get keyboardKeyNumpadSubtract => throw UnimplementedError();

  @override
  String get keyboardKeyPageDown => throw UnimplementedError();

  @override
  String get keyboardKeyPageUp => throw UnimplementedError();

  @override
  String get keyboardKeyPower => throw UnimplementedError();

  @override
  String get keyboardKeyPowerOff => throw UnimplementedError();

  @override
  String get keyboardKeyPrintScreen => throw UnimplementedError();

  @override
  String get keyboardKeyScrollLock => throw UnimplementedError();

  @override
  String get keyboardKeySelect => throw UnimplementedError();

  @override
  String get keyboardKeySpace => throw UnimplementedError();
}