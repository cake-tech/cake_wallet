

import "package:cake_wallet/utils/token_utilities.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/wallet_type.dart";

class SwapUriHelper {
  static PaymentURI getUri(String address, String amount, CryptoCurrency currency) {
    final uriWalletType = cryptoCurrencyOrTokenToWalletType(currency);

    if (uriWalletType == null) {
      return ExternalAddressURI(address: address, amount: amount);
    }

    switch (uriWalletType) {
      case WalletType.bitcoin:
        return BitcoinURI(address: address, amount: amount);
      case WalletType.bitcoinCash:
        return BitcoinCashURI(address: address, amount: amount);
      case WalletType.dogecoin:
        return DogeURI(address: address, amount: amount);
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
      case WalletType.robinhood:
        return _createERC681URI(currency, address, amount);
      case WalletType.solana:
        if (currency == CryptoCurrency.sol) {
          return SolanaURI(amount: amount, address: address);
        }
        return switch (TokenUtilities.findSolanaTokenMint(currency)) {
          final mint? => SolanaURI(amount: amount, address: address, contractAddress: mint),
          null => ExternalAddressURI(address: address, amount: amount),
        };
      case WalletType.tron:
        if (currency == CryptoCurrency.trx) {
          return TronURI(amount: amount, address: address);
        }
        return switch (TokenUtilities.findTronTokenContract(currency)) {
          final contract? => TronURI(amount: amount, address: address, contractAddress: contract),
          null => ExternalAddressURI(address: address, amount: amount),
        };
      case WalletType.monero:
        return MoneroURI(address: address, amount: amount);
      case WalletType.wownero:
        return MoneroURI(address: address, amount: amount);
      case WalletType.litecoin:
        return LitecoinURI(amount: amount, address: address);
      case WalletType.nano:
        return NanoURI(amount: amount, address: address);
      case WalletType.zano:
        return ZanoURI(amount: amount, address: address);
      case WalletType.decred:
        return DecredURI(amount: amount, address: address);
      case WalletType.zcash:
        return ZcashURI(amount: amount, address: address);
      case WalletType.banano:
      case WalletType.none:
      case WalletType.haven:
        throw Exception("bad wallet type");
    }
  }

  static PaymentURI _createERC681URI(CryptoCurrency currency, String address, String amount) {
    final chainId = TokenUtilities.getChainId(currency);
    final isNativeToken = TokenUtilities.isNativeToken(currency);

    if (isNativeToken) {
      return ERC681URI(
        chainId: chainId,
        address: address,
        amount: amount,
        contractAddress: null,
      );
    } else {
      final erc20Token = TokenUtilities.findErc20TokenForSwap(currency);

      if (erc20Token == null) {
        return ExternalAddressURI(address: address, amount: amount);
      }

      return ERC681URI(
        chainId: chainId,
        address: address,
        amount: amount,
        tokenDecimals: erc20Token.decimal,
        contractAddress: erc20Token.contractAddress,
      );
    }
  }
}