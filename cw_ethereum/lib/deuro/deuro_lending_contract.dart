// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"inputs":[{"internalType":"address","name":"_deuro","type":"address"},{"internalType":"address","name":"_leadrate","type":"address"},{"internalType":"address","name":"_roller","type":"address"},{"internalType":"address","name":"_factory","type":"address"},{"internalType":"address","name":"_gateway","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"ChallengeTimeTooShort","type":"error"},{"inputs":[],"name":"IncompatibleCollateral","type":"error"},{"inputs":[],"name":"InitPeriodTooShort","type":"error"},{"inputs":[],"name":"InsufficientCollateral","type":"error"},{"inputs":[],"name":"InvalidCollateralDecimals","type":"error"},{"inputs":[],"name":"InvalidPos","type":"error"},{"inputs":[],"name":"InvalidReservePPM","type":"error"},{"inputs":[],"name":"InvalidRiskPremium","type":"error"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"LeaveNoDust","type":"error"},{"inputs":[],"name":"UnexpectedPrice","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"position","type":"address"},{"indexed":false,"internalType":"uint256","name":"number","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"size","type":"uint256"}],"name":"ChallengeAverted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"challenger","type":"address"},{"indexed":true,"internalType":"address","name":"position","type":"address"},{"indexed":false,"internalType":"uint256","name":"size","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"number","type":"uint256"}],"name":"ChallengeStarted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"position","type":"address"},{"indexed":false,"internalType":"uint256","name":"number","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"bid","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"acquiredCollateral","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"challengeSize","type":"uint256"}],"name":"ChallengeSucceeded","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"pos","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"priceE36MinusDecimals","type":"uint256"}],"name":"ForcedSale","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"position","type":"address"},{"indexed":false,"internalType":"address","name":"original","type":"address"},{"indexed":false,"internalType":"address","name":"collateral","type":"address"}],"name":"PositionOpened","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"collateral","type":"address"},{"indexed":true,"internalType":"address","name":"beneficiary","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"PostponedReturn","type":"event"},{"inputs":[],"name":"CHALLENGER_REWARD","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"DEURO","outputs":[{"internalType":"contract IDecentralizedEURO","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"EXPIRED_PRICE_FACTOR","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"GATEWAY","outputs":[{"internalType":"contract IFrontendGateway","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"OPENING_FEE","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"RATE","outputs":[{"internalType":"contract ILeadrate","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ROLLER","outputs":[{"internalType":"contract PositionRoller","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint32","name":"_challengeNumber","type":"uint32"},{"internalType":"uint256","name":"size","type":"uint256"},{"internalType":"bool","name":"postponeCollateralReturn","type":"bool"}],"name":"bid","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IPosition","name":"pos","type":"address"},{"internalType":"uint256","name":"upToAmount","type":"uint256"}],"name":"buyExpiredCollateral","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_positionAddr","type":"address"},{"internalType":"uint256","name":"_collateralAmount","type":"uint256"},{"internalType":"uint256","name":"minimumPrice","type":"uint256"}],"name":"challenge","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"challenges","outputs":[{"internalType":"address","name":"challenger","type":"address"},{"internalType":"uint40","name":"start","type":"uint40"},{"internalType":"contract IPosition","name":"position","type":"address"},{"internalType":"uint256","name":"size","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"parent","type":"address"},{"internalType":"uint256","name":"_initialCollateral","type":"uint256"},{"internalType":"uint256","name":"_initialMint","type":"uint256"},{"internalType":"uint40","name":"expiration","type":"uint40"}],"name":"clone","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"parent","type":"address"},{"internalType":"uint256","name":"_initialCollateral","type":"uint256"},{"internalType":"uint256","name":"_initialMint","type":"uint256"},{"internalType":"uint40","name":"expiration","type":"uint40"},{"internalType":"bytes32","name":"frontendCode","type":"bytes32"}],"name":"clone","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"parent","type":"address"},{"internalType":"uint256","name":"_initialCollateral","type":"uint256"},{"internalType":"uint256","name":"_initialMint","type":"uint256"},{"internalType":"uint40","name":"expiration","type":"uint40"},{"internalType":"bytes32","name":"frontendCode","type":"bytes32"}],"name":"clone","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"parent","type":"address"},{"internalType":"uint256","name":"_initialCollateral","type":"uint256"},{"internalType":"uint256","name":"_initialMint","type":"uint256"},{"internalType":"uint40","name":"expiration","type":"uint40"}],"name":"clone","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IPosition","name":"pos","type":"address"}],"name":"expiredPurchasePrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"notifyInterestPaid","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_collateralAddress","type":"address"},{"internalType":"uint256","name":"_minCollateral","type":"uint256"},{"internalType":"uint256","name":"_initialCollateral","type":"uint256"},{"internalType":"uint256","name":"_mintingMaximum","type":"uint256"},{"internalType":"uint40","name":"_initPeriodSeconds","type":"uint40"},{"internalType":"uint40","name":"_expirationSeconds","type":"uint40"},{"internalType":"uint40","name":"_challengeSeconds","type":"uint40"},{"internalType":"uint24","name":"_riskPremium","type":"uint24"},{"internalType":"uint256","name":"_liqPrice","type":"uint256"},{"internalType":"uint24","name":"_reservePPM","type":"uint24"}],"name":"openPosition","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_collateralAddress","type":"address"},{"internalType":"uint256","name":"_minCollateral","type":"uint256"},{"internalType":"uint256","name":"_initialCollateral","type":"uint256"},{"internalType":"uint256","name":"_mintingMaximum","type":"uint256"},{"internalType":"uint40","name":"_initPeriodSeconds","type":"uint40"},{"internalType":"uint40","name":"_expirationSeconds","type":"uint40"},{"internalType":"uint40","name":"_challengeSeconds","type":"uint40"},{"internalType":"uint24","name":"_riskPremium","type":"uint24"},{"internalType":"uint256","name":"_liqPrice","type":"uint256"},{"internalType":"uint24","name":"_reservePPM","type":"uint24"},{"internalType":"bytes32","name":"_frontendCode","type":"bytes32"}],"name":"openPosition","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"collateral","type":"address"},{"internalType":"address","name":"owner","type":"address"}],"name":"pendingReturns","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint32","name":"challengeNumber","type":"uint32"}],"name":"price","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"collateral","type":"address"},{"internalType":"address","name":"target","type":"address"}],"name":"returnPostponedCollateral","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"}]',
  'MintingHubGateway',
);

class MintingHubGateway extends _i1.GeneratedContract {
  MintingHubGateway({
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
  Future<BigInt> CHALLENGER_REWARD({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'af5806b6'));
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
  Future<_i1.EthereumAddress> DEURO({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'dbe8a4c2'));
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
  Future<BigInt> EXPIRED_PRICE_FACTOR({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '0f2f8e86'));
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
  Future<_i1.EthereumAddress> GATEWAY({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
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
  Future<BigInt> OPENING_FEE({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '2bf78dd8'));
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
  Future<_i1.EthereumAddress> RATE({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '664e9704'));
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
  Future<_i1.EthereumAddress> ROLLER({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'f09e9e3a'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i1.EthereumAddress);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> bid(
    ({
      BigInt challengeNumber,
      BigInt size,
      bool postponeCollateralReturn
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '7eb81bb3'));
    final params = [
      args.challengeNumber,
      args.size,
      args.postponeCollateralReturn,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> buyExpiredCollateral(
    ({_i1.EthereumAddress pos, BigInt upToAmount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '25e28124'));
    final params = [
      args.pos,
      args.upToAmount,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> challenge(
    ({
      _i1.EthereumAddress positionAddr,
      BigInt collateralAmount,
      BigInt minimumPrice
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, 'c14a9f05'));
    final params = [
      args.positionAddr,
      args.collateralAmount,
      args.minimumPrice,
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
  Future<Challenges> challenges(
    ({BigInt $param8}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '8f1d3776'));
    final params = [args.$param8];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return Challenges(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<_i2.Uint8List> clone(
    ({
      _i1.EthereumAddress parent,
      BigInt initialCollateral,
      BigInt initialMint,
      BigInt expiration,
      _i2.Uint8List frontendCode
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '3bb84940'));
    final params = [
      args.parent,
      args.initialCollateral,
      args.initialMint,
      args.expiration,
      args.frontendCode,
    ];
    return
      writeRaw(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<_i2.Uint8List> clone$2(
    ({
      _i1.EthereumAddress owner,
      _i1.EthereumAddress parent,
      BigInt initialCollateral,
      BigInt initialMint,
      BigInt expiration,
      _i2.Uint8List frontendCode
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '93a83a24'));
    final params = [
      args.owner,
      args.parent,
      args.initialCollateral,
      args.initialMint,
      args.expiration,
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
  Future<BigInt> expiredPurchasePrice(
    ({_i1.EthereumAddress pos}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, 'e6ac5ea4'));
    final params = [args.pos];
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
  Future<String> notifyInterestPaid(
    ({BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '7d0ea02d'));
    final params = [args.amount];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> openPosition(
    ({
      _i1.EthereumAddress collateralAddress,
      BigInt minCollateral,
      BigInt initialCollateral,
      BigInt mintingMaximum,
      BigInt initPeriodSeconds,
      BigInt expirationSeconds,
      BigInt challengeSeconds,
      BigInt riskPremium,
      BigInt liqPrice,
      BigInt reservePPM
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, '35a4b349'));
    final params = [
      args.collateralAddress,
      args.minCollateral,
      args.initialCollateral,
      args.mintingMaximum,
      args.initPeriodSeconds,
      args.expirationSeconds,
      args.challengeSeconds,
      args.riskPremium,
      args.liqPrice,
      args.reservePPM,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> openPosition$2(
    ({
      _i1.EthereumAddress collateralAddress,
      BigInt minCollateral,
      BigInt initialCollateral,
      BigInt mintingMaximum,
      BigInt initPeriodSeconds,
      BigInt expirationSeconds,
      BigInt challengeSeconds,
      BigInt riskPremium,
      BigInt liqPrice,
      BigInt reservePPM,
      _i2.Uint8List frontendCode
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, '4cb95914'));
    final params = [
      args.collateralAddress,
      args.minCollateral,
      args.initialCollateral,
      args.mintingMaximum,
      args.initPeriodSeconds,
      args.expirationSeconds,
      args.challengeSeconds,
      args.riskPremium,
      args.liqPrice,
      args.reservePPM,
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
  Future<BigInt> pendingReturns(
    ({_i1.EthereumAddress collateral, _i1.EthereumAddress owner}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '643745fb'));
    final params = [
      args.collateral,
      args.owner,
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
  Future<BigInt> price(
    ({BigInt challengeNumber}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, 'e6ca1df2'));
    final params = [args.challengeNumber];
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
  Future<String> returnPostponedCollateral(
    ({_i1.EthereumAddress collateral, _i1.EthereumAddress target}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, 'e85cde6f'));
    final params = [
      args.collateral,
      args.target,
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
  Future<bool> supportsInterface(
    ({_i2.Uint8List interfaceId}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '01ffc9a7'));
    final params = [args.interfaceId];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// Returns a live stream of all ChallengeAverted events emitted by this contract.
  Stream<ChallengeAverted> challengeAvertedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ChallengeAverted');
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
      return ChallengeAverted(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ChallengeStarted events emitted by this contract.
  Stream<ChallengeStarted> challengeStartedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ChallengeStarted');
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
      return ChallengeStarted(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ChallengeSucceeded events emitted by this contract.
  Stream<ChallengeSucceeded> challengeSucceededEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ChallengeSucceeded');
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
      return ChallengeSucceeded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ForcedSale events emitted by this contract.
  Stream<ForcedSale> forcedSaleEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ForcedSale');
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
      return ForcedSale(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all PositionOpened events emitted by this contract.
  Stream<PositionOpened> positionOpenedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('PositionOpened');
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
      return PositionOpened(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all PostponedReturn events emitted by this contract.
  Stream<PostponedReturn> postponedReturnEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('PostponedReturn');
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
      return PostponedReturn(
        decoded,
        result,
      );
    });
  }
}

class Challenges {
  Challenges(List<dynamic> response)
      : challenger = (response[0] as _i1.EthereumAddress),
        start = (response[1] as BigInt),
        position = (response[2] as _i1.EthereumAddress),
        size = (response[3] as BigInt);

  final _i1.EthereumAddress challenger;

  final BigInt start;

  final _i1.EthereumAddress position;

  final BigInt size;
}

class ChallengeAverted {
  ChallengeAverted(
    List<dynamic> response,
    this.event,
  )   : position = (response[0] as _i1.EthereumAddress),
        number = (response[1] as BigInt),
        size = (response[2] as BigInt);

  final _i1.EthereumAddress position;

  final BigInt number;

  final BigInt size;

  final _i1.FilterEvent event;
}

class ChallengeStarted {
  ChallengeStarted(
    List<dynamic> response,
    this.event,
  )   : challenger = (response[0] as _i1.EthereumAddress),
        position = (response[1] as _i1.EthereumAddress),
        size = (response[2] as BigInt),
        number = (response[3] as BigInt);

  final _i1.EthereumAddress challenger;

  final _i1.EthereumAddress position;

  final BigInt size;

  final BigInt number;

  final _i1.FilterEvent event;
}

class ChallengeSucceeded {
  ChallengeSucceeded(
    List<dynamic> response,
    this.event,
  )   : position = (response[0] as _i1.EthereumAddress),
        number = (response[1] as BigInt),
        bid = (response[2] as BigInt),
        acquiredCollateral = (response[3] as BigInt),
        challengeSize = (response[4] as BigInt);

  final _i1.EthereumAddress position;

  final BigInt number;

  final BigInt bid;

  final BigInt acquiredCollateral;

  final BigInt challengeSize;

  final _i1.FilterEvent event;
}

class ForcedSale {
  ForcedSale(
    List<dynamic> response,
    this.event,
  )   : pos = (response[0] as _i1.EthereumAddress),
        amount = (response[1] as BigInt),
        priceE36MinusDecimals = (response[2] as BigInt);

  final _i1.EthereumAddress pos;

  final BigInt amount;

  final BigInt priceE36MinusDecimals;

  final _i1.FilterEvent event;
}

class PositionOpened {
  PositionOpened(
    List<dynamic> response,
    this.event,
  )   : owner = (response[0] as _i1.EthereumAddress),
        position = (response[1] as _i1.EthereumAddress),
        original = (response[2] as _i1.EthereumAddress),
        collateral = (response[3] as _i1.EthereumAddress);

  final _i1.EthereumAddress owner;

  final _i1.EthereumAddress position;

  final _i1.EthereumAddress original;

  final _i1.EthereumAddress collateral;

  final _i1.FilterEvent event;
}

class PostponedReturn {
  PostponedReturn(
    List<dynamic> response,
    this.event,
  )   : collateral = (response[0] as _i1.EthereumAddress),
        beneficiary = (response[1] as _i1.EthereumAddress),
        amount = (response[2] as BigInt);

  final _i1.EthereumAddress collateral;

  final _i1.EthereumAddress beneficiary;

  final BigInt amount;

  final _i1.FilterEvent event;
}
