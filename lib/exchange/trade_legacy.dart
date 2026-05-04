import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/get_encryption_key.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_currency_snapshot.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:hive/hive.dart';

part 'trade_legacy.part.dart';

Future<void> performTradeHiveMigration(SecureStorage secureStorage) async {
  try {
    if (!CakeHive.isAdapterRegistered(TradeLegacy.typeId)) {
      CakeHive.registerAdapter(TradeLegacyAdapter());
    }
    final tradesBoxKey = await getEncryptionKey(secureStorage: secureStorage, forKey: Trade.boxKey);
    final box = await CakeHive.openBox<TradeLegacy>(Trade.boxName, encryptionKey: tradesBoxKey);
    await TradeLegacy.migrateAllToSqlite(box);
  } catch (e) {
    printV('Trade Hive migration error: $e');
  }
}

class TradeLegacy extends HiveObject {
  TradeLegacy({
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
    this.userCurrencyFromRaw,
    this.userCurrencyToRaw,
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
    fromRaw = from?.raw ?? -1;
    toRaw = to?.raw ?? -1;
    if (state != null) stateRaw = state.raw;
  }

  static const typeId = TRADE_TYPE_ID;

  String id;
  late int providerRaw;
  int fromRaw = -1;
  int toRaw = -1;
  late String stateRaw;
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
  String? userCurrencyFromRaw;
  String? userCurrencyToRaw;
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

  Future<void> migrateToSqlite() async {
    final trade = Trade(
      id: id,
      amount: amount,
      receiveAmount: receiveAmount,
      createdAt: createdAt,
      expiredAt: expiredAt,
      inputAddress: inputAddress,
      extraId: extraId,
      outputTransaction: outputTransaction,
      refundAddress: refundAddress,
      walletId: walletId,
      payoutAddress: payoutAddress,
      password: password,
      providerId: providerId,
      providerName: providerName,
      fromWalletAddress: fromWalletAddress,
      memo: memo,
      fee: fee,
      txId: txId,
      isRefund: isRefund,
      isSendAll: isSendAll,
      router: router,
      from:
          TradeCurrencySnapshot.fromLegacyHive(raw: fromRaw, displayTitleTag: userCurrencyFromRaw),
      to: TradeCurrencySnapshot.fromLegacyHive(raw: toRaw, displayTitleTag: userCurrencyToRaw),
      needToRegisterInSwapXyz: needToRegisterInSwapXyz,
      sourceTokenAddress: sourceTokenAddress,
      sourceTokenDecimals: sourceTokenDecimals,
      routerData: routerData,
      routerValue: routerValue,
      routerChainId: routerChainId,
      sourceTokenAmountRaw: sourceTokenAmountRaw,
      requiresTokenApproval: requiresTokenApproval,
      chainId: chainId,
    );
    trade.providerRaw = providerRaw;
    trade.stateRaw = stateRaw;
    await trade.save();
  }

  static Future<void> migrateAllToSqlite(
    Box<TradeLegacy> box,
  ) async {
    printV('Migrating Trades to SQLite: start');
    final list = box.values.toList();
    for (final trade in list) {
      try {
        await trade.migrateToSqlite();
        await trade.delete();
      } catch (e) {
        printV('Error migrating trade ${trade.id}: $e');
      }
    }
    printV('Migrating Trades to SQLite: end');
  }
}
