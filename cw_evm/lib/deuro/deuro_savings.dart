import 'package:cw_core/crypto_currency.dart';
import 'package:cw_evm/deuro/deuro_savings_contract.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_evm/contract/erc20.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/pending_evm_chain_transaction.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const String savingsGatewayAddress = "0x073493d73258C4BEb6542e8dd3e1b2891C972303";

const String dEuroAddress = "0xbA3f535bbCcCcA2A154b573Ca6c5A49BAAE0a3ea";
const String frontendCode = "0x00000000000000000000000000000000000000000043616b652057616c6c6574";

class DEuro {
  final SavingsGateway _savingsGateway;
  final ERC20 _dEuro;
  final EVMChainWallet _wallet;

  DEuro(EVMChainWallet wallet)
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

  EthereumAddress get _address => EthereumAddress.fromHex(_wallet.walletAddresses.primaryAddress);

  Future<BigInt> get savingsBalance async =>
      (await _savingsGateway.savings(accountOwner: _address)).saved;

  Future<BigInt> get accruedInterest => _savingsGateway.accruedInterest(accountOwner: _address);

  Future<BigInt> get interestRate => _savingsGateway.currentRatePPM();

  Future<BigInt> get approvedBalance => _dEuro.allowance(_address, _savingsGateway.self.address);

  Future<void> _checkEthBalanceForGasFees(EVMChainTransactionPriority priority) async {
    final ethBalance = await _wallet.getWeb3Client()!.getBalance(_address);
    final currentBalance = ethBalance.getInWei;

    final gasFeesModel = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
      amount: BigInt.zero,
      contractAddress: _savingsGateway.self.address.hexEip55,
      receivingAddressHex: _savingsGateway.self.address.hexEip55,
      priority: priority,
      data: _savingsGateway.self.abi.functions[17]
          .encodeCall([BigInt.zero, hexToBytes(frontendCode)]),
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

      final signedTransaction = await _savingsGateway.save(
        (amount: amount, frontendCode: hexToBytes(frontendCode)),
        credentials: _wallet.evmChainPrivateKey,
      );

      final fee = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: amount,
        contractAddress: _savingsGateway.self.address.hexEip55,
        receivingAddressHex: _savingsGateway.self.address.hexEip55,
        priority: priority,
        data: _savingsGateway.self.abi.functions[17].encodeCall([amount, hexToBytes(frontendCode)]),
      );

      final sendTransaction = () => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

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

      final signedTransaction = await _savingsGateway.withdraw(
        (target: _address, amount: amount, frontendCode: hexToBytes(frontendCode)),
        credentials: _wallet.evmChainPrivateKey,
      );

      final fee = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: amount,
        contractAddress: _savingsGateway.self.address.hexEip55,
        receivingAddressHex: _savingsGateway.self.address.hexEip55,
        priority: priority,
        data: _savingsGateway.self.abi.functions[24].encodeCall([_address, amount, hexToBytes(frontendCode)]),
      );

      final sendTransaction = () => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

      return PendingEVMChainTransaction(
          sendTransaction: sendTransaction,
          signedTransaction: signedTransaction,
          fee: BigInt.from(fee.estimatedGasFee),
          amount: amount.toString(),
          feeCurrency: "ETH",
          exponent: 18);
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

      final signedTransaction = await _savingsGateway.refreshBalance((owner: _address),
        credentials: _wallet.evmChainPrivateKey,
      );

      final fee = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: BigInt.zero,
        contractAddress: _savingsGateway.self.address.hexEip55,
        receivingAddressHex: _savingsGateway.self.address.hexEip55,
        priority: priority,
        data: _savingsGateway.self.abi.functions[15].encodeCall([_address]),
      );

      final sendTransaction = () => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

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
        BigInt.parse(
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          radix: 16,
        ),
        _savingsGateway.self.address.hexEip55,
        CryptoCurrency.deuro,
        priority,
        "ETH",
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

