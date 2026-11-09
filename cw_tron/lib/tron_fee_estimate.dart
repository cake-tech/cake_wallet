class TronFeeEstimate {
  const TronFeeEstimate({
    required this.feeLimit,
    required this.estimatedBurn,
  });

  const TronFeeEstimate.zero()
      : feeLimit = 0,
        estimatedBurn = 0;

  factory TronFeeEstimate.calculate({
    required int energyUsed,
    required int availableEnergy,
    required int energyPrice,
    required int bandwidthUsed,
    required bool isBandwidthBurned,
    required int bandwidthPrice,
    int memoFee = 0,
  }) {
    final energyToBurn = energyUsed > availableEnergy ? energyUsed - availableEnergy : 0;
    final bandwidthToBurn = isBandwidthBurned ? bandwidthUsed : 0;

    return TronFeeEstimate(
      feeLimit: energyUsed * energyPrice * 120 ~/ 100, // the 20% covers any dynamic energy increase that can happen
      estimatedBurn: energyToBurn * energyPrice + bandwidthToBurn * bandwidthPrice + memoFee,
    );
  }

  final int feeLimit;
  final int estimatedBurn;
}
