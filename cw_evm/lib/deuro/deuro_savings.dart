import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_evm/deuro/deuro_savings_gateway_contract.dart' as v1;
import 'package:cw_evm/deuro/deuro_savings_contract.dart' as v2;
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_evm/contract/erc20.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/pending_evm_chain_transaction.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const String savingsGatewayAddress = "0x073493d73258C4BEb6542e8dd3e1b2891C972303";
const String savingsV2Address = "0x760233b90e45d186A9A98E911B115F7F4B90d3D9";

const String dEuroAddress = "0xbA3f535bbCcCcA2A154b573Ca6c5A49BAAE0a3ea";
const String frontendCode = "0x00000000000000000000000000000000000000000043616b652057616c6c6574";

class DEuro {
  final v2.Savings _savings;
  final ERC20 _dEuro;
  final EVMChainWallet _wallet;

  DEuro(EVMChainWallet wallet)
      : _wallet = wallet,
        _savings = _getSavings(wallet.getWeb3Client()!),
        _dEuro = _getDEuroToken(wallet.getWeb3Client()!);

  static v2.Savings _getSavings(Web3Client client) => v2.Savings(
        address: EthereumAddress.fromHex(savingsV2Address),
        client: client,
      );

  static v1.SavingsGateway _getSavingsGateway(Web3Client client) => v1.SavingsGateway(
        address: EthereumAddress.fromHex(savingsGatewayAddress),
        client: client,
      );

  static ERC20 _getDEuroToken(Web3Client client) => ERC20(
        address: EthereumAddress.fromHex(dEuroAddress),
        client: client,
      );

  EthereumAddress get _address => EthereumAddress.fromHex(_wallet.walletAddresses.primaryAddress);

  Future<Money> get savingsBalance async =>
      Money((await _savings.savings(accountOwner: _address)).saved, CryptoCurrency.deuro);

  Future<Money> get savingsBalanceV1 async => Money(
      (await _getSavingsGateway(_wallet.getWeb3Client()!).savings(accountOwner: _address)).saved,
      CryptoCurrency.deuro);

  Future<Money> get accruedInterest async =>
      Money(await _savings.accruedInterest(accountOwner: _address), CryptoCurrency.deuro);

  Future<BigInt> get interestRate => _savings.currentRatePPM();

  Future<BigInt> get approvedBalance => _dEuro.allowance(_address, _savings.self.address);

  Future<void> _checkEthBalanceForGasFees(EVMChainTransactionPriority priority) async {
    final ethBalance = await _wallet.getWeb3Client()!.getBalance(_address);
    final currentBalance = ethBalance.getInWei;
    final savings = _getSavingsGateway(_wallet.getWeb3Client()!);

    final gasFeesModel = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
      amount: Money.zero(_wallet.currency),
      contractAddress: savings.self.address.hexEip55,
      receivingAddressHex: savings.self.address.hexEip55,
      priority: priority,
      data: savings.self.abi.functions[17].encodeCall([BigInt.zero, hexToBytes(frontendCode)]),
    );

    final estimatedGasFee = BigInt.from(gasFeesModel.estimatedGasFee);
    final requiredBalance = estimatedGasFee;

    if (currentBalance < requiredBalance) {
      throw InsufficientGasFeeException(
        requiredGasFee: requiredBalance,
        currentBalance: currentBalance,
      );
    }
  }

  Future<PendingEVMChainTransaction> depositSavings(
      BigInt amount, EVMChainTransactionPriority priority) async {
    try {
      await _checkEthBalanceForGasFees(priority);

      final signedTransaction = await _savings.save(
        (amount: amount, compound: true),
        credentials: _wallet.evmChainPrivateKey,
      );

      final fee = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: Money.zero(_wallet.currency),
        contractAddress: _savings.self.address.hexEip55,
        receivingAddressHex: _savings.self.address.hexEip55,
        priority: priority,
        data: _savings.self.abi.functions[18].encodeCall([amount, true]),
      );

      sendTransaction() => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

      return PendingEVMChainTransaction(
        sendTransaction: sendTransaction,
        signedTransaction: signedTransaction,
        fee: Money(BigInt.from(fee.estimatedGasFee), CryptoCurrency.eth),
        amount: Money(amount, CryptoCurrency.deuro),
      );
    } catch (e) {
      if (e.toString().contains('insufficient funds for gas')) {
        final ethBalance = await _wallet.getWeb3Client()!.getBalance(_address);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }

  Future<PendingEVMChainTransaction> withdrawSavings(
      BigInt amount, EVMChainTransactionPriority priority) async {
    try {
      await _checkEthBalanceForGasFees(priority);

      final signedTransaction = await _savings.withdraw(
        (target: _address, amount: amount),
        credentials: _wallet.evmChainPrivateKey,
      );

      final fee = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: Money.zero(_wallet.currency),
        contractAddress: _savings.self.address.hexEip55,
        receivingAddressHex: _savings.self.address.hexEip55,
        priority: priority,
        data: _savings.self.abi.functions[23].encodeCall([_address, amount]),
      );

      sendTransaction() => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

      return PendingEVMChainTransaction(
        sendTransaction: sendTransaction,
        signedTransaction: signedTransaction,
        fee: Money(BigInt.from(fee.estimatedGasFee), CryptoCurrency.eth),
        amount: Money(amount, CryptoCurrency.deuro),
      );
    } catch (e) {
      if (e.toString().contains('insufficient funds for gas')) {
        final ethBalance = await _wallet.getWeb3Client()!.getBalance(_address);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }

  Future<PendingEVMChainTransaction> withdrawSavingsV1(EVMChainTransactionPriority priority) async {
    try {
      await _checkEthBalanceForGasFees(priority);
      final withdrawAmount = await savingsBalanceV1;

      // Withdraw at least a million to overflow and close the savings position
      final amount = BigInt.parse("1000000000000000000000000");
      final savings = _getSavingsGateway(_wallet.getWeb3Client()!);
      final signedTransaction = await savings.withdraw(
        (target: _address, amount: amount, frontendCode: hexToBytes(frontendCode)),
        credentials: _wallet.evmChainPrivateKey,
      );

      final fee = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: Money.zero(_wallet.currency),
        contractAddress: savings.self.address.hexEip55,
        receivingAddressHex: savings.self.address.hexEip55,
        priority: priority,
        data:
            savings.self.abi.functions[24].encodeCall([_address, amount, hexToBytes(frontendCode)]),
      );

      sendTransaction() => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

      return PendingEVMChainTransaction(
        sendTransaction: sendTransaction,
        signedTransaction: signedTransaction,
        fee: Money(BigInt.from(fee.estimatedGasFee), CryptoCurrency.eth),
        amount: withdrawAmount,
      );
    } catch (e) {
      if (e.toString().contains('insufficient funds for gas')) {
        final ethBalance = await _wallet.getWeb3Client()!.getBalance(_address);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }

  Future<PendingEVMChainTransaction> reinvestInterest(EVMChainTransactionPriority priority) async {
    try {
      await _checkEthBalanceForGasFees(priority);

      final signedTransaction = await _savings.refreshBalance(
        (owner: _address),
        credentials: _wallet.evmChainPrivateKey,
      );

      final fee = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: Money.zero(_wallet.currency),
        contractAddress: _savings.self.address.hexEip55,
        receivingAddressHex: _savings.self.address.hexEip55,
        priority: priority,
        data: _savings.self.abi.functions[16].encodeCall([_address]),
      );

      sendTransaction() => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

      return PendingEVMChainTransaction(
        sendTransaction: sendTransaction,
        signedTransaction: signedTransaction,
        fee: Money(BigInt.from(fee.estimatedGasFee), CryptoCurrency.eth),
        amount: Money.zero(CryptoCurrency.deuro),
      );
    } catch (e) {
      if (e.toString().contains('insufficient funds for gas')) {
        final ethBalance = await _wallet.getWeb3Client()!.getBalance(_address);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }

  // Set an infinite approval to save gas in the future
  Future<PendingEVMChainTransaction> enableSavings(EVMChainTransactionPriority priority) async {
    try {
      await _checkEthBalanceForGasFees(priority);

      return (await _wallet.createApprovalTransaction(
        Money(
            BigInt.parse(
              'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
              radix: 16,
            ),
            CryptoCurrency.deuro),
        _savings.self.address.hexEip55,
        priority,
      )) as PendingEVMChainTransaction;
    } catch (e) {
      if (e.toString().contains('insufficient funds for gas')) {
        final ethBalance = await _wallet.getWeb3Client()!.getBalance(_address);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }
}
