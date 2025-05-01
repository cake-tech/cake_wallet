class CakePayOrder {
  final String orderId;
  final List<OrderCard> cards;
  final String? externalId;
  final double amountUsd;
  final String status;
  final String? vouchers;
  final PaymentData paymentData;

  CakePayOrder({
    required this.orderId,
    required this.cards,
    required this.externalId,
    required this.amountUsd,
    required this.status,
    required this.vouchers,
    required this.paymentData,
  });

  factory CakePayOrder.fromMap(Map<String, dynamic> map) {
    return CakePayOrder(
        orderId: map['order_id'] as String,
        cards: (map['cards'] as List<dynamic>)
            .map((x) => OrderCard.fromMap(x as Map<String, dynamic>))
            .toList(),
        externalId: map['external_id'] as String?,
        amountUsd: map['amount_usd'] as double,
        status: map['status'] as String,
        vouchers: map['vouchers'] as String?,
        paymentData: PaymentData.fromMap(map['payment_data'] as Map<String, dynamic>));
  }
}

class OrderCard {
  final int cardId;
  final int? externalId;
  final String price;
  final int quantity;
  final String currencyCode;

  OrderCard({
    required this.cardId,
    required this.externalId,
    required this.price,
    required this.quantity,
    required this.currencyCode,
  });

  factory OrderCard.fromMap(Map<String, dynamic> map) {
    return OrderCard(
      cardId: map['card_id'] as int,
      externalId: map['external_id'] as int?,
      price: map['price'] as String,
      quantity: map['quantity'] as int,
      currencyCode: map['currency_code'] as String,
    );
  }
}

class PaymentData {
  final CryptoPaymentData btc;
  final CryptoPaymentData xmr;
  final DateTime invoiceTime;
  final DateTime expirationTime;
  final int? commission;

  PaymentData({
    required this.btc,
    required this.xmr,
    required this.invoiceTime,
    required this.expirationTime,
    required this.commission,
  });

  factory PaymentData.fromMap(Map<String, dynamic> map) {
    return PaymentData(
      btc: CryptoPaymentData.fromMap(map['BTC'] as Map<String, dynamic>),
      xmr: CryptoPaymentData.fromMap(map['XMR'] as Map<String, dynamic>),
      invoiceTime: DateTime.fromMillisecondsSinceEpoch(map['invoice_time'] as int),
      expirationTime: DateTime.fromMillisecondsSinceEpoch(map['expiration_time'] as int),
      commission: map['commission'] as int?,
    );
  }
}

class CryptoPaymentData {
  final String price;
  final PaymentUrl? paymentUrls;
  final String address;

  CryptoPaymentData({
    required this.price,
    this.paymentUrls,
    required this.address,
  });

  factory CryptoPaymentData.fromMap(Map<String, dynamic> map) {
    return CryptoPaymentData(
      price: map['price'] as String,
      paymentUrls: PaymentUrl.fromMap(map['paymentUrls'] as Map<String, dynamic>?),
      address: map['address'] as String,
    );
  }
}

class PaymentUrl {
  final String? bip21;
  final String? bip72;
  final String? bip72b;
  final String? bip73;
  final String? bolt11;

  PaymentUrl({
    this.bip21,
    this.bip72,
    this.bip72b,
    this.bip73,
    this.bolt11,
  });

  factory PaymentUrl.fromMap(Map<String, dynamic>? map) {
    return PaymentUrl(
      bip21: map?['BIP21'] as String?,
      bip72: map?['BIP72'] as String?,
      bip72b: map?['BIP72b'] as String?,
      bip73: map?['BIP73'] as String?,
      bolt11: map?['BOLT11'] as String?,
    );
  }
}
