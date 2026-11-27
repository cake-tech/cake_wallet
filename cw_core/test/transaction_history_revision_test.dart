import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";

class _TestTransaction extends TransactionInfo {
  _TestTransaction(String id) {
    this.id = id;
    amount = Money.fromInt(0, CryptoCurrency.btc);
    direction = TransactionDirection.incoming;
    isPending = false;
    date = DateTime.utc(2024, 6, 15);
  }
}

class _TestHistory extends TransactionHistoryBase<_TestTransaction> {
  @override
  Future<void> save() async {}

  @override
  void addOne(_TestTransaction transaction) => transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, _TestTransaction> transactions) =>
      this.transactions.addAll(transactions);
}

void main() {
  test("revision of an unknown id is 0", () {
    final history = _TestHistory();

    expect(history.revisionOf("missing"), 0);
  });

  test("storing an id for the first time gives revision 1", () {
    final history = _TestHistory();

    history.addOne(_TestTransaction("a"));

    expect(history.revisionOf("a"), 1);
  });

  test("storing a new object under the same id bumps the revision", () {
    final history = _TestHistory();

    history.addOne(_TestTransaction("a"));
    history.addOne(_TestTransaction("a"));

    expect(history.revisionOf("a"), 2);
  });

  test("revisions are counted per id", () {
    final history = _TestHistory();

    history.addOne(_TestTransaction("a"));
    history.addOne(_TestTransaction("a"));
    history.addOne(_TestTransaction("b"));

    expect(history.revisionOf("a"), 2);
    expect(history.revisionOf("b"), 1);
    expect(history.revisionOf("c"), 0);
  });

  test("addMany bumps every entry it stores", () {
    final history = _TestHistory();

    history.addOne(_TestTransaction("a"));
    history.addMany({"a": _TestTransaction("a"), "b": _TestTransaction("b")});

    expect(history.revisionOf("a"), 2);
    expect(history.revisionOf("b"), 1);
  });

  test("storing the identical object again does not bump the revision", () {
    final history = _TestHistory();
    final tx = _TestTransaction("a");

    history.addOne(tx);
    history.addOne(tx);

    expect(history.revisionOf("a"), 1);
  });

  test("clear removes entries but keeps their revisions so numbers are never reused", () {
    final history = _TestHistory();

    history.addOne(_TestTransaction("a"));
    history.addOne(_TestTransaction("a"));
    history.clear();

    expect(history.transactions, isEmpty);
    expect(history.revisionOf("a"), 2);

    history.addOne(_TestTransaction("a"));

    expect(history.revisionOf("a"), 3);
  });

  test("revisionOfStoredObject keeps the old object's revision after a replacement", () {
    final history = _TestHistory();
    final oldTx = _TestTransaction("a");
    final newTx = _TestTransaction("a");

    history.addOne(oldTx);
    history.addOne(newTx);

    expect(history.revisionOfStoredObject(oldTx), 1);
    expect(history.revisionOfStoredObject(newTx), 2);
    expect(history.revisionOfStoredObject(_TestTransaction("a")), 0);
  });

  test("observer follows a map that a subclass swaps in after construction", () {
    final history = _TestHistory();
    final replacementMap = ObservableMap<String, _TestTransaction>();

    history.transactions = replacementMap;
    history.addOne(_TestTransaction("a"));

    expect(history.transactions, same(replacementMap));
    expect(history.revisionOf("a"), 1);
  });

  test("writes to a map that was swapped out no longer bump the revision", () {
    final history = _TestHistory();
    final oldMap = history.transactions;

    history.transactions = ObservableMap<String, _TestTransaction>();
    oldMap["a"] = _TestTransaction("a");

    expect(history.revisionOf("a"), 0);
  });
}
