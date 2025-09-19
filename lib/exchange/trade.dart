import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

class Trade extends HiveObject {
  Trade({
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
    this.txId,
    this.isRefund,
    this.isSendAll,
    this.router,
    this.userCurrencyFromRaw,
    this.userCurrencyToRaw,
    // The following fields are used for SwapXyz trades only
    this.needToRegisterInSwapXyz,
    this.sourceTokenAddress,
    this.sourceTokenDecimals,
    this.routerData,
    this.routerValue,
    this.routerChainId,
    this.sourceTokenAmountRaw,
    this.requiresTokenApproval
  }) {
    if (provider != null) providerRaw = provider.raw;

    fromRaw = from?.raw ?? -1;
    toRaw   = to?.raw   ?? -1;

    if (state != null) stateRaw = state.raw;
  }

  static const typeId = TRADE_TYPE_ID;
  static const boxName = 'Trades';
  static const boxKey = 'tradesBoxKey';

  @HiveField(0, defaultValue: '')
  String id;

  @HiveField(1, defaultValue: 0)
  late int providerRaw;

  ExchangeProviderDescription get provider =>
      ExchangeProviderDescription.deserialize(raw: providerRaw);

  @HiveField(2, defaultValue: -1)
  int fromRaw = -1;

  CryptoCurrency? get from => CryptoCurrency.safeDeserialize(raw: fromRaw);

  @HiveField(3, defaultValue: -1)
  int toRaw = -1;

  CryptoCurrency? get to => CryptoCurrency.safeDeserialize(raw: toRaw);

  @HiveField(4, defaultValue: '')
  late String stateRaw;

  TradeState get state => TradeState.deserialize(raw: stateRaw);

  @HiveField(5)
  DateTime? createdAt;

  @HiveField(6)
  DateTime? expiredAt;

  @HiveField(7, defaultValue: '')
  String amount;

  @HiveField(8)
  String? inputAddress;

  @HiveField(9)
  String? extraId;

  @HiveField(10)
  String? outputTransaction;

  @HiveField(11)
  String? refundAddress;

  @HiveField(12)
  String? walletId;

  @HiveField(13)
  String? payoutAddress;

  @HiveField(14)
  String? password;

  @HiveField(15)
  String? providerId;

  @HiveField(16)
  String? providerName;

  @HiveField(17)
  String? fromWalletAddress;

  @HiveField(18)
  String? memo;

  @HiveField(19)
  String? txId;

  @HiveField(20)
  bool? isRefund;

  @HiveField(21)
  bool? isSendAll;

  @HiveField(22)
  String? router;

  @HiveField(23, defaultValue: '')
  String? receiveAmount;

  @HiveField(24, defaultValue: '')
  String? userCurrencyFromRaw;

  @HiveField(25, defaultValue: '')
  String? userCurrencyToRaw;

  // The following fields are used for SwapXyz trades only
  @HiveField(26)
  bool? needToRegisterInSwapXyz;

  @HiveField(27)
  String? sourceTokenAddress;

  @HiveField(28)
  int? sourceTokenDecimals;

  @HiveField(29)
  String? routerData;

  @HiveField(30)
  String? routerValue;

  @HiveField(31)
  int? routerChainId;

  @HiveField(32)
  String? sourceTokenAmountRaw;

  @HiveField(33, defaultValue: false)
  bool? requiresTokenApproval;

  CryptoCurrency? get userCurrencyFrom {
    if (userCurrencyFromRaw == null || userCurrencyFromRaw!.isEmpty) {
      return null;
    }
    final underscoreIndex = userCurrencyFromRaw!.indexOf('_');
    final title = userCurrencyFromRaw!.substring(0, underscoreIndex);
    final tag = userCurrencyFromRaw!.substring(underscoreIndex + 1);

    return CryptoCurrency(
      title: title,
      tag: tag.isNotEmpty ? tag : null,
      name: '',
      raw: -1,
      decimals: 1,
    );
  }

  CryptoCurrency? get userCurrencyTo {
    if (userCurrencyToRaw == null || userCurrencyToRaw!.isEmpty) {
      return null;
    }
    final underscoreIndex = userCurrencyToRaw!.indexOf('_');
    final title = userCurrencyToRaw!.substring(0, underscoreIndex);
    final tag = userCurrencyToRaw!.substring(underscoreIndex + 1);

    return CryptoCurrency(
      title: title,
      tag: tag.isNotEmpty ? tag : null,
      name: '',
      raw: -1,
      decimals: 1,
    );
  }

  static Trade fromMap(Map<String, Object?> map) {
    return Trade(
      id: map['id'] as String,
      provider: ExchangeProviderDescription.deserialize(raw: map['provider'] as int),
      from: CryptoCurrency.deserialize(raw: map['input'] as int),
      to: CryptoCurrency.deserialize(raw: map['output'] as int),
      createdAt:
          map['date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int) : null,
      amount: map['amount'] as String,
      receiveAmount: map['receive_amount'] as String?,
      walletId: map['wallet_id'] as String,
      fromWalletAddress: map['from_wallet_address'] as String?,
      memo: map['memo'] as String?,
      txId: map['tx_id'] as String?,
      isRefund: map['isRefund'] as bool?,
      isSendAll: map['isSendAll'] as bool?,
      router: map['router'] as String?,
      extraId: map['extra_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'provider': provider.serialize(),
      'input': fromRaw,
      'output': toRaw,
      'date': createdAt != null ? createdAt!.millisecondsSinceEpoch : null,
      'amount': amount,
      'receive_amount': receiveAmount,
      'wallet_id': walletId,
      'from_wallet_address': fromWalletAddress,
      'memo': memo,
      'tx_id': txId,
      'isRefund': isRefund,
      'isSendAll': isSendAll,
      'router': router,
      'extra_id': extraId,
    };
  }

  String amountFormatted() => formatAmount(amount);
  String receiveAmountFormatted() => formatAmount(receiveAmount ?? '');
}

class TradeAdapter extends TypeAdapter<Trade> {
  @override
  final int typeId = Trade.typeId;

  @override
  Trade read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      try {
        fields[reader.readByte()] = reader.read();
      } catch (_) {}
    }

    return Trade(
      id: fields[0] == null ? '' : fields[0] as String,
      amount: fields[7] == null ? '' : fields[7] as String,
      receiveAmount: fields[23] as String?,
      createdAt: fields[5] as DateTime?,
      expiredAt: fields[6] as DateTime?,
      inputAddress: fields[8] as String?,
      extraId: fields[9] as String?,
      outputTransaction: fields[10] as String?,
      refundAddress: fields[11] as String?,
      walletId: fields[12] as String?,
      payoutAddress: fields[13] as String?,
      password: fields[14] as String?,
      providerId: fields[15] as String?,
      providerName: fields[16] as String?,
      fromWalletAddress: fields[17] as String?,
      memo: fields[18] as String?,
      txId: fields[19] as String?,
      isRefund: fields[20] as bool?,
      isSendAll: fields[21] as bool?,
      router: fields[22] as String?,
      userCurrencyFromRaw: fields[24] as String?,
      userCurrencyToRaw: fields[25] as String?,
      needToRegisterInSwapXyz: fields[26] as bool?,
      sourceTokenAddress: fields[27] as String?,
      sourceTokenDecimals: fields[28] as int?,
      routerData: fields[29] as String?,
      routerValue: fields[30] as String?,
      routerChainId: fields[31] as int?,
      sourceTokenAmountRaw: fields[32] as String?,
      requiresTokenApproval: fields[33] as bool?,
    )
      ..providerRaw = fields[1] == null ? 0 : fields[1] as int
      ..fromRaw = (fields[2] as int?) ?? -1
      ..toRaw = (fields[3] as int?) ?? -1
      ..stateRaw = fields[4] == null ? '' : fields[4] as String;
  }

  @override
  void write(BinaryWriter writer, Trade obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.providerRaw)
      ..writeByte(2)
      ..write(obj.fromRaw)
      ..writeByte(3)
      ..write(obj.toRaw)
      ..writeByte(4)
      ..write(obj.stateRaw)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.expiredAt)
      ..writeByte(7)
      ..write(obj.amount)
      ..writeByte(8)
      ..write(obj.inputAddress)
      ..writeByte(9)
      ..write(obj.extraId)
      ..writeByte(10)
      ..write(obj.outputTransaction)
      ..writeByte(11)
      ..write(obj.refundAddress)
      ..writeByte(12)
      ..write(obj.walletId)
      ..writeByte(13)
      ..write(obj.payoutAddress)
      ..writeByte(14)
      ..write(obj.password)
      ..writeByte(15)
      ..write(obj.providerId)
      ..writeByte(16)
      ..write(obj.providerName)
      ..writeByte(17)
      ..write(obj.fromWalletAddress)
      ..writeByte(18)
      ..write(obj.memo)
      ..writeByte(19)
      ..write(obj.txId)
      ..writeByte(20)
      ..write(obj.isRefund)
      ..writeByte(21)
      ..write(obj.isSendAll)
      ..writeByte(22)
      ..write(obj.router)
      ..writeByte(23)
      ..write(obj.receiveAmount)
      ..writeByte(24)
      ..write(obj.userCurrencyFromRaw)
      ..writeByte(25)
      ..write(obj.userCurrencyToRaw)
      ..writeByte(26)
      ..write(obj.needToRegisterInSwapXyz)
      ..writeByte(27)
      ..write(obj.sourceTokenAddress)
      ..writeByte(28)
      ..write(obj.sourceTokenDecimals)
      ..writeByte(29)
      ..write(obj.routerData)
      ..writeByte(30)
      ..write(obj.routerValue)
      ..writeByte(31)
      ..write(obj.routerChainId)
      ..writeByte(32)
      ..write(obj.sourceTokenAmountRaw)
      ..writeByte(33)
      ..write(obj.requiresTokenApproval);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
