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

  static Future<List<WalletInfoAddressInfo>> addressesForAccountsWallet(WalletInfo wallet) async {
    final List<WalletInfoAddressInfo> ret = [];
    final addresses = await wallet.getAddressInfos();
    for (var list in addresses.values) {
      // we only want the "primary" account addresses - those that contain account names.
      ret.addAll(list.where((item) => item.label.split(" ").length > 1));
    }
    return ret;
  }
}
