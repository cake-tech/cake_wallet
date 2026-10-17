import "package:cake_wallet/core/everstake/exceptions.dart";
import "package:cake_wallet/core/everstake/models.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:web3dart/crypto.dart";
import "package:web3dart/web3dart.dart";

class EverstakeEthereumTransactionValidator {
  // Mainnet addresses and call inputs from @everstake/wallet-sdk-ethereum 1.1.4.
  static const _poolAddress = "0xD523794C879D9eC028960a231F866758e405bE34";
  static const _accountingAddress = "0x7a7f0b3c23C23a31cFcb0c44709be70d4D545c6e";

  static final _abi = ContractAbi.fromJson(
    '''
    [
      {
        "type": "function",
        "name": "stake",
        "stateMutability": "payable",
        "inputs": [{"name": "source", "type": "uint64"}]
      },
      {
        "type": "function",
        "name": "unstake",
        "inputs": [
          {"name": "value", "type": "uint256"},
          {"name": "allowedInterchangeNum", "type": "uint16"},
          {"name": "source", "type": "uint64"}
        ]
      },
      {
        "type": "function",
        "name": "unstakePending",
        "inputs": [{"name": "amount", "type": "uint256"}]
      },
      {"type": "function", "name": "claimWithdrawRequest", "inputs": []},
      {"type": "function", "name": "activateStake", "inputs": []},
      {"type": "function", "name": "autocompound", "inputs": []}
    ]
  ''',
    "Everstake",
  );

  void validateStake(
    EverstakeEthereumTransaction transaction, {
    required String address,
    required Money amount,
    required String source,
  }) =>
      _validate(
        transaction,
        address: address,
        contract: _poolAddress,
        value: amount,
        method: "stake",
        arguments: [BigInt.parse(source)],
      );

  void validateUnstake(
    EverstakeEthereumTransaction transaction, {
    required String address,
    required Money amount,
    required int allowedInterchangeNum,
    required String source,
  }) =>
      _validate(
        transaction,
        address: address,
        contract: _poolAddress,
        value: Money.zero(CryptoCurrency.eth),
        method: "unstake",
        arguments: [_wei(amount), BigInt.from(allowedInterchangeNum), BigInt.parse(source)],
      );

  void validateUnstakePending(
    EverstakeEthereumTransaction transaction, {
    required String address,
    required Money amount,
  }) =>
      _validate(
        transaction,
        address: address,
        contract: _poolAddress,
        value: Money.zero(CryptoCurrency.eth),
        method: "unstakePending",
        arguments: [_wei(amount)],
      );

  void validateClaimWithdrawRequest(
    EverstakeEthereumTransaction transaction, {
    required String address,
  }) =>
      _validate(
        transaction,
        address: address,
        contract: _accountingAddress,
        value: Money.zero(CryptoCurrency.eth),
        method: "claimWithdrawRequest",
      );

  void validateActivateStake(EverstakeEthereumTransaction transaction, {required String address}) =>
      _validate(
        transaction,
        address: address,
        contract: _poolAddress,
        value: Money.zero(CryptoCurrency.eth),
        method: "activateStake",
      );

  void validateAutocompound(EverstakeEthereumTransaction transaction, {required String address}) =>
      _validate(
        transaction,
        address: address,
        contract: _accountingAddress,
        value: Money.zero(CryptoCurrency.eth),
        method: "autocompound",
      );

  void _validate(
    EverstakeEthereumTransaction transaction, {
    required String address,
    required String contract,
    required Money value,
    required String method,
    List<BigInt> arguments = const [],
  }) {
    if (transaction.from.toLowerCase() != address.toLowerCase()) {
      throw EverstakeException("Unexpected Everstake transaction sender");
    }
    if (transaction.to.toLowerCase() != contract.toLowerCase()) {
      throw EverstakeException("Unexpected Everstake transaction contract");
    }
    final expectedValue = _wei(value);
    if (expectedValue.isNegative || expectedValue.bitLength > 256) {
      throw ArgumentError.value(value, "value", "Expected a uint256 ETH amount");
    }
    if (_wei(transaction.value) != expectedValue) {
      throw EverstakeException("Unexpected Everstake transaction value");
    }

    final function = _abi.functions.firstWhere((function) => function.name == method);
    for (var i = 0; i < arguments.length; i++) {
      final parameter = function.parameters[i];
      final type = parameter.type as UintType;
      if (arguments[i].isNegative || arguments[i].bitLength > type.length) {
        throw ArgumentError.value(arguments[i], parameter.name, "Expected ${type.name}");
      }
    }

    final data = bytesToHex(function.encodeCall(arguments), include0x: true);
    if (!transaction.data.startsWith("0x") || transaction.data.toLowerCase() != data) {
      throw EverstakeException("Unexpected Everstake transaction data");
    }
  }

  BigInt _wei(Money amount) {
    if (amount.currency != CryptoCurrency.eth || amount.decimals != CryptoCurrency.eth.decimals) {
      throw ArgumentError.value(amount, "amount", "Expected ETH with 18 decimals");
    }
    return amount.amount;
  }
}
