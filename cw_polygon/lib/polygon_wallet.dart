import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_polygon/default_polygon_erc20_tokens.dart';

class PolygonWallet extends EVMChainWallet {
  PolygonWallet({
    required super.walletInfo,
    required super.password,
    super.mnemonic,
    super.initialBalance,
    super.privateKey,
    super.nativeCurrency = CryptoCurrency.maticpoly,
  });

  @override
  Future<void> initErc20TokensBox() async {
    evmChainErc20TokensBox = await CakeHive.openBox<Erc20Token>(
      "${walletInfo.name.replaceAll(" ", "_")}_${Erc20Token.polygonBoxName}",
    );
  }

  @override
  void addInitialTokens() {
    final initialErc20Tokens = DefaultPolygonErc20Tokens().initialPolygonErc20Tokens;

    for (var token in initialErc20Tokens) {
      evmChainErc20TokensBox.put(token.contractAddress, token);
    }
  }

  @override
  Future<bool> checkIfScanProviderIsEnabled() async {
    bool isPolygonScanEnabled = (await sharedPrefs.future).getBool("use_polygonscan") ?? true;
    return isPolygonScanEnabled;
  }

  @override
  String getTransactionHistoryFileName() => 'polygon_transactions.json';
}
