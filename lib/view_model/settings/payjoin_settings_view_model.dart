import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'payjoin_settings_view_model.g.dart';

class PayjoinSettingsViewModel = PayjoinSettingsViewModelBase
    with _$PayjoinSettingsViewModel;

abstract class PayjoinSettingsViewModelBase with Store {
  PayjoinSettingsViewModelBase(this._settingsStore, this._wallet);

  final SettingsStore _settingsStore;
  final WalletBase _wallet;

  WalletType get _walletType => _wallet.type;
  String get _walletName => _wallet.name;
  String get _walletId => _wallet.id;

  @computed
  bool get usePayjoin => _settingsStore.usePayjoin;

  @action
  void setUsePayjoin(bool value) {
    _settingsStore.usePayjoin = value;
    bitcoin!.updatePayjoinState(_wallet, value);
  }

  Future<String> getAbbreviatedLogs() async {
    final path = await pathForWalletDir(name: _walletName, type: _walletType);
    final logFile = File("$path/payjoin.log");
    final buf = StringBuffer();

    buf.writeln('=== Payjoin Sessions ===');
    buf.writeln('Wallet: $_walletName ($_walletType)');
    buf.writeln('');

    try {
      final box = await CakeHive.openBox<PayjoinSession>(PayjoinSession.boxName);
      final allSessions = box.values.toList();
      final sessions = allSessions.where((s) => s.walletId == _walletId).toList();
      buf.writeln('Total sessions: ${allSessions.length}');
      buf.writeln('Sessions for this wallet: ${sessions.length}');

      if (sessions.isNotEmpty) {
        buf.writeln('');
        buf.writeln('--- Session Data ---');
        for (final session in sessions) {
          buf.writeln('');
          buf.writeln(
              'Direction: ${session.isSenderSession ? "Sender (outgoing)" : "Receiver (incoming)"}');
          buf.writeln('Status: ${session.status}');
          buf.writeln('URI: ${session.pjUri ?? "-"}');
          buf.writeln('Receiver: ${session.receiver ?? "-"}');
          buf.writeln('Sender: ${session.sender ?? "-"}');
          buf.writeln('Amount: ${session.rawAmount ?? "-"}');
          buf.writeln('TxID: ${session.txId ?? "-"}');
          buf.writeln('Used Fallback: ${session.usedFallback}');
          buf.writeln('Error: ${session.error ?? "-"}');

          try {
            final eventsBox = await CakeHive.openBox<String>('PayjoinSessionEvents');
            final eventKey = session.isSenderSession
                ? 'send_${session.pjUri}'
                : 'recv_${session.receiver}';
            final raw = eventsBox.get(eventKey);
            if (raw != null) {
              final events = List<String>.from(jsonDecode(raw) as List);
              if (events.isNotEmpty) {
                buf.writeln('Protocol Events:');
                for (final event in events) {
                  buf.writeln('  $event');
                }
              }
            }
          } catch (_) {}
        }
        buf.writeln('');
        buf.writeln('--- End Session Data ---');
      }
    } catch (_) {}

    if (await logFile.exists()) {
      buf.writeln('');
      buf.writeln('--- Raw Payjoin Log ---');
      buf.writeln(await logFile.readAsString());
    }

    final logs = buf.toString();
    return logs.length > 10000 ? logs.substring(logs.length - 10000) : logs;
  }

  Future<File> getPayjoinLogFile() async {
    final path = await pathForWalletDir(name: _walletName, type: _walletType);
    final logFile = File("$path/payjoin.log");
    final buf = StringBuffer();

    buf.writeln('=== Payjoin Export ===');
    buf.writeln('Wallet: $_walletName ($_walletType)');
    buf.writeln('Wallet ID: $_walletId');
    buf.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buf.writeln('');

    try {
      final box = await CakeHive.openBox<PayjoinSession>(PayjoinSession.boxName);
      final allSessions = box.values.toList();
      final sessions = allSessions.where((s) => s.walletId == _walletId).toList();
      buf.writeln('Total sessions in Hive box: ${allSessions.length}');
      buf.writeln('Sessions for this wallet: ${sessions.length}');
      buf.writeln('Sessions for other wallets: ${allSessions.length - sessions.length}');
      if (sessions.isNotEmpty) {
        buf.writeln('');
        buf.writeln('--- Session Data ---');
        for (final session in sessions) {
          buf.writeln('');
          buf.writeln(
              'Direction: ${session.isSenderSession ? "Sender (outgoing)" : "Receiver (incoming)"}');
          buf.writeln('Status: ${session.status}');
          buf.writeln('URI: ${session.pjUri ?? "-"}');
          buf.writeln('Receiver: ${session.receiver ?? "-"}');
          buf.writeln('Sender: ${session.sender ?? "-"}');
          buf.writeln('Amount: ${session.rawAmount ?? "-"}');
          buf.writeln('TxID: ${session.txId ?? "-"}');
          buf.writeln('Used Fallback: ${session.usedFallback}');
          buf.writeln('Error: ${session.error ?? "-"}');

          try {
            final eventsBox = await CakeHive.openBox<String>('PayjoinSessionEvents');
            final eventKey = session.isSenderSession
                ? 'send_${session.pjUri}'
                : 'recv_${session.receiver}';
            final raw = eventsBox.get(eventKey);
            if (raw != null) {
              final events = List<String>.from(jsonDecode(raw) as List);
              if (events.isNotEmpty) {
                buf.writeln('Protocol Events:');
                for (final event in events) {
                  buf.writeln('  $event');
                }
              }
            }
          } catch (_) {}
        }
        buf.writeln('');
        buf.writeln('--- End Session Data ---');
      }
    } catch (_) {}

    if (await logFile.exists()) {
      buf.writeln('');
      buf.writeln('--- Raw Payjoin Log ---');
      buf.writeln(await logFile.readAsString());
    }

    final exportPath = "$path/payjoin_export.txt";
    await File(exportPath).writeAsString(buf.toString());
    return File(exportPath);
  }
}
