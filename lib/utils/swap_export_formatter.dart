import 'dart:async';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// From trade_monitor.dart -- TODO: remove unused when finished
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
// Prolly remove these, we'll see

// From transactions export formatter -- TODO: remove unused when finished

// KB: TODO: this approach may be intensive to run on wallets with large numbers of transactions
// We could consider an approach that runs in an isolate, but that doesn't make sense because user has taken an action
// to export transactions, so some delay is acceptable. We can optimize later if needed

/*

Seth wanted:
Swaps
  Timestamp/date - got
  Deposit TXID - got
  Amount - got
  From Currency -> To Currency (swap pair header row) - got
  Withdrawal TXID - got
  Amount - got
  Provider - got
  Rate - will need to calculate from (deposit - fee) / (receive amount)
  
I'm considering supplementing with: 
  Status - this isn't easily accessed via TradeState
  Note(?)

*/

// Standardized transaction export data class containing all exportable fields
class SwapExportData {
  SwapExportData(Trade trade)
      : createdAt = trade.createdAt,
        depositTxId = trade.txId,
        amount = trade.amount,
        from = trade.from,
        to = trade.to,
        withdrawalTxId = trade.outputTransaction ?? 'N/A',
        providerName = trade.providerName,
        receiveAmount = trade.receiveAmount;

  // TODO: Consider including status

  final DateTime? createdAt;
  final String? depositTxId;
  final String amount;
  final CryptoCurrency? from, to;
  final String withdrawalTxId;
  final String? receiveAmount;
  final String? providerName;
  // Rate calculation will need to be done inside a method. I don't see us storing fees anywhere

  static String _escapeCsvField(String field) {
    if (field.contains(',') ||
        field.contains('\n') ||
        field.contains('"') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String csvHeader() {
    return 'Created At,Deposit TXID,Amount,Swap Pair,Provider Name,Withdrawal TXID,Receive Amount,Exchange Rate';
  }

  // There's a bug in the rate calculation
  static dynamic formatSwap(Trade trade) {
    final rate = (trade.receiveAmount != null &&
            trade.amount.isNotEmpty &&
            trade.receiveAmount!.isNotEmpty)
        ? (double.parse(trade.receiveAmount!) / double.parse(trade.amount)).toStringAsPrecision(16)
        : 'N/A';
    printV(rate);

    return _formatSwapData(trade, rate);
  }

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  static _formatSwapData(Trade trade, String rate) {
    final timestamp = _dateFormat.format(trade.createdAt ?? DateTime.now());
    final timestampString = "'" + timestamp;
    var responseString = [
      _escapeCsvField(timestampString),
      _escapeCsvField(trade.txId ?? 'N/A'),
      _escapeCsvField(trade.amount),
      _escapeCsvField('${trade.from?.fullName ?? 'N/A'} -> ${trade.to?.fullName ?? 'N/A'}'),
      _escapeCsvField(trade.providerName ?? 'N/A'),
      _escapeCsvField(trade.outputTransaction ?? 'N/A'),
      _escapeCsvField(trade.receiveAmount ?? 'N/A'),
      _escapeCsvField(rate),
    ].join("','");
    responseString = responseString + "'";
    return responseString;
  }
}

  /// Returns generic CSV header row
  // static String csvHeader() {
  //   return 'Timestamp,Transaction ID,Amount,Fee,Type,Block Height,Confirmations,Subwallet Number,Key,Recipient Address,Explorer Link';
  // }

  /// Escapes CSV field according to RFC 4180
  /// Wraps in quotes if contains comma, newline, or quote
  /// Doubles internal quotes

  /// Converts export data to CSV row with RFC 4180 escaping
  // String toCsvRow() {
  //   return [
  //     _escapeCsvField(timestamp),
  //     _escapeCsvField(depositTxId),
  //     _escapeCsvField(depositAmount),
  //     _escapeCsvField(swapPair),
  //     _escapeCsvField(withdrawalTxId),
  //     _escapeCsvField(withdrawalAmount),
  //     _escapeCsvField(provider),
  //     _escapeCsvField(rate),
  //     _escapeCsvField(status),
  //     _escapeCsvField(explorerLink),
  //   ].join(',');
  // }
//   final String timestamp;
//   final String txId;
//   final String amount;
//   final String fee;
//   final String type;
//   final String height;
//   final String note;
//   final String confirmations;
//   final String subwalletNumber;
//   final String key;
//   final String recipientAddress;
//   final String explorerLink;

//   /// Converts export data to CSV row with RFC 4180 escaping
//   String toCsvRow() {
//     return [
//       _escapeCsvField(timestamp),
//       _escapeCsvField(txId),
//       _escapeCsvField(amount),
//       _escapeCsvField(fee),
//       _escapeCsvField(type),
//       _escapeCsvField(height),
//       _escapeCsvField(confirmations),
//       _escapeCsvField(subwalletNumber),
//       _escapeCsvField(key),
//       _escapeCsvField(recipientAddress),
//       _escapeCsvField(explorerLink),
//     ].join(',');
//   }

//   /// Converts export data to JSON map
//   Map<String, dynamic> toJson() {
//     return {
//       'timestamp': timestamp,
//       'txId': txId,
//       'amount': amount,
//       'fee': fee,
//       'type': type,
//       'height': height,
//       'confirmations': confirmations,
//       'subwalletNumber': subwalletNumber,
//       'key': key,
//       'recipientAddress': recipientAddress,
//       'explorerLink': explorerLink,
//     };
//   }

//   /// Escapes CSV field according to RFC 4180
//   /// Wraps in quotes if contains comma, newline, or quote
//   /// Doubles internal quotes
//   static String _escapeCsvField(String field) {
//     if (field.contains(',') ||
//         field.contains('\n') ||
//         field.contains('"') ||
//         field.contains('\r')) {
//       return '"${field.replaceAll('"', '""')}"';
//     }
//     return field;
//   }

//   /// Returns generic CSV header row
//   static String csvHeader() {
//     return 'Timestamp,Transaction ID,Amount,Fee,Type,Block Height,Confirmations,Subwallet Number,Key,Recipient Address,Explorer Link';
//   }
// }

// /// Transaction export formatter utility
// class TransactionExportFormatter {
//   static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

//   /// Formats any TransactionInfo into standardized export data
//   /// Safely extracts properties based on wallet type
//   static TransactionExportData formatTransaction(
//     TransactionInfo tx,
//     WalletType walletType,
//   ) {
//     try {
//       printV(tx.amount);
//       printV(tx.amountFormatted());
//       // Format timestamp
//       final timestamp = _dateFormat.format(tx.date);

//       // Format transaction type
//       final type = tx.direction == TransactionDirection.incoming ? 'Received' : 'Sent';

//       // Format recipient address based on direction
//       String recipientAddress = 'N/A';
//       if (tx.direction == TransactionDirection.incoming) {
//         recipientAddress = 'N/A'; // Incoming transactions don't have recipient
//       } else {
//         // Try to get recipient address from transaction-specific fields
//         recipientAddress = _extractRecipientAddress(tx) ?? 'Not known';
//       }

//       // Extract wallet-type-specific fields
//       switch (walletType) {
//         case WalletType.monero:
//           return _formatMoneroTransaction(tx, timestamp, type, recipientAddress);
//         case WalletType.wownero:
//           return _formatWowneroTransaction(tx, timestamp, type, recipientAddress);
//         case WalletType.bitcoin:
//         case WalletType.litecoin:
//         case WalletType.bitcoinCash:
//         case WalletType.dogecoin:
//           return _formatElectrumTransaction(tx, timestamp, type, recipientAddress, walletType);
//         case WalletType.ethereum:
//         case WalletType.polygon:
//         case WalletType.arbitrum:
//         case WalletType.base:
//           return _formatEVMTransaction(tx, timestamp, type, recipientAddress, walletType);
//         case WalletType.solana:
//           return _formatSolanaTransaction(tx, timestamp, type, recipientAddress);
//         case WalletType.tron:
//           return _formatTronTransaction(tx, timestamp, type, recipientAddress);
//         case WalletType.nano:
//         case WalletType.banano:
//           return _formatNanoTransaction(tx, timestamp, type, recipientAddress);
//         case WalletType.decred:
//           return _formatDecredTransaction(tx, timestamp, type, recipientAddress);
//         default:
//           return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
//       }
//     } catch (e) {
//       // Fallback to generic formatting if specific formatting fails
//       return _formatGenericTransaction(
//         tx,
//         _dateFormat.format(tx.date),
//         tx.direction == TransactionDirection.incoming ? 'Received' : 'Sent',
//         'Not known',
//       );
//     }
//   }
//   /// Formats Decred transaction
//   static TransactionExportData _formatDecredTransaction(
//     TransactionInfo tx,
//     String timestamp,
//     String type,
//     String recipientAddress,
//   ) {
//     try {
//       final dynamic decredProp = tx;

//       final amount = decredProp.amountFormatted?.toString() ?? 'N/A';
//       final height = decredProp.height?.toString() ?? 'N/A';
//       final confirmations = decredProp.confirmations?.toString() ?? 'N/A';
//       final txId = tx.id;
//       final fee = decredProp.feeFormatted?.toString() ?? 'N/A';
//       final note = decredProp.note?.toString() ?? '';

//       if (decredProp.address != null && decredProp.address.toString().isNotEmpty) {
//         recipientAddress = decredProp.address.toString();
//       }

//       final explorerLink = 'https://dcrdata.decred.org/tx/$txId';

//       return TransactionExportData(
//         timestamp: timestamp,
//         amount: amount,
//         type: type,
//         height: height,
//         note: note,
//         confirmations: confirmations,
//         txId: txId,
//         fee: fee,
//         subwalletNumber: 'N/A',
//         key: 'N/A',
//         recipientAddress: recipientAddress,
//         explorerLink: explorerLink,
//       );
//     } catch (e) {
//       return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
//     }
//   }

//   /// Generic fallback formatter for unknown or unsupported wallet types
//   static TransactionExportData _formatGenericTransaction(
//     TransactionInfo tx,
//     String timestamp,
//     String type,
//     String recipientAddress,
//   ) {
//     // To be finished

//     return TransactionExportData(
//       timestamp: timestamp,
//       amount: 'N/A',
//       type: type,
//       height: 'N/A',
//       note: '',
//       confirmations: 'N/A',
//       txId: tx.id,
//       fee: 'N/A',
//       subwalletNumber: 'N/A',
//       key: 'N/A',
//       recipientAddress: recipientAddress,
//       explorerLink: 'N/A',
//     );
//   }

//   /// Attempts to extract recipient address from transaction based on generic field names
//   static String? _extractRecipientAddress(TransactionInfo tx) {
//     try {
//       final dynamic txProp = tx;

//       // Try common field names
//       if (txProp.to != null && txProp.to.toString().isNotEmpty) {
//         return txProp.to.toString();
//       }
//       if (txProp.recipientAddress != null && txProp.recipientAddress.toString().isNotEmpty) {
//         return txProp.recipientAddress.toString();
//       }
//       if (txProp.address != null && txProp.address.toString().isNotEmpty) {
//         return txProp.address.toString();
//       }

//       return null;
//     } catch (e) {
//       return null;
//     }
//   }
// }
