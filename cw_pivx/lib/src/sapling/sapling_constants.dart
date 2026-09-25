/// PIVX Sapling constants. Follows Zcash Sapling with PIVX network parameters.
library;

/// Diversifier (11) + pk_d (32).
const int kSaplingPaymentAddressSize = 43;

abstract class PivxSaplingNetwork {
  static const String mainnetPaymentAddressHrp = 'ps';

  static const int mainnetSaplingActivationHeight = 2700500;
}

/// Groth16 proving params; files are verified against these sizes and SHA256.
abstract class SaplingParams {
  static const String spendParamsFileName = 'sapling-spend.params';

  static const String outputParamsFileName = 'sapling-output.params';

  static const String spendParamsHash =
      '8e48ffd23abb3a5fd9c5589204f32d9c31285a04b78096ba40a79b75677efc13';

  static const String outputParamsHash =
      '2f0ebbcbb9bb0bcffe95a397e7eba89c29eb4dde6191c339db88570e3f3fb0e4';

  static const int spendParamsSize = 47958396;

  static const int outputParamsSize = 3592860;

  // PIVX Sapling uses Zcash's Sapling circuit, so the params are byte-identical
  // to Zcash's. Tried in order; every copy is checked against the hashes above.
  static const List<String> mirrors = [
    'https://download.z.cash/downloads',
    'https://duddino.com',
  ];
}

/// Mirrors PIVX Core v5.6.1 relay policy: shielded fee is 100x the min relay
/// fee on the serialized size, with transparent outputs priced at the EXM
/// size (one byte over P2PKH).
abstract class PivxFeePolicy {
  static const int minRelayFeePerKb = 10000;
  static const int dustRelayFeePerKb = 30000;
  static const int saplingFeeFactor = 100;
  static const int transparentDustThreshold = 5460;
  static const int shieldedDustThreshold = 1446000;

  static const int transparentInputSize = 148;

  /// Sized for the largest transparent output: an exchange (EXM) script is 26
  /// bytes (OP_EXCHANGEADDR), so 35 against P2PKH's 34. Estimates never see
  /// the output type. Cost: a P2PKH output prices 1 byte high, 1000 zat on a
  /// shielded fee (100x factor).
  static const int transparentOutputSize = 35;
  static const int transparentTxOverheadSize = 10;

  /// PIVX Core IsDust uses the real output size: dustRelayFeePerKb * (35 +
  /// 148) / 1000. A 34-byte P2PKH output gives transparentDustThreshold.
  static const int exchangeDustThreshold = 5490;

  static const int saplingSpendSize = 384;
  static const int saplingOutputSize = 948;

  /// The builder pads shielded outputs to this many with dummies (same as
  /// PIVX Core); the fee must cover the padded count.
  static const int minShieldedOutputs = 2;

  /// version/type (4) + locktime (4) + sapling flag (1) + valueBalance (8) +
  /// bindingSig (64); CompactSize count prefixes are added in [saplingTxSize].
  static const int saplingFixedOverheadSize = 81;

  /// Matches PIVX Core: 1 byte below 253, 3 bytes up to 65535.
  static int compactSizeLength(int count) =>
      count < 0xfd ? 1 : (count <= 0xffff ? 3 : 5);

  static int feeForSize(int size, {int feePerKb = minRelayFeePerKb}) {
    if (size <= 0) return minRelayFeePerKb;
    final fee = (feePerKb * size + 999) ~/ 1000;
    if (feePerKb == minRelayFeePerKb && fee < minRelayFeePerKb) {
      return minRelayFeePerKb;
    }
    return fee;
  }

  // Final transparent fees use the serialized size; this is the preview.
  static int transparentTxSize(int inputsCount, int outputsCount) =>
      inputsCount * transparentInputSize +
      outputsCount * transparentOutputSize +
      transparentTxOverheadSize;

  static int saplingTxSize({
    int saplingInputs = 0,
    int saplingOutputs = 0,
    int transparentInputs = 0,
    int transparentOutputs = 0,
  }) {
    final effectiveSaplingOutputs = saplingOutputs > minShieldedOutputs
        ? saplingOutputs
        : minShieldedOutputs;
    // The fee is pinned to this size; an under-estimate is rejected as
    // insufficient fee. Transparent outputs carry a 1-byte EXM margin.
    return saplingFixedOverheadSize +
        compactSizeLength(transparentInputs) +
        compactSizeLength(transparentOutputs) +
        compactSizeLength(saplingInputs) +
        compactSizeLength(effectiveSaplingOutputs) +
        (saplingInputs * saplingSpendSize) +
        (effectiveSaplingOutputs * saplingOutputSize) +
        (transparentInputs * transparentInputSize) +
        (transparentOutputs * transparentOutputSize);
  }

  static int saplingFee({
    int saplingInputs = 0,
    int saplingOutputs = 0,
    int transparentInputs = 0,
    int transparentOutputs = 0,
  }) =>
      saplingFeeFactor *
      feeForSize(
        saplingTxSize(
          saplingInputs: saplingInputs,
          saplingOutputs: saplingOutputs,
          transparentInputs: transparentInputs,
          transparentOutputs: transparentOutputs,
        ),
      );
}
