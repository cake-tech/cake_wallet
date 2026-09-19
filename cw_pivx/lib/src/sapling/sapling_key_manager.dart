/// Sapling key derivation from a BIP39 seed per ZIP-32
/// (https://zips.z.cash/zip-0032). Key hierarchy for PIVX Sapling:
/// ```
/// seed (64 bytes from BIP39)
///   └── master extended spending key (m_sapling)
///         └── purpose = 32' (hardened, Sapling)
///               └── coin_type = 119' (hardened, PIVX)
///                     └── account = n' (hardened)
///                           ├── Extended Spending Key (extsk)
///                           │     └── Used to spend notes
///                           └── Extended Full Viewing Key (extfvk)
///                                 ├── Used to scan for incoming notes
///                                 └── Diversified payment addresses
/// ```
library;

import 'dart:typed_data';

import 'sapling_constants.dart';

/// Sapling extended spending key. Contains:
/// - ask (256 bits): The spend authorizing key
/// - nsk (256 bits): The nullifier private key
/// - ovk (256 bits): The outgoing viewing key
/// - dk (256 bits): The diversifier key
/// - chain_code (256 bits): The chain code for derivation
///
/// This key can derive child keys and sign transactions.
class SaplingExtendedSpendingKey {
  SaplingExtendedSpendingKey({
    required this.raw,
    required this.encoded,
    required this.isTestnet,
  });

  final Uint8List raw;

  /// Bech32-encoded key; format [HRP]1[data], HRP 'p-secret-extended-key-main'/'-test'.
  final String encoded;

  final bool isTestnet;

  String get hrp => isTestnet
      ? PivxSaplingNetwork.testnetExtendedSpendingKeyHrp
      : PivxSaplingNetwork.mainnetExtendedSpendingKeyHrp;
}

/// Sapling extended full viewing key. Contains:
/// - ak (256 bits): The spend validating key (derived from ask)
/// - nk (256 bits): The nullifier deriving key (derived from nsk)
/// - ovk (256 bits): The outgoing viewing key
/// - dk (256 bits): The diversifier key
/// - chain_code (256 bits): The chain code for derivation
///
/// This key can:
/// - Derive payment addresses
/// - Scan for incoming notes (trial decryption)
/// - Derive nullifiers for spent detection
/// - View outgoing transaction details
///
/// It CANNOT sign transactions (that requires the spending key).
class SaplingExtendedFullViewingKey {
  SaplingExtendedFullViewingKey({
    required this.raw,
    required this.encoded,
    required this.isTestnet,
  });

  final Uint8List raw;

  /// Bech32-encoded key; format [HRP]1[data], HRP 'pviews'/'pviewtestsapling'.
  final String encoded;

  final bool isTestnet;

  String get hrp => isTestnet
      ? PivxSaplingNetwork.testnetFullViewingKeyHrp
      : PivxSaplingNetwork.mainnetFullViewingKeyHrp;
}

/// Sapling incoming viewing key (ivk), derived from ak and nk:
/// ivk = CRH^ivk(ak, nk).
/// Decrypts incoming notes only (trial decryption); cannot derive nullifiers
/// or view outgoing transactions.
class SaplingIncomingViewingKey {
  SaplingIncomingViewingKey({
    required this.raw,
    required this.encoded,
    required this.isTestnet,
  });

  /// The raw key bytes (32 bytes).
  final Uint8List raw;

  final String encoded;

  final bool isTestnet;
}

/// Sapling diversifier. Yields multiple unlinkable addresses from one viewing
/// key; 11 bytes, and not all 11-byte values are valid diversifiers.
class SaplingDiversifier {
  SaplingDiversifier({
    required this.bytes,
    required this.index,
  });

  final Uint8List bytes;

  /// The diversifier index used to derive this diversifier.
  final Uint8List index;

  /// True for the default diversifier (index 0).
  bool get isDefault {
    for (final b in index) {
      if (b != 0) return false;
    }
    return true;
  }
}

/// Sapling payment address. Consists of:
/// - diversifier d (11 bytes): unique per address
/// - pk_d (32 bytes): diversified transmission key
/// Encoded as [HRP]1[Bech32(d || pk_d)].
class SaplingPaymentAddress {
  SaplingPaymentAddress({
    required this.diversifier,
    required this.pkD,
    required this.encoded,
    required this.isTestnet,
  });

  final Uint8List diversifier;

  final Uint8List pkD;

  /// Bech32-encoded address; ps1... (mainnet) or ptestsapling1... (testnet).
  final String encoded;

  final bool isTestnet;

  String get hrp => isTestnet
      ? PivxSaplingNetwork.testnetPaymentAddressHrp
      : PivxSaplingNetwork.mainnetPaymentAddressHrp;

  /// Raw address bytes (43 bytes).
  Uint8List get raw {
    final bytes = Uint8List(43);
    bytes.setAll(0, diversifier);
    bytes.setAll(11, pkD);
    return bytes;
  }
}

/// Manages Sapling key derivation and diversified address generation: keys from
/// a BIP39 seed, multiple accounts, transaction signing, and note scanning.
abstract class SaplingKeyManager {
  SaplingKeyManager({
    required this.seed,
    required this.isTestnet,
    this.accountIndex = 0,
  });

  /// The BIP39 seed (64 bytes).
  final Uint8List seed;

  final bool isTestnet;

  /// The account index (used in key derivation path).
  final int accountIndex;

  int get coinType => isTestnet
      ? PivxSaplingNetwork.testnetCoinType
      : PivxSaplingNetwork.mainnetCoinType;

  /// Derive master and account keys from the seed. Must be called first.
  Future<void> initialize();

  Future<SaplingExtendedSpendingKey> getExtendedSpendingKey();

  Future<SaplingExtendedFullViewingKey> getExtendedFullViewingKey();

  Future<SaplingIncomingViewingKey> getIncomingViewingKey();

  /// Default payment address (diversifier index 0).
  Future<SaplingPaymentAddress> getDefaultAddress();

  /// Next unused address: advances the diversifier index to the next valid one.
  Future<SaplingPaymentAddress> getNextAddress();

  /// Address at [diversifierIndex] (11-byte index); null if that index is invalid.
  Future<SaplingPaymentAddress?> getAddressAtIndex(Uint8List diversifierIndex);

  /// Whether [address] belongs to this wallet.
  Future<bool> isOwnAddress(String address);

  Uint8List get currentDiversifierIndex;

  void dispose();
}
