import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/account_customizer.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/accounts_promo.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  late SharedPreferences preferences;
  late int openCount;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    openCount = 0;
  });

  Widget testApp() => MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: AccountsPromo(
            preferences: preferences,
            walletName: "Monero",
            onTap: () => openCount++,
          ),
        ),
      );

  test("education and archival entry points follow the Monero adapter", () {
    expect(supportsAccountEducationAndArchival(WalletType.monero), isTrue);
    expect(supportsAccountEducationAndArchival(WalletType.wownero), isFalse);
  });

  testWidgets("shows generic current-wallet copy and opens Accounts", (tester) async {
    await tester.pumpWidget(testApp());

    expect(find.text("Accounts for Monero are here!"), findsOneWidget);
    expect(find.text("Manage all your assets in a unified interface"), findsOneWidget);
    expect(find.text("Don’t show this anymore"), findsOneWidget);

    await tester.tap(find.text("Accounts for Monero are here!"));
    expect(openCount, 1);
  });

  testWidgets("explicit dismissal persists and hides only the promo", (tester) async {
    await tester.pumpWidget(testApp());

    await tester.tap(find.text("Don’t show this anymore"));
    await tester.pumpAndSettle();

    expect(find.text("Accounts for Monero are here!"), findsNothing);
    expect(preferences.getBool(PreferencesKey.accountsHomePromoDismissed), isTrue);
    expect(openCount, 0);
  });

  testWidgets("a previously dismissed promo stays hidden", (tester) async {
    await preferences.setBool(PreferencesKey.accountsHomePromoDismissed, true);
    await tester.pumpWidget(testApp());

    expect(find.text("Accounts for Monero are here!"), findsNothing);
  });
}
