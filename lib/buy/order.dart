import 'dart:convert';

import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

import 'onramper/onramper_buy_provider.dart';

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
      ProviderType? provider,
      OnRamperPartner? onramperPartner,
      TradeState? state,
      this.from,
      this.to}) {
    if (provider != null) {
      providerRaw = ProvidersHelper.serialize(provider);
    }
    if (onramperPartner != null) {
      onramperPartnerRaw = onramperPartner.index;
    }
    if (state != null) {
      stateRaw = state.raw;
    }
  }

  factory Order.fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map<String, dynamic>;
    final providerRaw = decoded['providerRaw'] as int?;
    final onramperPartnerRaw = decoded['onramperPartnerRaw'] as int?;

    return Order(
      id: decoded['id'] as String,
      transferId: decoded['transferId'] as String? ?? '',
      createdAt: DateTime.parse(decoded['createdAt'] as String),
      amount: decoded['amount'] as String? ?? '',
      receiveAddress: decoded['receiveAddress'] as String? ?? '',
      walletId: decoded['walletId'] as String? ?? '',
      provider: providerRaw != null ? ProvidersHelper.deserialize(raw: providerRaw) : null,
      onramperPartner:
          onramperPartnerRaw != null ? OnRamperBuyProvider.fromRaw(onramperPartnerRaw) : null,
      state: TradeState.created,
      from: decoded['from'] as String?,
      to: decoded['to'] as String?,
    );
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
  String? stateRaw;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6, defaultValue: '')
  String amount;

  @HiveField(7, defaultValue: '')
  String receiveAddress;

  @HiveField(8, defaultValue: '')
  String walletId;

  @HiveField(9)
  int? providerRaw;

  @HiveField(10)
  int? onramperPartnerRaw;

  TradeState? get state => stateRaw != null ? TradeState.deserialize(raw: stateRaw!) : null;

  ProviderType? get provider =>
      providerRaw != null ? ProvidersHelper.deserialize(raw: providerRaw!) : null;

  OnRamperPartner? get onramperPartner =>
      onramperPartnerRaw != null ? OnRamperBuyProvider.fromRaw(onramperPartnerRaw!) : null;

  String amountFormatted() => formatAmount(amount);
}
