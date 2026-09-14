import "package:cake_wallet/new-ui/viewmodels/coin_control/coin_control_bloc.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/coin_control/coin_control_wallet.dart";
import "package:cw_core/coin_control/coin_notes_store.dart";
import "package:cw_core/coin_control/coin_selection.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/node.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/unspent_transaction_output.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";

typedef _History = TransactionHistoryBase<TransactionInfo>;

Unspent coin(String hash, {int value = 1000, bool isChange = false}) =>
    Unspent("addr-$hash", hash, value, 0, null)..isChange = isChange;

/// The wallet the Bloc talks to. Coin control is a mixin on WalletBase, so a
/// double has to be one; everything WalletBase asks for that coin control does
/// not use throws, so a test that starts leaning on it fails loudly.
class _FakeWallet extends WalletBase<Balance, _History, TransactionInfo>
    with CoinControlWallet<Balance, _History, TransactionInfo> {
  _FakeWallet({
    required this.unspents,
    String id = "wallet-a",
    this.mwebIds = const {},
    this.failRefresh = false,
    this.failWrites = false,
    this.writeDelay = Duration.zero,
  }) : super(
          WalletInfo.external(
            id: id,
            name: id,
            type: WalletType.bitcoin,
            isRecovery: false,
            restoreHeight: 0,
            date: DateTime(2026),
            dirPath: "",
            path: "",
            address: "",
          ),
          DerivationInfo(),
        );

  @override
  List<Unspent> unspents;

  /// Frozen state, keyed by output id. Overriding the mixin's two members is
  /// the whole surface the Bloc can reach, so no store double is needed here --
  /// notes go through CoinNotesStore.instance and are faked separately.
  final Map<String, bool> frozenRecords = {};

  /// What was written, in the order it landed.
  final List<bool> frozenWrites = [];

  /// Delays writes, so ordering between rapid changes can be observed.
  Duration writeDelay;

  /// Ids to treat as MWEB outputs, so the coin type constraint can be exercised.
  final Set<String> mwebIds;

  bool failRefresh;
  bool failWrites;
  int refreshCount = 0;

  @override
  Future<void> refreshUnspents() async {
    refreshCount++;
    if (failRefresh) throw Exception("electrum unreachable");
  }

  @override
  bool allowsCoinType(Unspent coin, UnspentCoinType coinType) {
    final isMweb = mwebIds.contains(coin.id);
    switch (coinType) {
      case UnspentCoinType.mweb:
        return isMweb;
      case UnspentCoinType.nonMweb:
        return !isMweb;
      case UnspentCoinType.any:
      case UnspentCoinType.lightning:
        return true;
    }
  }

  @override
  Future<Set<String>> frozenIds() async =>
      frozenRecords.entries.where((entry) => entry.value).map((entry) => entry.key).toSet();

  @override
  Future<void> setFrozen(String coinId, bool frozen) async {
    if (failWrites) throw Exception("database is locked");
    if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
    frozenRecords[coinId] = frozen;
    frozenWrites.add(frozen);
  }

  // WalletBase's remaining surface, none of which coin control touches.

  @override
  ObservableMap<CryptoCurrency, Balance> get balance => throw UnimplementedError();

  @override
  SyncStatus get syncStatus => throw UnimplementedError();

  @override
  set syncStatus(SyncStatus status) => throw UnimplementedError();

  @override
  String? get seed => throw UnimplementedError();

  @override
  Object get keys => throw UnimplementedError();

  @override
  WalletAddresses get walletAddresses => throw UnimplementedError();

  @override
  String get password => throw UnimplementedError();

  @override
  Future<void> connectToNode({required Node node}) => throw UnimplementedError();

  @override
  Future<void> startSync() => throw UnimplementedError();

  @override
  Future<PendingTransaction> createTransaction(Object credentials) => throw UnimplementedError();

  @override
  Future<int> calculateEstimatedFee(
    TransactionPriority priority,
    int? amount, {
    CoinSelection selection = const AllCoinSelection(),
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, TransactionInfo>> fetchTransactions() => throw UnimplementedError();

  @override
  Future<void> save() => throw UnimplementedError();

  @override
  Future<void> rescan({required int height}) => throw UnimplementedError();

  @override
  Future<void> close({bool shouldCleanup = false}) => throw UnimplementedError();

  @override
  Future<void> changePassword(String password) => throw UnimplementedError();

  @override
  Future<void>? updateBalance() => throw UnimplementedError();

  @override
  Future<String> signMessage(String message, {String? address}) => throw UnimplementedError();

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) =>
      throw UnimplementedError();

  @override
  Future<bool> checkNodeHealth() => throw UnimplementedError();
}

/// Notes are read and written through the global store rather than the wallet,
/// so the Bloc is given an in-memory one.
class _FakeNotesStore extends CoinNotesStore {
  final Map<String, Map<String, String>> _byWallet = {};

  /// What was written, in the order it landed.
  final List<String> writes = [];

  Duration writeDelay = Duration.zero;
  bool failWrites = false;

  Map<String, String> records(String walletId) => _byWallet.putIfAbsent(walletId, () => {});

  @override
  Future<Map<String, String>> forWallet(String walletId) async => Map.of(records(walletId));

  @override
  Future<void> save(String walletId, String id, String note) async {
    if (failWrites) throw Exception("database is locked");
    if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
    records(walletId)[id] = note;
    writes.add(note);
  }

  @override
  Future<void> deleteWallet(String walletId) async => _byWallet.remove(walletId);
}

void main() {
  late _FakeWallet wallet;
  late _FakeNotesStore notes;

  final a = coin("aa", value: 300);
  final b = coin("bb", value: 200);
  final c = coin("cc", value: 100);

  CoinControlBloc build({
    CoinSelection initialSelection = const AllCoinSelection(),
    UnspentCoinType constraint = UnspentCoinType.any,
  }) =>
      CoinControlBloc(
        wallet: wallet,
        fiatConversionStore: FiatConversionStore(),
        constraint: constraint,
        initialSelection: initialSelection,
      );

  /// The Bloc adds Init from its constructor, so every test waits for the load
  /// to settle before acting.
  Future<CoinControlLoaded> loaded(CoinControlBloc bloc) async {
    final state = await bloc.stream.firstWhere((state) => state is! CoinControlLoading);
    return state as CoinControlLoaded;
  }

  setUp(() {
    wallet = _FakeWallet(unspents: [a, b, c]);
    notes = _FakeNotesStore();
    CoinNotesStore.instance = notes;
  });

  group("initialization", () {
    test("starts loading, then loads a row per output", () async {
      final bloc = build();
      expect(bloc.state, isA<CoinControlLoading>());

      final state = await loaded(bloc);
      expect(state.rows.map((row) => row.id), [a.id, b.id, c.id]);
      await bloc.close();
    });

    test("refreshes the output list first", () async {
      final bloc = build();
      await loaded(bloc);
      expect(wallet.refreshCount, 1);
      await bloc.close();
    });

    test("orders rows by descending value", () async {
      wallet.unspents = [c, a, b];
      final bloc = build();

      final state = await loaded(bloc);
      expect(state.rows.map((row) => row.amount.amount.toInt()), [300, 200, 100]);
      await bloc.close();
    });

    test("selects everything when the caller has no selection yet", () async {
      final state = await loaded(build());
      expect(state.rows.every((row) => row.isSelected), isTrue);
      expect(state.isAllSelected, isTrue);
    });

    test("restores a previous selection", () async {
      final state = await loaded(build(initialSelection: SpecificCoinSelection({a.id})));

      expect(state.rowFor(a.id)!.isSelected, isTrue);
      expect(state.rowFor(b.id)!.isSelected, isFalse);
      expect(state.isAllSelected, isFalse);
    });

    test("never selects a frozen output, even under an all-outputs selection", () async {
      wallet.frozenRecords[b.id] = true;

      final state = await loaded(build());
      expect(state.rowFor(b.id)!.isFrozen, isTrue);
      expect(state.rowFor(b.id)!.isSelected, isFalse);
    });

    test("carries notes onto the rows", () async {
      notes.records(wallet.id)[a.id] = "rent";

      final state = await loaded(build());
      expect(state.rowFor(a.id)!.note, "rent");
      expect(state.rowFor(b.id)!.note, isEmpty);
    });

    test("hides outputs the coin type constraint excludes", () async {
      wallet = _FakeWallet(
        unspents: [a, b, c],
        mwebIds: {b.id},
      );

      final state = await loaded(build(constraint: UnspentCoinType.nonMweb));
      expect(state.rows.map((row) => row.id), [a.id, c.id]);
    });

    test("fails visibly when the output list cannot be fetched", () async {
      wallet.failRefresh = true;
      final bloc = build();

      final state = await bloc.stream.firstWhere((state) => state is! CoinControlLoading);
      expect(state, isA<CoinControlFailure>());
      await bloc.close();
    });

    test("loads with no rows when the wallet has no outputs", () async {
      wallet.unspents = [];

      final state = await loaded(build());
      expect(state.rows, isEmpty);
      // An empty wallet reports an all-outputs selection rather than an empty
      // explicit one, so a coin arriving later is still spendable.
      expect(state.selection, const AllCoinSelection());
    });
  });

  group("selecting", () {
    test("unselecting one output leaves the rest alone", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(SelectionChanged(b.id, value: false));
      final state = await loaded(bloc);

      expect(state.rowFor(a.id)!.isSelected, isTrue);
      expect(state.rowFor(b.id)!.isSelected, isFalse);
      expect(state.rowFor(c.id)!.isSelected, isTrue);
      await bloc.close();
    });

    test("writes nothing to storage", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(SelectionChanged(b.id, value: false));
      await loaded(bloc);

      // The whole difference between unselecting and freezing.
      expect(wallet.frozenRecords, isEmpty);
      expect(notes.records(wallet.id), isEmpty);
      await bloc.close();
    });

    test("is ignored for a frozen output", () async {
      wallet.frozenRecords[b.id] = true;
      final bloc = build();
      final before = await loaded(bloc);

      bloc.add(SelectionChanged(b.id, value: true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, before);
      await bloc.close();
    });

    test("is ignored for an unknown id", () async {
      final bloc = build();
      final before = await loaded(bloc);

      bloc.add(SelectionChanged("not-a-real-id", value: false));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, before);
      await bloc.close();
    });
  });

  group("select all", () {
    test("selects every selectable output", () async {
      final bloc = build(initialSelection: SpecificCoinSelection(const <String>{}));
      await loaded(bloc);

      bloc.add(SelectAllChanged(value: true));
      final state = await loaded(bloc);

      expect(state.isAllSelected, isTrue);
      await bloc.close();
    });

    test("unselects every output", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(SelectAllChanged(value: false));
      final state = await loaded(bloc);

      expect(state.rows.any((row) => row.isSelected), isFalse);
      await bloc.close();
    });

    test("leaves frozen outputs alone", () async {
      wallet.frozenRecords[b.id] = true;
      final bloc = build();
      await loaded(bloc);

      bloc.add(SelectAllChanged(value: true));
      final state = await loaded(bloc);

      expect(state.rowFor(b.id)!.isSelected, isFalse);
      expect(state.isAllSelected, isTrue, reason: "frozen rows are not selectable");
      await bloc.close();
    });
  });

  group("freezing", () {
    test("writes immediately and marks the row", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      final state = await loaded(bloc);

      expect(state.rowFor(b.id)!.isFrozen, isTrue);
      expect(await wallet.frozenIds(), {b.id});
      await bloc.close();
    });

    test("also unselects the output", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      final state = await loaded(bloc);

      expect(state.rowFor(b.id)!.isSelected, isFalse);
      await bloc.close();
    });

    test("unfreezing clears the flag and leaves the row unselected", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      await loaded(bloc);
      bloc.add(FreezeToggled(b.id, value: false));
      final state = await loaded(bloc);

      expect(state.rowFor(b.id)!.isFrozen, isFalse);
      expect(state.rowFor(b.id)!.isSelected, isFalse);
      expect(await wallet.frozenIds(), isEmpty);
      await bloc.close();
    });

    test("a freeze then a note on one output both land", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      await loaded(bloc);
      bloc.add(NoteChanged(b.id, note: "cold"));
      final state = await loaded(bloc);

      expect(state.rowFor(b.id)!.isFrozen, isTrue);
      expect(state.rowFor(b.id)!.note, "cold");
      expect(state.rowFor(b.id)!.isSelected, isFalse);
      await bloc.close();
    });

    test("a freeze and a note in flight together both reach storage", () async {
      // Freezing and noting have independent queues, so the two can overlap.
      wallet = _FakeWallet(unspents: [a, b, c], writeDelay: const Duration(milliseconds: 20));
      notes.writeDelay = const Duration(milliseconds: 20);
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      bloc.add(NoteChanged(b.id, note: "cold"));

      // One emission per write, in whichever order the two queues finish.
      await bloc.stream.take(2).last;

      expect(wallet.frozenRecords[b.id], isTrue);
      expect(notes.records(wallet.id)[b.id], "cold");

      // The row that ends up emitted can be missing one of the two: each
      // handler rebuilds it from the state its own write started with, so
      // whichever finishes second publishes a row that predates the other.
      // Storage is what the next load reads, so neither change is lost.
      await bloc.close();
    });

    test("an event for an unknown output fails visibly", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled("no-such-output", value: true));
      final state = await bloc.stream.first;

      // Not reachable from the details page, which only offers rows that
      // exist. Worth pinning because the write lands before the row is looked
      // up, so the state that follows is a failure rather than the old row.
      expect(state, isA<CoinControlFailure>());
      expect(wallet.frozenRecords["no-such-output"], isTrue);
      await bloc.close();
    });

    test("a note-only change leaves the frozen flag alone", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      await loaded(bloc);
      bloc.add(NoteChanged(b.id, note: "still frozen"));
      final state = await loaded(bloc);

      expect(state.rowFor(b.id)!.isFrozen, isTrue);
      expect(state.rowFor(b.id)!.note, "still frozen");
      await bloc.close();
    });

    test("a freeze-only change leaves the note alone", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(NoteChanged(b.id, note: "keep me"));
      await loaded(bloc);
      bloc.add(FreezeToggled(b.id, value: true));
      final state = await loaded(bloc);

      expect(state.rowFor(b.id)!.note, "keep me");
      expect(state.rowFor(b.id)!.isFrozen, isTrue);
      await bloc.close();
    });

    test("rapid freezes on one output apply in order, not concurrently", () async {
      // The reason the handler is sequential(): on Monero each write reaches
      // wallet2 by an index taken from the last refresh, so two of them in
      // flight at once could be applied against different orderings.
      wallet = _FakeWallet(unspents: [a, b, c], writeDelay: const Duration(milliseconds: 20));
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      bloc.add(FreezeToggled(b.id, value: false));
      bloc.add(FreezeToggled(b.id, value: true));

      await bloc.stream.take(3).last;

      expect(wallet.frozenWrites, [true, false, true], reason: "no write was skipped or reordered");
      expect(wallet.frozenRecords[b.id], isTrue, reason: "the last change wins");
      await bloc.close();
    });

    test("rapid notes on one output apply in order", () async {
      wallet = _FakeWallet(unspents: [a, b, c], writeDelay: const Duration(milliseconds: 20));
      final bloc = build();
      await loaded(bloc);

      bloc.add(NoteChanged(b.id, note: "first"));
      bloc.add(NoteChanged(b.id, note: "second"));

      final state = await bloc.stream.take(2).last as CoinControlLoaded;

      expect(notes.writes, ["first", "second"]);
      expect(state.rowFor(b.id)!.note, "second");
      await bloc.close();
    });

    test("a failed write surfaces and does not change the row", () async {
      final bloc = build();
      await loaded(bloc);
      wallet.failWrites = true;

      bloc.add(FreezeToggled(b.id, value: true));
      final state = await bloc.stream.first;

      expect(state, isA<CoinControlFailure>());
      expect(await wallet.frozenIds(), isEmpty);
      await bloc.close();
    });
  });

  group("notes", () {
    test("are written and shown on the row", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(NoteChanged(a.id, note: "cold storage"));
      final state = await loaded(bloc);

      expect(state.rowFor(a.id)!.note, "cold storage");
      expect(notes.records(wallet.id)[a.id], "cold storage");
      await bloc.close();
    });

    test("do not make an output unspendable", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(NoteChanged(a.id, note: "note"));
      final state = await loaded(bloc);

      expect(state.rowFor(a.id)!.isSelected, isTrue);
      expect(state.rowFor(a.id)!.isFrozen, isFalse);
      await bloc.close();
    });

    test("clearing a note keeps the record and the row", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(NoteChanged(a.id, note: "temporary"));
      await loaded(bloc);
      bloc.add(NoteChanged(a.id, note: ""));
      final state = await loaded(bloc);

      expect(state.rowFor(a.id)!.note, isEmpty);
      expect(notes.records(wallet.id).length, 1);
      await bloc.close();
    });
  });

  group("saving", () {
    test("everything selected yields an all-outputs selection", () async {
      // Not an enumerated list of every current id: that would freeze the set
      // of outputs and silently exclude one received afterwards.
      final bloc = build();
      await loaded(bloc);

      bloc.add(SelectionSaved());
      final state = await bloc.stream.firstWhere((state) => state is CoinControlSaved);

      expect((state as CoinControlSaved).selection, const AllCoinSelection());
      await bloc.close();
    });

    test("a partial selection yields the chosen ids", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(SelectionChanged(b.id, value: false));
      await loaded(bloc);
      bloc.add(SelectionSaved());
      final state = await bloc.stream.firstWhere((state) => state is CoinControlSaved);

      expect(((state as CoinControlSaved).selection as SpecificCoinSelection).ids, {a.id, c.id});
      await bloc.close();
    });

    test("a frozen output is excluded by the wallet, not by the selection", () async {
      // Freezing every-other-row-selected still yields an all-outputs
      // selection, because frozen is applied by spendableCoins independently.
      // That is the point of keeping the two concepts apart, and it keeps a
      // coin received later spendable.
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      await loaded(bloc);
      bloc.add(SelectionSaved());
      final state = await bloc.stream.firstWhere((state) => state is CoinControlSaved);

      final selection = (state as CoinControlSaved).selection;
      expect(selection, const AllCoinSelection());

      final spendable = await wallet.spendableCoins(selection: selection);
      expect(spendable.map((coin) => coin.id), [a.id, c.id]);
      await bloc.close();
    });

    test("an explicitly narrowed selection excludes both", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      await loaded(bloc);
      bloc.add(SelectionChanged(c.id, value: false));
      await loaded(bloc);
      bloc.add(SelectionSaved());
      final state = await bloc.stream.firstWhere((state) => state is CoinControlSaved);

      final selection = (state as CoinControlSaved).selection;
      expect((selection as SpecificCoinSelection).ids, {a.id});
      expect((await wallet.spendableCoins(selection: selection)).map((coin) => coin.id), [a.id]);
      await bloc.close();
    });

    test("all selectable selected while one is frozen still yields all-outputs", () async {
      // spendableCoins excludes frozen outputs itself, so an all-outputs
      // selection is the honest answer and stays correct for coins arriving
      // later.
      wallet.frozenRecords[b.id] = true;
      final bloc = build();
      await loaded(bloc);

      bloc.add(SelectionSaved());
      final state = await bloc.stream.firstWhere((state) => state is CoinControlSaved);

      expect((state as CoinControlSaved).selection, const AllCoinSelection());
      await bloc.close();
    });

    test("unselecting everything yields an empty selection", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(SelectAllChanged(value: false));
      await loaded(bloc);
      bloc.add(SelectionSaved());
      final state = await bloc.stream.firstWhere((state) => state is CoinControlSaved);

      // Saved as an empty explicit selection rather than refused, so nothing is
      // spendable under it and the caller is the one that has to notice.
      final selection = (state as CoinControlSaved).selection;
      expect((selection as SpecificCoinSelection).ids, isEmpty);
      expect(await wallet.spendableCoins(selection: selection), isEmpty);
      await bloc.close();
    });

    test("does not wait on an in-flight write, because it cannot affect the result", () async {
      // The selection is a set of output ids and carries neither frozen state
      // nor notes, so a write still landing cannot change what is handed back.
      wallet = _FakeWallet(unspents: [a, b, c], writeDelay: const Duration(milliseconds: 30));
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      bloc.add(SelectionSaved());

      final state = await bloc.stream.firstWhere((state) => state is CoinControlSaved);
      expect((state as CoinControlSaved).selection, const AllCoinSelection());
      await bloc.close();
    });
  });

  group("derived state", () {
    test("selectable and frozen partition the rows", () async {
      wallet.frozenRecords[b.id] = true;

      final state = await loaded(build());
      expect(state.selectable.map((row) => row.id), [a.id, c.id]);
      expect(state.frozen.map((row) => row.id), [b.id]);
    });

    test("isAllSelected is false when a selectable row is unticked", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(SelectionChanged(c.id, value: false));
      final state = await loaded(bloc);

      expect(state.isAllSelected, isFalse);
      await bloc.close();
    });
  });
}

/// Delays writes so a save racing an in-flight freeze can be observed.
