import 'dart:typed_data';

import 'package:web3dart/web3dart.dart' as web3;

final ethereumContractAbi = web3.ContractAbi.fromJson(
    '[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]',
    'Erc20');

/// Interface of the ERC20 standard as defined in the EIP.
class ERC20 extends web3.GeneratedContract {
  /// Constructor.
  ERC20({
    required web3.EthereumAddress address,
    required web3.Web3Client client,
    int? chainId,
  }) : super(web3.DeployedContract(ethereumContractAbi, address), client, chainId);

  /// Returns the remaining number of tokens that [spender] will be allowed to spend on behalf of [owner] through [transferFrom]. This is zero by default. This value changes when [approve] or [transferFrom] are called.
  ///
  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> allowance(
      web3.EthereumAddress owner,
      web3.EthereumAddress spender, {
        web3.BlockNum? atBlock,
      }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, 'dd62ed3e'));
    final params = [owner, spender];
    final response = await read(function, params, atBlock);
    return (response[0] as BigInt);
  }

  /// Sets [amount] as the allowance of [spender] over the caller's tokens. Returns a boolean value indicating whether the operation succeeded. IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may use both the old and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729 Emits an [Approval] event.
  ///
  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<Uint8List> approve(
      web3.EthereumAddress spender,
      BigInt amount, {
        required web3.Credentials credentials,
        web3.Transaction? transaction,
      }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '095ea7b3'));
    final params = [spender, amount];
    return writeRaw(credentials, transaction, function, params);
  }

  /// Returns the amount of tokens owned by [account].
  ///
  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> balanceOf(
      web3.EthereumAddress account, {
        web3.BlockNum? atBlock,
      }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '70a08231'));
    final params = [account];
    final response = await read(function, params, atBlock);
    return (response[0] as BigInt);
  }

  /// Returns the decimal precision of the token.
  ///
  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> decimals({web3.BlockNum? atBlock}) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '313ce567'));
    final params = [];
    final response = await read(function, params, atBlock);
    return (response[0] as BigInt);
  }

  /// Returns the name of the token.
  ///
  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<String> name({web3.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '06fdde03'));
    final params = [];
    final response = await read(function, params, atBlock);
    return (response[0] as String);
  }

  /// Returns the symbol of the token.
  ///
  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<String> symbol({web3.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '95d89b41'));
    final params = [];
    final response = await read(function, params, atBlock);
    return (response[0] as String);
  }

  /// Returns the amount of tokens in existence.
  ///
  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> totalSupply({web3.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '18160ddd'));
    final params = [];
    final response = await read(function, params, atBlock);
    return (response[0] as BigInt);
  }

  /// Moves [amount] tokens from the caller's account to [recipient]. Returns a boolean value indicating whether the operation succeeded. Emits a [Transfer] event.
  ///
  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<Uint8List> transfer(
      web3.EthereumAddress recipient,
      BigInt amount, {
        required web3.Credentials credentials,
        web3.Transaction? transaction,
      }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'a9059cbb'));
    final params = [recipient, amount];
    return writeRaw(credentials, transaction, function, params);
  }

  /// Moves [amount] tokens from [sender] to [recipient] using the allowance mechanism. [amount] is then deducted from the caller's allowance. Returns a boolean value indicating whether the operation succeeded. Emits a [Transfer] event.
  ///
  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<Uint8List> transferFrom(web3.EthereumAddress sender,
      web3.EthereumAddress recipient, BigInt amount,
      {required web3.Credentials credentials,
        web3.Transaction? transaction}) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '23b872dd'));
    final params = [sender, recipient, amount];
    return writeRaw(credentials, transaction, function, params);
  }

  /// Returns a live stream of all Approval events emitted by this contract.
  Stream<Approval> approvalEvents(
      {web3.BlockNum? fromBlock, web3.BlockNum? toBlock}) {
    final event = self.event('Approval');
    final filter = web3.FilterOptions.events(
        contract: self, event: event, fromBlock: fromBlock, toBlock: toBlock);
    return client.events(filter).map((web3.FilterEvent result) {
      final decoded = event.decodeResults(result.topics!, result.data!);
      return Approval._(decoded);
    });
  }

  /// Returns a live stream of all Transfer events emitted by this contract.
  Stream<Transfer> transferEvents(
      {web3.BlockNum? fromBlock, web3.BlockNum? toBlock}) {
    final event = self.event('Transfer');
    final filter = web3.FilterOptions.events(
        contract: self, event: event, fromBlock: fromBlock, toBlock: toBlock);
    return client.events(filter).map((web3.FilterEvent result) {
      final decoded = event.decodeResults(result.topics!, result.data!);
      return Transfer._(decoded);
    });
  }
}

/// Emitted when the allowance of a [spender] for an [owner] is set by a call to [ERC20.approve]. [value] is the new allowance.
class Approval {
  Approval._(List<dynamic> response)
      : owner = (response[0] as web3.EthereumAddress),
        spender = (response[1] as web3.EthereumAddress),
        value = (response[2] as BigInt);

  /// The owner address.
  final web3.EthereumAddress owner;

  /// The spender address.
  final web3.EthereumAddress spender;

  /// Value.
  final BigInt value;
}

/// Emitted when [value] tokens are moved from one account ([from]) to another ([to]). Note that [value] may be zero.
class Transfer {
  Transfer._(List<dynamic> response)
      : from = (response[0] as web3.EthereumAddress),
        to = (response[1] as web3.EthereumAddress),
        value = (response[2] as BigInt);

  /// From address.
  final web3.EthereumAddress from;

  /// To address.
  final web3.EthereumAddress to;

  /// Value.
  final BigInt value;
}
