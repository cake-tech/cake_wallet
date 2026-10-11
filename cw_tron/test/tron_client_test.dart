import "package:cw_tron/tron_client.dart";
import "package:cw_tron/tron_transaction_model.dart";
import "package:cw_tron/tron_transactions_api.dart";
import "package:flutter_test/flutter_test.dart";

class FakeTronTransactionsApi implements TronTransactionsApi {
  FakeTronTransactionsApi({this.transactions, this.trc20Transactions});

  // null means the api fails, an empty list is a working api with no history.
  final List<TronTransactionModel>? transactions;
  final List<TronTRC20TransactionModel>? trc20Transactions;
  int transactionCalls = 0;
  int trc20Calls = 0;
  String? lastAddress;

  @override
  Future<List<TronTransactionModel>> getTransactions(String address) async {
    transactionCalls++;
    lastAddress = address;
    if (transactions == null) {
      throw Exception("api down");
    }
    return transactions!;
  }

  @override
  Future<List<TronTRC20TransactionModel>> getTrc20Transactions(String address) async {
    trc20Calls++;
    lastAddress = address;
    if (trc20Transactions == null) {
      throw Exception("api down");
    }
    return trc20Transactions!;
  }
}

TronTransactionModel tx(String id) => TronTransactionModel(txID: id);

TronTRC20TransactionModel trc20(String id) => TronTRC20TransactionModel(transactionId: id);

void main() {
  test("a working primary is the only api asked", () async {
    final primary = FakeTronTransactionsApi(transactions: [tx("primary-tx")]);
    final fallback = FakeTronTransactionsApi(transactions: [tx("fallback-tx")]);
    final client = TronClient(transactionsApi: primary, fallbackTransactionsApi: fallback);

    final result = await client.fetchTransactions("TAddress");

    expect(result.single.hash, "primary-tx");
    expect(primary.transactionCalls, 1);
    expect(primary.lastAddress, "TAddress");
    expect(fallback.transactionCalls, 0);
  });

  test("an empty primary result is no history, not a failure", () async {
    final primary = FakeTronTransactionsApi(transactions: []);
    final fallback = FakeTronTransactionsApi(transactions: [tx("fallback-tx")]);
    final client = TronClient(transactionsApi: primary, fallbackTransactionsApi: fallback);

    expect(await client.fetchTransactions("TAddress"), isEmpty);
    expect(fallback.transactionCalls, 0);
  });

  test("a failing primary is retried through the fallback", () async {
    final primary = FakeTronTransactionsApi();
    final fallback = FakeTronTransactionsApi(
      transactions: [tx("fallback-tx")],
      trc20Transactions: [trc20("fallback-trc20")],
    );
    final client = TronClient(transactionsApi: primary, fallbackTransactionsApi: fallback);

    final result = await client.fetchTransactions("TAddress");

    expect(result.single.hash, "fallback-tx");
    expect(primary.transactionCalls, 1);
    expect(fallback.transactionCalls, 1);
    expect(fallback.lastAddress, "TAddress");

    final trc20Result = await client.fetchTrc20ExcludedTransactions("TAddress");

    expect(trc20Result.single.hash, "fallback-trc20");
    expect(primary.trc20Calls, 1);
    expect(fallback.trc20Calls, 1);
  });

  test("both apis failing gives an empty history, not an error", () async {
    final client = TronClient(
      transactionsApi: FakeTronTransactionsApi(),
      fallbackTransactionsApi: FakeTronTransactionsApi(),
    );

    expect(await client.fetchTransactions("TAddress"), isEmpty);
    expect(await client.fetchTrc20ExcludedTransactions("TAddress"), isEmpty);
  });
}
