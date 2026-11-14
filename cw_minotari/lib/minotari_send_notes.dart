import 'dart:convert';
import 'dart:io';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_minotari/src/rust/api/send_transaction.dart';
import 'package:cw_minotari/src/rust/api/transactions.dart';

/// The suffix of a wallet's send notes file, beside its `.keys` file.
const minotariSendNotesSuffix = '.sends.json';

/// What Cake knows about a wallet's sends that cw's history doesn't say: sends the node had not
/// accepted when they were made, sends the user abandoned, and abandoned sends mined after all
/// that the user has been told about. Kept in a JSON file beside the .keys files; notes are only
/// ever added.
class MinotariSendNotes {
  MinotariSendNotes(this.path);

  final String path;

  /// Send id → the node's reason for not accepting it (empty when it gave none).
  final Map<String, String> notAccepted = {};
  final Set<String> abandoned = {};
  final Set<String> alerted = {};

  /// Reads [path]; a missing or unreadable file reads as no notes.
  static Future<MinotariSendNotes> load(String path) async {
    final notes = MinotariSendNotes(path);
    try {
      final file = File(path);
      if (!file.existsSync()) return notes;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      notes.notAccepted.addAll(
          (json['notAccepted'] as Map<String, dynamic>? ?? {}).cast<String, String>());
      notes.abandoned.addAll((json['abandoned'] as List<dynamic>? ?? []).cast<String>());
      notes.alerted.addAll((json['alerted'] as List<dynamic>? ?? []).cast<String>());
    } catch (e) {
      printV('Minotari send notes unreadable: $e');
    }
    return notes;
  }

  /// Adds [change] to the notes and writes them, together with any another engine (Android
  /// background sync) wrote meanwhile, through a temp file and a rename. Never throws: a failed
  /// write is logged and the notes in memory still change.
  Future<void> update(void Function(MinotariSendNotes notes) change) async {
    final stored = await load(path);
    stored.notAccepted.forEach((id, reason) => notAccepted.putIfAbsent(id, () => reason));
    abandoned.addAll(stored.abandoned);
    alerted.addAll(stored.alerted);
    change(this);
    try {
      final temp = File('$path.tmp');
      await temp.writeAsString(jsonEncode({
        'notAccepted': notAccepted,
        'abandoned': abandoned.toList(),
        'alerted': alerted.toList(),
      }));
      await temp.rename(path);
    } catch (e) {
      printV('Minotari send notes not saved: $e');
    }
  }
}

/// Adds the notes on send [id] to its transaction's [info]: `notAcceptedByNode` (the node's
/// reason) while cw still has it [status] pending, `abandoned`, and `minedAfterAbandon` when it
/// is in [minedAfterAbandon].
void addMinotariSendNotes(
  Map<String, dynamic> info, {
  required String id,
  required DisplayedTransactionStatus status,
  required MinotariSendNotes notes,
  required Set<String> minedAfterAbandon,
}) {
  final reason = notes.notAccepted[id];
  if (reason != null && status == DisplayedTransactionStatus.pending) {
    info['notAcceptedByNode'] = reason;
  }
  if (notes.abandoned.contains(id)) info['abandoned'] = true;
  if (minedAfterAbandon.contains(id)) info['minedAfterAbandon'] = true;
}

/// The ids of cw's [warnings] about abandoned sends that were mined after all.
List<String> minotariMinedAfterAbandon(List<AbandonWarningDto> warnings) => [
      for (final warning in warnings)
        if (warning.kind == AbandonWarningKind.minedAfterAbandon) warning.transactionId,
    ];
