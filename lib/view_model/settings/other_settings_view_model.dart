import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/package_info.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'other_settings_view_model.g.dart';

class OtherSettingsViewModel = OtherSettingsViewModelBase with _$OtherSettingsViewModel;

abstract class OtherSettingsViewModelBase with Store {
  OtherSettingsViewModelBase(this._settingsStore, this._wallet, this.sendViewModel)
      : walletType = _wallet.type,
        chainId = _wallet.chainId,
        currentVersion = '' {
    PackageInfo.fromPlatform()
        .then((PackageInfo packageInfo) => currentVersion = packageInfo.version);

    final priority = _settingsStore.getPriority(_wallet.type, chainId: _wallet.chainId);
    final priorities = priorityForWalletType(_wallet.type);

    if (!priorities.contains(priority) && priorities.isNotEmpty) {
      _settingsStore.setPriority(_wallet.type, priorities.first, chainId: _wallet.chainId);
    }
  }

  final WalletType walletType;
  final int? chainId;
  final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> _wallet;

  @observable
  String currentVersion;

  final SettingsStore _settingsStore;
  final SendViewModel sendViewModel;

  @computed
  TransactionPriority get transactionPriority {
    final priority = _settingsStore.getPriority(walletType, chainId: chainId);

    if (priority == null) {
      throw Exception('Unexpected type ${walletType.toString()}');
    }

    return priority;
  }

  @computed
  bool get isAutoGenerateSubaddressesEnabled =>
      _settingsStore.autoGenerateSubaddressStatus != AutoGenerateSubaddressStatus.disabled;

  @action
  void setAutoGenerateSubaddresses(bool value) {
    _wallet.isEnabledAutoGenerateSubaddress = value;
    _settingsStore.autoGenerateSubaddressStatus =
        value ? AutoGenerateSubaddressStatus.enabled : AutoGenerateSubaddressStatus.disabled;
  }

  bool get isAutoGenerateSubaddressesVisible => [
        WalletType.monero,
        WalletType.wownero,
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.bitcoinCash,
        WalletType.dogecoin,
        WalletType.decred
      ].contains(_wallet.type);

  @computed
  bool get isMoneroWallet => _wallet.type == WalletType.monero;

  @computed
  bool get shouldSaveRecipientAddress => _settingsStore.shouldSaveRecipientAddress;

  @computed
  bool get changeRepresentativeEnabled =>
      [WalletType.nano, WalletType.banano].contains(_wallet.type);

  @computed
  bool get changeHardwareWalletTypeEnabled => [
        HardwareWalletType.cupcake,
        HardwareWalletType.coldcard,
        HardwareWalletType.seedsigner,
      ].contains(_wallet.hardwareWalletType);

  @computed
  bool get displayTransactionPriority => !(changeRepresentativeEnabled ||
      [
        WalletType.solana,
        WalletType.tron,
        WalletType.arbitrum,
      ].contains(_wallet.type));

  String getDisplayPriority(dynamic priority) {
    final _priority = priority as TransactionPriority;

    if ([
      WalletType.bitcoin,
      WalletType.litecoin,
      WalletType.bitcoinCash,
      WalletType.dogecoin,
    ].contains(_wallet.type)) {
      final rate = bitcoin!.getFeeRate(_wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate);
    }

    return priority.toString();
  }

  String getDisplayBitcoinPriority(dynamic priority, int customValue) {
    final _priority = priority as TransactionPriority;

    if ([
      WalletType.bitcoin,
      WalletType.litecoin,
      WalletType.bitcoinCash,
      WalletType.dogecoin,
    ].contains(_wallet.type)) {
      final rate = bitcoin!.getFeeRate(_wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate, customRate: customValue);
    }

    return priority.toString();
  }

  void onDisplayPrioritySelected(TransactionPriority priority) =>
      _settingsStore.setPriority(walletType, priority, chainId: chainId);

  void onDisplayBitcoinPrioritySelected(TransactionPriority priority, double customValue) {
    if (_wallet.type == WalletType.bitcoin) {
      _settingsStore.customBitcoinFeeRate = customValue.round();
    }
    _settingsStore.setPriority(_wallet.type, priority, chainId: _wallet.chainId);
  }

  @action
  Future<void> onHardwareWalletTypeChanged(HardwareWalletType hwType) async {
    _wallet.walletInfo.hardwareWalletType = hwType;
    await _wallet.walletInfo.save();
  }

  @computed
  double get customBitcoinFeeRate => _settingsStore.customBitcoinFeeRate.toDouble();

  @action
  void setShouldSaveRecipientAddress(bool value) =>
      _settingsStore.shouldSaveRecipientAddress = value;

  int? get customPriorityItemIndex {
    final priorities = priorityForWalletType(walletType);
    final customItem = priorities
        .firstWhereOrNull((element) => element == bitcoin!.getBitcoinTransactionPriorityCustom());
    return customItem != null ? priorities.indexOf(customItem) : null;
  }

  int? get maxCustomFeeRate {
    if (_wallet.type == WalletType.bitcoin) {
      return bitcoin!.getMaxCustomFeeRate(_wallet);
    }
    return null;
  }

  Future<File?> getLightningLog() async {
    final path = await pathForWalletDir(name: _wallet.name, type: walletType);
    final logFile = File("$path/lightning.log");

    if (await logFile.exists()) return logFile;
    return null;
  }

  Future<File?> getPayjoinLog() async {
    final path = await pathForWalletDir(name: _wallet.name, type: walletType);
    final logFile = File("$path/payjoin.log");
    final buf = StringBuffer();

    buf.writeln('=== Payjoin Export ===');
    buf.writeln('Wallet: ${_wallet.name} (${walletType})');
    buf.writeln('Wallet ID: ${_wallet.id}');
    buf.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buf.writeln('');

    try {
      final box = await CakeHive.openBox<PayjoinSession>(PayjoinSession.boxName);
      final allSessions = box.values.toList();
      final sessions = allSessions.where((s) => s.walletId == _wallet.id).toList();
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
