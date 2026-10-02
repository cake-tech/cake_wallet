import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/wallet_types.g.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

class WalletNetwork {
  const WalletNetwork.builtin(this.type) : chainId = null;

  const WalletNetwork.added(int this.chainId) : type = WalletType.evm;

  const WalletNetwork._(this.type, this.chainId);

  factory WalletNetwork.of(WalletType type, int? chainId) {
    if (type != WalletType.evm) {
      return WalletNetwork.builtin(type);
    }

    return chainId == null
        ? const WalletNetwork._(WalletType.evm, null)
        : WalletNetwork.added(chainId);
  }

  factory WalletNetwork.fromWallet(WalletInfo info) => WalletNetwork.of(info.type, info.chainId);

  static WalletNetwork? tryFromCurrency(CryptoCurrency currency) {
    final type = cryptoCurrencyOrTokenToWalletType(currency);
    if (type == null) {
      return null;
    }

    return WalletNetwork.of(type, getChainIdByCryptoCurrency(currency));
  }

  final WalletType type;
  final int? chainId;

  CryptoCurrency get nativeCurrency => walletTypeToCryptoCurrency(type, chainId: chainId);

  int? get evmChainId {
    if (type == WalletType.evm) {
      return chainId;
    }

    return isEVMCompatibleChain(type) ? evm?.getChainIdByWalletType(type) : null;
  }

  bool isCurrencyNetwork(CryptoCurrency currency) => tryFromCurrency(currency) == this;

  @override
  bool operator ==(Object other) =>
      other is WalletNetwork && other.type == type && other.chainId == chainId;

  @override
  int get hashCode => Object.hash(type, chainId);
}

String builtinNetworkIconPath(WalletType type) => switch (type) {
      WalletType.monero => "assets/new-ui/network_icons/monero.svg",
      WalletType.bitcoin => "assets/new-ui/network_icons/bitcoin.svg",
      WalletType.ethereum => "assets/new-ui/network_icons/ethereum.svg",
      WalletType.bsc => "assets/new-ui/network_icons/bsc.svg",
      WalletType.solana => "assets/new-ui/network_icons/solana.svg",
      WalletType.zcash => "assets/new-ui/network_icons/zcash.svg",
      WalletType.tron => "assets/new-ui/network_icons/tron.svg",
      WalletType.dogecoin => "assets/new-ui/network_icons/dogecoin.svg",
      WalletType.bitcoinCash => "assets/new-ui/network_icons/bitcoin_cash.svg",
      WalletType.litecoin => "assets/new-ui/network_icons/litecoin.svg",
      WalletType.base => "assets/new-ui/network_icons/base.svg",
      WalletType.arbitrum => "assets/new-ui/network_icons/arbitrum.svg",
      WalletType.polygon => "assets/new-ui/network_icons/polygon.svg",
      WalletType.nano => "assets/new-ui/network_icons/nano.svg",
      WalletType.decred => "assets/new-ui/network_icons/decred.svg",
      WalletType.zano => "assets/new-ui/network_icons/zano.svg",
      WalletType.haven ||
      WalletType.banano ||
      WalletType.wownero ||
      WalletType.evm ||
      WalletType.none =>
        getCryptoCurrencyIconForWalletListItem(type),
    };

List<WalletType> get builtinNetworkTypes =>
    availableWalletTypes.where((type) => type != WalletType.evm).toList();
