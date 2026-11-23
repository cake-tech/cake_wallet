import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cake_wallet/view_model/dashboard/transaction_list_item.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockBalanceViewModel extends Mock implements BalanceViewModel {}

class _MockAppStore extends Mock implements AppStore {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _FakeTransactionInfo extends TransactionInfo {
  _FakeTransactionInfo({
    required TransactionDirection direction,
    required bool isPending,
    required String amount,
    required Map<String, dynamic> additionalInfo,
    required bool isReplaced,
  }) {
    id = "tx1";
    txHash = "tx1";
    this.amount = Money.parse(amount, CryptoCurrency.xmr);
    this.direction = direction;
    this.isPending = isPending;
    this.isReplaced = isReplaced;
    date = DateTime.utc(2026, 11, 19, 16, 15);
    confirmations = isPending ? 0 : 10;
    this.additionalInfo.addAll(additionalInfo);
  }
}

void main() {
  late _MockBalanceViewModel balanceViewModel;

  setUpAll(() => S.current = const S());

  setUp(() {
    balanceViewModel = _MockBalanceViewModel();
    final wallet = _MockWallet();
    when(() => wallet.type).thenReturn(WalletType.monero);
    when(() => balanceViewModel.wallet).thenReturn(wallet);
    when(() => balanceViewModel.displayMode).thenReturn(BalanceDisplayMode.displayableBalance);
  });

  TransactionListItem itemFor(
    TransactionDirection direction, {
    bool isPending = false,
    String amount = "0.124",
    Map<String, dynamic> additionalInfo = const {},
    bool isReplaced = false,
  }) =>
      TransactionListItem(
        transaction: _FakeTransactionInfo(
          direction: direction,
          isPending: isPending,
          amount: amount,
          additionalInfo: additionalInfo,
          isReplaced: isReplaced,
        ),
        balanceViewModel: balanceViewModel,
        appStore: _MockAppStore(),
        key: const ValueKey("tx1"),
      );

  void hideAmounts() =>
      when(() => balanceViewModel.displayMode).thenReturn(BalanceDisplayMode.hiddenBalance);

  group("formattedCryptoAmount", () {
    test("adds + to a received amount and - to a sent one", () {
      final received = itemFor(TransactionDirection.incoming);
      final sent = itemFor(TransactionDirection.outgoing, isPending: true, amount: "0.012");

      expect(received.formattedCryptoAmount, "+0.124 XMR");
      expect(received.hasSignedAmount, isTrue);
      expect(sent.formattedCryptoAmount, "-0.012 XMR");
      expect(sent.hasSignedAmount, isTrue);
    });

    test("leaves a zero amount unsigned", () {
      final item = itemFor(TransactionDirection.incoming, amount: "0");

      expect(item.formattedCryptoAmount, "0 XMR");
      expect(item.hasSignedAmount, isFalse);
    });

    test("leaves the amount of a fee-bumped (replaced) transaction unsigned", () {
      final item = itemFor(TransactionDirection.outgoing, isReplaced: true);

      expect(item.formattedCryptoAmount, "0.124 XMR");
      expect(item.hasSignedAmount, isFalse);
    });

    test("keeps hidden amounts as --- without a sign", () {
      hideAmounts();
      final item = itemFor(TransactionDirection.incoming);

      expect(item.formattedCryptoAmount, "---");
      expect(item.hasSignedAmount, isFalse);
    });
  });

  group("noteTitle", () {
    test("is the note once the transaction is confirmed", () {
      final received = itemFor(TransactionDirection.incoming);
      final sent = itemFor(TransactionDirection.outgoing);

      expect(received.noteTitle("Friday dinner"), "Friday dinner");
      expect(sent.noteTitle("VPN Subscription"), "VPN Subscription");
      expect(received.formattedTitle, S.current.received);
      expect(sent.formattedTitle, S.current.sent);
    });

    test("is empty while the transaction confirms", () {
      final item = itemFor(TransactionDirection.outgoing, isPending: true);

      expect(item.noteTitle("VPN Subscription"), isEmpty);
      expect(item.formattedTitle, startsWith(S.current.sending));
    });

    test("is empty while amounts are hidden", () {
      hideAmounts();
      final item = itemFor(TransactionDirection.incoming);

      expect(item.noteTitle("Friday dinner"), isEmpty);
    });

    test("puts a multi-line note on one line and ignores a blank one", () {
      final item = itemFor(TransactionDirection.outgoing);

      expect(item.noteTitle(" Rent\n\nUtilities "), "Rent Utilities");
      expect(item.noteTitle(" \n "), isEmpty);
    });

    test("is empty for shielding and migration transactions", () {
      final shielding =
          itemFor(TransactionDirection.outgoing, additionalInfo: {"isAutoShield": true});
      final migration =
          itemFor(TransactionDirection.outgoing, additionalInfo: {"isIronwoodMigration": true});

      expect(shielding.noteTitle("Note"), isEmpty);
      expect(shielding.formattedTitle, S.current.shielding);
      expect(migration.noteTitle("Note"), isEmpty);
    });
  });
}
