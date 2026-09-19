import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_name.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

/// PIVX network config from PIVX Core chainparams.cpp base58Prefixes:
/// https://github.com/PIVX-Project/PIVX/blob/master/src/chainparams.cpp
/// BIP44 coin type 119 (SLIP-44), path m/44'/119'/account'/change/index.
final CoinConf pivxMainNetConf = CoinConf(
  coinName: const CoinNames("PIVX", "PIVX"),
  params: const CoinParams(
    p2pkhNetVer: [30], // 0x1E 'D' prefix
    p2shNetVer: [13], // 0x0D '6' prefix
    wifNetVer: [212], // 0xD4 WIF prefix
  ),
);

final CoinConf pivxTestNetConf = CoinConf(
  coinName: const CoinNames("PIVX TestNet", "PIVX"),
  params: const CoinParams(
    p2pkhNetVer: [139], // 0x8B testnet P2PKH prefix
    p2shNetVer: [19], // 0x13 testnet P2SH prefix
    wifNetVer: [239], // 0xEF testnet WIF prefix
  ),
);

class PivxNetwork implements BasedUtxoNetwork {
  static const PivxNetwork mainnet = PivxNetwork._("pivxMainnet");
  static const PivxNetwork testnet = _PivxTestnet._("pivxTestnet");

  @override
  final String value;

  const PivxNetwork._(this.value);

  @override
  CoinConf get conf => pivxMainNetConf;

  @override
  List<int> get wifNetVer => conf.params.wifNetVer!;

  /// P2PKH version bytes ('D' addresses).
  @override
  List<int> get p2pkhNetVer => conf.params.p2pkhNetVer!;

  /// P2SH version bytes ('6' addresses).
  @override
  List<int> get p2shNetVer => conf.params.p2shNetVer!;

  /// No native SegWit; return "" instead of throwing so address-type
  /// detection can fall back.
  @override
  String get p2wpkhHrp => "";

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    PubKeyAddressType.p2pk,
    P2pkhAddressType.p2pkh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
  ];

  @override
  bool get isMainnet => this == PivxNetwork.mainnet;

  @override
  List<BipCoins> get coins {
    // blockchain_utils lacks PIVX; use Bitcoin's Bip44 coin and override coin
    // type 119 in derivation.
    if (isMainnet) return [Bip44Coins.bitcoin];
    return [Bip44Coins.bitcoinTestnet];
  }

  // PIVX-specific extensions, not part of BasedUtxoNetwork.

  /// Staking address prefix, 'S' addresses.
  static const int stakingAddressPrefix = 63;

  /// SLIP-44 coin type.
  static const int coinType = 119;

  /// P2P magic bytes.
  static const List<int> magicBytes = [0x90, 0xc4, 0xfd, 0xe9];

  static const int defaultPort = 51472;

  static const int rpcPort = 51473;

  /// Coinbase maturity in blocks.
  static const int coinbaseMaturity = 100;

  /// Target block time in seconds.
  static const int targetBlockTime = 60;

  /// min gap between header-triggered shield syncs. short so a new block header
  /// kicks a sync right away (dedups only header bursts), instead of once a block.
  static const int shieldedHeaderSyncMinInterval = 5;

  /// shield sync poll fallback for when the header subscription is dead.
  static const int shieldedSyncPollInterval = 20;

  /// minRelayTxFee, sat/kB.
  static const int minRelayTxFee = 10000;

  /// Dust relay fee, sat/kB.
  static const int dustRelayFee = 30000;

  /// Dust threshold, sat.
  static const int dustThreshold = 5460;

  /// PIVX Sapling payment address HRP
  static const String saplingPaymentAddressHrp = 'ps';

  /// PIVX Sapling full viewing key HRP
  static const String saplingFullViewingKeyHrp = 'pviews';

  /// PIVX Sapling incoming viewing key HRP
  static const String saplingIncomingViewingKeyHrp = 'pivks';

  /// PIVX Sapling extended spending key HRP
  static const String saplingExtendedSpendingKeyHrp =
      'p-secret-extended-key-main';

  static bool isValidAddress(String address) {
    if (address.startsWith('D') &&
        address.length >= 26 &&
        address.length <= 35) {
      return true;
    }
    if (address.startsWith('6') &&
        address.length >= 26 &&
        address.length <= 35) {
      return true;
    }
    if (address.startsWith('S') &&
        address.length >= 26 &&
        address.length <= 35) {
      return true;
    }
    if (address.startsWith('EXM') &&
        address.length >= 26 &&
        address.length <= 35) {
      return true;
    }
    if (address.startsWith('ps') && address.length > 50) {
      return true;
    }
    return false;
  }

  static String getAddressType(String address) {
    if (address.startsWith('D')) return 'P2PKH';
    if (address.startsWith('6')) return 'P2SH';
    if (address.startsWith('S')) return 'Staking';
    if (address.startsWith('EXM')) return 'Exchange';
    if (address.startsWith('ps')) return 'Sapling';
    return 'Unknown';
  }

  /// Exchange address version bytes ('EXM'), chainparams.cpp
  /// EXCHANGE_ADDRESS = {0x01,0xb9,0xa2}. Cannot receive shielded transactions.
  static const List<int> exchangeAddressPrefix = [0x01, 0xb9, 0xa2];

  /// OP_EXCHANGEADDR (script.h), appended to exchange address scriptPubKeys.
  static const int opExchangeAddr = 0xe0;

  /// Build the 25-byte P2PKH scriptPubKey hex for a standard PIVX
  /// transparent address. Returns "" for unsupported address shapes.
  static String p2pkhScriptPubKeyHex(String address) {
    try {
      final decoded = Base58Decoder.checkDecode(address);
      if (decoded.length != 21) return '';
      final pubkeyHash = decoded.sublist(1);
      final script = Uint8List(25);
      script[0] = 0x76; // OP_DUP
      script[1] = 0xa9; // OP_HASH160
      script[2] = 0x14; // push 20 bytes
      script.setRange(3, 23, pubkeyHash);
      script[23] = 0x88; // OP_EQUALVERIFY
      script[24] = 0xac; // OP_CHECKSIG
      return script.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    } catch (_) {
      return '';
    }
  }

  /// Scripthash (reversed SHA256 of the scriptPubKey) for P2PKH/staking/
  /// exchange addresses; avoids bitcoin_base's SegWit exceptions.
  static String computeScriptHash(String address) {
    try {
      final decoded = Base58Decoder.checkDecode(address);
      if (decoded.isEmpty) return '';

      Uint8List pubkeyHash;
      bool isExchangeAddress = false;

      if (address.startsWith('EXM')) {
        // Exchange: 3-byte version prefix [0x01,0xb9,0xa2] + 20-byte pubkey hash.
        if (decoded.length < 23) return '';
        pubkeyHash = Uint8List.fromList(decoded.sublist(3));
        isExchangeAddress = true;
      } else {
        // 1-byte version prefix + 20-byte pubkey hash ('D', 'S', '8').
        pubkeyHash = Uint8List.fromList(decoded.sublist(1));
      }

      if (pubkeyHash.length != 20) return '';

      Uint8List scriptPubKey;

      if (isExchangeAddress) {
        // Exchange scriptPubKey (26 bytes).
        scriptPubKey = Uint8List(26);
        scriptPubKey[0] = 0xe0; // OP_EXCHANGEADDR
        scriptPubKey[1] = 0x76; // OP_DUP
        scriptPubKey[2] = 0xa9; // OP_HASH160
        scriptPubKey[3] = 0x14; // Push 20 bytes
        scriptPubKey.setRange(4, 24, pubkeyHash);
        scriptPubKey[24] = 0x88; // OP_EQUALVERIFY
        scriptPubKey[25] = 0xac; // OP_CHECKSIG
      } else {
        // P2PKH scriptPubKey (25 bytes).
        scriptPubKey = Uint8List(25);
        scriptPubKey[0] = 0x76; // OP_DUP
        scriptPubKey[1] = 0xa9; // OP_HASH160
        scriptPubKey[2] = 0x14; // Push 20 bytes
        scriptPubKey.setRange(3, 23, pubkeyHash);
        scriptPubKey[23] = 0x88; // OP_EQUALVERIFY
        scriptPubKey[24] = 0xac; // OP_CHECKSIG
      }

      final hash = QuickCrypto.sha256Hash(scriptPubKey);

      // scripthash is the reversed SHA256.
      final reversed = Uint8List.fromList(hash.reversed.toList());
      return BytesUtils.toHexString(reversed);
    } catch (e) {
      return '';
    }
  }
}

class _PivxTestnet extends PivxNetwork {
  const _PivxTestnet._(String value) : super._(value);

  @override
  CoinConf get conf => pivxTestNetConf;

  @override
  bool get isMainnet => false;

  static const List<int> testnetMagicBytes = [0x45, 0x76, 0x65, 0x21];

  static const int testnetPort = 51474;

  static const int testnetRpcPort = 51475;
}
