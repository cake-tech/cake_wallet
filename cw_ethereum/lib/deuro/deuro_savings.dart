import 'package:cw_core/crypto_currency.dart';
import 'package:cw_ethereum/deuro/constants.dart';
import 'package:cw_ethereum/deuro/deuro_base.dart';
import 'package:cw_ethereum/deuro/deuro_savings_contract.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/pending_evm_chain_transaction.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class DEuroSavings extends DEuroBase {
  final SavingsGateway _savingsGateway;

  DEuroSavings(super.wallet_) : _savingsGateway = _getSavingsGateway(wallet_.getWeb3Client()!);

  static SavingsGateway _getSavingsGateway(Web3Client client) => SavingsGateway(
        address: EthereumAddress.fromHex(savingsGatewayAddress),
        client: client,
      );

  Future<BigInt> get savingsBalance async =>
      (await _savingsGateway.savings(accountOwner: walletAddress)).saved;

  Future<BigInt> get accruedInterest =>
      _savingsGateway.accruedInterest(accountOwner: walletAddress);

  Future<BigInt> get interestRate => _savingsGateway.currentRatePPM();

  Future<BigInt> get approvedBalance =>
      dEuro.allowance(walletAddress, _savingsGateway.self.address);

  Future<PendingEVMChainTransaction> depositSavings(
      BigInt amount, EVMChainTransactionPriority priority) async {
    try {
      final fee = await wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: amount,
        contractAddress: _savingsGateway.self.address.hexEip55,
        receivingAddressHex: _savingsGateway.self.address.hexEip55,
        priority: priority,
        data: _savingsGateway.self.abi.functions[17].encodeCall([amount, hexToBytes(frontendCode)]),
      );

      await assertEthBalanceForGasFees(BigInt.from(fee.estimatedGasFee));

      final signedTransaction = await _savingsGateway.save(
        (amount: amount, frontendCode: hexToBytes(frontendCode)),
        credentials: wallet.evmChainPrivateKey,
      );

      final sendTransaction = () => wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

      return PendingEVMChainTransaction(
        feeCurrency: "ETH",
        sendTransaction: sendTransaction,
        signedTransaction: signedTransaction,
        fee: BigInt.from(fee.estimatedGasFee),
        amount: amount.toString(),
        exponent: 18,
      );
    } catch (e) {
      if (e.toString().contains('insufficient funds for gas')) {
        final ethBalance = await wallet.getWeb3Client()!.getBalance(walletAddress);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }

  Future<PendingEVMChainTransaction> withdrawSavings(
      BigInt amount, EVMChainTransactionPriority priority) async {
    try {
      final fee = await wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: amount,
        contractAddress: _savingsGateway.self.address.hexEip55,
        receivingAddressHex: _savingsGateway.self.address.hexEip55,
        priority: priority,
        data: _savingsGateway.self.abi.functions[24]
            .encodeCall([walletAddress, amount, hexToBytes(frontendCode)]),
      );

      await assertEthBalanceForGasFees(BigInt.from(fee.estimatedGasFee));

      final signedTransaction = await _savingsGateway.withdraw(
        (target: walletAddress, amount: amount, frontendCode: hexToBytes(frontendCode)),
        credentials: wallet.evmChainPrivateKey,
      );
      final sendTransaction = () => wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

      return PendingEVMChainTransaction(
          sendTransaction: sendTransaction,
          signedTransaction: signedTransaction,
          fee: BigInt.from(fee.estimatedGasFee),
          amount: amount.toString(),
          feeCurrency: "ETH",
          exponent: 18);
    } catch (e) {
      if (e.toString().contains('insufficient funds for gas')) {
        final ethBalance = await wallet.getWeb3Client()!.getBalance(walletAddress);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }

  Future<PendingEVMChainTransaction> reinvestInterest(EVMChainTransactionPriority priority) async {
    try {
      final fee = await wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: BigInt.zero,
        contractAddress: _savingsGateway.self.address.hexEip55,
        receivingAddressHex: _savingsGateway.self.address.hexEip55,
        priority: priority,
        data: _savingsGateway.self.abi.functions[15].encodeCall([walletAddress]),
      );

      await assertEthBalanceForGasFees(BigInt.from(fee.estimatedGasFee));

      final signedTransaction = await _savingsGateway.refreshBalance(
        (owner: walletAddress),
        credentials: wallet.evmChainPrivateKey,
      );

      final sendTransaction = () => wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

      return PendingEVMChainTransaction(
        feeCurrency: "ETH",
        sendTransaction: sendTransaction,
        signedTransaction: signedTransaction,
        fee: BigInt.from(fee.estimatedGasFee),
        amount: 0.toString(),
        exponent: 18,
      );
    } catch (e) {
      if (e.toString().contains('insufficient funds for gas')) {
        final ethBalance = await wallet.getWeb3Client()!.getBalance(walletAddress);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }

  // Set an infinite approval to save gas in the future
  Future<PendingEVMChainTransaction> enableSavings(EVMChainTransactionPriority priority) async {
    try {
      final infinity = BigInt.parse(
        'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        radix: 16,
      );

      final fee = await wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: BigInt.zero,
        contractAddress: dEuro.self.address.hexEip55,
        receivingAddressHex: dEuro.self.address.hexEip55,
        priority: priority,
        data: dEuro.self.abi.functions[1].encodeCall([_savingsGateway.self.address, infinity]),
      );

      await assertEthBalanceForGasFees(BigInt.from(fee.estimatedGasFee));

      return (await wallet.createApprovalTransaction(
        infinity,
        _savingsGateway.self.address.hexEip55,
        CryptoCurrency.deuro,
        priority,
        "ETH",
      )) as PendingEVMChainTransaction;
    } catch (e) {
      if (e.toString().contains('insufficient funds for gas')) {
        final ethBalance = await wallet.getWeb3Client()!.getBalance(walletAddress);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }
}
