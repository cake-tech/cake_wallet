import "package:bip39/bip39.dart" as bip39;
import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_mnemonic.dart" show mnemonicToSeedBytes;
import "package:cw_core/utils/print_verbose.dart";

/// The seed algorithm a recovery chain's master key comes from.
enum RecoverySeedType { bip39, electrum }

/// A mnemonic's master keys under both seed algorithms.
class RecoveryMasters {
  RecoveryMasters.fromSeeds({required List<int> bip39Seed, required List<int> electrumSeed})
      : _masters = {
          RecoverySeedType.bip39: Bip32Slip10Secp256k1.fromSeed(bip39Seed),
          RecoverySeedType.electrum: Bip32Slip10Secp256k1.fromSeed(electrumSeed),
        };

  static Future<RecoveryMasters> fromMnemonic(String mnemonic, {String passphrase = ""}) async =>
      RecoveryMasters.fromSeeds(
        bip39Seed: bip39.mnemonicToSeed(mnemonic, passphrase: passphrase),
        electrumSeed: await mnemonicToSeedBytes(mnemonic, passphrase: passphrase),
      );

  final Map<RecoverySeedType, Bip32Slip10Secp256k1> _masters;

  Bip32Slip10Secp256k1 operator [](RecoverySeedType seedType) => _masters[seedType]!;
}

/// The receive (0) or change (1) chain of one derivation path, searched as [addressTypes].
class RecoveryChain {
  const RecoveryChain(this.seedType, this.path, this.addressTypes);

  final RecoverySeedType seedType;

  /// From the master key, e.g. `m/84'/0'/0'/1`, or `m/0` for the master key's own receive chain.
  final String path;

  final List<BitcoinAddressType> addressTypes;

  bool get isChange => path.endsWith("/1");

  Bip32Slip10Secp256k1 hd(RecoveryMasters masters) =>
      masters[seedType].derivePath(path) as Bip32Slip10Secp256k1;

  @override
  String toString() => "${seedType.name} $path";
}

/// Every chain the recovery searches, for both seed algorithms:
/// - `m/0`, `m/1`: the master key's own chains (Electrum 2 standard wallets, and wallets whose
///   saved derivation path was empty, which collapses to the master key), P2WPKH and P2PKH;
/// - `m/0'/0`, `m/0'/1`: Electrum segwit, P2WPKH;
/// - `m/{44,49,84,86}'/{coinType}'/0'/{0,1}` for the native coin type and Bitcoin's 0, each as its
///   purpose's own address type and as P2WPKH.
List<RecoveryChain> recoveryChains({required int nativeCoinType, required bool supportsTaproot}) =>
    [
      for (final seedType in RecoverySeedType.values) ...[
        ..._chains(seedType, "m", const [SegwitAddresType.p2wpkh, P2pkhAddressType.p2pkh]),
        ..._chains(seedType, "m/0'", const [SegwitAddresType.p2wpkh]),
        for (final coinType in {nativeCoinType, 0}) ...[
          ..._chains(
            seedType,
            "m/44'/$coinType'/0'",
            const [P2pkhAddressType.p2pkh, SegwitAddresType.p2wpkh],
          ),
          ..._chains(
            seedType,
            "m/49'/$coinType'/0'",
            const [P2shAddressType.p2wpkhInP2sh, SegwitAddresType.p2wpkh],
          ),
          ..._chains(seedType, "m/84'/$coinType'/0'", const [SegwitAddresType.p2wpkh]),
          ..._chains(
            seedType,
            "m/86'/$coinType'/0'",
            [if (supportsTaproot) SegwitAddresType.p2tr, SegwitAddresType.p2wpkh],
          ),
        ],
      ],
    ];

List<RecoveryChain> _chains(
  RecoverySeedType seedType,
  String accountPath,
  List<BitcoinAddressType> addressTypes,
) =>
    [
      RecoveryChain(seedType, "$accountPath/0", addressTypes),
      RecoveryChain(seedType, "$accountPath/1", addressTypes),
    ];

/// The [type] address of [publicKey], as the wallet encodes it.
String addressForPublicKey(ECPublic publicKey, BitcoinAddressType type, BasedUtxoNetwork network) {
  if (type == P2pkhAddressType.p2pkh) {
    return publicKey.toP2pkhAddress().toAddress(network);
  }
  if (type == SegwitAddresType.p2tr) {
    return publicKey.toTaprootAddress().toAddress(network);
  }
  if (type == SegwitAddresType.p2wsh) {
    return publicKey.toP2wshAddress().toAddress(network);
  }
  if (type == P2shAddressType.p2wpkhInP2sh) {
    return publicKey.toP2wpkhInP2sh().toAddress(network);
  }
  return publicKey.toP2wpkhAddress().toAddress(network);
}

/// Generates the address string for the [hd] child at [index] encoded as
/// [type].  Mirrors the dispatch logic in BitcoinWalletAddresses.getAddress().
String generateAddressForType({
  required Bip32Slip10Secp256k1 hd,
  required int index,
  required BitcoinAddressType type,
  required BasedUtxoNetwork network,
}) =>
    addressForPublicKey(
      ECPublic.fromBip32(hd.childKey(Bip32KeyIndex(index)).publicKey),
      type,
      network,
    );

/// Searches [candidateHDs] across indices 0..[maxIndex) for a child key whose
/// derived address (encoded as [targetType]) matches [targetAddress].
/// Returns the [ECPrivate] on match, or null if not found.
ECPrivate? bruteForcePrivkeyForAddress({
  required String targetAddress,
  required BitcoinAddressType targetType,
  required Iterable<Bip32Slip10Secp256k1> candidateHDs,
  required BasedUtxoNetwork network,
  int maxIndex = 1000,
}) {
  for (final hd in candidateHDs) {
    for (int i = 0; i < maxIndex; i++) {
      if (generateAddressForType(hd: hd, index: i, type: targetType, network: network) ==
          targetAddress) {
        printV("Found address at index $i");
        return ECPrivate(hd.childKey(Bip32KeyIndex(i)).privateKey);
      }
    }
  }
  return null;
}

/// A key found on a recovery chain.
class RecoveryKey {
  RecoveryKey(this.chain, this.index, this.privateKey);

  final RecoveryChain chain;
  final int index;
  final ECPrivate privateKey;
}

const _timeSlice = Duration(milliseconds: 16);

/// Yields to the UI isolate once [slice] has run for a frame's worth of time.
Future<void> yieldIfSliceElapsed(Stopwatch slice) async {
  if (slice.elapsed >= _timeSlice) {
    await Future<void>.delayed(Duration.zero);
    slice.reset();
  }
}

/// Searches every one of [chains] for [address], encoded as [type], across indices 0..[maxIndex),
/// yielding to the UI isolate as it goes. Null when nothing matches.
Future<RecoveryKey?> searchRecoveryKey({
  required RecoveryMasters masters,
  required List<RecoveryChain> chains,
  required String address,
  required BitcoinAddressType type,
  required BasedUtxoNetwork network,
  int maxIndex = 1000,
}) async {
  final slice = Stopwatch()..start();
  for (final chain in chains) {
    final hd = chain.hd(masters);
    for (var index = 0; index < maxIndex; index++) {
      final child = hd.childKey(Bip32KeyIndex(index));
      if (addressForPublicKey(ECPublic.fromBip32(child.publicKey), type, network) == address) {
        return RecoveryKey(chain, index, ECPrivate(child.privateKey));
      }
      await yieldIfSliceElapsed(slice);
    }
  }
  return null;
}
