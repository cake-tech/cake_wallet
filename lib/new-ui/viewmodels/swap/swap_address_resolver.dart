
import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/lightning_invoice_service.dart";
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_info.dart";

class SwapAddressResolver {
  const SwapAddressResolver({required AppStore appStore}) : _appStore = appStore;

  final AppStore _appStore;




  Future<String> resolveRefundAddress(SwapSource source, CryptoCurrency curr) async =>
      source.refundAddress ?? await _ownAddress(curr);

  Future<String> resolvePayoutAddress(SwapAddress address, CryptoCurrency curr) async =>
      switch (address) {
        InternalWalletSwapAddress(:final walletInfo) =>
          await _addressFromWalletInfo(walletInfo, curr),
        _ => address.address,
      };

  Future<String?> lightningInvoiceFor(String address) async => switch (address) {
    _ when !address.contains("@") => null,
    _ when address == _ownLightningAddress => await _newLightningInvoice(),
    _ => await getBolt11FromLightingAddress(address),
  };

  // a lightning address registered this session isn't in addressesMap until the next refresh
  Future<String> _ownAddress(CryptoCurrency curr) async => curr == CryptoCurrency.btcln
      ? _ownLightningAddress ?? await _newLightningInvoice()
      : _appStore.wallet!.walletAddresses.addressForExchange;

  String? get _ownLightningAddress =>
      _lightningAddressIn(_appStore.wallet!.walletAddresses.addressesMap);

  Future<String> _newLightningInvoice() async =>
      (await bitcoin!.getLightningInvoice(_appStore.wallet!, BigInt.zero))!;

  String? _lightningAddressIn(Map<String, String> addresses) =>
      addresses.entries.firstWhereOrNull((e) => e.value.contains("LN") && e.key.contains("@"))?.key;

  // HACK: not much more we can do here with the way we fetch the wallet list
  Future<String> _addressFromWalletInfo(WalletInfo wi, CryptoCurrency curr) async {
    if (wi.internalId == _appStore.wallet!.walletInfo.internalId) {
      return _ownAddress(curr);
    }

    if (wi.type == .bitcoin) {
      final _walletAddresses = await wi.getAddresses();
      if (curr == CryptoCurrency.btcln) {
        final lightningAddressOfWallet = _lightningAddressIn(_walletAddresses);
        if (lightningAddressOfWallet != null) {
          return lightningAddressOfWallet;
        }
      }
      if (curr == CryptoCurrency.btc) {
        final segwitAddressOfWallet = _walletAddresses.entries
            .firstWhereOrNull((e) => e.value.contains("P2WPKH"))
            ?.key;
        if (segwitAddressOfWallet != null) {
          return segwitAddressOfWallet;
        }
      }
    }

    if (wi.type == .zcash && curr == CryptoCurrency.zec) {

      return (await wi.getAddresses()).entries
              .firstWhereOrNull((e) => e.value == "transparent")
              ?.key ??
          wi.address;
    }

    return wi.address;
  }

}
