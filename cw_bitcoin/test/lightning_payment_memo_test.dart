import "package:breez_sdk_spark_flutter/breez_sdk_spark.dart";
import "package:cw_bitcoin/lightning/utils.dart";
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

void main() {
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
}
