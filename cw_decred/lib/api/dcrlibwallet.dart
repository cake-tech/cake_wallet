import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_decred/balance.dart';
import 'package:cw_decred/pending_transaction.dart';
import 'package:cw_decred/transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'dart:typed_data';
import 'dart:io';

// Will it work if none of these are async functions?
class SPVWallet {
  SPVWallet();

  SPVWallet create(Uint8List seed, String password, WalletInfo walletInfo) {
    return SPVWallet();
  }

  SPVWallet load(String password, String name, WalletInfo walletInfo) {
    return SPVWallet();
  }

  DecredBalance balance() {
    return DecredBalance(
      confirmed: 777,
      unconfirmed: 111,
    );
  }

  int feeRate(int priority) {
    return 1000;
  }

  int calculateEstimatedFeeWithFeeRate(int feeRate, int amount) {
    // Ideally we create a tx with wallet going to this amount and just return
    // the fee we get back.
    return 123000;
  }

  void close() {}

  DecredPendingTransaction createTransaction(Object credentials) {
    return DecredPendingTransaction(
        spv: this,
        txid:
            "3cbf3eb9523fd04e96dbaf98cdbd21779222cc8855ece8700494662ae7578e02",
        amount: 12345678,
        fee: 1234,
        rawHex: "baadbeef");
  }

  void rescan(int height) {
    sleep(Duration(seconds: 10));
  }

  void startSync() {
    sleep(Duration(seconds: 5));
  }

  SyncStatus syncStatus() {
    return SyncedSyncStatus();
  }

  int height() {
    return 400;
  }

  Map<String, DecredTransactionInfo> transactions() {
    final txInfo = DecredTransactionInfo(
      id: "3cbf3eb9523fd04e96dbaf98cdbd21779222cc8855ece8700494662ae7578e02",
      amount: 1234567,
      fee: 123,
      direction: TransactionDirection.outgoing,
      isPending: true,
      date: DateTime.now(),
      height: 0,
      confirmations: 0,
      to: "DsT4qJPPaYEuQRimfgvSKxKH3paysn1x3Nt",
    );
    return {
      "3cbf3eb9523fd04e96dbaf98cdbd21779222cc8855ece8700494662ae7578e02": txInfo
    };
  }

  String newAddress() {
    // external
    return "DsT4qJPPaYEuQRimfgvSKxKH3paysn1x3Nt";
  }

  List<String> addresses() {
    return [
      "DsT4qJPPaYEuQRimfgvSKxKH3paysn1x3Nt",
      "DsVZGfGpd7WVffBZ5wbFZEHLV3FHNmXs9Az"
    ];
  }

  List<Unspent> unspents() {
    return [
      Unspent(
          "DsT4qJPPaYEuQRimfgvSKxKH3paysn1x3Nt",
          "3cbf3eb9523fd04e96dbaf98cdbd21779222cc8855ece8700494662ae7578e02",
          1234567,
          0,
          null)
    ];
  }

  void changePassword(String newPW) {}

  void sendRawTransaction(String rawHex) {}

  String signMessage(String message, String? address) {
    return "abababababababab";
  }
}

Uint8List mnemonicToSeedBytes(String mnemonic) {
  return Uint8List(32);
}

String generateMnemonic() {
  return "maid upper strategy dove theory dream material cruel season best napkin ethics biology top episode rough hotel flight video target organ six disagree verify maid upper strategy dove theory dream material cruel season best napkin ethics biology top episode rough hotel flight video target organ six disagree verify";
}

bool validateMnemonic(String mnemonic) {
  return true;
}
