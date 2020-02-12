import 'package:hive/hive.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/domain/exchange/trade_state.dart';
import 'package:cake_wallet/src/domain/common/format_amount.dart';

part 'trade.g.dart';

@HiveType()
class Trade extends HiveObject {
  Trade(
      {this.id,
      ExchangeProviderDescription provider,
      CryptoCurrency from,
      CryptoCurrency to,
      TradeState state,
      this.createdAt,
      this.expiredAt,
      this.amount,
      this.inputAddress,
      this.extraId,
      this.outputTransaction,
      this.refundAddress,
      this.walletId})
      : providerRaw = provider?.raw,
        fromRaw = from?.raw,
        toRaw = to?.raw,
        stateRaw = state?.raw;

  static const boxName = 'Trades';

  @HiveField(0)
  String id;

  @HiveField(1)
  int providerRaw;

  ExchangeProviderDescription get provider =>
      ExchangeProviderDescription.deserialize(raw: providerRaw);

  @HiveField(2)
  int fromRaw;

  CryptoCurrency get from => CryptoCurrency.deserialize(raw: fromRaw);

  @HiveField(3)
  int toRaw;

  CryptoCurrency get to => CryptoCurrency.deserialize(raw: toRaw);

  @HiveField(4)
  String stateRaw;

  TradeState get state => TradeState.deserialize(raw: stateRaw);

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime expiredAt;

  @HiveField(7)
  String amount;

  @HiveField(8)
  String inputAddress;

  @HiveField(9)
  String extraId;

  @HiveField(10)
  String outputTransaction;

  @HiveField(11)
  String refundAddress;

  @HiveField(12)
  String walletId;

  static Trade fromMap(Map map) {
    return Trade(
        id: map['id'] as String,
        provider: ExchangeProviderDescription.deserialize(
            raw: map['provider'] as int),
        from: CryptoCurrency.deserialize(raw: map['input'] as int),
        to: CryptoCurrency.deserialize(raw: map['output'] as int),
        createdAt: map['date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
            : null,
        amount: map['amount'] as String,
        walletId: map['wallet_id'] as String);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'provider': provider.serialize(),
      'input': from.serialize(),
      'output': to.serialize(),
      'date': createdAt != null ? createdAt.millisecondsSinceEpoch : null,
      'amount': amount,
      'wallet_id': walletId
    };
  }

  String amountFormatted() => formatAmount(amount);
}
