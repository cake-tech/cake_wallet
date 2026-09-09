import "package:cake_wallet/new-ui/viewmodels/coin_control/coin_control_bloc.dart";
import "package:cw_core/coin_control/coin_control_wallet.dart";
import "package:cw_core/coin_control/coin_selection.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/unspent_transaction_output.dart";
import "package:flutter_test/flutter_test.dart";

Unspent coin(String hash, {int value = 1000, bool isChange = false}) =>
    Unspent("addr-$hash", hash, value, 0, null)..isChange = isChange;

/// The Bloc asks for a wallet and a currency, so a double needs no more.
class _FakeWallet with CoinControlWallet {
  _FakeWallet({
    required this.unspents,
    this.id = "wallet-a",
    this.mwebIds = const {},
    this.failRefresh = false,
    this.failWrites = false,
    this.writeDelay = Duration.zero,
  });

  @override
  final String id;

  @override
  List<Unspent> unspents;

  /// Stored state, keyed by output id, in the two tables the app keeps it in.
  /// The Bloc reaches the stores only through the wallet, so overriding these
  /// four members is the whole surface it can touch -- no store double needed.
  final Map<String, bool> frozenRecords = {};
  final Map<String, String> noteRecords = {};

  /// What each store was told, in the order it landed.
  final List<bool> frozenWrites = [];
  final List<String> noteWrites = [];

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
  Future<Map<String, String>> notes() async => Map.of(noteRecords);

  @override
  Future<void> setFrozen(String coinId, bool frozen) async {
    await _write();
    frozenRecords[coinId] = frozen;
    frozenWrites.add(frozen);
  }

  @override
  Future<void> saveNote(String coinId, String note) async {
    await _write();
    noteRecords[coinId] = note;
    noteWrites.add(note);
  }

  Future<void> _write() async {
    if (failWrites) throw Exception("database is locked");
    if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
  }
}

void main() {
  late _FakeWallet wallet;

  final a = coin("aa", value: 300);
  final b = coin("bb", value: 200);
  final c = coin("cc", value: 100);

  CoinControlBloc build({
    CoinSelection initialSelection = const AllCoinSelection(),
    UnspentCoinType constraint = UnspentCoinType.any,
  }) =>
      CoinControlBloc(
        wallet: wallet,
        currency: CryptoCurrency.btc,
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
      wallet.noteRecords[a.id] = "rent";

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
      // Nothing to save, so Done stays disabled regardless of isAllSelected.
      expect(state.canSave, isFalse);
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
      expect(wallet.noteRecords, isEmpty);
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
      expect(state.canSave, isFalse);
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

    test("a freeze and a note in flight together both survive", () async {
      // The two events have separate queues, so they can overlap. Each handler
      // applies its own field to the state as it stands once its write lands,
      // which is what stops the later one from publishing a row built before
      // the earlier one's change.
      wallet = _FakeWallet(unspents: [a, b, c], writeDelay: const Duration(milliseconds: 20));
      final bloc = build();
      await loaded(bloc);

      bloc.add(FreezeToggled(b.id, value: true));
      bloc.add(NoteChanged(b.id, note: "cold"));

      // One emission per write, in whichever order the two queues finish.
      final state = await bloc.stream.take(2).last as CoinControlLoaded;

      expect(state.rowFor(b.id)!.isFrozen, isTrue);
      expect(state.rowFor(b.id)!.note, "cold");
      expect(state.rowFor(b.id)!.isSelected, isFalse);
      await bloc.close();
    });

    test("an event for an unknown output writes nothing", () async {
      final bloc = build();
      final before = await loaded(bloc);

      bloc.add(FreezeToggled("no-such-output", value: true));
      bloc.add(NoteChanged("no-such-output", note: "n"));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, before);
      expect(wallet.frozenRecords, isEmpty);
      expect(wallet.noteRecords, isEmpty);
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

      expect(wallet.noteWrites, ["first", "second"]);
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
      expect(wallet.noteRecords[a.id], "cold storage");
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
      expect(wallet.noteRecords.length, 1);
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

      expect((state as CoinControlSaved).selection, SpecificCoinSelection({a.id, c.id}));
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

      final spendable = await wallet.spendableCoins(selection);
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
      expect(selection, SpecificCoinSelection({a.id}));
      expect((await wallet.spendableCoins(selection)).map((coin) => coin.id), [a.id]);
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

    test("refuses to save an empty selection", () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(SelectAllChanged(value: false));
      final before = await loaded(bloc);
      expect(before.canSave, isFalse);

      bloc.add(SelectionSaved());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<CoinControlLoaded>());
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
    test("canSave is false only when nothing is selected", () async {
      final bloc = build();
      var state = await loaded(bloc);
      expect(state.canSave, isTrue);

      bloc.add(SelectAllChanged(value: false));
      state = await loaded(bloc);
      expect(state.canSave, isFalse);

      bloc.add(SelectionChanged(a.id, value: true));
      state = await loaded(bloc);
      expect(state.canSave, isTrue);
      await bloc.close();
    });

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
