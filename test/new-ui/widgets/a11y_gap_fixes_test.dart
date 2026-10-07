import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_amount_modal.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "../../utils/semantics_helpers.dart";

class _MockWalletAddressListViewModel extends Mock implements WalletAddressListViewModel {}

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

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  SemanticsNode one(WidgetTester tester, String id) {
    final nodes = platformNodesWithId(tester, id);
    expect(nodes, hasLength(1), reason: "exactly one platform node should carry '$id'");
    return nodes.single;
  }

  Future<void> pumpReceiveAmountModal(WidgetTester tester) async {
    final viewModel = _MockWalletAddressListViewModel();
    when(() => viewModel.selectedCurrency).thenReturn(CryptoCurrency.btc);
    when(() => viewModel.displayAmount).thenReturn("");
    when(() => viewModel.hasTokensList).thenReturn(false);
    when(() => viewModel.selectedCurrencyDecimals).thenReturn(8);
    when(() => viewModel.useSatoshi).thenReturn(false);
    when(() => viewModel.selectedCurrencySymbol).thenReturn("BTC");
    await tester.pumpWidget(
      wrap(ReceiveAmountModal(walletAddressListViewModel: viewModel, onSubmitted: (_) {})),
    );
  }

  group("receive amount modal", () {
    testWidgets("field, title and continue button are distinct identified nodes", (tester) async {
      final handle = tester.ensureSemantics();
      await pumpReceiveAmountModal(tester);

      expect(
        one(tester, "receive_amount_modal_amount_textfield_key"),
        isSemantics(isTextField: true, hasTapAction: true),
      );
      expect(
        one(tester, "receive_amount_modal_title_key"),
        isSemantics(label: "Set amount", isHeader: true),
      );
      expect(
        one(tester, "receive_amount_modal_continue_button_key"),
        isSemantics(label: "Continue", isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });

  group("amount semantics label", () {
    testWidgets("the Set amount field label has no doubled colon", (tester) async {
      final handle = tester.ensureSemantics();
      await pumpReceiveAmountModal(tester);

      final label = one(tester, "receive_amount_modal_amount_textfield_key").label;
      expect(label, startsWith("Amount\n"));
      expect(label, isNot(contains(":")));
      handle.dispose();
    });
  });
}
