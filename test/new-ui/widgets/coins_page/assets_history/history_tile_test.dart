import "package:cake_wallet/di.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/themes/utils/theme_list.dart";
import "package:cake_wallet/themes/utils/theme_provider.dart";
import "package:cw_core/transaction_direction.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

HistoryTile _receivedTile({required String title, required bool titleIsNote}) => HistoryTile(
      title: title,
      titleIsNote: titleIsNote,
      date: "16:15",
      amount: "+0.124 XMR",
      signedAmount: true,
      amountFiat: "USD 50.29",
      roundedTop: true,
      roundedBottom: true,
      bottomSeparator: false,
      direction: TransactionDirection.incoming,
      pending: false,
      hasTokens: false,
    );

void main() {
  late ThemeStore themeStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeStore = ThemeStore()..sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<ThemeStore>(themeStore);
  });

  tearDown(() => getIt.unregister<ThemeStore>());

  Future<void> pumpApp(WidgetTester tester, Widget body) async {
    await tester.pumpWidget(
      ThemeProvider(
        themeStore: themeStore,
        materialAppBuilder: (context, theme, darkTheme, themeMode) => MaterialApp(
          theme: theme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          home: Scaffold(body: body),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("recolours a received row when the theme changes", (tester) async {
    await themeStore.setTheme(ThemeList.darkTheme);
    await pumpApp(tester, _receivedTile(title: "Received", titleIsNote: false));

    Color? amountColor() => tester.widget<Text>(find.text("+0.124 XMR")).style?.color;
    ColorFilter? iconFilter() =>
        tester.widget<CakeImageWidget>(find.byType(CakeImageWidget)).colorFilter;

    final dark = ThemeList.darkTheme.customColors;
    expect(amountColor(), dark.receivedAmountColor);
    expect(iconFilter(), ColorFilter.mode(dark.receivedIconColor, BlendMode.srcIn));

    await themeStore.setTheme(ThemeList.lightTheme);
    await tester.pumpAndSettle();

    final light = ThemeList.lightTheme.customColors;
    expect(amountColor(), light.receivedAmountColor);
    expect(iconFilter(), ColorFilter.mode(light.receivedIconColor, BlendMode.srcIn));
  });

  testWidgets("sets a note title in SemiBold and leaves Received in the default weight",
      (tester) async {
    await pumpApp(
      tester,
      Column(
        children: [
          _receivedTile(title: "Friday dinner", titleIsNote: true),
          _receivedTile(title: "Received", titleIsNote: false),
        ],
      ),
    );

    FontWeight? weightOf(String title) => tester.widget<Text>(find.text(title)).style?.fontWeight;
    expect(weightOf("Friday dinner"), FontWeight.w600);
    expect(weightOf("Received"), isNull);
  });
}
