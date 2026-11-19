class CctpQuote {
  const CctpQuote({required this.maxFee});

  // Fast Transfer fee plus forwarding fee, deducted from the bridged amount, in USDC subunits.
  final BigInt maxFee;
}
