import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_ethereum/deuro/deuro_savings_contract.dart';
import 'package:cw_ethereum/ethereum_wallet.dart';
import 'package:cw_evm/contract/erc20.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/pending_evm_chain_transaction.dart';
import 'package:web3dart/web3dart.dart';

const String savingsGatewayAddress =
    "0x073493d73258C4BEb6542e8dd3e1b2891C972303";

const String dEuroAddress = "0xbA3f535bbCcCcA2A154b573Ca6c5A49BAAE0a3ea";

class DEuro {
  final SavingsGateway _savingsGateway;
  final ERC20 _dEuro;
  final EthereumWallet _wallet;

  DEuro(EthereumWallet wallet)
      : _wallet = wallet,
        _savingsGateway = _getSavingsGateway(wallet.getWeb3Client()!),
        _dEuro = _getDEuroToken(wallet.getWeb3Client()!);

  static SavingsGateway _getSavingsGateway(Web3Client client) => SavingsGateway(
        address: EthereumAddress.fromHex(savingsGatewayAddress),
        client: client,
      );

  static ERC20 _getDEuroToken(Web3Client client) => ERC20(
        address: EthereumAddress.fromHex(dEuroAddress),
        client: client,
      );

  final frontendCode =
      Uint8List.fromList(sha256.convert(utf8.encode("wallet")).bytes);

  EthereumAddress get _address =>
      EthereumAddress.fromHex(_wallet.walletAddresses.primaryAddress);

  Future<BigInt> get savingsBalance async =>
      (await _savingsGateway.savings(accountOwner: _address)).saved;

  Future<BigInt> get accruedInterest =>
      _savingsGateway.accruedInterest(accountOwner: _address);

  Future<BigInt> get interestRate => _savingsGateway.currentRatePPM();

  Future<BigInt> get approvedBalance =>
      _dEuro.allowance(_address, _savingsGateway.self.address);

  Future<PendingEVMChainTransaction> depositSavings(
      BigInt amount, EVMChainTransactionPriority priority) async {
    final signedTransaction = await _savingsGateway.save(
      (amount: amount, frontendCode: frontendCode),
      credentials: _wallet.evmChainPrivateKey,
    );

    final fee = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
      amount: amount,
      contractAddress: _savingsGateway.self.address.hexEip55,
      receivingAddressHex: _savingsGateway.self.address.hexEip55,
      priority: priority,
      data: _savingsGateway.self.abi.functions[17]
          .encodeCall([amount, frontendCode]),
    );

    final sendTransaction =
        () => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

    return PendingEVMChainTransaction(
        sendTransaction: sendTransaction,
        signedTransaction: signedTransaction,
        fee: BigInt.from(fee.estimatedGasFee),
        amount: amount.toString(),
        exponent: 18);
  }

  Future<PendingEVMChainTransaction> withdrawSavings(
      BigInt amount, EVMChainTransactionPriority priority) async {
    final signedTransaction = await _savingsGateway.withdraw(
      (target: _address, amount: amount, frontendCode: frontendCode),
      credentials: _wallet.evmChainPrivateKey,
    );

    final fee = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
      amount: amount,
      contractAddress: _savingsGateway.self.address.hexEip55,
      receivingAddressHex: _savingsGateway.self.address.hexEip55,
      priority: priority,
      data: _savingsGateway.self.abi.functions[17]
          .encodeCall([amount, frontendCode]),
    );

    final sendTransaction =
        () => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

    return PendingEVMChainTransaction(
        sendTransaction: sendTransaction,
        signedTransaction: signedTransaction,
        fee: BigInt.from(fee.estimatedGasFee),
        amount: amount.toString(),
        exponent: 18);
  }

  // Set an infinite approval to save gas in the future
  Future<PendingEVMChainTransaction> enableSavings(
          EVMChainTransactionPriority priority) async =>
      (await _wallet.createApprovalTransaction(
        BigInt.parse(
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          radix: 16,
        ),
        _savingsGateway.self.address.hexEip55,
        CryptoCurrency.deuro,
        priority,
      )) as PendingEVMChainTransaction;
}
