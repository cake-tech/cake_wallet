// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"inputs":[{"internalType":"contract IDecentralizedEURO","name":"deuro_","type":"address"},{"internalType":"uint24","name":"initialRatePPM","type":"uint24"},{"internalType":"address","name":"gateway_","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"ChangeNotReady","type":"error"},{"inputs":[],"name":"ModuleDisabled","type":"error"},{"inputs":[],"name":"NoPendingChange","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"interest","type":"uint256"}],"name":"InterestCollected","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint24","name":"newRate","type":"uint24"}],"name":"RateChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"who","type":"address"},{"indexed":false,"internalType":"uint24","name":"nextRate","type":"uint24"},{"indexed":false,"internalType":"uint40","name":"nextChange","type":"uint40"}],"name":"RateProposed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint192","name":"amount","type":"uint192"}],"name":"Saved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint192","name":"amount","type":"uint192"}],"name":"Withdrawn","type":"event"},{"inputs":[],"name":"GATEWAY","outputs":[{"internalType":"contract IFrontendGateway","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountOwner","type":"address"}],"name":"accruedInterest","outputs":[{"internalType":"uint192","name":"","type":"uint192"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"accountOwner","type":"address"},{"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"accruedInterest","outputs":[{"internalType":"uint192","name":"","type":"uint192"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint192","name":"targetAmount","type":"uint192"},{"internalType":"bytes32","name":"frontendCode","type":"bytes32"}],"name":"adjust","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint192","name":"targetAmount","type":"uint192"}],"name":"adjust","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"applyChange","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"uint192","name":"saved","type":"uint192"},{"internalType":"uint64","name":"ticks","type":"uint64"}],"internalType":"struct Savings.Account","name":"account","type":"tuple"},{"internalType":"uint64","name":"ticks","type":"uint64"}],"name":"calculateInterest","outputs":[{"internalType":"uint192","name":"","type":"uint192"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"currentRatePPM","outputs":[{"internalType":"uint24","name":"","type":"uint24"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"currentTicks","outputs":[{"internalType":"uint64","name":"","type":"uint64"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"deuro","outputs":[{"internalType":"contract IERC20","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"equity","outputs":[{"internalType":"contract IReserve","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"nextChange","outputs":[{"internalType":"uint40","name":"","type":"uint40"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"nextRatePPM","outputs":[{"internalType":"uint24","name":"","type":"uint24"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint24","name":"newRatePPM_","type":"uint24"},{"internalType":"address[]","name":"helpers","type":"address[]"}],"name":"proposeChange","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"refreshBalance","outputs":[{"internalType":"uint192","name":"","type":"uint192"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"refreshMyBalance","outputs":[{"internalType":"uint192","name":"","type":"uint192"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint192","name":"amount","type":"uint192"},{"internalType":"bytes32","name":"frontendCode","type":"bytes32"}],"name":"save","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint192","name":"amount","type":"uint192"}],"name":"save","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint192","name":"amount","type":"uint192"},{"internalType":"bytes32","name":"frontendCode","type":"bytes32"}],"name":"save","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint192","name":"amount","type":"uint192"}],"name":"save","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"savings","outputs":[{"internalType":"uint192","name":"saved","type":"uint192"},{"internalType":"uint64","name":"ticks","type":"uint64"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"ticks","outputs":[{"internalType":"uint64","name":"","type":"uint64"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"},{"internalType":"uint192","name":"amount","type":"uint192"}],"name":"withdraw","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"},{"internalType":"uint192","name":"amount","type":"uint192"},{"internalType":"bytes32","name":"frontendCode","type":"bytes32"}],"name":"withdraw","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"}]',
  'SavingsGateway',
);

class SavingsGateway extends _i1.GeneratedContract {
  SavingsGateway({
    required _i1.EthereumAddress address,
    required _i1.Web3Client client,
    int? chainId,
  }) : super(
    _i1.DeployedContract(
      _contractAbi,
      address,
    ),
    client,
    chainId,
  );

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i1.EthereumAddress> GATEWAY({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '338c5371'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i1.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> accruedInterest({
        required _i1.EthereumAddress accountOwner,
        _i1.BlockNum? atBlock,
      }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '77267ec3'));
    final params = [accountOwner];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> accruedInterest$2(
      ({_i1.EthereumAddress accountOwner, BigInt timestamp}) args, {
        _i1.BlockNum? atBlock,
      }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'a696399d'));
    final params = [
      args.accountOwner,
      args.timestamp,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> adjust(
      ({BigInt targetAmount, _i2.Uint8List frontendCode}) args, {
        required _i1.Credentials credentials,
        _i1.Transaction? transaction,
      }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '753ef93c'));
    final params = [
      args.targetAmount,
      args.frontendCode,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> calculateInterest(
      ({dynamic account, BigInt ticks}) args, {
        _i1.BlockNum? atBlock,
      }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '7915ce20'));
    final params = [
      args.account,
      args.ticks,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> currentRatePPM({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '06a7b376'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> currentTicks({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, 'b079f163'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i1.EthereumAddress> deuro({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '82b8eaf5'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i1.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i1.EthereumAddress> equity({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '91a0ac6a'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i1.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> nextChange({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, 'b6f83c17'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> nextRatePPM({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '2e4b20ab'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<_i2.Uint8List> refreshBalance(
      ({_i1.EthereumAddress owner}) args, {
        required _i1.Credentials credentials,
        _i1.Transaction? transaction,
      }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'b77cd1c7'));
    final params = [args.owner];
    return writeRaw(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<_i2.Uint8List> refreshMyBalance({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '85bd12d1'));
    final params = [];
    return writeRaw(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<_i2.Uint8List> save(
      ({BigInt amount, _i2.Uint8List frontendCode}) args, {
        required _i1.Credentials credentials,
        _i1.Transaction? transaction,
      }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '9e2363dc'));
    final params = [
      args.amount,
      args.frontendCode,
    ];
    return writeRaw(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<_i2.Uint8List> saveTo(
      ({
      _i1.EthereumAddress owner,
      BigInt amount,
      _i2.Uint8List frontendCode
      }) args, {
        required _i1.Credentials credentials,
        _i1.Transaction? transaction,
      }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'cbcf9676'));
    final params = [
      args.owner,
      args.amount,
      args.frontendCode,
    ];
    return writeRaw(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<Savings> savings({
        required _i1.EthereumAddress accountOwner,
        _i1.BlockNum? atBlock,
      }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '1f7cdd5f'));
    final params = [accountOwner];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return Savings(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<_i2.Uint8List> withdraw(
    ({
      _i1.EthereumAddress target,
      BigInt amount,
      _i2.Uint8List frontendCode
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, '829a0476'));
    final params = [
      args.target,
      args.amount,
      args.frontendCode,
    ];
    return writeRaw(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all InterestCollected events emitted by this contract.
  Stream<InterestCollected> interestCollectedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('InterestCollected');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return InterestCollected(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all RateChanged events emitted by this contract.
  Stream<RateChanged> rateChangedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('RateChanged');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return RateChanged(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all RateProposed events emitted by this contract.
  Stream<RateProposed> rateProposedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('RateProposed');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return RateProposed(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Saved events emitted by this contract.
  Stream<Saved> savedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Saved');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Saved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Withdrawn events emitted by this contract.
  Stream<Withdrawn> withdrawnEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Withdrawn');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Withdrawn(
        decoded,
        result,
      );
    });
  }
}

class Savings {
  Savings(List<dynamic> response)
      : saved = (response[0] as BigInt),
        ticks = (response[1] as BigInt);

  final BigInt saved;

  final BigInt ticks;
}

class InterestCollected {
  InterestCollected(
      List<dynamic> response,
      this.event,
      )   : account = (response[0] as _i1.EthereumAddress),
        interest = (response[1] as BigInt);

  final _i1.EthereumAddress account;

  final BigInt interest;

  final _i1.FilterEvent event;
}

class RateChanged {
  RateChanged(
      List<dynamic> response,
      this.event,
      ) : newRate = (response[0] as BigInt);

  final BigInt newRate;

  final _i1.FilterEvent event;
}

class RateProposed {
  RateProposed(
      List<dynamic> response,
      this.event,
      )   : who = (response[0] as _i1.EthereumAddress),
        nextRate = (response[1] as BigInt),
        nextChange = (response[2] as BigInt);

  final _i1.EthereumAddress who;

  final BigInt nextRate;

  final BigInt nextChange;

  final _i1.FilterEvent event;
}

class Saved {
  Saved(
      List<dynamic> response,
      this.event,
      )   : account = (response[0] as _i1.EthereumAddress),
        amount = (response[1] as BigInt);

  final _i1.EthereumAddress account;

  final BigInt amount;

  final _i1.FilterEvent event;
}

class Withdrawn {
  Withdrawn(
      List<dynamic> response,
      this.event,
      )   : account = (response[0] as _i1.EthereumAddress),
        amount = (response[1] as BigInt);

  final _i1.EthereumAddress account;

  final BigInt amount;

  final _i1.FilterEvent event;
}
