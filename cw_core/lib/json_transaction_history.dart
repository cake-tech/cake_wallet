import "dart:convert";

import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/json_transaction_info.dart";
import "package:cw_core/pathForWallet.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:meta/meta.dart";

export "package:cw_core/json_transaction_info.dart";

abstract class JsonTransactionHistory<TransactionType extends JsonTransactionInfo>
    extends TransactionHistory<TransactionType> {
  JsonTransactionHistory({
    required this.walletInfo,
    required String password,
    required this.encryptionFileUtils,
  }) : _password = password;

  final WalletInfo walletInfo;
  final EncryptionFileUtils encryptionFileUtils;

  String _password;

  Future<void> _saveQueue = Future.value();

  String get fileName;

  @protected
  TransactionType? transactionFromJson(Map<String, dynamic> json);

  @protected
  bool shouldPersist(TransactionType transaction) => true;

  Future<void> init() async {
    clear();
    await load();
  }

  Future<void> changePassword(String password) async {
    _password = password;
    await save();
  }

  Future<void> save() async {
    final write = _saveQueue.then((_) async {
        await _write();
    });

    _saveQueue = write;
  }

  Future<void> _write() async {
    final serialized = <String, dynamic>{};
    for (final entry in transactions.entries) {
      if (shouldPersist(entry.value)) {
        serialized[entry.key] = entry.value.toJson();
      }
    }

    final data = json.encode({"transactions": serialized});

    await encryptionFileUtils.write(path: await _path(), password: _password, data: data);
  }

  @protected
  Future<void> prepareForLoad() async {}

  @protected
  Future<void> load() async {
    try {
      await prepareForLoad();

      final content = await _read();
      final txs = content["transactions"] as Map<String, dynamic>? ?? {};

      for (final value in txs.values) {

        final transaction = transactionFromJson(value as Map<String, dynamic>);
        if (transaction != null) {
          put(transaction.id, transaction);
        }
      }
    } catch (e) {
      printV("Error while loading ${walletInfo.type.name} transaction history: $e");
    } finally {
      markLoaded();
    }
  }

  Future<Map<String, dynamic>> _read() async {
    final content = await encryptionFileUtils.read(path: await _path(), password: _password);
    if (content.isEmpty) {
      return {};
    }
    return json.decode(content) as Map<String, dynamic>;
  }

  Future<String> _path() async => "${await pathForWalletDir(name: walletInfo.name, type: walletInfo.type)}/$fileName";
}
