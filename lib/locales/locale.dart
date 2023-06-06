import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/locales/hausa_intl.dart';
import 'package:cake_wallet/locales/yoruba_intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Iterable<LocalizationsDelegate<dynamic>> localizationDelegates = [
  S.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  HaMaterialLocalizations.delegate,
  HaCupertinoLocalizations.delegate,
  YoCupertinoLocalizations.delegate,
  YoMaterialLocalizations.delegate,
];
