import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_name.dart';

import 'package:blockchain_utils/blockchain_utils.dart' show Bech32Decoder;
import 'pivx_exchange_address.dart';
import 'sapling/sapling_constants.dart';

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

// Implements DogecoinNetwork only so bitcoin_base's addressTypeFromStr takes its
// base58 P2PKH branch: PIVX, like Dogecoin, has no segwit.
class PivxNetwork implements DogecoinNetwork, OutputScriptDecoder {
  static const PivxNetwork mainnet = PivxNetwork._("pivxMainnet");

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
  bool get isMainnet => true;

  /// Exchange outputs (OP_EXCHANGEADDR) for history labels.
  @override
  BitcoinBaseAddress? decodeOutputScript(Script script) =>
      PivxExchangeAddress.fromScript(script);

  @override
  // blockchain_utils lacks PIVX; use Bitcoin's Bip44 coin and override coin
  // type 119 in derivation.
  List<BipCoins> get coins => [Bip44Coins.bitcoin];

  /// Seconds. Only dedups header bursts, so each new block syncs right away.
  static const int shieldedHeaderSyncMinInterval = 5;

  /// Seconds. Fallback for a dead header subscription.
  static const int shieldedSyncPollInterval = 20;

  /// Checksum-checked, not shape only: a mistyped address otherwise passes as
  /// valid and fails later in the builder. No S (P2CS): nothing here pays it.
  static bool isValidAddress(String address) {
    try {
      if (address.startsWith('ps')) {
        return Bech32Decoder.decode(
                    PivxSaplingNetwork.mainnetPaymentAddressHrp, address)
                .length ==
            kSaplingPaymentAddressSize;
      }
      if (address.startsWith('EXM')) {
        PivxExchangeAddress.fromAddress(address);
      } else if (address.startsWith('6')) {
        P2shAddress.fromAddress(address: address, network: mainnet);
      } else if (address.startsWith('D')) {
        P2pkhAddress.fromAddress(address: address, network: mainnet);
      } else {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
