import "dart:async";

import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/utils/currency_from_serialized.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/generate_name.dart";
import "package:sqflite/sqflite.dart";

class Trade {
  Trade({
    required this.state,
    required this.depositAmount,
    required this.payoutAmount,
    required this.fundingAddress,
    required this.id, required this.provider, required this.payoutAddress, required this.refundAddress, this.internalId = 0,
    this.createdAt,
    this.expiredAt,
    this.extraId,
    this.outputTransaction,
    this.walletId,
    this.toAddressExtraId,
    this.password,
    this.providerId,
    this.memo,
    this.fee,
    this.txId,
    this.isRefund,
    this.isSendAll,
    this.router,
  });

  static const tableName = "Trade";
  static const selfIdColumn = "tradeId";

  static const boxName = "Trades";
  static const boxKey = "tradesBoxKey";

  static final StreamController<void> onChanged = StreamController<void>.broadcast();

  int internalId;

  String id;

  final ExchangeProviderDescription provider;

  final TradeState state;

  DateTime? createdAt;
  DateTime? expiredAt;
  final Money depositAmount;
  final Money payoutAmount;
  final String fundingAddress;
  String? extraId;
  String? outputTransaction;
  String? walletId;
  final String refundAddress;
  final String payoutAddress;

  // holds the receive address memo or destination tag that was passed for this trade
  String? toAddressExtraId;
  String? password;
  String? providerId;
  String? memo;
  String? txId;
  bool? isRefund;
  bool? isSendAll;
  String? router;

  int? chainId;
  double? fee;

  String get chainName {
    if (chainId == null) {
      return "";
    }

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
      orderBy: orderBy ?? "createdAt DESC",
    );
    return Future.wait( List.generate(
      list.length,
      (i) => Trade.fromSqliteRow(list[i]),
    ));
  }

  static Future<Trade?> getByTradeId(String id) async {
    final list = await db!.query(
      tableName,
      where: "id = ?",
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
      whereArgs: [trade.internalId],
    );
    onChanged.add(null);
    return rows;
  }

  Map<String, dynamic> toSqliteMap() => {
      selfIdColumn: internalId,
      "id": id,
      "providerRaw": provider.raw,
    "payoutAmount": payoutAmount.serialized,
    "depositAmount": depositAmount.serialized,
      "stateRaw": state.raw,
      "createdAt": createdAt?.millisecondsSinceEpoch,
      "expiredAt": expiredAt?.millisecondsSinceEpoch,
      "extraId": extraId,
      "outputTransaction": outputTransaction,
      "walletId": walletId,
      "payoutAddress": payoutAddress,
      "toAddressExtraId": toAddressExtraId,
      "password": password,
      "providerId": providerId,
      "memo": memo,
      "txId": txId,
      "isRefund": isRefund == true ? 1 : 0,
      "isSendAll": isSendAll == true ? 1 : 0,
      "router": router,
      "chainId": chainId,
      "fee": fee,
    };

  static Future<Trade> fromSqliteRow(Map<String, dynamic> row) async {
    final trade = Trade(
      id: row["id"] as String? ?? "",
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
      refundAddress: row["refundAddress"] as String,
      walletId: row["walletId"] as String?,
      payoutAddress: row["payoutAddress"] as String,
      provider: ExchangeProviderDescription.deserialize(raw: row["provider"] as int),
      toAddressExtraId: row["toAddressExtraId"] as String?,
      password: row["password"] as String?,
      providerId: row["providerId"] as String?,
      state: TradeState.deserialize(raw: row["state"] as String),
      memo: row["memo"] as String?,
      fee: row["fee"] as double?,
      txId: row["txId"] as String?,
      isRefund: (row["isRefund"] as int?) == 1,
      isSendAll: (row["isSendAll"] as int?) == 1,
      router: row["router"] as String?,
      depositAmount: await moneyFromSerialized(row["depositAmount"] as String),
      payoutAmount: await moneyFromSerialized(row["depositAmount"] as String),
      fundingAddress: row["fundingAddress"] as String,
      // from: _currencyFromRow(row, 'from'),
      // to: _currencyFromRow(row, 'to'),
      // needToRegisterInSwapXyz: (row['needToRegisterInSwapXyz'] as int?) == 1,
      // sourceTokenAddress: row['sourceTokenAddress'] as String?,
      // sourceTokenDecimals: row['sourceTokenDecimals'] as int?,
      // routerData: row['routerData'] as String?,
      // routerValue: row['routerValue'] as String?,
      // routerChainId: row['routerChainId'] as int?,
      // sourceTokenAmountRaw: row['sourceTokenAmountRaw'] as String?,
      // requiresTokenApproval: (row['requiresTokenApproval'] as int?) == 1,
      // chainId: row['chainId'] as int?,
    );
    trade.internalId = row[selfIdColumn] as int? ?? 0;
    // trade.providerRaw = row['providerRaw'] as int? ?? 0;
    // trade.stateRaw = row['stateRaw'] as String? ?? '';
    return trade;
  }

  // static CryptoCurrency? _currencyFromRow(Map<String, dynamic> row, String prefix) {
  //   final title = row['${prefix}Title'] as String?;
  //   if (title == null || title.isEmpty) return null;
  //
  //   final tag = row['${prefix}Tag'] as String?;
  //
  //   final live = CryptoCurrency.safeParseCurrencyFromString(title, tag: tag);
  //   if (live != null) return live;
  //
  //   return CryptoCurrency(
  //     title: title,
  //     name: row['${prefix}Name'] as String? ?? '',
  //     tag: tag,
  //     fullName: row['${prefix}FullName'] as String?,
  //     decimals: row['${prefix}Decimals'] as int? ?? 1,
  //     raw: row['${prefix}Raw'] as int? ?? -1,
  //     iconPath: row['${prefix}IconPath'] as String?,
  //     flatIconPath: row['${prefix}FlatIconPath'] as String?,
  //     chainIconPath: row['${prefix}ChainIconPath'] as String?,
  //   );
  // }
}
