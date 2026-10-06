import "dart:async";

import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/uri_helper.dart";
import "package:cake_wallet/utils/currency_from_serialized.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/generate_name.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:sqflite/sqflite.dart";

class Trade {
  Trade({
    required this.state,
    required this.depositAmount,
    required this.payoutAmount,
    required this.fundingAddress,
    this.providerName,
    required this.id, required this.provider, required this.payoutAddress, required this.refundAddress,
    this.createdAt,
    this.expiredAt,
    this.accountIndex = 0,
    this.extraId,
    this.outputTransaction,
    this.walletId,
    this.toAddressExtraId,
    this.password,
    this.providerId,
    this.memo,
    this.txId,
    this.isRefund,
    this.chainId
  });

  static const tableName = "Trade";
  static const selfIdColumn = "id";

  static const boxName = "Trades";
  static const boxKey = "tradesBoxKey";

  static final StreamController<void> onChanged = StreamController<void>.broadcast();

  final String id;

  final ExchangeProviderDescription provider;

  final TradeState state;

  final DateTime? createdAt;
  final DateTime? expiredAt;
  final Money depositAmount;
  final Money payoutAmount;
  final String fundingAddress;
  final String? extraId;
  final String? outputTransaction;
  final String? walletId;
  final int? accountIndex;
  final String refundAddress;
  final String payoutAddress;
  final String? providerName;

  // holds the receive address memo or destination tag that was passed for this trade
  final String? toAddressExtraId;
  final String? password;
  final String? providerId;
  final String? memo;
  final String? txId;
  final bool? isRefund;

  CryptoCurrency get depositCurrency => depositAmount.currency as CryptoCurrency;
  CryptoCurrency get payoutCurrency => payoutAmount.currency as CryptoCurrency;

  PaymentURI get uri =>
      SwapUriHelper.getUri(
          fundingAddress, depositAmount.toString(), depositAmount.currency as CryptoCurrency);


  final int? chainId;

  String get chainName {
    if (chainId == null) {
      return "";
    }

    return evm!.getChainNameByChainId(chainId!).capitalized();
  }

  // ── SQLite CRUD ──────────────────────────────────────

  Future<void> save() async {
    await db!.insert(
      tableName,
      toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    onChanged.add(null);
  }

  static Future<List<Trade>> getAll({String? orderBy}) async {
    final list = await db!.query(
      tableName,
      orderBy: orderBy ?? "createdAt DESC",
    );
    return (await Future.wait(
      list.map((row) async {
        try {
          return await Trade.fromSqliteRow(row);
        } catch (e, st) {
          printV("failed to deserialize trade ${row[selfIdColumn]}: $e\n$st");
          return null;
        }
      }),
    )).nonNulls.toList();
  }

  static Future<Trade?> getByTradeId(String id) async {
    final list = await db!.query(
      tableName,
      where: "$selfIdColumn = ?",
      whereArgs: [id],
      limit: 1,
    );
    if (list.isEmpty) {
      return null;
    }
    return Trade.fromSqliteRow(list.first);
  }

  static Future<int> deleteTrade(Trade trade) async {
    final rows = await db!.delete(
      tableName,
      where: "$selfIdColumn = ?",
      whereArgs: [trade.id],
    );
    onChanged.add(null);
    return rows;
  }

  Map<String, dynamic> toSqliteMap() => {
      selfIdColumn: id,
      "provider": provider.raw,
      "payoutAmount": payoutAmount.serialized,
      "depositAmount": depositAmount.serialized,
      "state": state.raw,
      "createdAt": createdAt?.millisecondsSinceEpoch,
      "expiredAt": expiredAt?.millisecondsSinceEpoch,
      "extraId": extraId,
      "outputTransaction": outputTransaction,
      "walletId": walletId,
      "payoutAddress": payoutAddress,
      "toAddressExtraId": toAddressExtraId,
      "password": password,
      "accountIndex": accountIndex,
      "providerId": providerId,
      "providerName": providerName,
      "memo": memo,
      "txId": txId,
      "isRefund": isRefund == true ? 1 : 0,
      "chainId": chainId,
      "fundingAddress": fundingAddress,
      "refundAddress": refundAddress
    };

  static Future<Trade> fromSqliteRow(Map<String, dynamic> row) async => Trade(
      id: row[selfIdColumn] as String,
      createdAt: row["createdAt"] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              row["createdAt"] as int,
            )
          : null,
      expiredAt: row["expiredAt"] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              row["expiredAt"] as int,
            )
          : null,
      extraId: row["extraId"] as String?,
      outputTransaction: row["outputTransaction"] as String?,
      refundAddress: row["refundAddress"] as String? ?? "",
      walletId: row["walletId"] as String?,
      accountIndex: row["accountIndex"] as int?,
      payoutAddress: row["payoutAddress"] as String? ?? "",
      provider: ExchangeProviderDescription.deserialize(raw: row["provider"] as int),
      toAddressExtraId: row["toAddressExtraId"] as String?,
      password: row["password"] as String?,
      providerId: row["providerId"] as String?,
      providerName: row["providerName"] as String?,
      state: TradeState.deserialize(raw: row["state"] as String),
      memo: row["memo"] as String?,
      txId: row["txId"] as String?,
      isRefund: (row["isRefund"] as int?) == 1,
      depositAmount: await moneyFromSerialized(row["depositAmount"] as String),
      payoutAmount: await moneyFromSerialized(row["payoutAmount"] as String),
      fundingAddress: row["fundingAddress"] as String,
    );

  Trade copyWith({
    TradeState? state,
    Money? depositAmount,
    Money? payoutAmount,
    String? fundingAddress,
    String? providerName,
    String? id,
    ExchangeProviderDescription? provider,
    String? payoutAddress,
    String? refundAddress,
    int? accountIndex,
    DateTime? createdAt,
    DateTime? expiredAt,
    String? extraId,
    String? outputTransaction,
    String? walletId,
    String? toAddressExtraId,
    String? password,
    String? providerId,
    String? memo,
    String? txId,
    bool? isRefund,
    int? chainId,
  }) => Trade(
      state: state ?? this.state,
      depositAmount: depositAmount ?? this.depositAmount,
      payoutAmount: payoutAmount ?? this.payoutAmount,
      fundingAddress: fundingAddress ?? this.fundingAddress,
      providerName: providerName ?? this.providerName,
      id: id ?? this.id,
      accountIndex: accountIndex ?? this.accountIndex,
      provider: provider ?? this.provider,
      payoutAddress: payoutAddress ?? this.payoutAddress,
      refundAddress: refundAddress ?? this.refundAddress,
      createdAt: createdAt ?? this.createdAt,
      expiredAt: expiredAt ?? this.expiredAt,
      extraId: extraId ?? this.extraId,
      outputTransaction: outputTransaction ?? this.outputTransaction,
      walletId: walletId ?? this.walletId,
      toAddressExtraId: toAddressExtraId ?? this.toAddressExtraId,
      password: password ?? this.password,
      providerId: providerId ?? this.providerId,
      memo: memo ?? this.memo,
      txId: txId ?? this.txId,
      isRefund: isRefund ?? this.isRefund,
      chainId: chainId ?? this.chainId,
    );

}

class RoutableTrade extends Trade {
  RoutableTrade({required this.routerData, required this.routerValue, required super.state, required super.depositAmount, required super.payoutAmount, required super.id, required super.provider, required super.payoutAddress, required super.refundAddress,

    required super.fundingAddress, super.createdAt,
    super.expiredAt,
    super.extraId,
    super.outputTransaction,
    super.walletId,
    super.toAddressExtraId,
    super.password,
    super.providerId,
    super.memo,
    super.chainId,
    super.txId,
    super.isRefund, this.router,});

  final String routerData;
  final String routerValue;
  final String? router;
}
