import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/account_education_page.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  late bool registeredThemeStore;
  late SharedPreferences preferences;

  setUpAll(() {
    registeredThemeStore = !getIt.isRegistered<ThemeStore>();
    if (registeredThemeStore) {
      getIt.registerSingleton(ThemeStore());
    }
  });

  tearDownAll(() async {
    if (registeredThemeStore) {
      await getIt.unregister<ThemeStore>();
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
  });

  Widget educationApp() => MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: AccountEducationPage(preferences: preferences),
      );

  Future<void> continueToNextPage(WidgetTester tester) async {
    await tester.tap(find.text("Continue"));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets("first page explains account organization and exposes progress", (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(educationApp());
    await tester.pump();

    expect(
      find.text(
        "Accounts let you organize your funds by acting as separate pockets within one wallet",
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        "You can create one for your regular spending, another for your savings... all accessible from the same homescreen",
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel("Page 1 of 4"), findsOneWidget);
    expect(find.text("Continue"), findsOneWidget);
    expect(AccountEducationPage.shouldShow(preferences), isTrue);

    final title = find.text(
      "Accounts let you organize your funds by acting as separate pockets within one wallet",
    );
    final image = find.byKey(const ValueKey("accounts-education-overview-image"));
    final description = find.text(
      "You can create one for your regular spending, another for your savings... all accessible from the same homescreen",
    );
    expect(tester.getBottomLeft(title).dy, lessThan(tester.getTopLeft(image).dy));
    expect(tester.getBottomLeft(image).dy, lessThan(tester.getTopLeft(description).dy));
    expect(
      tester.getTopLeft(image).dy - tester.getBottomLeft(title).dy,
      greaterThanOrEqualTo(24),
    );
    expect(
      tester.getTopLeft(description).dy - tester.getBottomLeft(image).dy,
      greaterThanOrEqualTo(24),
    );
    semantics.dispose();
  });

  testWidgets("Continue advances to the recovery education page", (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(educationApp());
    await tester.pump();
    await continueToNextPage(tester);

    expect(
      find.text(
        "Accounts belong together in one wallet, they can all be restored from just one Recovery Phrase",
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel("Page 2 of 4"), findsOneWidget);
    expect(preferences.containsKey(PreferencesKey.accountsEducationSeen), isFalse);
    semantics.dispose();
  });

  testWidgets("account-order education follows the Figma content sequence", (tester) async {
    await tester.pumpWidget(educationApp());
    await tester.pump();
    await continueToNextPage(tester);
    await continueToNextPage(tester);

    final orderImage = find.byKey(const ValueKey("accounts-education-order-image"));
    final title = find.text(
      "Accounts are created in order, and they are restored in the same order",
    );
    final accountImage = find.byKey(
      const ValueKey("accounts-education-ordered-account-image"),
    );
    final description = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText() ==
              "The order of creation is shown alongside the account name, in the Accounts menu",
    );
    final restoreDescription = find.text(
      "This is useful to know if you want to restore your accounts, both in Cake Wallet or elsewhere",
    );

    expect(tester.getBottomLeft(orderImage).dy, lessThan(tester.getTopLeft(title).dy));
    expect(tester.getBottomLeft(title).dy, lessThan(tester.getTopLeft(accountImage).dy));
    expect(tester.getBottomLeft(accountImage).dy, lessThan(tester.getTopLeft(description).dy));
    expect(
      tester.getBottomLeft(description).dy,
      lessThan(tester.getTopLeft(restoreDescription).dy),
    );
    expect(
      tester.getTopLeft(title).dy - tester.getBottomLeft(orderImage).dy,
      moreOrLessEquals(51, epsilon: 0.1),
    );
    expect(
      tester.getTopLeft(accountImage).dy - tester.getBottomLeft(title).dy,
      moreOrLessEquals(51, epsilon: 0.1),
    );
    expect(
      tester.getTopLeft(description).dy - tester.getBottomLeft(accountImage).dy,
      moreOrLessEquals(51, epsilon: 0.1),
    );
  });

  testWidgets("final acknowledgement marks education as seen", (tester) async {
    await tester.pumpWidget(educationApp());
    await tester.pump();

    await continueToNextPage(tester);
    await continueToNextPage(tester);
    await continueToNextPage(tester);

    expect(
      find.text("Accounts cannot be deleted, only archived"),
      findsOneWidget,
    );
    expect(
      find.text(
        "If you deposit funds to an account, they will still be there even if you archive it",
      ),
      findsOneWidget,
    );
    expect(find.text("I understand. Continue"), findsOneWidget);

    await tester.tap(find.text("I understand. Continue"));
    await tester.pumpAndSettle();

    expect(preferences.getBool(PreferencesKey.accountsEducationSeen), isTrue);
    expect(AccountEducationPage.shouldShow(preferences), isFalse);
  });

  testWidgets("closing education also marks it as seen", (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(educationApp());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel("Close"));
    await tester.pumpAndSettle();

    expect(preferences.getBool(PreferencesKey.accountsEducationSeen), isTrue);
    expect(AccountEducationPage.shouldShow(preferences), isFalse);
    semantics.dispose();
  });
}
