import 'package:cake_wallet/cake_pay/src/models/cake_pay_voucher.dart';

/// A single purchased gift card (one unit of an order line), built from `GET /api/orders/my_orders/`.
class CakePayUserCard {
  const CakePayUserCard({
    required this.orderId,
    required this.redemptionToken,
    required this.cardId,
    required this.unitIndex,
    required this.name,
    required this.currencyCode,
    required this.price,
    this.imageUrl,
  });

  final String orderId;

  /// `voucher_share_token` of the order, used to reveal the codes.
  final String redemptionToken;
  final int cardId;

  /// Position of this card among the units of [cardId] within the order, used to pick its voucher.
  final int unitIndex;
  final String name;
  final String currencyCode;

  /// Face value as sent by the API, kept as a string to avoid floating point amounts.
  final String price;
  final String? imageUrl;

  String get valueLabel => '$price $currencyCode';

  CakePayVoucher? voucherFrom(List<CakePayVoucher> vouchers) {
    var matching = vouchers.where((v) => v.cardId == cardId).toList(growable: false);

    // `card_id` is optional on vouchers, so fall back to the ones that don't carry it.
    if (matching.isEmpty) {
      matching = vouchers.where((v) => v.cardId == null).toList(growable: false);
    }

    if (matching.isEmpty) {
      return null;
    }

    return matching[unitIndex < matching.length ? unitIndex : 0];
  }

  /// Expands the orders returned by the API into one entry per purchased unit. Orders without a
  /// `voucher_share_token` have no codes yet and are skipped.
  static List<CakePayUserCard> fromOrders(List<Map<String, dynamic>> orders) {
    final result = <CakePayUserCard>[];

    for (final order in orders) {
      final token = order['voucher_share_token'] as String?;
      if (token == null || token.isEmpty) {
        continue;
      }

      final unitsPerCard = <int, int>{};
      for (final line in (order['cards'] as List? ?? const [])) {
        final map = line as Map<String, dynamic>;
        final cardId = map['card_id'] as int;
        final quantity = map['quantity'] as int? ?? 1;
        final currencyCode = map['currency_code'] as String? ?? '';
        // The API may send the price as "25.00" or "25.00 USD".
        final price = (map['price'] as String? ?? '').trim().split(' ').first;

        for (var i = 0; i < quantity; i++) {
          final unitIndex = unitsPerCard[cardId] ?? 0;
          unitsPerCard[cardId] = unitIndex + 1;

          result.add(
            CakePayUserCard(
              orderId: order['order_id'] as String,
              redemptionToken: token,
              cardId: cardId,
              unitIndex: unitIndex,
              name: (map['name'] as String?) ?? (map['real_name'] as String?) ?? '',
              currencyCode: currencyCode,
              price: price,
              imageUrl: map['card_image_url'] as String?,
            ),
          );
        }
      }
    }

    return result;
  }
}
