import 'dart:typed_data';

import 'package:cw_ethereum/deuro/deuro_savings_contract.dart';
import 'package:cw_ethereum/ethereum_wallet.dart';
import 'package:cw_evm/pending_evm_chain_transaction.dart';
import 'package:web3dart/web3dart.dart';

const String savingsGatewayAddress =
    "0x073493d73258C4BEb6542e8dd3e1b2891C972303";

class DEuro {
  final SavingsGateway _savingsGateway;
  final EthereumWallet _wallet;

  DEuro(EthereumWallet wallet)
      : _wallet = wallet,
        _savingsGateway = _getSavingsGateway(wallet.getWeb3Client()!);

  static SavingsGateway _getSavingsGateway(Web3Client client) => SavingsGateway(
        address: EthereumAddress.fromHex(savingsGatewayAddress),
        client: client,
      );

  EthereumAddress get _address =>
      EthereumAddress.fromHex(_wallet.walletAddresses.primaryAddress);

  Future<BigInt> get savingsBalance async =>
      (await _savingsGateway.savings(accountOwner: _address)).saved;

  Future<BigInt> get accruedInterest =>
      _savingsGateway.accruedInterest(accountOwner: _address);

  Future<BigInt> get interestRate => _savingsGateway.currentRatePPM();

  Future<PendingEVMChainTransaction> depositSavings(BigInt amount) async {
    final signedTransaction = await _savingsGateway.save(
      (amount: amount, frontendCode: Uint8List(0)),
      credentials: _wallet.evmChainPrivateKey,
    );

    final fee = await _wallet.getWeb3Client()!.estimateGas(
      sender: _wallet.evmChainPrivateKey.address,
      to: _savingsGateway.self.address,
      data: _savingsGateway.self.function('save').encodeCall([amount, Uint8List(0)]),
    );

    final sendTransaction =
        () => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

    return PendingEVMChainTransaction(
        sendTransaction: sendTransaction,
        signedTransaction: signedTransaction,
        fee: fee,
        amount: amount.toString(),
        exponent: 18);
  }
}
