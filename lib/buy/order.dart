import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cw_core/format_amount.dart';

part 'order.g.dart';

@HiveType(typeId: Order.typeId)
class Order extends HiveObject {
  Order(
      {required this.idRaw,
        required this.transferIdRaw,
        required this.createdAtRaw,
        required this.amountRaw,
        required this.receiveAddressRaw,
        required this.walletIdRaw,
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

  factory Order.create({required String id,
        required String transferId,
        required DateTime createdAt,
        required String amount,
        required String receiveAddress,
        required String walletId,
        BuyProviderDescription? provider,
        TradeState? state,
        String? from,
        String? to})
    => Order(
      idRaw: id,
      transferIdRaw: transferId,
      createdAtRaw: createdAt,
      amountRaw: amount,
      receiveAddressRaw: receiveAddress,
      walletIdRaw: walletId,
      provider: provider,
      state: state,
      from: from,
      to: to);

  static const typeId = 8;
  static const boxName = 'Orders';
  static const boxKey = 'ordersBoxKey';

  @HiveField(0)
  String? idRaw;

  @HiveField(1)
  String? transferIdRaw;

  @HiveField(2)
  String? from;

  @HiveField(3)
  String? to;

  @HiveField(4)
  late String? stateRaw;

  TradeState get state => TradeState.deserialize(raw: stateRaw ?? '');

  @HiveField(5)
  DateTime? createdAtRaw;

  @HiveField(6)
  String? amountRaw;

  @HiveField(7)
  String? receiveAddressRaw;

  @HiveField(8)
  String? walletIdRaw;

  @HiveField(9)
  late int? providerRaw;

  String get id => idRaw ?? '';

  set id(String value) => idRaw = value;

  String get transferId => transferIdRaw ?? '';

  set transferId(String value) => transferIdRaw = value;

  DateTime get createdAt => createdAtRaw ?? DateTime.fromMillisecondsSinceEpoch(0);
  
  set createdAt(DateTime value) => createdAtRaw = value;

  String get amount => amountRaw ?? '';

  set amount(String value) => amountRaw = value;

  String get receiveAddress => receiveAddressRaw ?? '';

  set receiveAddress(String value) => receiveAddressRaw = value;

  String get walletId => walletIdRaw ?? '';

  set walletId(String value) => walletIdRaw = value;

  BuyProviderDescription get provider =>
      BuyProviderDescription.deserialize(raw: providerRaw ?? 0);

  String amountFormatted() => formatAmount(amount);
}