import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_amount_modal.dart";
import "package:cake_wallet/src/screens/pin_code/pin_code_widget.dart";
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

  group("PIN pad", () {
    testWidgets("progress is a live region that never exposes the PIN", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          PinCodeWidget(
            key: const ValueKey("pin_code_widget"),
            onFullPin: (_, __) {},
            initialPinLength: 4,
            onChangedPin: (_) {},
            hasLengthSwitcher: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(one(tester, "pin_code_progress_key"), isSemantics(label: "0 of 4 digits entered"));
      await tester.tap(find.byKey(const ValueKey("pin_code_button_7_key")));
      await tester.tap(find.byKey(const ValueKey("pin_code_button_3_key")));
      await tester.pump();

      final progress = one(tester, "pin_code_progress_key");
      expect(progress, isSemantics(label: "2 of 4 digits entered", isLiveRegion: true));
      expect(progress.value, isEmpty);
      final texts = <String>[];
      void visit(SemanticsNode node) {
        texts
          ..add(node.label)
          ..add(node.value);
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
      expect(texts.where((text) => text.contains("73")), isEmpty);
      expect(one(tester, "pin_code_button_7_key"), isSemantics(label: "7", isButton: true));
      expect(one(tester, "pin_code_button_0_key"), isSemantics(label: "0", isButton: true));
      expect(
        one(tester, "pin_code_delete_button_key"),
        isSemantics(label: "Delete", isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });
}
