import 'package:cw_core/wallet_base.dart';
import 'package:cw_ethereum/ethereum_balance.dart';
import 'package:cw_ethereum/ethereum_transaction_history.dart';
import 'package:cw_ethereum/ethereum_transaction_info.dart';
import 'package:mobx/mobx.dart';

part 'ethereum_wallet.g.dart';

class EthereumWallet = EthereumWalletBase with _$EthereumWallet;

abstract class EthereumWalletBase
    extends WalletBase<EthereumBalance, EthereumTransactionHistory, EthereumTransactionInfo>
    with Store {
  EthereumWalletBase(super.walletInfo);
}
