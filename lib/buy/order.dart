import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cw_core/format_amount.dart';

part 'order.g.dart';

@HiveType(typeId: Order.typeId)
class Order extends HiveObject {
  Order(
      {this.id,
        BuyProviderDescription provider,
        this.transferId,
        this.from,
        this.to,
        TradeState state,
        this.createdAt,
        this.amount,
        this.receiveAddress,
        this.walletId})
      : providerRaw = provider?.raw,
        stateRaw = state?.raw;

  static const typeId = 8;
  static const boxName = 'Orders';
  static const boxKey = 'ordersBoxKey';

  @HiveField(0)
  String id;

  @HiveField(1)
  String transferId;

  @HiveField(2)
  String from;

  @HiveField(3)
  String to;

  @HiveField(4)
  String stateRaw;

  TradeState get state => TradeState.deserialize(raw: stateRaw);

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String amount;

  @HiveField(7)
  String receiveAddress;

  @HiveField(8)
  String walletId;

  @HiveField(9)
  int providerRaw;

  BuyProviderDescription get provider =>
      BuyProviderDescription.deserialize(raw: providerRaw);

  String amountFormatted() => formatAmount(amount);
}