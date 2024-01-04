import 'package:cw_core/crypto_currency.dart';
import 'package:cw_ethereum/default_ethereum_erc20_tokens.dart';
import 'package:cw_evm/evm_chain_wallet.dart';

class EthereumWallet extends EVMChainWallet {
  EthereumWallet({
    required super.walletInfo,
    required super.password,
    super.mnemonic,
    super.initialBalance,
    super.privateKey,
    super.nativeCurrency = CryptoCurrency.eth,
  });

  @override
  void addInitialTokens() {
    final initialErc20Tokens = DefaultEthereumErc20Tokens().initialErc20Tokens;

    for (var token in initialErc20Tokens) {
      evmChainErc20TokensBox.put(token.contractAddress, token);
    }
  }
}
