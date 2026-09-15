import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/account_customizer.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/accounts_promo.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show Observable, runInAction;
import "package:mocktail/mocktail.dart";

class _MockSettingsStore extends Mock implements SettingsStore {
  final _dismissed = Observable(false);

  @override
  bool get accountsHomePromoDismissed => _dismissed.value;

  @override
  set accountsHomePromoDismissed(bool value) => runInAction(() => _dismissed.value = value);
}

void main() {
  late _MockSettingsStore settingsStore;
  late int openCount;

  setUp(() {
    settingsStore = _MockSettingsStore();
    openCount = 0;
  });

  Widget testApp() => MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: AccountsPromo(
            settingsStore: settingsStore,
            walletName: "Bitcoin",
            onTap: () => openCount++,
          ),
        ),
      );

  test("Bitcoin promo eligibility is separate from Monero education and archival", () {
    expect(AccountsPromo.supportsWallet(WalletType.bitcoin), isTrue);
    expect(AccountsPromo.supportsWallet(WalletType.monero), isFalse);
    expect(AccountsPromo.supportsWallet(WalletType.wownero), isFalse);
    expect(supportsAccountEducationAndArchival(WalletType.monero), isTrue);
    expect(supportsAccountEducationAndArchival(WalletType.wownero), isFalse);
  });

  testWidgets("shows generic current-wallet copy and opens Accounts", (tester) async {
    await tester.pumpWidget(testApp());

    expect(find.text("Accounts for Bitcoin are here!"), findsOneWidget);
    expect(find.text("Manage all your assets in a unified interface"), findsOneWidget);
    expect(find.text("Don’t show this anymore"), findsOneWidget);

    await tester.tap(find.text("Accounts for Bitcoin are here!"));
    expect(openCount, 1);
  });

  testWidgets("explicit dismissal updates the store and hides only the promo", (tester) async {
    await tester.pumpWidget(testApp());

    await tester.tap(find.text("Don’t show this anymore"));
    await tester.pumpAndSettle();

    expect(find.text("Accounts for Bitcoin are here!"), findsNothing);
    expect(settingsStore.accountsHomePromoDismissed, isTrue);
    expect(openCount, 0);
  });

  testWidgets("a previously dismissed promo stays hidden", (tester) async {
    settingsStore.accountsHomePromoDismissed = true;
    await tester.pumpWidget(testApp());

    expect(find.text("Accounts for Bitcoin are here!"), findsNothing);
  });
}
