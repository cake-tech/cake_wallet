import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:intl/intl.dart';

// KB: TODO: this approach is not ideal for wallets with large numbers of transactions
// TODO: should we add a balance at time of transaction field?

/*

Seth wanted:
Transactions
  Timestamp/date
  TXID
  Amount
  Fee amount
  Currency
  Note

I've also included
  Type (Sent/Received)
  Block Height
  Subwallet Number
  Key (index)
  Recipient Address (if applicable)
  Tx Explorer Links

Swaps
  See swap_export_formatter.dart
*/

/// Standardized transaction export data class containing all exportable fields
class TransactionExportData {
  TransactionExportData({
    required this.timestamp,
    required this.txId,
    required this.amount,
    required this.fee,
    required this.type,
    required this.height,
    required this.note,
    required this.confirmations,
    required this.subwalletNumber,
    required this.key,
    required this.recipientAddress,
    required this.explorerLink,
  });

  final String timestamp;
  final String txId;
  final String amount;
  final String fee;
  final String type;
  final String height;
  final String note;
  final String confirmations;
  final String subwalletNumber;
  final String key;
  final String recipientAddress;
  final String explorerLink;

  /// Converts export data to CSV row with RFC 4180 escaping
  String toCsvRow() {
    return [
      _escapeCsvField(timestamp),
      _escapeCsvField(txId),
      _escapeCsvField(amount),
      _escapeCsvField(fee),
      _escapeCsvField(type),
      _escapeCsvField(height),
      _escapeCsvField(confirmations),
      _escapeCsvField(subwalletNumber),
      _escapeCsvField(key),
      _escapeCsvField(recipientAddress),
      _escapeCsvField(explorerLink),
      "\n"
    ].join("','");
  }

  /// Converts export data to JSON map
  // KB: TODO: Either remove or use for debugging
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'txId': txId,
      'amount': amount,
      'fee': fee,
      'type': type,
      'height': height,
      'confirmations': confirmations,
      'subwalletNumber': subwalletNumber,
      'key': key,
      'recipientAddress': recipientAddress,
      'explorerLink': explorerLink,
    };
  }

  /// Escapes CSV field according to RFC 4180
  /// Wraps in quotes if contains comma, newline, or quote
  /// Doubles internal quotes
  static String _escapeCsvField(String field) {
    if (field.contains(',') ||
        field.contains('\n') ||
        field.contains('"') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Returns generic CSV header row
  static String csvHeader() {
    return 'Timestamp,Transaction ID,Amount,Fee,Type,Block Height,Confirmations,Subwallet Number,Key,Recipient Address,Explorer Link';
  }
}

/// Transaction export formatter utility
class TransactionExportFormatter {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String _escapeCsvField(String field) {
    if (field.contains(',') ||
        field.contains('\n') ||
        field.contains('"') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Formats any TransactionInfo into standardized export data
  /// Safely extracts properties based on wallet type
  static String formatTransaction(
    TransactionInfo tx,
    WalletType walletType,
  ) {
    try {
      // Format timestamp
      final timestamp = _dateFormat.format(tx.date);
      printV("Timestamp: $timestamp");
      final timeString = '"$timestamp';
      // Format transaction type
      final type = tx.direction == TransactionDirection.incoming ? 'Received' : 'Sent';

      // Format recipient address based on direction
      String recipientAddress = 'N/A';
      if (tx.direction == TransactionDirection.incoming) {
        recipientAddress = 'N/A'; // Incoming transactions don't have recipient
      } else {
        // Try to get recipient address from transaction-specific fields
        recipientAddress = _extractRecipientAddress(tx) ?? 'Not known';
      }

      printV("Figure out what we're processing this as for wallet type: $walletType");
      // Extract wallet-type-specific fields
      switch (walletType) {
        case WalletType.monero:
          return _formatMoneroTransaction(tx, timestamp, type, recipientAddress);
        case WalletType.wownero:
          return _formatWowneroTransaction(tx, timestamp, type, recipientAddress);
        case WalletType.bitcoin:
        case WalletType.litecoin:
        case WalletType.bitcoinCash:
        case WalletType.dogecoin:
          return _formatElectrumTransaction(tx, timestamp, type, recipientAddress, walletType);
        case WalletType.ethereum:
        case WalletType.polygon:
        case WalletType.arbitrum:
        case WalletType.base:
          return _formatEVMTransaction(tx, timestamp, type, recipientAddress, walletType);
        case WalletType.solana:
          return _formatSolanaTransaction(tx, timestamp, type, recipientAddress);
        case WalletType.tron:
          return _formatTronTransaction(tx, timestamp, type, recipientAddress);
        case WalletType.nano:
        case WalletType.banano:
          return _formatNanoTransaction(tx, timestamp, type, recipientAddress);
        case WalletType.decred:
          return _formatDecredTransaction(tx, timestamp, type, recipientAddress);
        default:
          return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
      }
    } catch (e) {
      return _formatGenericTransaction(
        tx,
        _dateFormat.format(tx.date),
        tx.direction == TransactionDirection.incoming ? 'Received' : 'Sent',
        'Not known',
      );
    }
  }

  /// Formats Monero transaction with all Monero-specific fields
  static String _formatMoneroTransaction(
    TransactionInfo tx,
    String timestamp,
    String type,
    String recipientAddress,
  ) {
    try {
      final dynamic moneroProp = tx;

      //final amount = moneroProp.amount?.toString() ?? 'N/A';
      final amount = tx.amountFormatted().toString();
      final height = tx.height.toString();
      //final confirmations = moneroProp.confirmations?.toString() ?? 'N/A';
      final txId = tx.txHash.toString();
      final fee = moneroProp.feeFormatted().toString();
      final subwalletNumber = moneroProp.addressIndex.toString();
      final key = moneroProp.key.toString();
      //final note = moneroProp.note?.toString() ?? '';
      // Override recipient address if available in Monero tx
      if (moneroProp.recipientAddress != null &&
          moneroProp.recipientAddress.toString().isNotEmpty) {
        recipientAddress = moneroProp.recipientAddress.toString();
      }

      final explorerLink = 'https://monero.com/tx/$txId';
      final formattedData = [
        _escapeCsvField(timestamp),
        _escapeCsvField(amount),
        _escapeCsvField(type),
        _escapeCsvField(height),
        //_escapeCsvField(note),
        _escapeCsvField(txId),
        _escapeCsvField(fee),
        _escapeCsvField(subwalletNumber),
        _escapeCsvField(key),
        _escapeCsvField(recipientAddress),
        _escapeCsvField(explorerLink),
      ].join("','");

      var formattedString = "'" + formattedData + "'";
      return formattedString;
    } catch (e) {
      // rethrow;
      return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
    }
  }

  /// Formats Wownero transaction (similar to Monero)
  static String _formatWowneroTransaction(
    TransactionInfo tx,
    String timestamp,
    String type,
    String recipientAddress,
  ) {
    // throw UnimplementedError("TODO: Implement Wownero transaction formatting");
    try {
      final dynamic wowneroProp = tx;

      final amount = tx.amountFormatted().toString();
      final height = tx.height.toString();
      final txId = tx.txHash.toString();
      final fee = wowneroProp.feeFormatted().toString();
      final subwalletNumber = wowneroProp.addressIndex.toString();
      final key = wowneroProp.key.toString();
      // final note = wowneroProp.note?.toString() ?? '';
      // Override recipient address if available in tx
      if (wowneroProp.recipientAddress != null &&
          wowneroProp.recipientAddress.toString().isNotEmpty) {
        recipientAddress = wowneroProp.recipientAddress.toString();
      }

      final explorerLink = 'https://explore.wownero.com/tx/$txId';
      final formattedData = [
        _escapeCsvField(timestamp),
        _escapeCsvField(amount),
        _escapeCsvField(type),
        _escapeCsvField(height),
        //_escapeCsvField(note),
        _escapeCsvField(txId),
        _escapeCsvField(fee),
        _escapeCsvField(subwalletNumber),
        _escapeCsvField(key),
        _escapeCsvField(recipientAddress),
        _escapeCsvField(explorerLink),
      ].join("','");

      var formattedString = "'" + formattedData + "'";
      return formattedString;
    } catch (e) {
      return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
    }
  }

  /// Formats Bitcoin/Litecoin/Bitcoin Cash/Dogecoin transaction
  static String _formatElectrumTransaction(
    TransactionInfo tx,
    String timestamp,
    String type,
    String recipientAddress,
    WalletType walletType,
  ) {
    try {
      final dynamic electrumProp = tx;

      final amount = tx.amountFormatted().toString() ?? 'N/A';
      final height = tx.height.toString() ?? 'N/A';
      // final confirmations = tx.confirmations?.toString() ?? 'N/A';
      final txId = tx.txHash.toString();
      final fee = electrumProp.feeFormatted().toString();
      final subwalletNumber = electrumProp.key.toString();
      final key = electrumProp.key.toString();
      // final note = electrumProp.note?.toString() ?? '';
      // Try to get recipient from transaction
      if (electrumProp.to != null && electrumProp.to.toString().isNotEmpty) {
        recipientAddress = electrumProp.to.toString();
      }

      String explorerLink = 'N/A';
      switch (walletType) {
        case WalletType.bitcoin:
          explorerLink = 'https://blockchair.com/bitcoin/transaction/$txId';
          break;
        case WalletType.litecoin:
          explorerLink = 'https://blockchair.com/litecoin/transaction/$txId';
          break;
        case WalletType.bitcoinCash:
          explorerLink = 'https://blockchair.com/bitcoin-cash/transaction/$txId';
          break;
        case WalletType.dogecoin:
          explorerLink = 'https://blockchair.com/dogecoin/transaction/$txId';
          break;
        default:
          explorerLink = 'N/A';
      }

      final formattedData = [
        _escapeCsvField(timestamp),
        _escapeCsvField(amount),
        _escapeCsvField(type),
        _escapeCsvField(height),
        //_escapeCsvField(note),
        _escapeCsvField(txId),
        _escapeCsvField(fee),
        _escapeCsvField(subwalletNumber),
        _escapeCsvField(key),
        _escapeCsvField(recipientAddress),
        _escapeCsvField(explorerLink),
      ].join("','");

      var formattedString = "'" + formattedData + "'";
      return formattedString;
    } catch (e) {
      return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
    }
  }

  /// Formats EVM chain transaction (Ethereum, Polygon, Arbitrum, etc)
  static String _formatEVMTransaction(
    TransactionInfo tx,
    String timestamp,
    String type,
    String recipientAddress,
    WalletType walletType,
  ) {
    try {
      final dynamic evmProp = tx;

      final amount = tx.amountFormatted().toString();
      final height = tx.height.toString();
      //final confirmations = tx.confirmations?.toString() ?? 'N/A';
      final txId = tx.id;
      // final note = tx.note?.toString() ?? '';
      final fee = evmProp.feeFormatted?.toString() ?? 'N/A';
      final subwalletNumber = evmProp.addressIndex.toString();
      final key = evmProp.key.toString();

      if (evmProp.to != null && evmProp.to.toString().isNotEmpty) {
        recipientAddress = evmProp.recipientAddress.toString();
      }

      String explorerLink = 'N/A';
      switch (walletType) {
        case WalletType.ethereum:
          explorerLink = 'https://etherscan.io/tx/$txId';
          break;
        case WalletType.polygon:
          explorerLink = 'https://polygonscan.com/tx/$txId';
          break;
        case WalletType.arbitrum:
          explorerLink = 'https://arbiscan.io/tx/$txId';
          break;
        case WalletType.base:
          explorerLink = 'https://basescan.org/tx/$txId';
          break;
        default:
          explorerLink = 'N/A';
      }

      final formattedData = [
        _escapeCsvField(timestamp),
        _escapeCsvField(amount),
        _escapeCsvField(type),
        _escapeCsvField(height),
        //_escapeCsvField(note),
        _escapeCsvField(txId),
        _escapeCsvField(fee),
        _escapeCsvField(subwalletNumber),
        _escapeCsvField(key),
        _escapeCsvField(recipientAddress),
        _escapeCsvField(explorerLink),
      ].join("','");

      var formattedString = "'" + formattedData + "'";
      return formattedString;
    } catch (e) {
      return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
    }
  }

  /// Formats Solana transaction
  static String _formatSolanaTransaction(
    TransactionInfo tx,
    String timestamp,
    String type,
    String recipientAddress,
  ) {
    try {
      final dynamic solanaProp = tx;

      final amount = tx.amountFormatted().toString();
      final height = tx.height.toString();
      //final confirmations = moneroProp.confirmations?.toString() ?? 'N/A';
      final txId = tx.txHash.toString();
      final fee = solanaProp.feeFormatted().toString();
      final subwalletNumber = solanaProp.addressIndex.toString();
      final key = solanaProp.key.toString();

      if (solanaProp.recipientAddress != null && solanaProp.recipientAddress.toString().isNotEmpty) {
        recipientAddress = solanaProp.recipientAddress.toString();
      }

      final explorerLink = 'https://explorer.solana.com/tx/$txId';

     final formattedData = [
        _escapeCsvField(timestamp),
        _escapeCsvField(amount),
        _escapeCsvField(type),
        _escapeCsvField(height),
        //_escapeCsvField(note),
        _escapeCsvField(txId),
        _escapeCsvField(fee),
        _escapeCsvField(subwalletNumber),
        _escapeCsvField(key),
        _escapeCsvField(recipientAddress),
        _escapeCsvField(explorerLink),
      ].join("','");

      var formattedString = "'" + formattedData + "'";
      return formattedString;
    } catch (e) {
      return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
    }
  }

  /// Formats Tron transaction
  static String _formatTronTransaction(
    TransactionInfo tx,
    String timestamp,
    String type,
    String recipientAddress,
  ) {
    try {
      final dynamic tronProp = tx;
      final amount = tx.amountFormatted().toString();
      final height = tx.height.toString();
      //final confirmations = moneroProp.confirmations?.toString() ?? 'N/A';
      final txId = tx.txHash.toString();
      final fee = tronProp.feeFormatted().toString();
      final subwalletNumber = tronProp.addressIndex.toString();
      final key = tronProp.key.toString();
      //final note = tronProp.note?.toString() ?? '';
      if (tronProp.recipientAddress != null &&
          tronProp.recipientAddress.toString().isNotEmpty) {
        recipientAddress = tronProp.recipientAddress.toString();
      }

      final explorerLink = 'https://tronscan.org/#/transaction/$txId';
      final formattedData = [
        _escapeCsvField(timestamp),
        _escapeCsvField(amount),
        _escapeCsvField(type),
        _escapeCsvField(height),
        //_escapeCsvField(note),
        _escapeCsvField(txId),
        _escapeCsvField(fee),
        _escapeCsvField(subwalletNumber),
        _escapeCsvField(key),
        _escapeCsvField(recipientAddress),
        _escapeCsvField(explorerLink),
      ].join("','");

      var formattedString = "'" + formattedData + "'";
      return formattedString;
    } catch (e) {
      // rethrow;
      return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
    }
  }

  /// Formats Nano transaction
  static String _formatNanoTransaction(
    TransactionInfo tx,
    String timestamp,
    String type,
    String recipientAddress,
  ) {
    try {
      // final dynamic nanoProp = tx;

      // final amount = nanoProp.amountFormatted?.toString() ?? 'N/A';
      // final height = nanoProp.height?.toString() ?? 'N/A';
      // final confirmations = nanoProp.confirmed == true ? '1' : '0';
      // final txId = tx.id;

      // if (nanoProp.to != null && nanoProp.to.toString().isNotEmpty) {
      //   recipientAddress = nanoProp.to.toString();
      // }

      // final explorerLink = 'https://nanolooker.com/block/$txId';

      // return TransactionExportData(
      //   timestamp: timestamp,
      //   amount: amount,
      //   type: type,
      //   height: height,
      //   confirmations: confirmations,
      //   txId: txId,
      //   subwalletNumber: 'N/A',
      //   key: 'N/A',
      //   recipientAddress: recipientAddress,
      //   explorerLink: explorerLink,
      // );
      throw UnimplementedError();
    } catch (e) {
      return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
    }
  }

  /// Formats Decred transaction
  static String _formatDecredTransaction(
    TransactionInfo tx,
    String timestamp,
    String type,
    String recipientAddress,
  ) {
    try {
      final dynamic decredProp = tx;

      final amount = tx.amountFormatted().toString();
      final height = tx.height.toString();
      final txId = tx.txHash.toString();
      final fee = decredProp.feeFormatted().toString();
      final subwalletNumber = decredProp.addressIndex.toString();
      final key = decredProp.key.toString();
      if (decredProp.recipientAddress != null &&
          decredProp.recipientAddress.toString().isNotEmpty) {
        recipientAddress = decredProp.recipientAddress.toString();
      }

      final explorerLink = 'https://dcrdata.decred.org/tx/$txId';
      final formattedData = [
        _escapeCsvField(timestamp),
        _escapeCsvField(amount),
        _escapeCsvField(type),
        _escapeCsvField(height),
        //_escapeCsvField(note),
        _escapeCsvField(txId),
        _escapeCsvField(fee),
        _escapeCsvField(subwalletNumber),
        _escapeCsvField(key),
        _escapeCsvField(recipientAddress),
        _escapeCsvField(explorerLink),
      ].join("','");

      var formattedString = "'" + formattedData + "'";
      return formattedString;

    } catch (e) {
      return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
    }
  }

  /// Generic fallback formatter for unknown or unsupported wallet types
  static String _formatGenericTransaction(
    TransactionInfo tx,
    String timestamp,
    String type,
    String recipientAddress,
  ) {
    // To be finished

    try {

      final dynamic genericProp = tx;

      //final amount = genericProp.amount?.toString() ?? 'N/A';
      final amount = tx.amountFormatted().toString();
      final height = tx.height.toString();
      //final confirmations = genericProp.confirmations?.toString() ?? 'N/A';
      final txId = tx.txHash.toString();
      final fee = genericProp.feeFormatted().toString();
      final subwalletNumber = genericProp.addressIndex.toString();
      final key = genericProp.key.toString();
      //final note = genericProp.note?.toString() ?? '';
      // Override recipient address if available in generic tx
      if (genericProp.recipientAddress != null &&
          genericProp.recipientAddress.toString().isNotEmpty) {
        recipientAddress = genericProp.recipientAddress.toString();
      }

      final explorerLink = 'N/A';

      final formattedData = [
        _escapeCsvField(timestamp),
        _escapeCsvField(amount),
        _escapeCsvField(type),
        _escapeCsvField(height),
        //_escapeCsvField(note),
        _escapeCsvField(txId),
        _escapeCsvField(fee),
        _escapeCsvField(subwalletNumber),
        _escapeCsvField(key),
        _escapeCsvField(recipientAddress),
        _escapeCsvField(explorerLink),
      ].join("','");

      var formattedString = "'" + formattedData + "'";
      return formattedString;
    } catch (e) {
      // rethrow;
      return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
    }
  }

  /// Attempts to extract recipient address from transaction based on generic field names
  static String? _extractRecipientAddress(TransactionInfo tx) {
    try {
      final dynamic txProp = tx;

      // Try common field names
      if (txProp.to != null && txProp.to.toString().isNotEmpty) {
        return txProp.to.toString();
      }
      if (txProp.recipientAddress != null && txProp.recipientAddress.toString().isNotEmpty) {
        return txProp.recipientAddress.toString();
      }
      if (txProp.address != null && txProp.address.toString().isNotEmpty) {
        return txProp.address.toString();
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
