import 'dart:io' show Platform, File, Directory;

import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart' show ClipboardData;
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import 'package:cake_wallet/utils/clipboard_util.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/utils/transaction_export_formatter.dart';
import 'package:cake_wallet/utils/swap_export_formatter.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cake_wallet/generated/i18n.dart';

class ExportHistoryService {
  /// Generates CSV string from wallet transactions
  static String generateTransactionCSV({
    required WalletBase wallet,
  }) {
    final allTransactions = wallet.transactionHistory.transactions.values.toList();

    // Sort transactions chronologically (oldest first)
    final sortedTransactions = [...allTransactions]..sort((a, b) => a.date.compareTo(b.date));

    // Format transactions
    final formattedData = sortedTransactions.map((tx) {
      return TransactionExportFormatter.formatTransaction(tx, wallet.type);
    }).toList();

    // Build CSV string
    final buffer = StringBuffer();
    buffer.writeln(TransactionExportData.csvHeader());

    for (final data in formattedData) {
      buffer.writeln(data);
    }

    return buffer.toString();
  }

  /// Generates CSV string from wallet swaps/trades
  static String generateSwapCSV({
    required TradesStore tradesStore,
    required String walletId,
  }) {
    final swaps = tradesStore.trades
        .where((trade) => trade.trade.walletId == walletId)
        .toList();

    final buffer = StringBuffer();
    buffer.writeln(SwapExportData.csvHeader());

    for (final data in swaps) {
      buffer.writeln(SwapExportData.formatSwap(data.trade));
    }

    return buffer.toString();
  }

  /// Generates combined CSV string with both transactions and swaps
  static String generateCombinedCSV({
    required WalletBase wallet,
    required TradesStore tradesStore,
  }) {
    final transactionCSV = generateTransactionCSV(wallet: wallet);
    final swapCSV = generateSwapCSV(tradesStore: tradesStore, walletId: wallet.id);

    final buffer = StringBuffer();
    
    // Add transaction section
    buffer.writeln('=== TRANSACTIONS ===');
    buffer.write(transactionCSV);
    buffer.writeln();
    
    // Add swaps section
    buffer.writeln('=== SWAPS ===');
    buffer.write(swapCSV);

    return buffer.toString();
  }

  /// Exports combined transaction and swap data to clipboard
  static Future<bool> exportToClipboard({
    required WalletBase wallet,
    required TradesStore tradesStore,
    BuildContext? context,
  }) async {
    try {
      final csvContent = generateCombinedCSV(wallet: wallet, tradesStore: tradesStore);

      await ClipboardUtil.setSensitiveDataToClipboard(ClipboardData(text: csvContent));

      if (context != null) {
        Fluttertoast.showToast(
          msg: S.of(context).copied_to_clipboard,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }

      return true;
    } catch (e) {
      printV('Error copying to clipboard: $e');
      if (context != null) {
        Fluttertoast.showToast(
          msg: 'Export failed: ${e.toString()}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
      return false;
    }
  }

  /// Saves CSV data to file (platform-specific handling)
  static Future<bool> saveToFile({
    required String csvContent,
    required String walletName,
    BuildContext? context,
  }) async {
    try {
      final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final timestamp = formatter.format(DateTime.now());
      final fileName = 'cakewallet_history_${walletName}_$timestamp.csv';

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Desktop: Use file picker
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV Export',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsString(csvContent);

          if (context != null) {
            Fluttertoast.showToast(
              msg: 'Export saved successfully',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
          return true;
        }
        return false;
      } else if (Platform.isAndroid) {
        // Android: Save to Downloads folder
        const downloadDirPath = '/storage/emulated/0/Download';
        final filePath = '$downloadDirPath/$fileName';
        final file = File(filePath);

        if (file.existsSync()) {
          file.deleteSync();
        }
        await file.writeAsString(csvContent);

        if (context != null) {
          Fluttertoast.showToast(
            msg: 'Export saved to Downloads',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
        return true;
      } else if (Platform.isIOS) {
        // iOS: Save to temp and share
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsString(csvContent);

        if (context != null) {
          await ShareUtil.shareFile(
            filePath: tempFile.path,
            fileName: fileName,
            context: context,
          );

          // Clean up temp file
          if (tempFile.existsSync()) {
            tempFile.deleteSync();
          }
        }
        return true;
      }

      return false;
    } catch (e) {
      printV('Error saving CSV file: $e');
      if (context != null) {
        Fluttertoast.showToast(
          msg: 'Export failed: ${e.toString()}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
      return false;
    }
  }

  /// Shares CSV data via share dialog (platform-specific handling)
  static Future<bool> shareFile({
    required String csvContent,
    required String walletName,
    required BuildContext context,
  }) async {
    try {
      final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final timestamp = formatter.format(DateTime.now());
      final fileName = 'cakewallet_history_${walletName}_$timestamp.csv';

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(csvContent);

      await ShareUtil.shareFile(
        filePath: tempFile.path,
        fileName: fileName,
        context: context,
      );

      // Clean up temp file after a delay to ensure sharing is complete
      Future.delayed(Duration(seconds: 2), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });

      return true;
    } catch (e) {
      printV('Error sharing CSV file: $e');
      Fluttertoast.showToast(
        msg: 'Export failed: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }
  }
}
