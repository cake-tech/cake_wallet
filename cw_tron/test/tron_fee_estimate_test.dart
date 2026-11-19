import "package:cw_tron/tron_fee_estimate.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const usdtTransferEnergy = 64285;
  const energyPrice = 210;
  const transactionBytes = 339;
  const bandwidthPrice = 1000;

  TronFeeEstimate estimate({
    required int availableEnergy,
    bool isBandwidthBurned = true,
    int memoFee = 0,
  }) =>
      TronFeeEstimate.calculate(
        energyUsed: usdtTransferEnergy,
        availableEnergy: availableEnergy,
        energyPrice: energyPrice,
        bandwidthUsed: transactionBytes,
        isBandwidthBurned: isBandwidthBurned,
        bandwidthPrice: bandwidthPrice,
        memoFee: memoFee,
      );

  test("rented energy that covers the call still gets a fee limit for the whole call", () {
    final result = estimate(availableEnergy: 130000);

    expect(result.feeLimit ~/ energyPrice, greaterThanOrEqualTo(usdtTransferEnergy));
    expect(result.feeLimit, 16199820);
    expect(result.estimatedBurn, 339000);
  });

  test("rented energy and free bandwidth burn nothing but keep the fee limit", () {
    final result = estimate(availableEnergy: 130000, isBandwidthBurned: false);

    expect(result.feeLimit, 16199820);
    expect(result.estimatedBurn, 0);
  });

  test("partial energy only lowers the burn", () {
    final result = estimate(availableEnergy: 20000);

    expect(result.feeLimit, 16199820);
    expect(result.estimatedBurn, 44285 * energyPrice + 339000);
  });

  test("no energy burns the whole call", () {
    final result = estimate(availableEnergy: 0);

    expect(result.feeLimit, 16199820);
    expect(result.estimatedBurn, usdtTransferEnergy * energyPrice + 339000);
  });

  test("memo fee adds to the burn and not to the fee limit", () {
    final result = estimate(availableEnergy: 130000, isBandwidthBurned: false, memoFee: 1000000);

    expect(result.feeLimit, 16199820);
    expect(result.estimatedBurn, 1000000);
  });

  test("native transfers use no energy", () {
    final result = TronFeeEstimate.calculate(
      energyUsed: 0,
      availableEnergy: 0,
      energyPrice: energyPrice,
      bandwidthUsed: 268,
      isBandwidthBurned: true,
      bandwidthPrice: bandwidthPrice,
    );

    expect(result.feeLimit, 0);
    expect(result.estimatedBurn, 268000);
  });
}
