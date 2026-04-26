class USDT0Quote {
  const USDT0Quote({
    required this.nativeFee,
    required this.lzTokenFee,
  });

  /// Fee in native token (e.g. ETH, MATIC) in wei.
  final BigInt nativeFee;

  /// Fee in LZ token (if paying with LZ token).
  final BigInt lzTokenFee;

  @override
  String toString() => 'USDT0Quote(nativeFee: $nativeFee, lzTokenFee: $lzTokenFee)';
}
