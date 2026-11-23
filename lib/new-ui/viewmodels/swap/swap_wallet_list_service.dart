import "package:cake_wallet/exchange/utils/deposit_wallet_utils.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

class SwapWalletListService {
  static Future<List<WalletInfo>> getWallets(CryptoCurrency currency) async {
    final type = cryptoCurrencyOrTokenToWalletType(currency);

    if (type == null) {
      return [];
    }

    return WalletInfo.getAllForType(type);
  }

  static Future<List<WalletInfo>> getDepositWallets(CryptoCurrency currency) async {
    final type = depositWalletType(currency);

    if (type == null) {
      return [];
    }

    return (await WalletInfo.getAllForType(type))
        .where((wallet) => canFundDeposit(wallet, currency))
        .toList();
  }

  static Future<List<WalletInfoAddressInfo>?> accountAddresses(WalletInfo wallet) async {
    if (wallet.type != WalletType.monero) {
    // btc has accounts as well but doesn't save addresses per-account
    // we could work around it but there's a refactor for it right around the corner so i'm not touching wallet code
      return null;
    }

    final addresses = [
      // we only want the "primary" account addresses - those that contain account names.
      for (final list in (await wallet.getAddressInfos()).values)
        ...list.where((item) => item.label.split(" ").length > 1),
    ];

    return addresses.isEmpty ? null : addresses;
  }
}
