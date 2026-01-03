import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';

/// DigiByte Network Configuration
///
/// DigiByte is a UTXO blockchain that supports:
/// - Legacy P2PKH addresses (prefix 'D')
/// - P2SH addresses (prefix 'S')
/// - SegWit bech32 addresses (prefix 'dgb1')
/// - Taproot support (activated April 2025)
class DigibyteNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration
  static const DigibyteNetwork mainnet = DigibyteNetwork._(
    "digibyteMainnet",
    _DigibyteNetworkParams.mainnet,
  );

  /// Testnet configuration
  static const DigibyteNetwork testnet = DigibyteNetwork._(
    "digibyteTestnet",
    _DigibyteNetworkParams.testnet,
  );

  @override
  final String value;

  final _DigibyteNetworkParams _params;

  const DigibyteNetwork._(this.value, this._params);

  /// Retrieves the Wallet Import Format (WIF) version bytes
  @override
  List<int> get wifNetVer => _params.wifNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes
  /// P2PKH addresses start with 'D' (version byte 0x1e / 30)
  @override
  List<int> get p2pkhNetVer => _params.p2pkhNetVer;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes
  /// P2SH addresses start with 'S' (version byte 0x3f / 63)
  @override
  List<int> get p2shNetVer => _params.p2shNetVer;

  /// Retrieves the Human-Readable Part (HRP) for SegWit addresses
  /// SegWit addresses start with 'dgb1'
  @override
  String get p2wpkhHrp => _params.p2wpkhHrp;

  /// Not used for DigiByte - use direct network params instead
  @override
  CoinConf get conf => throw UnimplementedError("DigiByte uses direct network params");

  /// Checks if the current network is the mainnet
  @override
  bool get isMainnet => this == DigibyteNetwork.mainnet;

  @override
  List<BitcoinAddressType> get supportedAddress => [
        P2pkhAddressType.p2pkh,
        SegwitAddresType.p2wpkh,
        P2shAddressType.p2wpkhInP2sh,
        P2shAddressType.p2pkhInP2sh,
        PubKeyAddressType.p2pk,
        SegwitAddresType.p2tr, // Taproot support
      ];

  @override
  List<BipCoins> get coins {
    // Using Dogecoin coin types as placeholder
    // DigiByte support should be added to blockchain_utils
    if (isMainnet) {
      return [Bip44Coins.dogecoin];
    }
    return [Bip44Coins.dogecoinTestnet];
  }

  // SLIP-0044 coin type for DigiByte
  static const int coinType = 20;
}

/// Internal class for DigiByte network parameters
class _DigibyteNetworkParams {
  /// Mainnet parameters
  static const _DigibyteNetworkParams mainnet = _DigibyteNetworkParams._(
    wifNetVer: [0x80], // Same as Bitcoin (128)
    p2pkhNetVer: [0x1e], // 'D' prefix (30)
    p2shNetVer: [0x3f], // 'S' prefix (63) - changed from 0x05 in 2019
    p2wpkhHrp: 'dgb', // Bech32 SegWit prefix
  );

  /// Testnet parameters
  static const _DigibyteNetworkParams testnet = _DigibyteNetworkParams._(
    wifNetVer: [0xfe], // Testnet WIF (254)
    p2pkhNetVer: [0x7e], // Testnet P2PKH (126)
    p2shNetVer: [0x8c], // Testnet P2SH (140)
    p2wpkhHrp: 'dgbt', // Testnet bech32 prefix
  );

  final List<int> wifNetVer;
  final List<int> p2pkhNetVer;
  final List<int> p2shNetVer;
  final String p2wpkhHrp;

  const _DigibyteNetworkParams._({
    required this.wifNetVer,
    required this.p2pkhNetVer,
    required this.p2shNetVer,
    required this.p2wpkhHrp,
  });
}
