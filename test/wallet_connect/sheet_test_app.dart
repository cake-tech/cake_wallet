import "dart:io";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/themes/theme_classes/dark_theme.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

const phoneSizes = [Size(360, 640), Size(375, 667), Size(390, 844), Size(412, 915)];

Future<void> loadSheetFonts() async {
  final wix = FontLoader(DarkTheme.fontFamily);
  for (final weight in ["Regular", "Medium", "SemiBold", "Bold"]) {
    wix.addFont(_fontBytes("assets/fonts/WixMadeforText-$weight.ttf"));
  }
  await wix.load();

  final mono = FontLoader("IBM Plex Mono")
    ..addFont(_fontBytes("assets/fonts/IBM_Plex_Mono/IBMPlexMono-Regular.ttf"));
  await mono.load();
}

Future<ByteData> _fontBytes(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

void setPhoneSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Widget sheetTestApp({
  required Widget home,
  GlobalKey<NavigatorState>? navigatorKey,
  RouteFactory? onGenerateRoute,
}) => MaterialApp(
  navigatorKey: navigatorKey,
  theme: DarkTheme().themeData,
  locale: const Locale("en"),
  localizationsDelegates: localizationDelegates,
  supportedLocales: S.delegate.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
    child: child!,
  ),
  onGenerateRoute: onGenerateRoute,
  home: home,
);
