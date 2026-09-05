class TronFeeEstimate {
  const TronFeeEstimate({
    required this.feeLimit,
    required this.estimatedBurn,
  });

  const TronFeeEstimate.zero()
      : feeLimit = 0,
        estimatedBurn = 0;

  final int feeLimit;
  final int estimatedBurn;
}

TronFeeEstimate calculateTronFeeEstimate({
  required int energyUsed,
  required int availableEnergy,
  required int energyPrice,
  required int bandwidthUsed,
  required int availableBandwidth,
  required int bandwidthPrice,
  required bool useAvailableBandwidth,
  int memoFee = 0,
}) {
  // Available Energy reduces the amount of TRX that may be burned, but it does not reduce the
  // execution budget declared by the transaction's fee limit.
  final energyToBurn = energyUsed > availableEnergy ? energyUsed - availableEnergy : 0;
  final bandwidthToBurn =
      useAvailableBandwidth && availableBandwidth >= bandwidthUsed ? 0 : bandwidthUsed;

  return TronFeeEstimate(
    feeLimit: energyUsed * energyPrice,
    estimatedBurn: energyToBurn * energyPrice + bandwidthToBurn * bandwidthPrice + memoFee,
  );
}
