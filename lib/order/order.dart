import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

import 'order_provider_description.dart';
import 'order_source_description.dart';

part 'order.g.dart';

@HiveType(typeId: Order.typeId)
class Order extends HiveObject {
  Order({
    required this.id,
    required this.transferId,
    required this.createdAt,
    required this.amount,
    this.receiveAmount,
    this.quantity,
    required this.receiveAddress,
    required this.walletId,
    this.from,
    this.to,
    TradeState? state,
    OrderSourceDescription source = OrderSourceDescription.buy,
    BuyProviderDescription? buyProvider,
    OrderProviderDescription? giftCardProvider,
  }) {
    sourceRaw = source.raw;
    if (state != null) stateRaw = state.raw;
    if (buyProvider != null) providerRaw = buyProvider.raw;
    if (giftCardProvider != null) providerRaw = giftCardProvider.raw;
  }

  static const typeId = ORDER_TYPE_ID;
  static const boxName = 'Orders';
  static const boxKey = 'ordersBoxKey';

  @HiveField(0, defaultValue: '')
  String id;

  @HiveField(1, defaultValue: '')
  String transferId;

  @HiveField(2)
  String? from;

  @HiveField(3)
  String? to;

  @HiveField(4, defaultValue: '')
  late String stateRaw;

  TradeState get state => TradeState.deserialize(raw: stateRaw);

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6, defaultValue: '')
  String amount;

  @HiveField(7, defaultValue: '')
  String receiveAddress;

  @HiveField(8, defaultValue: '')
  String walletId;

  @HiveField(9, defaultValue: 0)
  late int providerRaw;

  @HiveField(10, defaultValue: '')
  String? receiveAmount;

  @HiveField(11, defaultValue: 0)
  late int? sourceRaw;

  @HiveField(12, defaultValue: '')
  String? quantity;

  OrderSourceDescription get source => OrderSourceDescription.deserialize(raw: sourceRaw ?? 0);

  BuyProviderDescription? get buyProvider => source == OrderSourceDescription.buy
      ? BuyProviderDescription.deserialize(raw: providerRaw)
      : null;

  OrderProviderDescription? get orderProvider => source == OrderSourceDescription.order
      ? OrderProviderDescription.deserialize(raw: providerRaw)
      : null;

  String get providerTitle {
    if (source == OrderSourceDescription.buy) {
      return buyProvider?.title ?? '';
    } else {
      return orderProvider?.title ?? '';
    }
  }

  String get providerIcon {
    if (source == OrderSourceDescription.buy) {
      return buyProvider?.image ?? '';
    } else {
      return orderProvider?.image ?? '';
    }
  }

  String amountFormatted() => formatAmount(amount) + ' ${from ?? ''}';
}
