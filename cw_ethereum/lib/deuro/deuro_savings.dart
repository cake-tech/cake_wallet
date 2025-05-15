import 'package:cw_ethereum/deuro/deuro_savings_contract.dart';
import 'package:cw_ethereum/ethereum_wallet.dart';
import 'package:web3dart/web3dart.dart';

const String savingsGatewayAddress =
    "0x073493d73258C4BEb6542e8dd3e1b2891C972303";

SavingsGateway _getSavingsGateway(Web3Client client) => SavingsGateway(
    address: EthereumAddress.fromHex(savingsGatewayAddress), client: client);


Future<BigInt> getSavingsBalance(EthereumWallet wallet) async {
  final savings = _getSavingsGateway(wallet.getWeb3Client()!);
  final address = EthereumAddress.fromHex(wallet.walletAddresses.primaryAddress);
  final amount = await savings.savings(accountOwner: address);
  return amount.saved;
}

Future<BigInt> getAccruedInterest(EthereumWallet wallet) async {
  final savings = _getSavingsGateway(wallet.getWeb3Client()!);

  final address = EthereumAddress.fromHex(wallet.walletAddresses.primaryAddress);
  return savings.accruedInterest(accountOwner: address);
}

