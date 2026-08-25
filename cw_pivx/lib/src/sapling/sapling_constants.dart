/// PIVX Sapling protocol constants. PIVX Sapling follows Zcash Sapling with
/// PIVX-specific network parameters (notably the address HRP strings).
library;

/// Sapling note commitment tree depth: a 32-level Merkle tree (2^32 leaves).
const int kSaplingTreeDepth = 32;

/// Sapling extended spending key size in bytes.
const int kSaplingExtendedSpendingKeySize = 169;

/// Sapling extended full viewing key size in bytes.
const int kSaplingExtendedFullViewingKeySize = 169;

/// Sapling payment address size in bytes.
const int kSaplingPaymentAddressSize = 43;

/// Sapling note plaintext size in bytes.
const int kSaplingNotePlaintextSize = 580;

/// Sapling diversifier size in bytes.
const int kSaplingDiversifierSize = 11;

abstract class PivxSaplingNetwork {
  /// BIP-44 coin type for mainnet (used in key derivation).
  static const int mainnetCoinType = 119;

  /// BIP-44 coin type for testnet (used in key derivation).
  static const int testnetCoinType = 1;

  /// Payment address HRP (mainnet); addresses start with "ps".
  static const String mainnetPaymentAddressHrp = 'ps';

  /// Payment address HRP (testnet); addresses start with "ptestsapling".
  static const String testnetPaymentAddressHrp = 'ptestsapling';

  /// Extended spending key HRP (mainnet); starts with "p-secret-extended-key-main".
  static const String mainnetExtendedSpendingKeyHrp =
      'p-secret-extended-key-main';

  /// Extended spending key HRP (testnet); starts with "p-secret-extended-key-test".
  static const String testnetExtendedSpendingKeyHrp =
      'p-secret-extended-key-test';

  /// Full viewing key HRP (mainnet); keys start with "pviews".
  static const String mainnetFullViewingKeyHrp = 'pviews';

  /// Full viewing key HRP (testnet); keys start with "pviewtestsapling".
  static const String testnetFullViewingKeyHrp = 'pviewtestsapling';

  /// Incoming viewing key HRP (mainnet); keys start with "pivks".
  static const String mainnetIncomingViewingKeyHrp = 'pivks';

  /// Incoming viewing key HRP (testnet); keys start with "pivktestsapling".
  static const String testnetIncomingViewingKeyHrp = 'pivktestsapling';

  /// Mainnet Sapling activation height; shielded scanning starts here.
  static const int mainnetSaplingActivationHeight = 2700500;

  /// Testnet Sapling activation height. Confirmed against PIVX Core v5.6.1
  /// `src/chainparams.cpp`.
  static const int testnetSaplingActivationHeight = 201;

  /// Default shield-sync start: a buffer before activation so no tx is missed.
  static const int mainnetDefaultStartingShieldBlock = 2700000;

  static const int testnetDefaultStartingShieldBlock = 201;
}

/// Sapling proving-parameter files: one for spends, one for outputs (zk-SNARK).
abstract class SaplingParams {
  static const String spendParamsFileName = 'sapling-spend.params';

  static const String outputParamsFileName = 'sapling-output.params';

  /// Expected SHA256 of sapling-spend.params; guards against corruption/tampering.
  static const String spendParamsHash =
      '8e48ffd23abb3a5fd9c5589204f32d9c31285a04b78096ba40a79b75677efc13';

  /// Expected SHA256 hash of sapling-output.params.
  static const String outputParamsHash =
      '2f0ebbcbb9bb0bcffe95a397e7eba89c29eb4dde6191c339db88570e3f3fb0e4';

  /// Size of sapling-spend.params file in bytes (approximately 47.5 MB).
  static const int spendParamsSize = 47958396;

  /// Size of sapling-output.params file in bytes (approximately 3.6 MB).
  static const int outputParamsSize = 3592860;

  /// URL for downloading sapling-spend.params (PIVX hosting).
  static const String spendParamsUrl =
      'https://duddino.com/sapling-spend.params';

  /// URL for downloading sapling-output.params (PIVX hosting).
  static const String outputParamsUrl =
      'https://duddino.com/sapling-output.params';
}

/// PIVX transaction fee and dust policy shared by transparent and Sapling code.
///
/// These values mirror PIVX Core's v5.6.1 relay policy: min relay fee of
/// 10,000 zatoshis/kB, dust relay fee of 30,000 zatoshis/kB, Sapling relay fee
/// factor of 100, transparent dust threshold of 5,460 zatoshis, and shielded
/// dust threshold of 1,446,000 zatoshis.
abstract class PivxFeePolicy {
  static const int zatoshisPerPiv = 100000000;
  static const int minRelayFeePerKb = 10000;
  static const int dustRelayFeePerKb = 30000;
  static const int saplingFeeFactor = 100;
  static const int transparentDustThreshold = 5460;
  static const int shieldedDustThreshold = 1446000;
  static const int dustThreshold = transparentDustThreshold;
  static const int maxReasonableFee = zatoshisPerPiv;

  static const int transparentInputSize = 148;
  static const int transparentOutputSize = 34;
  static const int transparentTxOverheadSize = 10;

  static const int saplingSpendSize = 384;
  static const int saplingOutputSize = 948;
  static const int saplingTxOverheadSize = 85;

  /// The Sapling builder (BundleType::Transactional, bundle_required) pads
  /// shielded outputs to at least this many with zero-value dummy outputs, a
  /// protocol privacy rule shared with PIVX Core. The fee must cover the padded
  /// count or the node rejects the tx as insufficient fee.
  static const int minShieldedOutputs = 2;

  /// Fixed non-count serialization bytes: version/type (4) + locktime (4) +
  /// sapling-data flag (1) + valueBalance (8) + bindingSig (64). The four
  /// CompactSize vector-count prefixes are added separately in [saplingTxSize].
  static const int saplingFixedOverheadSize = 81;

  /// CompactSize prefix length for a vector of [count] elements, matching PIVX
  /// Core: 1 byte below 253, 3 bytes up to 65535.
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
    // The builder pads shielded outputs to [minShieldedOutputs] with dummy
    // outputs, so the wire tx has that many even with fewer real outputs.
    final effectiveSaplingOutputs = saplingOutputs > minShieldedOutputs
        ? saplingOutputs
        : minShieldedOutputs;
    // Fixed bytes + the four CompactSize vector-count prefixes. Below 253
    // elements each prefix is 1 byte and this equals saplingTxOverheadSize
    // (85); at >=253 a prefix grows to 3 bytes so the estimate stays an exact
    // upper bound on the real serialized size. The shielded fee is pinned to
    // this exact size with no margin, so an under-estimate here is rejected by
    // the network as "insufficient fee".
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

  static bool isDust(int amount, {bool shielded = false}) =>
      amount > 0 &&
      amount < (shielded ? shieldedDustThreshold : transparentDustThreshold);
}

/// Backwards-compatible Sapling fee facade.
abstract class SaplingFees {
  static const int feePerKb = PivxFeePolicy.minRelayFeePerKb;
  static const int saplingOutputSize = PivxFeePolicy.saplingOutputSize;
  static const int saplingSpendSize = PivxFeePolicy.saplingSpendSize;
  static const int transparentInputSize = PivxFeePolicy.transparentInputSize;
  static const int transparentOutputSize = PivxFeePolicy.transparentOutputSize;
  static const int txOverheadSize = PivxFeePolicy.saplingTxOverheadSize;

  static int calculateFee({
    int saplingInputs = 0,
    int saplingOutputs = 0,
    int transparentInputs = 0,
    int transparentOutputs = 0,
  }) =>
      PivxFeePolicy.saplingFee(
        saplingInputs: saplingInputs,
        saplingOutputs: saplingOutputs,
        transparentInputs: transparentInputs,
        transparentOutputs: transparentOutputs,
      );
}
