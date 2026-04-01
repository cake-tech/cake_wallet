import 'dart:async';

import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade_currency_snapshot.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/generate_name.dart';
import 'package:sqflite/sqflite.dart';

class Trade {
  Trade({
    this.internalId = 0,
    required this.id,
    required this.amount,
    ExchangeProviderDescription? provider,
    CryptoCurrency? from,
    CryptoCurrency? to,
    TradeState? state,
    this.receiveAmount,
    this.createdAt,
    this.expiredAt,
    this.inputAddress,
    this.extraId,
    this.outputTransaction,
    this.refundAddress,
    this.walletId,
    this.payoutAddress,
    this.password,
    this.providerId,
    this.providerName,
    this.fromWalletAddress,
    this.memo,
    this.fee,
    this.txId,
    this.isRefund,
    this.isSendAll,
    this.router,
    String? fromCurrencyJson,
    String? toCurrencyJson,
    // The following fields are used for SwapXyz trades only
    this.needToRegisterInSwapXyz,
    this.sourceTokenAddress,
    this.sourceTokenDecimals,
    this.routerData,
    this.routerValue,
    this.routerChainId,
    this.sourceTokenAmountRaw,
    this.requiresTokenApproval,
    this.chainId,
  }) {
    if (provider != null) providerRaw = provider.raw;

    this.fromCurrencyJson = fromCurrencyJson ?? TradeCurrencySnapshot.encode(from);
    this.toCurrencyJson = toCurrencyJson ?? TradeCurrencySnapshot.encode(to);

    if (state != null) stateRaw = state.raw;
  }

  static const tableName = 'Trade';
  static const selfIdColumn = 'tradeId';

  static const boxName = 'Trades';
  static const boxKey = 'tradesBoxKey';

  static final StreamController<void> onChanged = StreamController<void>.broadcast();

  int internalId;

  String id;

  int providerRaw = 0;

  ExchangeProviderDescription get provider =>
      ExchangeProviderDescription.deserialize(raw: providerRaw);

  String? fromCurrencyJson;

  String? toCurrencyJson;

  CryptoCurrency? get from => TradeCurrencySnapshot.decode(fromCurrencyJson);

  CryptoCurrency? get to => TradeCurrencySnapshot.decode(toCurrencyJson);

  String stateRaw = '';

  TradeState get state => TradeState.deserialize(raw: stateRaw);

  DateTime? createdAt;
  DateTime? expiredAt;
  String amount;
  String? receiveAmount;
  String? inputAddress;
  String? extraId;
  String? outputTransaction;
  String? refundAddress;
  String? walletId;
  String? payoutAddress;
  String? password;
  String? providerId;
  String? providerName;
  String? fromWalletAddress;
  String? memo;
  String? txId;
  bool? isRefund;
  bool? isSendAll;
  String? router;

  // The following fields are used for SwapXyz trades only
  bool? needToRegisterInSwapXyz;
  String? sourceTokenAddress;
  int? sourceTokenDecimals;
  String? routerData;
  String? routerValue;
  int? routerChainId;
  String? sourceTokenAmountRaw;
  bool? requiresTokenApproval;

  int? chainId;
  double? fee;

  String get chainName {
    if (chainId == null) return '';

    return evm!.getChainNameByChainId(chainId!).capitalized();
  }

  // ── SQLite CRUD ──────────────────────────────────────

  Future<int> save() async {
    final json = toSqliteMap();
    if (json[selfIdColumn] == 0) {
      json[selfIdColumn] = null;
    }
    internalId = await db!.insert(
      tableName,
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    onChanged.add(null);
    return internalId;
  }

  static Future<List<Trade>> getAll({String? orderBy}) async {
    final list = await db!.query(
      tableName,
      orderBy: orderBy ?? 'createdAt DESC',
    );
    return List.generate(
      list.length,
      (i) => Trade.fromSqliteRow(list[i]),
    );
  }

  static Future<Trade?> getByTradeId(String id) async {
    final list = await db!.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (list.isEmpty) return null;
    return Trade.fromSqliteRow(list.first);
  }

  static Future<int> deleteTrade(Trade trade) async {
    final rows = await db!.delete(
      tableName,
      where: '$selfIdColumn = ?',
      whereArgs: [trade.internalId],
    );
    onChanged.add(null);
    return rows;
  }

  // ── SQLite serialization ─────────────────────────────

  static bool _hasValidString(String? value) => value != null && value.trim().isNotEmpty;

  void mergeFindTradeByIdResult(Trade updated) {
    final keepInternalId = internalId;

    if (updated.id.isNotEmpty) id = updated.id;

    providerRaw = updated.providerRaw;

    if (updated.stateRaw.isNotEmpty) stateRaw = updated.stateRaw;
    if (updated.amount.trim().isNotEmpty) amount = updated.amount;
    if (updated.createdAt != null) createdAt = updated.createdAt;
    if (updated.expiredAt != null) expiredAt = updated.expiredAt;
    if (updated.isRefund != null) isRefund = updated.isRefund;
    if (updated.isSendAll != null) isSendAll = updated.isSendAll;
    if (updated.chainId != null) chainId = updated.chainId;
    if (updated.fee != null) fee = updated.fee;

    if (_hasValidString(updated.memo)) memo = updated.memo;
    if (_hasValidString(updated.txId)) txId = updated.txId;

    if (_hasValidString(updated.fromCurrencyJson)) {
      fromCurrencyJson = updated.fromCurrencyJson;
    }
    if (_hasValidString(updated.toCurrencyJson)) {
      toCurrencyJson = updated.toCurrencyJson;
    }
    if (_hasValidString(updated.receiveAmount)) {
      receiveAmount = updated.receiveAmount;
    }
    if (_hasValidString(updated.inputAddress)) {
      inputAddress = updated.inputAddress;
    }
    if (_hasValidString(updated.extraId)) {
      extraId = updated.extraId;
    }
    if (_hasValidString(updated.outputTransaction)) {
      outputTransaction = updated.outputTransaction;
    }
    if (_hasValidString(updated.refundAddress)) {
      refundAddress = updated.refundAddress;
    }
    if (_hasValidString(updated.walletId)) {
      walletId = updated.walletId;
    }
    if (_hasValidString(updated.payoutAddress)) {
      payoutAddress = updated.payoutAddress;
    }
    if (_hasValidString(updated.password)) {
      password = updated.password;
    }
    if (_hasValidString(updated.providerId)) {
      providerId = updated.providerId;
    }
    if (_hasValidString(updated.providerName)) {
      providerName = updated.providerName;
    }
    if (_hasValidString(updated.fromWalletAddress)) {
      fromWalletAddress = updated.fromWalletAddress;
    }

    if (_hasValidString(updated.router)) {
      router = updated.router;
    }
    if (updated.needToRegisterInSwapXyz != null) {
      needToRegisterInSwapXyz = updated.needToRegisterInSwapXyz;
    }
    if (updated.sourceTokenDecimals != null) {
      sourceTokenDecimals = updated.sourceTokenDecimals;
    }
    if (updated.routerChainId != null) {
      routerChainId = updated.routerChainId;
    }
    if (updated.requiresTokenApproval != null) {
      requiresTokenApproval = updated.requiresTokenApproval;
    }
    if (_hasValidString(updated.sourceTokenAddress)) {
      sourceTokenAddress = updated.sourceTokenAddress;
    }
    if (_hasValidString(updated.routerData)) {
      routerData = updated.routerData;
    }
    if (_hasValidString(updated.routerValue)) {
      routerValue = updated.routerValue;
    }
    if (_hasValidString(updated.sourceTokenAmountRaw)) {
      sourceTokenAmountRaw = updated.sourceTokenAmountRaw;
    }

    internalId = keepInternalId;
  }

  Map<String, dynamic> toSqliteMap() {
    return <String, dynamic>{
      selfIdColumn: internalId,
      'id': id,
      'providerRaw': providerRaw,
      'fromCurrencyJson': fromCurrencyJson,
      'toCurrencyJson': toCurrencyJson,
      'stateRaw': stateRaw,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'expiredAt': expiredAt?.millisecondsSinceEpoch,
      'amount': amount,
      'receiveAmount': receiveAmount,
      'inputAddress': inputAddress,
      'extraId': extraId,
      'outputTransaction': outputTransaction,
      'refundAddress': refundAddress,
      'walletId': walletId,
      'payoutAddress': payoutAddress,
      'password': password,
      'providerId': providerId,
      'providerName': providerName,
      'fromWalletAddress': fromWalletAddress,
      'memo': memo,
      'txId': txId,
      'isRefund': isRefund == true ? 1 : 0,
      'isSendAll': isSendAll == true ? 1 : 0,
      'router': router,
      'needToRegisterInSwapXyz': needToRegisterInSwapXyz == true ? 1 : 0,
      'sourceTokenAddress': sourceTokenAddress,
      'sourceTokenDecimals': sourceTokenDecimals,
      'routerData': routerData,
      'routerValue': routerValue,
      'routerChainId': routerChainId,
      'sourceTokenAmountRaw': sourceTokenAmountRaw,
      'requiresTokenApproval': requiresTokenApproval == true ? 1 : 0,
      'chainId': chainId,
      'fee': fee,
    };
  }

  factory Trade.fromSqliteRow(Map<String, dynamic> row) {
    final trade = Trade(
      id: row['id'] as String? ?? '',
      amount: row['amount'] as String? ?? '',
      receiveAmount: row['receiveAmount'] as String?,
      createdAt: row['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              row['createdAt'] as int,
            )
          : null,
      expiredAt: row['expiredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              row['expiredAt'] as int,
            )
          : null,
      inputAddress: row['inputAddress'] as String?,
      extraId: row['extraId'] as String?,
      outputTransaction: row['outputTransaction'] as String?,
      refundAddress: row['refundAddress'] as String?,
      walletId: row['walletId'] as String?,
      payoutAddress: row['payoutAddress'] as String?,
      password: row['password'] as String?,
      providerId: row['providerId'] as String?,
      providerName: row['providerName'] as String?,
      fromWalletAddress: row['fromWalletAddress'] as String?,
      memo: row['memo'] as String?,
      fee: row['fee'] as double?,
      txId: row['txId'] as String?,
      isRefund: (row['isRefund'] as int?) == 1,
      isSendAll: (row['isSendAll'] as int?) == 1,
      router: row['router'] as String?,
      fromCurrencyJson: row['fromCurrencyJson'] as String?,
      toCurrencyJson: row['toCurrencyJson'] as String?,
      needToRegisterInSwapXyz: (row['needToRegisterInSwapXyz'] as int?) == 1,
      sourceTokenAddress: row['sourceTokenAddress'] as String?,
      sourceTokenDecimals: row['sourceTokenDecimals'] as int?,
      routerData: row['routerData'] as String?,
      routerValue: row['routerValue'] as String?,
      routerChainId: row['routerChainId'] as int?,
      sourceTokenAmountRaw: row['sourceTokenAmountRaw'] as String?,
      requiresTokenApproval: (row['requiresTokenApproval'] as int?) == 1,
      chainId: row['chainId'] as int?,
    );
    trade.internalId = row[selfIdColumn] as int? ?? 0;
    trade.providerRaw = row['providerRaw'] as int? ?? 0;
    trade.stateRaw = row['stateRaw'] as String? ?? '';
    return trade;
  }

  String amountFormatted() => formatAmount(amount);
  String receiveAmountFormatted() => formatAmount(receiveAmount ?? '');
}
