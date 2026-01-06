import 'dart:async';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

// From trade_monitor.dart -- TODO: remove unused when finished
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
// Prolly remove these, we'll see
import 'package:cake_wallet/exchange/provider/simpleswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/swapsxyz_exchange_provider.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/chainflip_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exolix_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/letsexchange_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/swaptrade_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/stealth_ex_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/xoswap_exchange_provider.dart';

// From transactions export formatter -- TODO: remove unused when finished
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:intl/intl.dart';

// KB: TODO: this approach may be intensive to run on wallets with large numbers of transactions
// We could consider an approach that runs in an isolate, but that doesn't make sense because user has taken an action
// to export transactions, so some delay is acceptable. We can optimize later if needed

/*

Seth wanted:
Swaps
  Timestamp/date
  Deposit TXID
  Amount
  From Currency -> To Currency (swap pair header row)
  Withdrawal TXID
  Amount
  Provider
  Rate
  

  
I'm considering supplementing with: 
  Block explorer, 
  Status,
  Note(?)

*/

// Standardized transaction export data class containing all exportable fields
class SwapExportData {
  SwapExportData({
    
  });

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

//   /// Formats Monero transaction with all Monero-specific fields
//   static TransactionExportData _formatMoneroTransaction(
//     TransactionInfo tx,
//     String timestamp,
//     String type,
//     String recipientAddress,
//   ) {
//     try {
//       final dynamic moneroProp = tx;

//       //final amount = moneroProp.amountFormatted?.toString() ?? 'N/A';
//       final amount = tx.amountFormatted().toString();
//       final height = moneroProp.height?.toString() ?? 'N/A';
//       final confirmations = moneroProp.confirmations?.toString() ?? 'N/A';
//       final txId = moneroProp.txHash?.toString() ?? tx.id;
//       final fee = moneroProp.feeFormatted?.toString() ?? 'N/A';
//       final subwalletNumber = moneroProp.addressIndex?.toString() ?? 'N/A';
//       final key = moneroProp.key?.toString() ?? 'N/A';
//       final note = moneroProp.note?.toString() ?? '';
//       // Override recipient address if available in Monero tx
//       if (moneroProp.recipientAddress != null &&
//           moneroProp.recipientAddress.toString().isNotEmpty) {
//         recipientAddress = moneroProp.recipientAddress.toString();
//       }

//       final explorerLink = txId != 'N/A' && txId != tx.id ? 'https://monero.com/tx/$txId' : 'N/A';
//       printV("MONERO: $amount");
//       return TransactionExportData(
//         timestamp: timestamp,
//         amount: amount,
//         type: type,
//         height: height,
//         note: note,
//         confirmations: confirmations,
//         txId: txId,
//         fee: fee,
//         subwalletNumber: subwalletNumber,
//         key: key,
//         recipientAddress: recipientAddress,
//         explorerLink: explorerLink,
//       );
//     } catch (e) {
//       return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
//     }
//   }

//   /// Formats Wownero transaction (similar to Monero)
//   static TransactionExportData _formatWowneroTransaction(
//     TransactionInfo tx,
//     String timestamp,
//     String type,
//     String recipientAddress,
//   ) {
//     try {
//       final dynamic moneroProp = tx;

//       //final amount = moneroProp.amountFormatted?.toString() ?? 'N/A';
//       final amount = tx.amountFormatted().toString();
//       final height = moneroProp.height?.toString() ?? 'N/A';
//       final confirmations = moneroProp.confirmations?.toString() ?? 'N/A';
//       final txId = moneroProp.txHash?.toString() ?? tx.id;
//       final fee = moneroProp.feeFormatted?.toString() ?? 'N/A';
//       final subwalletNumber = moneroProp.addressIndex?.toString() ?? 'N/A';
//       final key = moneroProp.key?.toString() ?? 'N/A';
//       final note = moneroProp.note?.toString() ?? '';
//       // Override recipient address if available in Monero tx
//       if (moneroProp.recipientAddress != null &&
//           moneroProp.recipientAddress.toString().isNotEmpty) {
//         recipientAddress = moneroProp.recipientAddress.toString();
//       }

//       final explorerLink = txId != 'N/A' && txId != tx.id ? 'wowNero.wow/$txId' : 'N/A';
//       printV("Wownero: $amount");
//       return TransactionExportData(
//         timestamp: timestamp,
//         amount: amount,
//         type: type,
//         height: height,
//         note: note,
//         confirmations: confirmations,
//         txId: txId,
//         fee: fee,
//         subwalletNumber: subwalletNumber,
//         key: key,
//         recipientAddress: recipientAddress,
//         explorerLink: explorerLink,
//       );
//     } catch (e) {
//       return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
//     }
//   }

//   /// Formats Bitcoin/Litecoin/Bitcoin Cash/Dogecoin transaction
//   static TransactionExportData _formatElectrumTransaction(
//     TransactionInfo tx,
//     String timestamp,
//     String type,
//     String recipientAddress,
//     WalletType walletType,
//   ) {
//     try {
//       final dynamic electrumProp = tx;

//       final amount = electrumProp.amountFormatted?.toString() ?? 'N/A';
//       final height = electrumProp.height?.toString() ?? 'N/A';
//       final confirmations = electrumProp.confirmations?.toString() ?? 'N/A';
//       final txId = tx.id;
//       final fee = electrumProp.feeFormatted?.toString() ?? 'N/A';
//       final note = electrumProp.note?.toString() ?? '';

//       // Try to get recipient from transaction
//       if (electrumProp.to != null && electrumProp.to.toString().isNotEmpty) {
//         recipientAddress = electrumProp.to.toString();
//       }

//       String explorerLink = 'N/A';
//       switch (walletType) {
//         case WalletType.bitcoin:
//           explorerLink = 'https://blockchair.com/bitcoin/transaction/$txId';
//           break;
//         case WalletType.litecoin:
//           explorerLink = 'https://blockchair.com/litecoin/transaction/$txId';
//           break;
//         case WalletType.bitcoinCash:
//           explorerLink = 'https://blockchair.com/bitcoin-cash/transaction/$txId';
//           break;
//         case WalletType.dogecoin:
//           explorerLink = 'https://blockchair.com/dogecoin/transaction/$txId';
//           break;
//         default:
//           explorerLink = 'N/A';
//       }

//       return TransactionExportData(
//         timestamp: timestamp,
//         amount: amount,
//         type: type,
//         height: height,
//         confirmations: confirmations,
//         txId: txId,
//         fee: fee,
//         subwalletNumber: 'N/A',
//         note: note,
//         key: 'N/A',
//         recipientAddress: recipientAddress,
//         explorerLink: explorerLink,
//       );
//     } catch (e) {
//       return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
//     }
//   }

//   /// Formats EVM chain transaction (Ethereum, Polygon, Arbitrum, etc)
//   static TransactionExportData _formatEVMTransaction(
//     TransactionInfo tx,
//     String timestamp,
//     String type,
//     String recipientAddress,
//     WalletType walletType,
//   ) {
//     try {
//       final dynamic evmProp = tx;

//       final amount = evmProp.amountFormatted?.toString() ?? 'N/A';
//       final height = evmProp.height?.toString() ?? 'N/A';
//       final confirmations = evmProp.confirmations?.toString() ?? 'N/A';
//       final txId = tx.id;
//       final note = evmProp.note?.toString() ?? '';
//       final fee = evmProp.feeFormatted?.toString() ?? 'N/A';

//       if (evmProp.to != null && evmProp.to.toString().isNotEmpty) {
//         recipientAddress = evmProp.to.toString();
//       }

//       String explorerLink = 'N/A';
//       switch (walletType) {
//         case WalletType.ethereum:
//           explorerLink = 'https://etherscan.io/tx/$txId';
//           break;
//         case WalletType.polygon:
//           explorerLink = 'https://polygonscan.com/tx/$txId';
//           break;
//         case WalletType.arbitrum:
//           explorerLink = 'https://arbiscan.io/tx/$txId';
//           break;
//         case WalletType.base:
//           explorerLink = 'https://basescan.org/tx/$txId';
//           break;
//         default:
//           explorerLink = 'N/A';
//       }

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

//   /// Formats Solana transaction
//   static TransactionExportData _formatSolanaTransaction(
//     TransactionInfo tx,
//     String timestamp,
//     String type,
//     String recipientAddress,
//   ) {
//     try {
//       final dynamic solanaProp = tx;

//       final amount = solanaProp.amountFormatted?.toString() ?? 'N/A';
//       final height = 'N/A'; // Solana uses slots, not traditional height
//       final confirmations = '1'; // Solana finality
//       final txId = tx.id;
//       final fee = solanaProp.feeFormatted?.toString() ?? 'N/A';
//       final note = solanaProp.note?.toString() ?? '';

//       if (solanaProp.to != null && solanaProp.to.toString().isNotEmpty) {
//         recipientAddress = solanaProp.to.toString();
//       }

//       final explorerLink = 'https://explorer.solana.com/tx/$txId';

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

//   /// Formats Tron transaction
//   static TransactionExportData _formatTronTransaction(
//     TransactionInfo tx,
//     String timestamp,
//     String type,
//     String recipientAddress,
//   ) {
//     try {
//       final dynamic tronProp = tx;

//       final amount = tronProp.amountFormatted?.toString() ?? 'N/A';
//       final height = 'N/A';
//       final confirmations = '1';
//       final txId = tx.id;
//       final fee = tronProp.feeFormatted?.toString() ?? 'N/A';
//       final note = tronProp.note?.toString() ?? '';

//       if (tronProp.to != null && tronProp.to.toString().isNotEmpty) {
//         recipientAddress = tronProp.to.toString();
//       }

//       final explorerLink = 'https://tronscan.org/#/transaction/$txId';

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

//   /// Formats Nano transaction
//   static TransactionExportData _formatNanoTransaction(
//     TransactionInfo tx,
//     String timestamp,
//     String type,
//     String recipientAddress,
//   ) {
//     try {
//       // final dynamic nanoProp = tx;

//       // final amount = nanoProp.amountFormatted?.toString() ?? 'N/A';
//       // final height = nanoProp.height?.toString() ?? 'N/A';
//       // final confirmations = nanoProp.confirmed == true ? '1' : '0';
//       // final txId = tx.id;

//       // if (nanoProp.to != null && nanoProp.to.toString().isNotEmpty) {
//       //   recipientAddress = nanoProp.to.toString();
//       // }

//       // final explorerLink = 'https://nanolooker.com/block/$txId';

//       // return TransactionExportData(
//       //   timestamp: timestamp,
//       //   amount: amount,
//       //   type: type,
//       //   height: height,
//       //   confirmations: confirmations,
//       //   txId: txId,
//       //   subwalletNumber: 'N/A',
//       //   key: 'N/A',
//       //   recipientAddress: recipientAddress,
//       //   explorerLink: explorerLink,
//       // );
//       throw UnimplementedError();
//     } catch (e) {
//       return _formatGenericTransaction(tx, timestamp, type, recipientAddress);
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
