import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/backup/backup_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/anonpay_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class CsvExportService {
  static const _columns = [
    'record_type',
    'date_time',
    'type',
    'amount',
    'currency',
    'fee',
    'tx_id',
    'address',
    'status',
    'note',
    'from_amount',
    'from_currency',
    'to_amount',
    'to_currency',
    'trade_id',
    'provider',
    'confirmations',
  ];

  static const _utf8Bom = '﻿';

  String buildCsvContent(List<ActionListItem> items) {
    final buf = StringBuffer();
    buf.write(_utf8Bom);
    buf.writeln(_columns.join(','));

    for (final item in items) {
      if (item is DateSectionItem) continue;

      final row = _buildRow(item);
      if (row != null) buf.writeln(row);
    }

    return buf.toString();
  }

  String? _buildRow(ActionListItem item) {
    if (item is TransactionListItem) return _transactionRow(item);
    if (item is TradeListItem) return _tradeRow(item);
    if (item is OrderListItem) return _orderRow(item);
    if (item is AnonpayTransactionListItem) return _anonpayRow(item);
    if (item is PayjoinTransactionListItem) return _payjoinRow(item);
    return null;
  }

  String _transactionRow(TransactionListItem item) {
    final tx = item.transaction;
    final type = tx.direction == TransactionDirection.incoming ? 'incoming' : 'outgoing';
    final status = tx.isPending ? 'pending' : 'confirmed';

    // Prefer tx.to/tx.from; fall back to address lists for chains that don't populate them.
    final address = tx.direction == TransactionDirection.incoming
        ? (tx.from?.isNotEmpty == true ? tx.from! : (tx.inputAddresses?.firstOrNull ?? ''))
        : (tx.to?.isNotEmpty == true ? tx.to! : (tx.outputAddresses?.firstOrNull ?? ''));

    final fee = tx.fee != null && !tx.fee!.isZero ? tx.fee.toString() : '';

    return _row([
      'transaction',
      _isoDate(tx.date),
      type,
      tx.amount.toString(),
      tx.amount.currency.symbol,
      fee,
      tx.id,
      address,
      status,
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      tx.confirmations.toString(),
    ]);
  }

  String _tradeRow(TradeListItem item) {
    final trade = item.trade;
    return _row([
      'trade',
      _isoDate(trade.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
      'swap',
      '',
      '',
      trade.fee?.toString() ?? '',
      trade.outputTransaction ?? '',
      trade.payoutAddress ?? '',
      trade.state.title,
      trade.memo ?? '',
      trade.amount,
      trade.from?.name ?? '',
      trade.receiveAmount ?? '',
      trade.to?.name ?? '',
      trade.id,
      trade.provider.title,
      '',
    ]);
  }

  String _orderRow(OrderListItem item) {
    final order = item.order;
    return _row([
      'order',
      _isoDate(order.createdAt),
      order.source.title,
      order.amountFormatted(),
      order.from ?? '',
      '',
      order.transferId,
      '',
      order.state.title,
      '',
      order.amountFormatted(),
      order.from ?? '',
      order.receiveAmount ?? '',
      order.to ?? '',
      order.id,
      order.providerTitle,
      '',
    ]);
  }

  String _anonpayRow(AnonpayTransactionListItem item) {
    final tx = item.transaction;
    final amount = tx.fiatAmount?.toString() ?? tx.amountTo?.toString() ?? '';
    final currency = tx.fiatEquiv ?? tx.coinTo;

    return _row([
      'anonpay',
      _isoDate(tx.createdAt),
      'anonymous_payment',
      amount,
      currency,
      '',
      tx.invoiceId,
      tx.address,
      tx.status,
      '',
      '',
      '',
      '',
      '',
      '',
      tx.provider,
      '',
    ]);
  }

  String _payjoinRow(PayjoinTransactionListItem item) {
    final session = item.session;
    final type = session.isSenderSession ? 'send' : 'receive';
    final amount = session.rawAmount ?? '0';

    return _row([
      'payjoin',
      _isoDate(session.inProgressSince ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
      type,
      amount,
      'BTC',
      '',
      session.txId ?? '',
      '',
      item.status,
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);
  }

  String _row(List<String> fields) => fields.map(escapeField).join(',');

  String escapeField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  String _isoDate(DateTime dt) => dt.toUtc().toIso8601String();

  Future<void> exportToCsv(List<ActionListItem> items, BuildContext context) async {
    final dataItems =
        items.whereType<ActionListItem>().where((e) => e is! DateSectionItem).toList();

    if (dataItems.isEmpty) {
      await showBar<void>(context, S.current.csv_nothing_to_export);
      return;
    }

    final now = DateTime.now();
    final fileName = 'cake_wallet_export_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';

    late File csvFile;

    final exportFuture = Future(() async {
      final content = buildCsvContent(items);
      csvFile = await _writeTempFile(fileName, content);
    });

    showPersistentActionOverlay(context, exportFuture, text: S.current.generating_csv);
    await exportFuture;

    if (!context.mounted) return;

    if (Platform.isAndroid) {
      _showAndroidExportDialog(context, csvFile, fileName);
    } else if (Platform.isIOS) {
      await _shareFile(csvFile, fileName, context);
    } else {
      await _saveFileDesktop(csvFile, fileName);
    }
  }

  void _showAndroidExportDialog(BuildContext context, File csvFile, String fileName) {
    showPopUp<void>(
      context: context,
      builder: (dialogContext) {
        return AlertWithTwoActions(
          alertTitle: S.current.export_csv,
          alertContent: S.current.select_destination,
          rightButtonText: S.current.save_to_downloads,
          leftButtonText: S.current.share,
          actionRightButton: () async {
            await _saveToDownloads(fileName, csvFile);
            Navigator.of(dialogContext).pop();
            await showBar<void>(context, S.current.file_saved);
            await csvFile.delete();
          },
          actionLeftButton: () async {
            Navigator.of(dialogContext).pop();
            await _shareFile(csvFile, fileName, context);
          },
        );
      },
    );
  }

  Future<void> _shareFile(File file, String fileName, BuildContext context) async {
    await ShareUtil.shareFile(filePath: file.path, fileName: fileName, context: context);
    if (await file.exists()) await file.delete();
  }

  Future<void> _saveFileDesktop(File csvFile, String fileName) async {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CSV export',
      fileName: fileName,
      lockParentWindow: true,
    );
    if (outputPath == null) return;
    await csvFile.copy(outputPath);
    await csvFile.delete();
  }

  Future<File> _writeTempFile(String fileName, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    if (file.existsSync()) file.deleteSync();
    await file.writeAsString(content, flush: true);
    return file;
  }

  Future<void> _saveToDownloads(String fileName, File file) async {
    if (!Platform.isAndroid) return;
    const downloadsPath = '/storage/emulated/0/Download';
    final dest = File('$downloadsPath/$fileName');
    if (dest.existsSync()) dest.deleteSync();
    await file.copy(dest.path);
  }
}
