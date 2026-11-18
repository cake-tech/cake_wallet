import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/entities/sync_status_display_mode.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart";
import "package:cake_wallet/src/screens/settings/display_settings_page.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/view_model/settings/display_settings_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockDisplaySettingsViewModel extends Mock implements DisplaySettingsViewModel {}

_MockDisplaySettingsViewModel _viewModel(String languageCode) {
  final viewModel = _MockDisplaySettingsViewModel();
  when(() => viewModel.languageCode).thenReturn(languageCode);
  when(() => viewModel.disabledFiatApiMode).thenReturn(false);
  when(() => viewModel.fiatCurrency).thenReturn(FiatCurrency.cad);
  when(() => viewModel.showFiatIsoCode).thenReturn(false);
  when(() => viewModel.themeMode).thenReturn(ThemeMode.system);
  when(() => viewModel.showThemePreview).thenReturn(false);
  when(() => viewModel.shouldShowMarketPlaceInDashboard).thenReturn(true);
  when(() => viewModel.shouldShowChartsInDashboard).thenReturn(true);
  when(() => viewModel.shouldShowNftsTab).thenReturn(true);
  when(() => viewModel.syncStatusDisplayMode).thenReturn(SyncStatusDisplayMode.values.first);
  when(() => viewModel.disableTradeOption).thenReturn(false);
  when(() => viewModel.showAddressBookPopup).thenReturn(true);
  when(() => viewModel.backgroundImage).thenReturn("");
  return viewModel;
}

Future<void> _openCurrencyPicker(
  WidgetTester tester,
  DisplaySettingsViewModel viewModel, {
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: localizationDelegates,
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: DisplaySettingsPage(viewModel)),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey("display_settings_fiat_currency")));
  await tester.pumpAndSettle();
}

void main() {
  late bool registeredThemeStore;

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

  testWidgets("switches to ISO codes from the top of the currency picker", (tester) async {
    final viewModel = _viewModel("en");
    await _openCurrencyPicker(tester, viewModel);

    final formatRow = find.byKey(const ValueKey("display_settings_currency_format"));
    expect(find.byType(FiatCurrencyPickerSheet), findsOneWidget);
    expect(find.descendant(of: formatRow, matching: find.text("Currency format")), findsOneWidget);
    expect(find.descendant(of: formatRow, matching: find.textContaining("Symbol")), findsOneWidget);

    await tester.tap(formatRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text("ISO code (CAD)").last);
    await tester.pumpAndSettle();

    verify(() => viewModel.setShowFiatIsoCode(true)).called(1);
  });

  testWidgets("keeps the symbol in order in a right-to-left language", (tester) async {
    await _openCurrencyPicker(tester, _viewModel("ar"), locale: const Locale("ar"));

    final option = find.descendant(
      of: find.byKey(const ValueKey("display_settings_currency_format")),
      matching: find.textContaining(r"C$"),
    );
    final text = (tester.widget(option) as Text).data!;
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: option, matching: find.byType(RichText)),
    );
    double leftOf(String character) {
      final index = text.indexOf(character);
      return paragraph
          .getBoxesForSelection(TextSelection(baseOffset: index, extentOffset: index + 1))
          .first
          .left;
    }

    expect(leftOf("C"), lessThan(leftOf(r"$")));
  });
}
