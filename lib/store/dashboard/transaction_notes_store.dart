import "dart:async";

import "package:cake_wallet/entities/transaction_description.dart";
import "package:hive/hive.dart";
import "package:mobx/mobx.dart";

part "transaction_notes_store.g.dart";

class TransactionNotesStore = TransactionNotesStoreBase with _$TransactionNotesStore;

abstract class TransactionNotesStoreBase with Store {
  TransactionNotesStoreBase({required this.transactionDescriptionSource}) : notes = {} {
    transactionDescriptionSource.watch().listen((_) => _scheduleUpdate());
    _updateNotes();
  }

  final Box<TransactionDescription> transactionDescriptionSource;

  Timer? _scheduledUpdate;

  @observable
  Map<String, String> notes;

  String noteOf(String txHash, String primaryAddress) =>
      notes["${txHash}_$primaryAddress"] ?? notes[txHash] ?? "";

  void _scheduleUpdate() => _scheduledUpdate ??= Timer(Duration.zero, _updateNotes);

  @action
  void _updateNotes() {
    _scheduledUpdate = null;
    final notesById = <String, String>{};
    for (final description in transactionDescriptionSource.values) {
      notesById.putIfAbsent(description.id, () => description.note);
    }
    notes = notesById;
  }
}
