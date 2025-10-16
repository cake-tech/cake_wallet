import 'package:cw_ethereum/deuro/constants.dart';
import 'package:cw_ethereum/ethereum_wallet.dart';
import 'package:cw_evm/contract/erc20.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';
import 'package:web3dart/web3dart.dart';

abstract class DEuroBase {
  final ERC20 dEuro;
  final EthereumWallet wallet;

  DEuroBase(EthereumWallet wallet_)
      : wallet = wallet_,
        dEuro = _getDEuroToken(wallet_.getWeb3Client()!);

  static ERC20 _getDEuroToken(Web3Client client) => ERC20(
        address: EthereumAddress.fromHex(dEuroAddress),
        client: client,
      );

  EthereumAddress get walletAddress =>
      EthereumAddress.fromHex(wallet.walletAddresses.primaryAddress);

  Future<void> assertEthBalanceForGasFees(BigInt requiredBalance) async {
    final currentBalance = await wallet.getWeb3Client()!.getBalance(walletAddress);

    if (currentBalance.getInWei < requiredBalance) {
      throw InsufficientGasFeeException(
        requiredGasFee: requiredBalance,
        currentBalance: currentBalance.getInWei,
      );
    }
  }
}
