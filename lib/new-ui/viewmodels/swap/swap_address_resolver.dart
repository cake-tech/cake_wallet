
import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/lightning_invoice_service.dart";
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/new-ui/services/wallet_switch_service.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_info.dart";

class SwapAddressResolver {
  const SwapAddressResolver(
      {required WalletSwitchService walletSwitchService, required AppStore appStore})
      : _walletSwitchService = walletSwitchService,
        _appStore = appStore;


  final WalletSwitchService _walletSwitchService;
  final AppStore _appStore;




  Future<String> resolveRefundAddress(SwapSource source, CryptoCurrency curr)async {
    if (source case final ExternalSwapSource source) {
      return source.refundAddress;
    } else if (source case final InternalSwapSource source) {
      String refundAddress;

      if (source.sourceWallet.internalId != _appStore.wallet!.walletInfo.internalId) {
        await _walletSwitchService.switchToWallet(source.sourceWallet);
      }
      refundAddress = curr == CryptoCurrency.btcln
          ? (await bitcoin!.getLightningInvoice(_appStore.wallet!, BigInt.zero))!
        : _appStore.wallet!.walletAddresses.addressForExchange;
      return refundAddress;
    }
    throw Exception("unreachable");
  }

  Future<String> resolvePayoutAddress(SwapAddress address, CryptoCurrency curr) async {
    String payoutAddress = address.address;
    if (address case final InternalWalletSwapAddress address) {
      payoutAddress = await _addressFromWalletInfo(address.walletInfo, curr);
    }

    if (payoutAddress.contains("@")) {
      payoutAddress = await getBolt11FromLightingAddress(payoutAddress) ?? payoutAddress;
    }

    return payoutAddress;
  }


  // HACK: not much more we can do here with the way we fetch the wallet list
  Future<String> _addressFromWalletInfo(WalletInfo wi, CryptoCurrency curr) async {
    if (wi.type == .bitcoin) {
      final _walletAddresses = await wi.getAddresses();
      if (curr == CryptoCurrency.btcln) {
        final lightningAddressOfWallet = _walletAddresses.entries
            .firstWhereOrNull((e) => e.value.contains("LN"))
            ?.key;
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

    return wi.address;
  }

}
