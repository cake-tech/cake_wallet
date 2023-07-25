import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'order.g.dart';

@HiveType(typeId: Order.typeId)
class Order extends HiveObject {
  Order(
      {required this.id,
        required this.transferId,
        required this.createdAt,
        required this.amount,
        required this.receiveAddress,
        required this.walletId,
        BuyProviderDescription? provider,
        TradeState? state,
        this.from,
        this.to}) {
      if (provider != null) {
        providerRaw = provider.raw;
      }
      if (state != null) {
        stateRaw = state.raw;
      }
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

  BuyProviderDescription get provider =>
      BuyProviderDescription.deserialize(raw: providerRaw);

  String amountFormatted() => formatAmount(amount);
}
