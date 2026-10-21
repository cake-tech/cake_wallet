import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/jupiter/jupiter_exchange_provider.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "fakes.dart";

Trade _trade({
  String? txId,
  TradeState state = TradeState.created,
  Duration age = Duration.zero,
}) => Trade(
  id: "request-id",
  provider: ExchangeProviderDescription.jupiter,
  state: state,
  depositAmount: Money.parse("2", CryptoCurrency.sol),
  payoutAmount: Money.parse("400", CryptoCurrency.usdcsol),
  fundingAddress: "",
  payoutAddress: "payout-address",
  refundAddress: "refund-address",
  createdAt: DateTime.now().subtract(age),
  txId: txId,
);

void main() {
  late FakeSolana fakeSolana;
  late Solana? realSolana;
  final provider = JupiterExchangeProvider();

  setUp(() {
    realSolana = solana;
    fakeSolana = FakeSolana();
    solana = fakeSolana;
  });

  tearDown(() => solana = realSolana);

  group("before the swap is broadcast", () {
    test("a fresh order is left alone", () async {
      final trade = await provider.updateTrade(_trade());

      expect(trade.state, TradeState.created);
      expect(fakeSolana.lookedUp, isEmpty);
    });

    test("an order past its blockhash can't land anymore", () async {
      final trade = await provider.updateTrade(_trade(age: const Duration(minutes: 10)));

      expect(trade.state, TradeState.expired);
      expect(fakeSolana.lookedUp, isEmpty);
    });
  });

  group("after the swap is broadcast", () {
    test("asks the node about the saved signature", () async {
      await provider.updateTrade(_trade(txId: "signature"));

      expect(fakeSolana.lookedUp, ["signature"]);
    });

    test("a swap that landed is completed", () async {
      fakeSolana.transactionResult = true;

      final trade = await provider.updateTrade(_trade(txId: "signature"));

      expect(trade.state, TradeState.completed);
    });

    test("a swap that failed on chain is failed", () async {
      fakeSolana.transactionResult = false;

      final trade = await provider.updateTrade(_trade(txId: "signature"));

      expect(trade.state, TradeState.failed);
    });

    test("a swap the cluster hasn't confirmed yet is processing", () async {
      fakeSolana.transactionResult = null;

      final trade = await provider.updateTrade(_trade(txId: "signature"));

      expect(trade.state, TradeState.processing);
    });

    test("an old signature doesn't expire the trade", () async {
      fakeSolana.transactionResult = true;

      final trade = await provider.updateTrade(
        _trade(txId: "signature", age: const Duration(hours: 1)),
      );

      expect(trade.state, TradeState.completed);
    });

    test("a landed swap isn't looked up again", () async {
      for (final state in [TradeState.completed, TradeState.failed]) {
        final trade = await provider.updateTrade(_trade(txId: "signature", state: state));

        expect(trade.state, state);
      }

      expect(fakeSolana.lookedUp, isEmpty);
    });

    test("keeps the rest of the trade", () async {
      fakeSolana.transactionResult = true;

      final trade = await provider.updateTrade(_trade(txId: "signature"));

      expect(trade.id, "request-id");
      expect(trade.txId, "signature");
      expect(trade.payoutAddress, "payout-address");
      expect(trade.depositAmount, Money.parse("2", CryptoCurrency.sol));
    });
  });
}
