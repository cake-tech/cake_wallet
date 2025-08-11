enum CakePayPaymentMethod { BTC, BTC_LN, XMR, LTC, LTC_MWEB }

extension CakePayPaymentMethodLabel on CakePayPaymentMethod {
  String get label => switch (this) {
        CakePayPaymentMethod.BTC => 'Bitcoin',
        CakePayPaymentMethod.BTC_LN => 'Bitcoin Lightning',
        CakePayPaymentMethod.XMR => 'Monero',
        CakePayPaymentMethod.LTC => 'Litecoin',
        CakePayPaymentMethod.LTC_MWEB => 'Litecoin MWEB',
      };
}

class CakePayOrder {
  final String orderId;
  final List<OrderCard> cards;
  final String? externalId;
  final double amountUsd;
  final String totalReceiveAmount;
  final int quantity;
  final String status;
  final String? vouchers;
  final String fiatCurrencyCode;
  final PaymentData paymentData;

  CakePayOrder({
    required this.orderId,
    required this.cards,
    required this.externalId,
    required this.amountUsd,
    required this.totalReceiveAmount,
    required this.quantity,
    required this.status,
    required this.vouchers,
    required this.fiatCurrencyCode,
    required this.paymentData,
  });

  factory CakePayOrder.fromMap(Map<String, dynamic> map) {

    final cards = map['cards'] as List<dynamic>;
    final firstCard = cards.isNotEmpty ? cards.first as Map<String, dynamic> : {};

    return CakePayOrder(
        orderId: map['order_id'] as String,
        cards: cards
            .map((x) => OrderCard.fromMap(x as Map<String, dynamic>))
            .toList(),
        externalId: map['external_id'] as String?,
        amountUsd: map['amount_usd'] as double,
        totalReceiveAmount: firstCard['subtotal'] as String? ?? '',
        quantity: firstCard['quantity'] as int,
        status: map['status'] as String,
        vouchers: map['vouchers'] as String?,
        fiatCurrencyCode: firstCard['currency_code'] as String? ?? '',
        paymentData: PaymentData.fromMap(map['payment_data'] as Map<String, dynamic>));
  }

  static CryptoPaymentData? getPaymentDataFor({CakePayPaymentMethod? method,CakePayOrder? order}) {
    if (order == null || method == null) return null;

    final data = switch (method) {
      CakePayPaymentMethod.BTC => order.paymentData.btc,
      CakePayPaymentMethod.XMR => order.paymentData.xmr,
      CakePayPaymentMethod.LTC => order.paymentData.ltc,
      CakePayPaymentMethod.LTC_MWEB => order.paymentData.ltc_mweb,
      _ => null
    };

    if (data == null) return null;

    final bip21 = data.paymentUrls?.bip21;
    if (bip21 != null && bip21.isNotEmpty) {
      final uri = Uri.parse(bip21);
      final addr = uri.path;
      final price = uri.queryParameters['amount'] ?? data.price;

      return CryptoPaymentData(price: price, address: addr, amount: data.amount, paymentUrls: data.paymentUrls);
    }

    return data;
  }

  static String getCurrencyCodeFromPaymentMethod(CakePayPaymentMethod method) {
    return switch (method) {
      CakePayPaymentMethod.BTC => 'BTC',
      CakePayPaymentMethod.BTC_LN => 'BTC',
      CakePayPaymentMethod.XMR => 'XMR',
      CakePayPaymentMethod.LTC => 'LTC',
      CakePayPaymentMethod.LTC_MWEB => 'LTC',
    };
  }
}

class OrderCard {
  final int cardId;
  final int? externalId;
  final String price;
  final int quantity;
  final String currencyCode;
  final String? cardName;
  final String? cardImagePath;

  OrderCard({
    required this.cardId,
    required this.externalId,
    required this.price,
    required this.quantity,
    required this.currencyCode,
    required this.cardName,
    required this.cardImagePath,
  });

  factory OrderCard.fromMap(Map<String, dynamic> map) {
    return OrderCard(
      cardId: map['card_id'] as int,
      externalId: map['external_id'] as int?,
      price: map['price'] as String,
      quantity: map['quantity'] as int,
      currencyCode: map['currency_code'] as String,
      cardName: map['name'] as String?,
      cardImagePath: map['card_image_url'] as String?,
    );
  }
}

class PaymentData {
  final CryptoPaymentData btc;
  final CryptoPaymentData btc_ln;
  final CryptoPaymentData xmr;
  final CryptoPaymentData ltc;
  final CryptoPaymentData ltc_mweb;
  final DateTime invoiceTime;
  final DateTime expirationTime;
  final int? commission;

  PaymentData({
    required this.btc,
    required this.btc_ln,
    required this.xmr,
    required this.ltc,
    required this.ltc_mweb,
    required this.invoiceTime,
    required this.expirationTime,
    required this.commission,
  });

  factory PaymentData.fromMap(Map<String, dynamic> map) {
    return PaymentData(
      btc: CryptoPaymentData.fromMap(map['BTC'] as Map<String, dynamic>),
      btc_ln: CryptoPaymentData.fromMap(map['BTC_LN'] as Map<String, dynamic>),
      xmr: CryptoPaymentData.fromMap(map['XMR'] as Map<String, dynamic>),
      ltc: CryptoPaymentData.fromMap(map['LTC'] as Map<String, dynamic>),
      ltc_mweb: CryptoPaymentData.fromMap(map['LTC_MWEB'] as Map<String, dynamic>),
      invoiceTime: DateTime.fromMillisecondsSinceEpoch(map['invoice_time'] as int),
      expirationTime: DateTime.fromMillisecondsSinceEpoch(map['expiration_time'] as int),
      commission: map['commission'] as int?,
    );
  }
}

class CryptoPaymentData {
  final String price;
  final String amount;
  final PaymentUrl? paymentUrls;
  final String address;

  CryptoPaymentData({
    required this.price,
    required this.amount,
    this.paymentUrls,
    required this.address,
  });

  factory CryptoPaymentData.fromMap(Map<String, dynamic> map) {
    return CryptoPaymentData(
      price: map['price'] as String,
      amount: (map['amount_from'] as double?)?.toString() ?? '',
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
