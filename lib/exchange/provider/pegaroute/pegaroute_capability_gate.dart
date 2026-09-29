import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'pegaroute_api.dart';
import 'pegaroute_currency_mapper.dart';

/// Final wallet/shape gates from trusted_execution and deposit, not the obsolete
/// phase-one registry gate. Recognizing a wire shape does not authorize it.
class PegarouteCapabilityGate {
  static const evmChains = {'ETH': 1, 'BSC': 56, 'BASE': 8453, 'ARBITRUM': 42161, 'POLYGON': 137};
  static const evmWallets = {WalletType.ethereum, WalletType.bsc, WalletType.base,
    WalletType.arbitrum, WalletType.polygon};
  static const depositWallets = {
    'BTC': WalletType.bitcoin, 'BCH': WalletType.bitcoinCash,
    'LTC': WalletType.litecoin, 'DOGE': WalletType.dogecoin,
    'XMR': WalletType.monero, 'SOL': WalletType.solana,
    'TRON': WalletType.tron, 'ZEC': WalletType.zcash,
  };
  static const utxo = {'BTC', 'BCH', 'LTC', 'DOGE'};
  static const providers = {'instaswap', 'thorchain', 'maya', 'openocean'};

  static bool source(WalletBase wallet, PegarouteAssetId asset) {
    if (wallet.isHardwareWallet || !wallet.isSoftwareWallet ||
        !const {null, '', 'mainnet'}.contains(wallet.walletInfo.network)) return false;
    if (evmChains.containsKey(asset.chain)) {
      return evmWallets.contains(wallet.type) && evmChains[asset.chain] == wallet.chainId;
    }
    if (depositWallets[asset.chain] != wallet.type ||
        (asset.token != asset.nativeToken && asset.chain != 'SOL')) return false;
    if (electrumWalletTypes.contains(wallet.type) &&
        (bitcoin == null || bitcoin!.isTestnet(wallet))) return false;
    return switch (wallet.type) {
      WalletType.monero => monero != null,
      WalletType.solana => solana != null,
      WalletType.tron => tron != null,
      WalletType.zcash => zcash != null,
      _ => true,
    };
  }

  static bool quote(PegarouteAssetId asset, PegarouteRoute route) {
    if ((route.privateValue?.isEnabled ?? false) || !providers.contains(route.provider)) return false;
    if (evmChains.containsKey(asset.chain)) {
      return route.provider != 'instaswap' || route.memo == null && route.router == null;
    }
    return asset.chain == 'SOL' && route.provider == 'openocean' ||
        depositWallets.containsKey(asset.chain) &&
        const {'instaswap', 'thorchain', 'maya'}.contains(route.provider) &&
        (asset.token == asset.nativeToken || asset.chain == 'SOL' && route.provider == 'instaswap') &&
        (utxo.contains(asset.chain) || route.memo == null);
  }

  static bool execution(PegarouteAssetId asset, PegarouteExecution value,
      String provider, int? walletChainId) {
    if (!providers.contains(provider)) return false;
    final native = asset.token == asset.nativeToken;
    if (value.family == 'evm') {
      if (!evmChains.containsKey(asset.chain) || evmChains[asset.chain] != walletChainId ||
          value.chainId != walletChainId ||
          !RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(value.to ?? '')) return false;
      return switch (value.mode) {
        'native-transfer' => native && value.approval == null && value.data == null &&
            value.memo == null && value.transferAmount == null,
        'erc20-transfer' => !native && provider == 'instaswap' && value.approval == null &&
            value.memo == null && value.data == null &&
            RegExp(r'^[^-]+-0x[0-9a-fA-F]{40}$').hasMatch(asset.token),
        'contract-call' => (!native || value.approval == null) && provider != 'instaswap' &&
            value.transferAmount == null && RegExp(r'^0x(?:[0-9a-fA-F]{2})+$').hasMatch(value.data ?? ''),
        _ => false,
      };
    }
    if (asset.chain == 'SOL' && value.family == 'solana' &&
        value.mode == 'serialized-tx' && provider == 'openocean') return true;
    if (!const {'instaswap', 'thorchain', 'maya'}.contains(provider) || value.to == null) return false;
    if (utxo.contains(asset.chain)) {
      return native && value.family == 'utxo' && value.mode == 'payment-with-memo';
    }
    if (value.memo != null) return false;
    return switch (asset.chain) {
      'ZEC' => native && value.family == 'utxo' && value.mode == 'payment-with-memo',
      'XMR' => native && value.family == 'other' && value.mode == 'deposit-transfer',
      'SOL' => value.family == 'solana' && value.mode == 'deposit-transfer' &&
          (native || provider == 'instaswap'),
      'TRON' => native && value.family == 'tron' && value.mode == 'deposit-transfer',
      _ => false,
    };
  }
}
