import "dart:async";

import "package:cake_wallet/entities/transaction_description.dart";
import "package:cake_wallet/store/dashboard/transaction_notes_store.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mobx/mobx.dart";

class _FakeDescriptionBox implements Box<TransactionDescription> {
  _FakeDescriptionBox(this.descriptions, this.events);

  List<TransactionDescription> descriptions;
  final Stream<BoxEvent> events;

  @override
  Iterable<TransactionDescription> get values => descriptions;

  @override
  Stream<BoxEvent> watch({dynamic key}) => events;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("${invocation.memberName} is not faked");
}

void main() {
  late StreamController<BoxEvent> events;

  setUp(() => events = StreamController<BoxEvent>());

  tearDown(() => events.close());

  TransactionNotesStore storeWith(List<TransactionDescription> descriptions) =>
      TransactionNotesStore(
        transactionDescriptionSource: _FakeDescriptionBox(descriptions, events.stream),
      );

  TransactionDescription description(String id, String? note) =>
      TransactionDescription(id: id, transactionNote: note);

  test("reads the note saved under the transaction hash and the wallet's primary address", () {
    final store = storeWith([description("tx1_primary", "Rent")]);

    expect(store.noteOf("tx1", "primary"), "Rent");
  });

  test("falls back to a note saved under the bare transaction hash", () {
    final store = storeWith([description("tx1", "Older note")]);

    expect(store.noteOf("tx1", "primary"), "Older note");
  });

  test("returns an empty note for another wallet's note or an unknown transaction", () {
    final store = storeWith([description("tx1_otherWallet", "Not mine"), description("tx2", null)]);

    expect(store.noteOf("tx1", "primary"), "");
    expect(store.noteOf("tx2", "primary"), "");
    expect(store.noteOf("tx3", "primary"), "");
  });

  test("keeps the first description saved for an id, as the details screen does", () {
    final store =
        storeWith([description("tx1_primary", "First"), description("tx1_primary", "Second")]);

    expect(store.noteOf("tx1", "primary"), "First");
  });

  test("updates once after a burst of box changes", () async {
    final box = _FakeDescriptionBox([], events.stream);
    final store = TransactionNotesStore(transactionDescriptionSource: box);
    var updates = 0;
    final dispose = reaction((_) => store.notes, (_) => updates++);
    addTearDown(dispose);

    box.descriptions = [description("tx1_primary", "Rent"), description("tx2_primary", "Dinner")];
    events
      ..add(BoxEvent(0, box.descriptions[0], false))
      ..add(BoxEvent(1, box.descriptions[1], false));

    expect(store.noteOf("tx1", "primary"), "");

    await pumpEventQueue();

    expect(store.noteOf("tx1", "primary"), "Rent");
    expect(store.noteOf("tx2", "primary"), "Dinner");
    expect(updates, 1);
  });
}
