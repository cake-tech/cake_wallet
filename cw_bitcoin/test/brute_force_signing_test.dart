import 'dart:math';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_bitcoin/bitcoin_mnemonic.dart' as electrum_mnemonic;
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Generates a cryptographically random 64-byte seed.
Uint8List _randomSeed() {
  final rng = Random.secure();
  return Uint8List.fromList(List.generate(64, (_) => rng.nextInt(256)));
}

class _HDSet {
  final Map<BitcoinAddressType, Bip32Slip10Secp256k1> mainHdByType;
  final Map<BitcoinAddressType, Bip32Slip10Secp256k1> sideHdByType;
  final Bip32Slip10Secp256k1 legacyMainHd;
  final Bip32Slip10Secp256k1 legacySideHd;
  final Bip32Slip10Secp256k1 master;

  _HDSet({
    required this.mainHdByType,
    required this.sideHdByType,
    required this.legacyMainHd,
    required this.legacySideHd,
    required this.master,
  });

  /// All HD nodes visible to the wallet (as ElectrumWallet collects them) plus
  /// the expanded Bitcoin-path and native-coin-type sets that the brute-force
  /// method adds at runtime.
  Set<Bip32Slip10Secp256k1> expandedHDs({required int nativeCoinType}) {
    final hds = <Bip32Slip10Secp256k1>{
      ...mainHdByType.values,
      ...sideHdByType.values,
      legacyMainHd,
      legacySideHd,
    };
    // Mirror the expansion performed by _bruteForcePrivkeyForAddress:
    // 1. Electrum path (m/0'), receive and change branches.
    hds.add(master.derivePath("m/0'/0") as Bip32Slip10Secp256k1);
    hds.add(master.derivePath("m/0'/1") as Bip32Slip10Secp256k1);
    // 2. All BIP purposes × {0, nativeCoinType}, receive and change branches.
    for (final coinType in {0, nativeCoinType}) {
      for (final purpose in [44, 49, 84, 86]) {
        final base = "m/$purpose'/$coinType'/0'";
        hds.add(master.derivePath("$base/0") as Bip32Slip10Secp256k1);
        hds.add(master.derivePath("$base/1") as Bip32Slip10Secp256k1);
      }
    }
    return hds;
  }
}

/// Builds the HD structure that ElectrumWallet creates for a BIP39 Bitcoin
/// wallet (coin type 0) on mainnet.
_HDSet _buildBitcoinHDs(Uint8List seedBytes) {
  final master = Bip32Slip10Secp256k1.fromSeed(seedBytes);
  Bip32Slip10Secp256k1 d(String p) => master.derivePath(p) as Bip32Slip10Secp256k1;

  final mainHdByType = <BitcoinAddressType, Bip32Slip10Secp256k1>{
    SegwitAddresType.p2wpkh:       d("m/84'/0'/0'/0"),
    P2pkhAddressType.p2pkh:        d("m/44'/0'/0'/0"),
    SegwitAddresType.p2tr:         d("m/86'/0'/0'/0"),
    SegwitAddresType.p2wsh:        d("m/84'/0'/0'/0"),
    P2shAddressType.p2wpkhInP2sh:  d("m/49'/0'/0'/0"),
  };
  final sideHdByType = <BitcoinAddressType, Bip32Slip10Secp256k1>{
    SegwitAddresType.p2wpkh:       d("m/84'/0'/0'/1"),
    P2pkhAddressType.p2pkh:        d("m/44'/0'/0'/1"),
    SegwitAddresType.p2tr:         d("m/86'/0'/0'/1"),
    SegwitAddresType.p2wsh:        d("m/84'/0'/0'/1"),
    P2shAddressType.p2wpkhInP2sh:  d("m/49'/0'/0'/1"),
  };
  final accountHD = d("m/84'/0'/0'");
  return _HDSet(
    mainHdByType: mainHdByType,
    sideHdByType: sideHdByType,
    legacyMainHd: accountHD.childKey(Bip32KeyIndex(0)),
    legacySideHd: accountHD.childKey(Bip32KeyIndex(1)),
    master: master,
  );
}

/// Builds the HD structure that ElectrumWallet creates for a BIP39 Litecoin
/// wallet (coin type 2) on mainnet.  Note: the wallet only puts p2wpkh into
/// mainHdByType by default (LITECOIN_ADDRESS_TYPES = [p2wpkh, mweb]).
_HDSet _buildLitecoinHDs(Uint8List seedBytes) {
  final master = Bip32Slip10Secp256k1.fromSeed(seedBytes);
  Bip32Slip10Secp256k1 d(String p) => master.derivePath(p) as Bip32Slip10Secp256k1;

  // Litecoin's LITECOIN_ADDRESS_TYPES only includes p2wpkh (+ mweb which
  // doesn't participate in this signing flow), so mainHdByType is narrow.
  final mainHdByType = <BitcoinAddressType, Bip32Slip10Secp256k1>{
    SegwitAddresType.p2wpkh: d("m/84'/2'/0'/0"),
  };
  final sideHdByType = <BitcoinAddressType, Bip32Slip10Secp256k1>{
    SegwitAddresType.p2wpkh: d("m/84'/2'/0'/1"),
  };
  final accountHD = d("m/84'/2'/0'");
  return _HDSet(
    mainHdByType: mainHdByType,
    sideHdByType: sideHdByType,
    legacyMainHd: accountHD.childKey(Bip32KeyIndex(0)),
    legacySideHd: accountHD.childKey(Bip32KeyIndex(1)),
    master: master,
  );
}

/// Mirrors the address-generation logic of _initAltSeedAddresses (post 200-address
/// expansion).  Returns every P2WPKH address that would be subscribed on restore:
/// both seeds × (Electrum m/0' + all BIP purposes × {coinType, 0}) × 200 indices.
Set<String> _simulateAltSeedAddresses({
  required Bip32Slip10Secp256k1 primaryMaster,
  required Bip32Slip10Secp256k1 altMaster,
  required int coinType,
  required BasedUtxoNetwork network,
  int count = 200,
}) {
  final addresses = <String>{};
  for (final master in [primaryMaster, altMaster]) {
    Bip32Slip10Secp256k1 d(String p) => master.derivePath(p) as Bip32Slip10Secp256k1;
    void fromBranch(Bip32Slip10Secp256k1 rx, Bip32Slip10Secp256k1 ch) {
      for (int i = 0; i < count; i++) {
        addresses.add(generateP2WPKHAddress(hd: rx, index: i, network: network));
        addresses.add(generateP2WPKHAddress(hd: ch, index: i, network: network));
      }
    }
    fromBranch(d("m/0'/0"), d("m/0'/1"));
    for (final ct in {coinType, 0}) {
      for (final purpose in [44, 49, 84, 86]) {
        fromBranch(d("m/$purpose'/$ct'/0'/0"), d("m/$purpose'/$ct'/0'/1"));
      }
    }
  }
  return addresses;
}

/// Verifies that [privkey] derives to [expectedAddress] when encoded as [type].
void _expectKeyMatchesAddress(
  ECPrivate privkey,
  String expectedAddress,
  BitcoinAddressType type,
  BasedUtxoNetwork network,
) {
  final pub = privkey.getPublic();
  final String derived;
  if (type == P2pkhAddressType.p2pkh) {
    derived = pub.toP2pkhAddress().toAddress(network);
  } else if (type == SegwitAddresType.p2tr) {
    derived = pub.toTaprootAddress().toAddress(network);
  } else if (type == SegwitAddresType.p2wsh) {
    derived = pub.toP2wshAddress().toAddress(network);
  } else if (type == P2shAddressType.p2wpkhInP2sh) {
    derived = pub.toP2wpkhInP2sh().toAddress(network);
  } else {
    derived = pub.toP2wpkhAddress().toAddress(network);
  }
  expect(derived, expectedAddress,
      reason: 'Private key found by brute-force must produce the target address');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Fixed 64-byte seed for deterministic tests (bytes 0x01..0x40).
  final fixedSeed = Uint8List.fromList(List.generate(64, (i) => i + 1));

  // -------------------------------------------------------------------------
  // Bitcoin tests
  // -------------------------------------------------------------------------

  group('Bitcoin – bruteForcePrivkeyForAddress', () {
    const network = BitcoinNetwork.mainnet;
    const nativeCoinType = 0;

    // Each address type at index 0 with a fixed seed.
    for (final entry in {
      'P2WPKH':        [SegwitAddresType.p2wpkh,       "m/84'/0'/0'/0"],
      'P2PKH':         [P2pkhAddressType.p2pkh,          "m/44'/0'/0'/0"],
      'P2TR':          [SegwitAddresType.p2tr,            "m/86'/0'/0'/0"],
      'P2WSH':         [SegwitAddresType.p2wsh,           "m/84'/0'/0'/0"],
      'P2SH(P2WPKH)':  [P2shAddressType.p2wpkhInP2sh,   "m/49'/0'/0'/0"],
    }.entries) {
      final label = entry.key;
      final type   = entry.value[0] as BitcoinAddressType;
      final path   = entry.value[1] as String;

      test('finds $label at receive index 0 (fixed seed)', () {
        final hds = _buildBitcoinHDs(fixedSeed);
        final targetHd = hds.master.derivePath(path) as Bip32Slip10Secp256k1;
        final addr = generateAddressForType(hd: targetHd, index: 0, type: type, network: network);

        final result = bruteForcePrivkeyForAddress(
          targetAddress: addr,
          targetType: type,
          candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
          network: network,
        );

        expect(result, isNotNull, reason: '$label key at index 0 must be found');
        _expectKeyMatchesAddress(result!, addr, type, network);
      });
    }

    test('finds P2PKH at receive index 42 (fixed seed)', () {
      final hds = _buildBitcoinHDs(fixedSeed);
      const type = P2pkhAddressType.p2pkh;
      final targetHd = hds.master.derivePath("m/44'/0'/0'/0") as Bip32Slip10Secp256k1;
      final addr = generateAddressForType(hd: targetHd, index: 42, type: type, network: network);

      final result = bruteForcePrivkeyForAddress(
        targetAddress: addr,
        targetType: type,
        candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
        network: network,
      );

      expect(result, isNotNull);
      _expectKeyMatchesAddress(result!, addr, type, network);
    });

    test('finds P2TR at receive index 99 (fixed seed)', () {
      final hds = _buildBitcoinHDs(fixedSeed);
      const type = SegwitAddresType.p2tr;
      final targetHd = hds.master.derivePath("m/86'/0'/0'/0") as Bip32Slip10Secp256k1;
      final addr = generateAddressForType(hd: targetHd, index: 99, type: type, network: network);

      final result = bruteForcePrivkeyForAddress(
        targetAddress: addr,
        targetType: type,
        candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
        network: network,
      );

      expect(result, isNotNull);
      _expectKeyMatchesAddress(result!, addr, type, network);
    });

    test('finds P2SH change address at index 17 (fixed seed)', () {
      final hds = _buildBitcoinHDs(fixedSeed);
      const type = P2shAddressType.p2wpkhInP2sh;
      final targetHd = hds.master.derivePath("m/49'/0'/0'/1") as Bip32Slip10Secp256k1;
      final addr = generateAddressForType(hd: targetHd, index: 17, type: type, network: network);

      final result = bruteForcePrivkeyForAddress(
        targetAddress: addr,
        targetType: type,
        candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
        network: network,
      );

      expect(result, isNotNull);
      _expectKeyMatchesAddress(result!, addr, type, network);
    });

    test(
        'recovers key when address was generated under a different '
        'derivation path than stored (fixed seed)', () {
      final hds = _buildBitcoinHDs(fixedSeed);
      // Actual: P2PKH, BIP44 receive HD, index 30.
      const actualType  = P2pkhAddressType.p2pkh;
      const actualIndex = 30;
      final actualHd = hds.master.derivePath("m/44'/0'/0'/0") as Bip32Slip10Secp256k1;
      final targetAddr = generateAddressForType(
          hd: actualHd, index: actualIndex, type: actualType, network: network);

      // Wrong stored record would derive: P2WPKH HD, index 5.
      final wrongHd  = hds.master.derivePath("m/84'/0'/0'/0") as Bip32Slip10Secp256k1;
      final wrongAddr = generateAddressForType(
          hd: wrongHd, index: 5, type: SegwitAddresType.p2wpkh, network: network);
      expect(wrongAddr, isNot(targetAddr));

      final result = bruteForcePrivkeyForAddress(
        targetAddress: targetAddr,
        targetType: actualType,
        candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
        network: network,
      );

      expect(result, isNotNull,
          reason: 'Must find the key even when stored path is wrong');
      _expectKeyMatchesAddress(result!, targetAddr, actualType, network);
    });

    test('returns null when address index is beyond maxIndex (fixed seed)', () {
      final hds = _buildBitcoinHDs(fixedSeed);
      const type = SegwitAddresType.p2wpkh;
      final targetHd = hds.master.derivePath("m/84'/0'/0'/0") as Bip32Slip10Secp256k1;
      // Address at index 10; search window is only 0..4.
      final addr = generateAddressForType(hd: targetHd, index: 10, type: type, network: network);

      final result = bruteForcePrivkeyForAddress(
        targetAddress: addr,
        targetType: type,
        candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
        network: network,
        maxIndex: 5,
      );

      expect(result, isNull);
    });

    test('finds correct key across 5 random seeds and all address types', () {
      const network = BitcoinNetwork.mainnet;
      final paths = <BitcoinAddressType, String>{
        SegwitAddresType.p2wpkh:       "m/84'/0'/0'/0",
        P2pkhAddressType.p2pkh:        "m/44'/0'/0'/0",
        SegwitAddresType.p2tr:         "m/86'/0'/0'/0",
        SegwitAddresType.p2wsh:        "m/84'/0'/0'/0",
        P2shAddressType.p2wpkhInP2sh:  "m/49'/0'/0'/0",
      };

      for (int s = 0; s < 5; s++) {
        final hds = _buildBitcoinHDs(_randomSeed());
        for (final entry in paths.entries) {
          final type  = entry.key;
          final index = Random().nextInt(49) + 1;
          final hd    = hds.master.derivePath(entry.value) as Bip32Slip10Secp256k1;
          final addr  = generateAddressForType(hd: hd, index: index, type: type, network: network);

          final result = bruteForcePrivkeyForAddress(
            targetAddress: addr,
            targetType: type,
            candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
            network: network,
            maxIndex: index + 1,
          );

          expect(result, isNotNull,
              reason: 'Seed $s, type $type, index $index: key must be found');
          _expectKeyMatchesAddress(result!, addr, type, network);
        }
      }
    });

    test('finds change (sideHd) addresses across types with random seed', () {
      const network = BitcoinNetwork.mainnet;
      final changePaths = <BitcoinAddressType, String>{
        SegwitAddresType.p2wpkh:       "m/84'/0'/0'/1",
        P2pkhAddressType.p2pkh:        "m/44'/0'/0'/1",
        SegwitAddresType.p2tr:         "m/86'/0'/0'/1",
        SegwitAddresType.p2wsh:        "m/84'/0'/0'/1",
        P2shAddressType.p2wpkhInP2sh:  "m/49'/0'/0'/1",
      };
      final hds = _buildBitcoinHDs(_randomSeed());
      for (final entry in changePaths.entries) {
        final type  = entry.key;
        final index = Random().nextInt(20) + 1;
        final hd    = hds.master.derivePath(entry.value) as Bip32Slip10Secp256k1;
        final addr  = generateAddressForType(hd: hd, index: index, type: type, network: network);

        final result = bruteForcePrivkeyForAddress(
          targetAddress: addr,
          targetType: type,
          candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
          network: network,
        );

        expect(result, isNotNull,
            reason: 'Change address for type $type index $index must be found');
        _expectKeyMatchesAddress(result!, addr, type, network);
      }
    });

    test('finds address derived from Electrum path m/0\' (fixed seed)', () {
      final hds = _buildBitcoinHDs(fixedSeed);
      // Electrum receive HD: m/0'/0, change HD: m/0'/1.
      final electrumReceiveHd = hds.master.derivePath("m/0'/0") as Bip32Slip10Secp256k1;
      final electrumChangeHd  = hds.master.derivePath("m/0'/1") as Bip32Slip10Secp256k1;

      for (final entry in {
        'receive index 0':  [electrumReceiveHd, 0],
        'receive index 15': [electrumReceiveHd, 15],
        'change index 7':   [electrumChangeHd,  7],
      }.entries) {
        final hd    = entry.value[0] as Bip32Slip10Secp256k1;
        final index = entry.value[1] as int;
        // Electrum wallets default to P2WPKH on Bitcoin.
        const type  = SegwitAddresType.p2wpkh;
        final addr  = generateAddressForType(hd: hd, index: index, type: type, network: network);

        final result = bruteForcePrivkeyForAddress(
          targetAddress: addr,
          targetType: type,
          candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
          network: network,
          maxIndex: index + 1,
        );

        expect(result, isNotNull,
            reason: "Electrum path key (${entry.key}) must be found");
        _expectKeyMatchesAddress(result!, addr, type, network);
      }
    });
  });

  // -------------------------------------------------------------------------
  // Litecoin tests
  // -------------------------------------------------------------------------

  group('Litecoin – bruteForcePrivkeyForAddress', () {
    const network = LitecoinNetwork.mainnet;
    const nativeCoinType = 2;

    test('finds native P2WPKH address at receive index 0 (fixed seed)', () {
      final hds = _buildLitecoinHDs(fixedSeed);
      const type = SegwitAddresType.p2wpkh;
      final targetHd = hds.master.derivePath("m/84'/2'/0'/0") as Bip32Slip10Secp256k1;
      final addr = generateAddressForType(hd: targetHd, index: 0, type: type, network: network);

      final result = bruteForcePrivkeyForAddress(
        targetAddress: addr,
        targetType: type,
        candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
        network: network,
      );

      expect(result, isNotNull);
      _expectKeyMatchesAddress(result!, addr, type, network);
    });

    // test('finds real-world P2WPKH address regardless of seed derivation algorithm', () async {
    //   const mnemonic = 'other other other';
    //   const type = SegwitAddresType.p2wpkh;
    //   const addr = "";
    //   const maxIndex = 1000;
    //
    //   ECPrivate? result;
    //   String? foundSeedType;
    //   String? foundPath;
    //   int? foundIndex;
    //
    //   final seedEntries = <MapEntry<String, Uint8List>>[
    //     MapEntry('bip39',    bip39.mnemonicToSeed(mnemonic)),
    //     MapEntry('electrum', await electrum_mnemonic.mnemonicToSeedBytes(mnemonic)),
    //   ];
    //
    //   outer:
    //   for (final seedEntry in seedEntries) {
    //     final seedBytes = seedEntry.value;
    //     final master = Bip32Slip10Secp256k1.fromSeed(seedBytes) as Bip32Slip10Secp256k1;
    //
    //     // Build labeled (path → HD) map mirroring expandedHDs().
    //     final labeledHDs = <String, Bip32Slip10Secp256k1>{
    //       "m/0'/0":  master.derivePath("m/0'/0")  as Bip32Slip10Secp256k1,
    //       "m/0'/1":  master.derivePath("m/0'/1")  as Bip32Slip10Secp256k1,
    //     };
    //     for (final coinType in {0, nativeCoinType}) {
    //       for (final purpose in [44, 49, 84, 86]) {
    //         final base = "m/$purpose'/$coinType'/0'";
    //         labeledHDs["$base/0"] = master.derivePath("$base/0") as Bip32Slip10Secp256k1;
    //         labeledHDs["$base/1"] = master.derivePath("$base/1") as Bip32Slip10Secp256k1;
    //       }
    //     }
    //
    //     for (final hdEntry in labeledHDs.entries) {
    //       for (int i = 0; i < maxIndex; i++) {
    //         if (generateAddressForType(
    //                 hd: hdEntry.value, index: i, type: type, network: network) ==
    //             addr) {
    //           result = generateECPrivate(hd: hdEntry.value, index: i, network: network);
    //           foundSeedType = seedEntry.key;
    //           foundPath = hdEntry.key;
    //           foundIndex = i;
    //           break outer;
    //         }
    //       }
    //     }
    //   }
    //
    //   print('Seed type: $foundSeedType, Path: $foundPath, Index: $foundIndex');
    //
    //   expect(result, isNotNull,
    //       reason: 'Address must be found with either BIP39 or Electrum seed derivation');
    //   _expectKeyMatchesAddress(result!, addr, type, network);
    // });

    // Core Litecoin scenario: address was derived using Bitcoin's coin type 0
    // instead of Litecoin's coin type 2.  This happens when wallets use the
    // wrong derivation path for LTC.  The expanded search must catch it.
    test(
        'recovers key generated with Bitcoin coin type (0) instead of '
        'Litecoin coin type (2) – P2WPKH receive (fixed seed)', () {
      final hds = _buildLitecoinHDs(fixedSeed);
      const type = SegwitAddresType.p2wpkh;
      const index = 10;

      // Address was generated at m/84'/0'/0'/0 (BTC path) but on the Litecoin
      // network encoding — so the address starts with "ltc1" but was derived
      // from coin type 0.
      final wrongCoinTypeHd = hds.master.derivePath("m/84'/0'/0'/0") as Bip32Slip10Secp256k1;
      final targetAddr =
          generateAddressForType(hd: wrongCoinTypeHd, index: index, type: type, network: network);

      // Confirm the native Litecoin HD does NOT produce this address.
      final nativeHd = hds.master.derivePath("m/84'/2'/0'/0") as Bip32Slip10Secp256k1;
      final nativeAddr =
          generateAddressForType(hd: nativeHd, index: index, type: type, network: network);
      expect(nativeAddr, isNot(targetAddr),
          reason: 'Sanity: Bitcoin-path and Litecoin-path addresses must differ');

      final result = bruteForcePrivkeyForAddress(
        targetAddress: targetAddr,
        targetType: type,
        candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
        network: network,
      );

      expect(result, isNotNull,
          reason: 'Must recover key derived with Bitcoin coin type on a Litecoin wallet');
      _expectKeyMatchesAddress(result!, targetAddr, type, network);
    });

    test(
        'recovers key generated with Bitcoin coin type (0) instead of '
        'Litecoin coin type (2) – P2PKH receive (fixed seed)', () {
      final hds = _buildLitecoinHDs(fixedSeed);
      const type = P2pkhAddressType.p2pkh;
      const index = 5;

      final wrongCoinTypeHd = hds.master.derivePath("m/44'/0'/0'/0") as Bip32Slip10Secp256k1;
      final targetAddr =
          generateAddressForType(hd: wrongCoinTypeHd, index: index, type: type, network: network);

      final result = bruteForcePrivkeyForAddress(
        targetAddress: targetAddr,
        targetType: type,
        candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
        network: network,
      );

      expect(result, isNotNull,
          reason: 'Must recover P2PKH key derived with Bitcoin coin type on a Litecoin wallet');
      _expectKeyMatchesAddress(result!, targetAddr, type, network);
    });

    test(
        'recovers key generated with Bitcoin coin type (0) instead of '
        'Litecoin coin type (2) – change address (fixed seed)', () {
      final hds = _buildLitecoinHDs(fixedSeed);
      const type = SegwitAddresType.p2wpkh;
      const index = 8;

      final wrongCoinTypeHd = hds.master.derivePath("m/84'/0'/0'/1") as Bip32Slip10Secp256k1;
      final targetAddr =
          generateAddressForType(hd: wrongCoinTypeHd, index: index, type: type, network: network);

      final result = bruteForcePrivkeyForAddress(
        targetAddress: targetAddr,
        targetType: type,
        candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
        network: network,
      );

      expect(result, isNotNull,
          reason: 'Must recover change key derived with Bitcoin coin type on a Litecoin wallet');
      _expectKeyMatchesAddress(result!, targetAddr, type, network);
    });

    test('finds Litecoin address across all purpose variants (fixed seed)', () {
      final hds = _buildLitecoinHDs(fixedSeed);
      // BIP purposes supported by Litecoin (P2TR / BIP86 is NOT supported by
      // the Litecoin network, so it is excluded here).
      final variants = <BitcoinAddressType, String>{
        SegwitAddresType.p2wpkh:       "m/84'/2'/0'/0",
        P2pkhAddressType.p2pkh:        "m/44'/2'/0'/0",
        P2shAddressType.p2wpkhInP2sh:  "m/49'/2'/0'/0",
      };

      for (final entry in variants.entries) {
        final type = entry.key;
        final hd   = hds.master.derivePath(entry.value) as Bip32Slip10Secp256k1;
        final addr = generateAddressForType(hd: hd, index: 3, type: type, network: network);

        final result = bruteForcePrivkeyForAddress(
          targetAddress: addr,
          targetType: type,
          candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
          network: network,
        );

        expect(result, isNotNull,
            reason: 'Purpose variant $type (coin type 2) index 3 must be found');
        _expectKeyMatchesAddress(result!, addr, type, network);
      }
    });

    test('finds Litecoin address across 5 random seeds (native + BTC paths)', () {
      // For each random seed, verify we can find:
      //   (a) a native Litecoin-path address (coin type 2), and
      //   (b) an address derived with Bitcoin paths (coin type 0) on the LTC network.
      for (int s = 0; s < 5; s++) {
        final seed = _randomSeed();
        final hds  = _buildLitecoinHDs(seed);
        final index = Random().nextInt(49) + 1;

        for (final coinTypePath in ['2', '0']) {
          const type = SegwitAddresType.p2wpkh;
          final hd   = hds.master.derivePath("m/84'/$coinTypePath'/0'/0")
              as Bip32Slip10Secp256k1;
          final addr = generateAddressForType(hd: hd, index: index, type: type, network: network);

          final result = bruteForcePrivkeyForAddress(
            targetAddress: addr,
            targetType: type,
            candidateHDs: hds.expandedHDs(nativeCoinType: nativeCoinType),
            network: network,
            maxIndex: index + 1,
          );

          expect(result, isNotNull,
              reason:
                  'Seed $s, coin type $coinTypePath, index $index: key must be found');
          _expectKeyMatchesAddress(result!, addr, type, network);
        }
      }
    });

    // ── Cross-algorithm seed tests ──────────────────────────────────────────
    // These tests verify that the alt-seed expansion covers addresses that were
    // created with the *other* seed-derivation algorithm (BIP39 vs Electrum).
    // The same mnemonic fed to bip39.mnemonicToSeed and electrum.mnemonicToSeedBytes
    // produces two completely different 64-byte seeds, so each yields a different
    // master HD and different addresses.  Without the alt-seed expansion the wallet
    // would be blind to half of its own history.

    test(
        'finds P2WPKH address from BIP39 seed when wallet was restored '
        'using Electrum derivation (alt-seed expansion is required)',
        () async {
      // Well-known BIP39 test vector — not a real-world funded wallet.
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const type = SegwitAddresType.p2wpkh;
      const targetPath = "m/84'/2'/0'/0";
      const targetIndex = 5;

      final bip39Seed    = bip39.mnemonicToSeed(mnemonic);
      final electrumSeed = await electrum_mnemonic.mnemonicToSeedBytes(mnemonic);
      // Sanity: the two algorithms must produce different seeds.
      expect(bip39Seed, isNot(electrumSeed));

      final bip39Master    = Bip32Slip10Secp256k1.fromSeed(bip39Seed);
      final electrumMaster = Bip32Slip10Secp256k1.fromSeed(electrumSeed);

      // Address was originally created with the BIP39 seed.
      final targetHd   = bip39Master.derivePath(targetPath) as Bip32Slip10Secp256k1;
      final targetAddr = generateAddressForType(
          hd: targetHd, index: targetIndex, type: type, network: network);

      // Wallet restored as Electrum → all primary HDs come from electrumSeed.
      final walletHDs = _buildLitecoinHDs(electrumSeed);

      // Without alt-seed: Electrum-master paths only → must NOT find the address.
      final primaryOnly = walletHDs.expandedHDs(nativeCoinType: nativeCoinType);
      expect(
        bruteForcePrivkeyForAddress(
          targetAddress: targetAddr,
          targetType: type,
          candidateHDs: primaryOnly,
          network: network,
          maxIndex: targetIndex + 1,
        ),
        isNull,
        reason: 'Electrum-derived HDs alone must not find a BIP39-seeded address',
      );

      // With alt-seed: add BIP39 master paths (mirrors _bruteForcePrivkeyForAddress
      // when _altMasterHD is the BIP39 master).
      final withAltSeed = walletHDs.expandedHDs(nativeCoinType: nativeCoinType);
      withAltSeed.add(bip39Master.derivePath("m/0'/0") as Bip32Slip10Secp256k1);
      withAltSeed.add(bip39Master.derivePath("m/0'/1") as Bip32Slip10Secp256k1);
      for (final coinType in {0, nativeCoinType}) {
        for (final purpose in [44, 49, 84, 86]) {
          final base = "m/$purpose'/$coinType'/0'";
          withAltSeed.add(bip39Master.derivePath("$base/0") as Bip32Slip10Secp256k1);
          withAltSeed.add(bip39Master.derivePath("$base/1") as Bip32Slip10Secp256k1);
        }
      }

      final result = bruteForcePrivkeyForAddress(
        targetAddress: targetAddr,
        targetType: type,
        candidateHDs: withAltSeed,
        network: network,
        maxIndex: targetIndex + 1,
      );

      expect(result, isNotNull,
          reason: 'Alt-seed (BIP39) expansion must find the BIP39-derived address');
      _expectKeyMatchesAddress(result!, targetAddr, type, network);
    });

    test(
        'finds P2WPKH address from Electrum seed when wallet was restored '
        'using BIP39 derivation (alt-seed expansion is required)',
        () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const type = SegwitAddresType.p2wpkh;
      const targetPath = "m/84'/2'/0'/0";
      const targetIndex = 7;

      final bip39Seed    = bip39.mnemonicToSeed(mnemonic);
      final electrumSeed = await electrum_mnemonic.mnemonicToSeedBytes(mnemonic);

      final bip39Master    = Bip32Slip10Secp256k1.fromSeed(bip39Seed);
      final electrumMaster = Bip32Slip10Secp256k1.fromSeed(electrumSeed);

      // Address was originally created with the Electrum seed.
      final targetHd   = electrumMaster.derivePath(targetPath) as Bip32Slip10Secp256k1;
      final targetAddr = generateAddressForType(
          hd: targetHd, index: targetIndex, type: type, network: network);

      // Wallet restored using BIP39 → all primary HDs come from bip39Seed.
      final walletHDs = _buildLitecoinHDs(bip39Seed);

      // Without alt-seed: BIP39-master paths only → must NOT find the address.
      final primaryOnly = walletHDs.expandedHDs(nativeCoinType: nativeCoinType);
      expect(
        bruteForcePrivkeyForAddress(
          targetAddress: targetAddr,
          targetType: type,
          candidateHDs: primaryOnly,
          network: network,
          maxIndex: targetIndex + 1,
        ),
        isNull,
        reason: 'BIP39-derived HDs alone must not find an Electrum-seeded address',
      );

      // With alt-seed: add Electrum master paths.
      final withAltSeed = walletHDs.expandedHDs(nativeCoinType: nativeCoinType);
      withAltSeed.add(electrumMaster.derivePath("m/0'/0") as Bip32Slip10Secp256k1);
      withAltSeed.add(electrumMaster.derivePath("m/0'/1") as Bip32Slip10Secp256k1);
      for (final coinType in {0, nativeCoinType}) {
        for (final purpose in [44, 49, 84, 86]) {
          final base = "m/$purpose'/$coinType'/0'";
          withAltSeed.add(electrumMaster.derivePath("$base/0") as Bip32Slip10Secp256k1);
          withAltSeed.add(electrumMaster.derivePath("$base/1") as Bip32Slip10Secp256k1);
        }
      }

      final result = bruteForcePrivkeyForAddress(
        targetAddress: targetAddr,
        targetType: type,
        candidateHDs: withAltSeed,
        network: network,
        maxIndex: targetIndex + 1,
      );

      expect(result, isNotNull,
          reason: 'Alt-seed (Electrum) expansion must find the Electrum-derived address');
      _expectKeyMatchesAddress(result!, targetAddr, type, network);
    });
  });

  // -------------------------------------------------------------------------
  // Alt-seed address generation tests (mirrors _initAltSeedAddresses)
  // -------------------------------------------------------------------------

  group('Alt-seed address generation – Bitcoin (200 per branch)', () {
    const network = BitcoinNetwork.mainnet;
    const coinType = 0;
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    test('Electrum m/0\' path included for both seeds at indices 0 and 199', () async {
      final bip39Master = Bip32Slip10Secp256k1.fromSeed(bip39.mnemonicToSeed(mnemonic));
      final electrumMaster = Bip32Slip10Secp256k1.fromSeed(
              await electrum_mnemonic.mnemonicToSeedBytes(mnemonic));
      final addrSet = _simulateAltSeedAddresses(
          primaryMaster: bip39Master,
          altMaster: electrumMaster,
          coinType: coinType,
          network: network);

      for (final master in [bip39Master, electrumMaster]) {
        final rx = master.derivePath("m/0'/0") as Bip32Slip10Secp256k1;
        final ch = master.derivePath("m/0'/1") as Bip32Slip10Secp256k1;
        for (final idx in [0, 199]) {
          expect(addrSet, contains(generateP2WPKHAddress(hd: rx, index: idx, network: network)),
              reason: 'm/0\'/0 index $idx must be present');
          expect(addrSet, contains(generateP2WPKHAddress(hd: ch, index: idx, network: network)),
              reason: 'm/0\'/1 index $idx must be present');
        }
      }
    });

    test('all BIP purposes × coin type 0 included for both seeds at indices 0 and 199', () async {
      final bip39Master = Bip32Slip10Secp256k1.fromSeed(bip39.mnemonicToSeed(mnemonic));
      final electrumMaster = Bip32Slip10Secp256k1.fromSeed(
              await electrum_mnemonic.mnemonicToSeedBytes(mnemonic));
      final addrSet = _simulateAltSeedAddresses(
          primaryMaster: bip39Master,
          altMaster: electrumMaster,
          coinType: coinType,
          network: network);

      for (final master in [bip39Master, electrumMaster]) {
        for (final purpose in [44, 49, 84, 86]) {
          final rx = master.derivePath("m/$purpose'/0'/0'/0") as Bip32Slip10Secp256k1;
          final ch = master.derivePath("m/$purpose'/0'/0'/1") as Bip32Slip10Secp256k1;
          for (final idx in [0, 199]) {
            expect(addrSet,
                contains(generateP2WPKHAddress(hd: rx, index: idx, network: network)),
                reason: 'purpose $purpose receive[$idx] must be present');
            expect(addrSet,
                contains(generateP2WPKHAddress(hd: ch, index: idx, network: network)),
                reason: 'purpose $purpose change[$idx] must be present');
          }
        }
      }
    });

    test('index 199 included, index 200 absent', () {
      final bip39Master = Bip32Slip10Secp256k1.fromSeed(bip39.mnemonicToSeed(mnemonic));
      final addrSet = _simulateAltSeedAddresses(
          primaryMaster: bip39Master,
          altMaster: bip39Master,
          coinType: coinType,
          network: network);

      final rx = bip39Master.derivePath("m/84'/0'/0'/0") as Bip32Slip10Secp256k1;
      expect(addrSet, contains(generateP2WPKHAddress(hd: rx, index: 199, network: network)));
      expect(addrSet, isNot(contains(generateP2WPKHAddress(hd: rx, index: 200, network: network))));
    });
  });

  group('Alt-seed address generation – Litecoin (200 per branch)', () {
    const network = LitecoinNetwork.mainnet;
    const coinType = 2;
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    test('all purposes × native (2) and BTC (0) coin types included for both seeds', () async {
      final bip39Master = Bip32Slip10Secp256k1.fromSeed(bip39.mnemonicToSeed(mnemonic));
      final electrumMaster = Bip32Slip10Secp256k1.fromSeed(
              await electrum_mnemonic.mnemonicToSeedBytes(mnemonic));
      final addrSet = _simulateAltSeedAddresses(
          primaryMaster: bip39Master,
          altMaster: electrumMaster,
          coinType: coinType,
          network: network);

      for (final master in [bip39Master, electrumMaster]) {
        for (final ct in [0, 2]) {
          for (final purpose in [44, 49, 84, 86]) {
            final rx = master.derivePath("m/$purpose'/$ct'/0'/0") as Bip32Slip10Secp256k1;
            final ch = master.derivePath("m/$purpose'/$ct'/0'/1") as Bip32Slip10Secp256k1;
            for (final idx in [0, 199]) {
              expect(addrSet,
                  contains(generateP2WPKHAddress(hd: rx, index: idx, network: network)),
                  reason: 'purpose $purpose / coinType $ct / receive[$idx] must be present');
              expect(addrSet,
                  contains(generateP2WPKHAddress(hd: ch, index: idx, network: network)),
                  reason: 'purpose $purpose / coinType $ct / change[$idx] must be present');
            }
          }
        }
      }
    });

    test('cross-seed: BIP39 address at m/84\'/2\'/0\'/0 index 150 found when primary is Electrum',
        () async {
      final bip39Master = Bip32Slip10Secp256k1.fromSeed(bip39.mnemonicToSeed(mnemonic));
      final electrumMaster = Bip32Slip10Secp256k1.fromSeed(
              await electrum_mnemonic.mnemonicToSeedBytes(mnemonic));
      final targetHd = bip39Master.derivePath("m/84'/2'/0'/0") as Bip32Slip10Secp256k1;
      final targetAddr = generateP2WPKHAddress(hd: targetHd, index: 150, network: network);

      final addrSet = _simulateAltSeedAddresses(
          primaryMaster: electrumMaster,
          altMaster: bip39Master,
          coinType: coinType,
          network: network);

      expect(addrSet, contains(targetAddr),
          reason: 'BIP39-seeded address must appear when Electrum is primary');
    });

    test('cross-seed: Electrum address at m/84\'/0\'/0\'/0 index 150 found when primary is BIP39',
        () async {
      final bip39Master = Bip32Slip10Secp256k1.fromSeed(bip39.mnemonicToSeed(mnemonic));
      final electrumMaster = Bip32Slip10Secp256k1.fromSeed(
              await electrum_mnemonic.mnemonicToSeedBytes(mnemonic));
      final targetHd = electrumMaster.derivePath("m/84'/0'/0'/0") as Bip32Slip10Secp256k1;
      final targetAddr = generateP2WPKHAddress(hd: targetHd, index: 150, network: network);

      final addrSet = _simulateAltSeedAddresses(
          primaryMaster: bip39Master,
          altMaster: electrumMaster,
          coinType: coinType,
          network: network);

      expect(addrSet, contains(targetAddr),
          reason: 'Electrum-seeded address must appear when BIP39 is primary');
    });
  });
}
