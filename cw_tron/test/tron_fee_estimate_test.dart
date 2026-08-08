import "package:cw_tron/tron_fee_estimate.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const energyUsed = 65000;
  const energyPrice = 210;

  TronFeeEstimate estimate({required int availableEnergy}) => calculateTronFeeEstimate(
        energyUsed: energyUsed,
        availableEnergy: availableEnergy,
        energyPrice: energyPrice,
        bandwidthUsed: 0,
        availableBandwidth: 0,
        bandwidthPrice: 1000,
        useAvailableBandwidth: true,
      );

  test("uses the full Energy cost as the fee limit without available Energy", () {
    final result = estimate(availableEnergy: 0);

    expect(result.feeLimit, energyUsed * energyPrice);
    expect(result.estimatedBurn, energyUsed * energyPrice);
  });

  test("available Energy reduces only the estimated burn", () {
    final result = estimate(availableEnergy: 20000);

    expect(result.feeLimit, energyUsed * energyPrice);
    expect(result.estimatedBurn, (energyUsed - 20000) * energyPrice);
  });

  test("fully covered Energy keeps the full fee limit with no estimated burn", () {
    final result = estimate(availableEnergy: 130000);

    expect(result.feeLimit, energyUsed * energyPrice);
    expect(result.estimatedBurn, 0);
  });

  test("bandwidth and memo fees affect the burn but not the Energy limit", () {
    final result = calculateTronFeeEstimate(
      energyUsed: energyUsed,
      availableEnergy: energyUsed,
      energyPrice: energyPrice,
      bandwidthUsed: 300,
      availableBandwidth: 0,
      bandwidthPrice: 1000,
      useAvailableBandwidth: true,
      memoFee: 1000000,
    );

    expect(result.feeLimit, energyUsed * energyPrice);
    expect(result.estimatedBurn, 1300000);
  });
}
