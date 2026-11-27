import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/transaction_details_modal.dart";
import "package:cake_wallet/src/screens/transaction_details/standart_list_item.dart";
import "package:cake_wallet/view_model/transaction_details_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "../../utils/semantics_helpers.dart";

class _MockTransactionDetailsViewModel extends Mock implements TransactionDetailsViewModel {}

_MockTransactionDetailsViewModel _buildViewModel({
  required bool isAmountPending,
  required String formattedTitle,
  required String formattedStatus,
}) {
  final viewModel = _MockTransactionDetailsViewModel();
  when(() => viewModel.items).thenReturn([
    StandartListItem(
      title: "Transaction ID",
      value: "e0007f02252bf58b591ec3251790690d6db5c38889990f1d4f7b43d1ffebc163",
      key: const ValueKey("standard_list_item_transaction_details_id_key"),
    ),
    StandartListItem(
      title: "Recipient address",
      value: "bc1q70vr0t3yrnztt3sd68sradq4elkd9pa2m9yl82",
      key: const ValueKey("standard_list_item_transaction_details_recipient_address_key"),
    ),
    StandartListItem(title: "Date", value: "2026-10-08"),
  ]);
  when(() => viewModel.note).thenReturn("");
  when(() => viewModel.transactionAsset).thenReturn(CryptoCurrency.btc);
  when(() => viewModel.formattedTitle).thenReturn(formattedTitle);
  when(() => viewModel.formattedStatus).thenReturn(formattedStatus);
  when(() => viewModel.transactionAmount).thenReturn("0.001 BTC");
  when(() => viewModel.transactionCopyAmount).thenReturn("0.001");
  when(() => viewModel.explorerDescription).thenReturn("View on explorer");
  when(() => viewModel.canReplaceByFee).thenReturn(false);
  when(() => viewModel.rawTransaction).thenReturn(null);
  when(() => viewModel.isAmountPending).thenReturn(isAmountPending);
  when(() => viewModel.feeFetchFailed).thenReturn(false);
  when(() => viewModel.isFetchingFee).thenReturn(false);
  when(() => viewModel.feeFetchResolvedInputs).thenReturn(0);
  when(() => viewModel.feeFetchTotalInputs).thenReturn(0);
  when(() => viewModel.isConfidentSend).thenReturn(false);
  when(() => viewModel.hasForeignInputs).thenReturn(false);
  when(() => viewModel.hasAdvancedInfo).thenReturn(false);
  when(() => viewModel.totalSentAmount).thenReturn("");
  when(() => viewModel.totalSentFiatAmount).thenReturn("");
  when(() => viewModel.transactionFiatAmount).thenReturn("");
  when(() => viewModel.feeFiatAmount).thenReturn("");
  when(() => viewModel.feeTitle).thenReturn("Fee");
  return viewModel;
}

Future<void> _pumpModal(WidgetTester tester, TransactionDetailsViewModel viewModel) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(body: TransactionDetailsModal(transactionDetailsViewModel: viewModel)),
      ),
    );

void main() {
  testWidgets("detail rows publish only their static model keys as identifiers", (tester) async {
    final handle = tester.ensureSemantics();
    final viewModel = _buildViewModel(
      isAmountPending: false,
      formattedTitle: "Sent",
      formattedStatus: "",
    );

    await _pumpModal(tester, viewModel);
    await tester.pumpAndSettle();

    for (final id in [
      "standard_list_item_transaction_details_id_key",
      "standard_list_item_transaction_details_recipient_address_key",
    ]) {
      expect(platformNodesWithId(tester, id), hasLength(1), reason: id);
      expect(find.byKey(ValueKey(id)), findsOneWidget);
    }
    expect(find.bySemanticsIdentifier(RegExp("Date|2026|bc1q|e0007f")), findsNothing);
    handle.dispose();
  });

  testWidgets("header uses a neutral title while the amount is pending", (tester) async {
    final viewModel = _buildViewModel(
      isAmountPending: true,
      formattedTitle: "Sent",
      formattedStatus: " (pending)",
    );

    await _pumpModal(tester, viewModel);
    // The amount area shows a spinner while pending, so pumpAndSettle would never return.
    await tester.pump(const Duration(milliseconds: 100));

    final neutralTitle = S.of(tester.element(find.byType(TransactionDetailsModal))).transaction;
    expect(find.text("$neutralTitle (pending)"), findsOneWidget);
    expect(find.textContaining("Sent"), findsNothing);
  });
}
