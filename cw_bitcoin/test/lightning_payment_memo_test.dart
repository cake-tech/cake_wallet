import "dart:convert";

import "package:breez_sdk_spark_flutter/breez_sdk_spark.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_bitcoin/lightning/utils.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/exceptions.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

Payment _lightningPayment(
  PaymentType paymentType, {
  String? description,
  LnurlPayInfo? lnurlPayInfo,
  LnurlReceiveMetadata? lnurlReceiveMetadata,
}) =>
    Payment(
      id: "payment",
      paymentType: paymentType,
      status: PaymentStatus.completed,
      amount: BigInt.from(100),
      fees: BigInt.zero,
      timestamp: BigInt.zero,
      method: PaymentMethod.lightning,
      details: PaymentDetails.lightning(
        description: description,
        invoice: "invoice",
        destinationPubkey: "pubkey",
        htlcDetails: SparkHtlcDetails(
          paymentHash: "hash",
          expiryTime: BigInt.zero,
          status: SparkHtlcStatus.preimageShared,
        ),
        lnurlPayInfo: lnurlPayInfo,
        lnurlReceiveMetadata: lnurlReceiveMetadata,
      ),
    );

Matcher _refusesWithLimit(int limit) => throwsA(
      isA<TransactionMemoNotAcceptedException>()
          .having((exception) => exception.maxLength, "maxLength", limit),
    );

void main() {
  group("ensureCommentAccepted", () {
    test("accepts no comment and a comment within the limit", () {
      ensureCommentAccepted(null, 0);
      ensureCommentAccepted("Thanks", 6);
    });

    test("refuses a comment the recipient has no room for", () {
      expect(() => ensureCommentAccepted("Thanks", 0), _refusesWithLimit(0));
      expect(() => ensureCommentAccepted("Thanks!", 6), _refusesWithLimit(6));
    });

    test("measures the comment in bytes", () {
      ensureCommentAccepted("спасибо", 14);
      expect(() => ensureCommentAccepted("спасибо", 13), _refusesWithLimit(13));
    });
  });

  group("lightningPaymentMemo", () {
    test("returns the comment sent with an LNURL payment", () {
      final payment = _lightningPayment(
        PaymentType.send,
        description: "Pay to konsti@cake.cash",
        lnurlPayInfo: const LnurlPayInfo(comment: "Thanks for dinner"),
      );

      expect(lightningPaymentMemo(payment), "Thanks for dinner");
    });

    test("returns nothing for an LNURL payment sent without a comment", () {
      final payment = _lightningPayment(
        PaymentType.send,
        description: "Pay to konsti@cake.cash",
        lnurlPayInfo: const LnurlPayInfo(),
      );

      expect(lightningPaymentMemo(payment), null);
    });

    test("returns the description of a paid invoice", () {
      final payment = _lightningPayment(PaymentType.send, description: "1 cup coffee");

      expect(lightningPaymentMemo(payment), "1 cup coffee");
    });

    test("returns the comment a sender attached to a received payment", () {
      final payment = _lightningPayment(
        PaymentType.receive,
        lnurlReceiveMetadata: const LnurlReceiveMetadata(senderComment: "Happy birthday"),
      );

      expect(lightningPaymentMemo(payment), "Happy birthday");
    });

    test("returns nothing for a received invoice payment", () {
      final payment = _lightningPayment(PaymentType.receive, description: "Send to Cake Wallet");

      expect(lightningPaymentMemo(payment), null);
    });

    test("returns nothing for a payment that is not a Lightning payment", () {
      final payment = Payment(
        id: "deposit",
        paymentType: PaymentType.receive,
        status: PaymentStatus.completed,
        amount: BigInt.from(100),
        fees: BigInt.zero,
        timestamp: BigInt.zero,
        method: PaymentMethod.deposit,
        details: const PaymentDetails.deposit(txId: "txid", vout: 0),
      );

      expect(lightningPaymentMemo(payment), null);
    });
  });

  group("redactPaymentComments", () {
    test("redacts the comment in a callback url", () {
      expect(
        redactPaymentComments(
          "Making GET request to: https://cake.cash/callback?amount=1000&comment=Thanks+for+dinner",
        ),
        "Making GET request to: https://cake.cash/callback?amount=1000&comment=<redacted>",
      );
      expect(
        redactPaymentComments("https://cake.cash/callback?comment=Hi%21&amount=1000 done"),
        "https://cake.cash/callback?comment=<redacted>&amount=1000 done",
      );
    });

    test("redacts sent and received comments in a payment dump", () {
      expect(
        redactPaymentComments(
          r'LnurlPayInfo { ln_address: Some("konsti@cake.cash"), '
          r'comment: Some("Thanks \"a\" lot"), domain: Some("cake.cash") }, '
          r'LnurlReceiveMetadata { sender_comment: Some("Happy birthday") }',
        ),
        r'LnurlPayInfo { ln_address: Some("konsti@cake.cash"), '
        r'comment: Some("<redacted>"), domain: Some("cake.cash") }, '
        r'LnurlReceiveMetadata { sender_comment: Some("<redacted>") }',
      );
    });

    test("redacts the comment in a sync record", () {
      expect(
        redactPaymentComments(
          r'{"lnurl_pay_info": Object {"comment": String("Thanks"), '
          r'"domain": String("cake.cash")}}',
        ),
        r'{"lnurl_pay_info": Object {"comment": String("<redacted>"), '
        r'"domain": String("cake.cash")}}',
      );
    });

    test("leaves other lines alone", () {
      const lines = [
        "Emitting payment event: Payment { comment: None, sender_comment: None }",
        "Making GET request to: https://cake.cash/.well-known/lnurlp/konsti",
        'description: Some("Send to Cake Wallet")',
      ];
      for (final line in lines) {
        expect(redactPaymentComments(line), line);
      }
    });
  });

  group("stored Lightning payment", () {
    test("keeps its memo when the history is saved and loaded", () {
      final payment = ElectrumTransactionInfo(
        WalletType.bitcoin,
        id: "payment",
        amount: Money.fromInt(1000, CryptoCurrency.btcln),
        fee: Money.fromInt(1, CryptoCurrency.btcln),
        direction: TransactionDirection.incoming,
        isPending: false,
        date: DateTime(2026, 11, 17, 12),
        confirmations: 0,
        additionalInfo: {"isLightning": true, "memo": "Happy birthday"},
      );

      final saved = jsonEncode(payment.toJson());
      final loaded = ElectrumTransactionInfo.fromJson(
        jsonDecode(saved) as Map<String, dynamic>,
        WalletType.bitcoin,
      );

      expect(loaded.additionalInfo["memo"], "Happy birthday");
    });
  });
}
