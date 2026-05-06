import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_starknet/pending_starknet_transaction.dart';
import 'package:cw_starknet/starknet_balance.dart';
import 'package:cw_starknet/starknet_client.dart';
import 'package:cw_starknet/starknet_rust.dart';
import 'package:cw_starknet/starknet_ur.dart';
import 'package:cw_starknet/starknet_wallet.dart';
import 'package:cw_starknet/starknet_wallet_creation_credentials.dart';
import 'package:cw_starknet/starknet_wallet_service.dart';
import 'package:cw_starknet/src/rust/api/starknet.dart' as rust_api;
import 'package:hex/hex.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class StarknetIntegrationHarness {
  StarknetIntegrationHarness()
      : rootDirectory =
            Directory.systemTemp.createTempSync('cake_starknet_it_');

  final Directory rootDirectory;
  int _walletIndex = 0;
  final List<StarknetWallet> _openWallets = <StarknetWallet>[];

  Future<void> setUp() async {
    PathProviderPlatform.instance =
        _HarnessPathProviderPlatform(rootDirectory.path);
    await initDb();
    CakeHive.init(rootDirectory.path);
  }

  Future<void> tearDown() async {
    for (final wallet in _openWallets) {
      await wallet.close();
    }
    _openWallets.clear();
    await CakeHive.close();
    await db?.close();
    db = null;
    if (rootDirectory.existsSync()) {
      await rootDirectory.delete(recursive: true);
    }
  }

  Future<WalletInfo> createWalletInfo(
    String prefix, {
    HardwareWalletType? hardwareWalletType,
  }) async {
    final name = '${prefix}_${++_walletIndex}';
    final dirPath =
        await pathForWalletDir(name: name, type: WalletType.starknet);
    final path = await pathForWallet(name: name, type: WalletType.starknet);
    await Directory(dirPath).create(recursive: true);
    final walletInfo = WalletInfo.external(
      id: WalletBase.idFor(name, WalletType.starknet),
      name: name,
      type: WalletType.starknet,
      isRecovery: false,
      restoreHeight: 0,
      date: DateTime.utc(2026, 4, 15),
      dirPath: dirPath,
      path: path,
      address: '',
      hardwareWalletType: hardwareWalletType,
    );
    await walletInfo.save();
    return walletInfo;
  }

  Future<rust_api.DerivedAccountData> deriveAccount({
    String? mnemonic,
    String? passphrase,
    String? privateKeyHex,
    String accountClassHashHex =
        StarknetWalletBase.openZeppelinAccountClassHashHex,
  }) async {
    await ensureStarknetRustInitialized();
    final response = await rust_api.deriveAccount(
      mnemonic: mnemonic,
      passphrase: passphrase,
      privateKeyHex: privateKeyHex,
      accountClassHashHex: accountClassHashHex,
    );
    return unwrapDerivedAccountDataResponse(response);
  }

  Future<StarknetWallet> createWallet({
    required FakeStarknetWalletClient client,
    required String mnemonic,
    String password = '123456',
  }) async {
    final walletInfo = await createWalletInfo('starknet_create');
    final service = StarknetWalletService(true, clientFactory: () => client);
    final credentials = StarknetNewWalletCredentials(
      name: walletInfo.name,
      walletInfo: walletInfo,
      password: password,
      mnemonic: mnemonic,
    );
    final wallet = await service.create(credentials);
    await connectAndSync(wallet);
    return _trackWallet(wallet);
  }

  Future<StarknetWallet> restoreWalletFromPrivateKey({
    required FakeStarknetWalletClient client,
    required String privateKeyHex,
    String password = '123456',
  }) async {
    final walletInfo = await createWalletInfo('starknet_software');
    final service = StarknetWalletService(true, clientFactory: () => client);
    final credentials = StarknetRestoreWalletFromPrivateKey(
      name: walletInfo.name,
      walletInfo: walletInfo,
      password: password,
      privateKey: privateKeyHex,
    );
    final wallet = await service.restoreFromKeys(credentials);
    await connectAndSync(wallet);
    return _trackWallet(wallet);
  }

  Future<StarknetWallet> restoreWalletFromPublicKey({
    required FakeStarknetWalletClient client,
    required String publicKeyHex,
    String password = '123456',
    String? accountClassHashHex,
    HardwareWalletType hardwareWalletType = HardwareWalletType.ledger,
  }) async {
    final walletInfo = await createWalletInfo(
      'starknet_airgapped',
      hardwareWalletType: hardwareWalletType,
    );
    final service = StarknetWalletService(true, clientFactory: () => client);
    final credentials = StarknetRestoreWalletFromPrivateKey.publicKey(
      name: walletInfo.name,
      walletInfo: walletInfo,
      password: password,
      publicKey: publicKeyHex,
      accountClassHashHex: accountClassHashHex,
    );
    final wallet = await service.restoreFromKeys(credentials);
    await connectAndSync(wallet);
    return _trackWallet(wallet);
  }

  Future<StarknetWallet> restoreLedgerWallet({
    required FakeStarknetWalletClient client,
    required HardwareAccountData accountData,
    required String accountClassHashHex,
    HardwareWalletService? hardwareWalletService,
    String password = '123456',
  }) async {
    final walletInfo = await createWalletInfo(
      'starknet_ledger',
      hardwareWalletType: HardwareWalletType.ledger,
    );
    final service = StarknetWalletService(true, clientFactory: () => client);
    final credentials = StarknetRestoreWalletFromHardware(
      name: walletInfo.name,
      walletInfo: walletInfo,
      password: password,
      hwAccountData: accountData,
      accountClassHashHex: accountClassHashHex,
    );
    credentials.hardwareWalletType = HardwareWalletType.ledger;
    final wallet =
        await service.restoreFromHardwareWallet(credentials) as StarknetWallet;
    if (hardwareWalletService != null) {
      wallet.setHardwareWalletService(hardwareWalletService);
    }
    await connectAndSync(wallet);
    return _trackWallet(wallet);
  }

  Future<void> connectAndSync(StarknetWallet wallet) async {
    await wallet.connectToNode(
      node: Node(
        uri: 'starknet.integration.test',
        type: WalletType.starknet,
      ),
    );
    await wallet.startSync();
  }

  StarknetWallet _trackWallet(StarknetWallet wallet) {
    _openWallets.add(wallet);
    return wallet;
  }

  Future<String> signMessageRequestUr({
    required String privateKeyHex,
    required String requestUr,
  }) async {
    await ensureStarknetRustInitialized();
    final payload = decodeStarknetMessageSignRequestUr(requestUr);
    final response = await rust_api.signMessageHash(
      privateKeyHex: privateKeyHex,
      messageHashHex: payload.messageHashHex,
    );
    final signature = unwrapSignatureResponse(response);
    return encodeStarknetMessageSignResponseUr(
      StarknetSignatureResponseUrPayload(
        messageHashHex: payload.messageHashHex,
        signature: StarknetUrSignature(
          rHex: signature.rHex,
          sHex: signature.sHex,
        ),
      ),
    );
  }

  Future<String> signTypedDataRequestUr({
    required String privateKeyHex,
    required String requestUr,
  }) async {
    await ensureStarknetRustInitialized();
    final payload = decodeStarknetTypedDataSignRequestUr(requestUr);
    final response = await rust_api.signMessageHash(
      privateKeyHex: privateKeyHex,
      messageHashHex: payload.typedDataHashHex,
    );
    final signature = unwrapSignatureResponse(response);
    return encodeStarknetTypedDataSignResponseUr(
      StarknetSignatureResponseUrPayload(
        messageHashHex: payload.typedDataHashHex,
        signature: StarknetUrSignature(
          rHex: signature.rHex,
          sHex: signature.sHex,
        ),
      ),
    );
  }

  Future<String> signTransactionRequestUr({
    required String privateKeyHex,
    required String requestUr,
  }) async {
    await ensureStarknetRustInitialized();
    final payload = decodeStarknetSignRequestUr(requestUr);
    final invokeResponse = await rust_api.signMessageHash(
      privateKeyHex: privateKeyHex,
      messageHashHex: payload.invokeTransactionHashHex,
    );
    final invokeSignature = unwrapSignatureResponse(invokeResponse);

    StarknetUrSignature? deploySignature;
    if (payload.deployAccountTransactionHashHex != null) {
      final deployResponse = await rust_api.signMessageHash(
        privateKeyHex: privateKeyHex,
        messageHashHex: payload.deployAccountTransactionHashHex!,
      );
      final decodedDeploySignature = unwrapSignatureResponse(deployResponse);
      deploySignature = StarknetUrSignature(
        rHex: decodedDeploySignature.rHex,
        sHex: decodedDeploySignature.sHex,
      );
    }

    return encodeStarknetSignResponseUr(
      StarknetSignResponseUrPayload(
        planJson: payload.planJson,
        invokeTransactionHashHex: payload.invokeTransactionHashHex,
        invokeSignature: StarknetUrSignature(
          rHex: invokeSignature.rHex,
          sHex: invokeSignature.sHex,
        ),
        deployAccountTransactionHashHex:
            payload.deployAccountTransactionHashHex,
        deploySignature: deploySignature,
      ),
    );
  }
}

class FakeStarknetWalletClient extends StarknetWalletClient {
  FakeStarknetWalletClient({
    Map<String, BigInt>? initialBalancesByToken,
    Map<String, rust_api.StarknetTokenMetadata>? tokenMetadataByAddress,
    bool initiallyDeployed = true,
    String defaultFeeWei = '10000000000000000',
  })  : _balancesByToken = {
          StarknetTokenAddresses.strk.toLowerCase(): BigInt.zero,
          ...?initialBalancesByToken
              ?.map((key, value) => MapEntry(key.toLowerCase(), value)),
        },
        _tokenMetadataByAddress = {
          StarknetTokenAddresses.strk.toLowerCase():
              const rust_api.StarknetTokenMetadata(
            tokenAddressHex: StarknetTokenAddresses.strk,
            name: 'Starknet Token',
            symbol: 'STRK',
            decimals: 18,
          ),
          StarknetTokenAddresses.eth.toLowerCase():
              const rust_api.StarknetTokenMetadata(
            tokenAddressHex: StarknetTokenAddresses.eth,
            name: 'Ether',
            symbol: 'ETH',
            decimals: 18,
          ),
          ...?tokenMetadataByAddress
              ?.map((key, value) => MapEntry(key.toLowerCase(), value)),
        },
        _accountDeployed = initiallyDeployed,
        _defaultFeeWei = defaultFeeWei;

  final Map<String, BigInt> _balancesByToken;
  final Map<String, rust_api.StarknetTokenMetadata> _tokenMetadataByAddress;
  final List<StarknetTransferEvent> _events = <StarknetTransferEvent>[];
  final Map<String, _FakeExecutionPlan> _plansByJson =
      <String, _FakeExecutionPlan>{};
  final Map<String, StarknetTransactionDetails> _transactionDetailsByHash =
      <String, StarknetTransactionDetails>{};
  final String _defaultFeeWei;

  bool _connected = false;
  bool _accountDeployed;
  String? _accountAddressHex;
  String? _publicKeyHex;
  String? _privateKeyHex;
  String? _hardwareDerivationPath;
  HardwareWalletService? _hardwareWalletService;
  int _nextHashValue = 1;
  int _nextBlockNumber = 1000;

  String? lastCommittedTransactionHash;
  bool lastExecutionRequiredDeployment = false;
  int hardwareCommitCount = 0;

  @override
  bool connect(Node node) {
    _connected = true;
    return true;
  }

  @override
  void stop() {
    _connected = false;
  }

  @override
  void setupAccount({
    required String privateKeyHex,
    required String addressHex,
  }) {
    _privateKeyHex = privateKeyHex;
    _accountAddressHex = addressHex;
  }

  @override
  void setupHardwareAccount({
    required String addressHex,
    required String publicKeyHex,
    required String derivationPath,
    HardwareWalletService? service,
  }) {
    _accountAddressHex = addressHex;
    _publicKeyHex = publicKeyHex;
    _hardwareDerivationPath = derivationPath;
    _hardwareWalletService = service;
  }

  @override
  void setHardwareWalletService(HardwareWalletService service) {
    _hardwareWalletService = service;
  }

  @override
  void setupExternalSignerAccount({
    required String addressHex,
    required String publicKeyHex,
  }) {
    _accountAddressHex = addressHex;
    _publicKeyHex = publicKeyHex;
    _privateKeyHex = null;
    _hardwareDerivationPath = null;
  }

  @override
  Future<StarknetBalance> getTokenBalance({
    required String accountAddressHex,
    required String tokenAddressHex,
    required int decimals,
  }) async {
    return StarknetBalance(
      _balancesByToken[tokenAddressHex.toLowerCase()] ?? BigInt.zero,
      decimals: decimals,
    );
  }

  @override
  Future<rust_api.StarknetTokenMetadata> getTokenMetadata(
      String tokenAddressHex) async {
    return _tokenMetadataByAddress[tokenAddressHex.toLowerCase()] ??
        rust_api.StarknetTokenMetadata(
          tokenAddressHex: tokenAddressHex.toLowerCase(),
          name: 'Token',
          symbol: 'TKN',
          decimals: 18,
        );
  }

  @override
  Future<rust_api.StarknetFeeQuote> estimateExecuteFee({
    required String accountAddressHex,
    required String accountClassHashHex,
    required List<StarknetExecutionCall> calls,
    required int feePriorityRaw,
  }) async =>
      _buildFeeQuote();

  @override
  Future<rust_api.StarknetFeeQuote> estimateHardwareExecuteFee({
    required String accountAddressHex,
    required String publicKeyHex,
    required String accountClassHashHex,
    required List<StarknetExecutionCall> calls,
    required int feePriorityRaw,
  }) async =>
      _buildFeeQuote();

  @override
  Future<PendingStarknetTransaction> createTransaction({
    required List<StarknetExecutionCall> calls,
    required String amountWei,
    required int amountDecimals,
    required String amountSymbol,
    required String destinationAddress,
    required String accountClassHashHex,
    required String feeWei,
    required int feePriorityRaw,
    Future<void> Function(String txHash)? onCommitted,
  }) async {
    return PendingStarknetTransaction(
      amountWei: amountWei,
      amountDecimals: amountDecimals,
      amountSymbol: amountSymbol,
      destinationAddress: destinationAddress,
      feeWei: feeWei,
      transactionHash: _nextHashHex(),
      sendTransaction: () async => _commitExecution(
        calls: calls,
        feeWei: feeWei,
      ),
      onCommitted: onCommitted,
    );
  }

  @override
  Future<PendingStarknetTransaction> createHardwareTransaction({
    required List<StarknetExecutionCall> calls,
    required String amountWei,
    required int amountDecimals,
    required String amountSymbol,
    required String destinationAddress,
    required String accountClassHashHex,
    required String feeWei,
    required int feePriorityRaw,
    Future<void> Function(String txHash)? onCommitted,
  }) async {
    return PendingStarknetTransaction(
      amountWei: amountWei,
      amountDecimals: amountDecimals,
      amountSymbol: amountSymbol,
      destinationAddress: destinationAddress,
      feeWei: feeWei,
      transactionHash: _nextHashHex(),
      sendTransaction: () async {
        final service = _hardwareWalletService;
        if (service == null || _hardwareDerivationPath == null) {
          throw Exception('Missing fake hardware signer');
        }

        hardwareCommitCount++;
        await service.signMessage(
          message: _hashBytes(_nextHashHex()),
          derivationPath: _hardwareDerivationPath,
        );

        return _commitExecution(
          calls: calls,
          feeWei: feeWei,
        );
      },
      onCommitted: onCommitted,
    );
  }

  @override
  Future<PendingStarknetTransaction> createOfflineTransaction({
    required List<StarknetExecutionCall> calls,
    required String amountWei,
    required int amountDecimals,
    required String amountSymbol,
    required String destinationAddress,
    required String accountClassHashHex,
    required String feeWei,
    required int feePriorityRaw,
    String? summaryActionName,
    String? summaryTokenAddress,
    Map<String, dynamic>? summaryAdditionalInfo,
    bool preferSummary = false,
  }) async {
    final requestUr = await buildUnsignedTransactionUr(
      calls: calls,
      amountWei: amountWei,
      amountDecimals: amountDecimals,
      amountSymbol: amountSymbol,
      destinationAddress: destinationAddress,
      accountClassHashHex: accountClassHashHex,
      feeWei: feeWei,
      feePriorityRaw: feePriorityRaw,
      summaryActionName: summaryActionName,
      summaryTokenAddress: summaryTokenAddress,
      summaryAdditionalInfo: summaryAdditionalInfo,
      preferSummary: preferSummary,
    );
    final requestPayload = decodeStarknetSignRequestUr(requestUr.values.first);

    return PendingStarknetTransaction(
      amountWei: amountWei,
      amountDecimals: amountDecimals,
      amountSymbol: amountSymbol,
      destinationAddress: destinationAddress,
      feeWei: feeWei,
      transactionHash: requestPayload.invokeTransactionHashHex,
      sendTransaction: () async => throw UnsupportedError(
        'Offline transaction requires commitUR()',
      ),
      buildUnsignedTransactionUr: () async => requestUr,
    );
  }

  @override
  Future<Map<String, String>> buildUnsignedTransactionUr({
    required List<StarknetExecutionCall> calls,
    required String amountWei,
    required int amountDecimals,
    required String amountSymbol,
    required String destinationAddress,
    required String accountClassHashHex,
    required String feeWei,
    required int feePriorityRaw,
    String? summaryActionName,
    String? summaryTokenAddress,
    Map<String, dynamic>? summaryAdditionalInfo,
    bool preferSummary = false,
  }) async {
    final invokeHashHex = _nextHashHex();
    final deployHashHex = !_accountDeployed ? _nextHashHex() : null;
    final planJson = jsonEncode({
      'invokeHashHex': invokeHashHex,
      'deployHashHex': deployHashHex,
      'callCount': calls.length,
    });

    _plansByJson[planJson] = _FakeExecutionPlan(
      calls: calls,
      feeWei: feeWei,
      invokeHashHex: invokeHashHex,
      deployHashHex: deployHashHex,
    );

    final requestPayload = StarknetSignRequestUrPayload(
      planJson: planJson,
      accountAddressHex: _requireAccountAddress(),
      publicKeyHex: _requirePublicKey(),
      accountClassHashHex: accountClassHashHex,
      invokeTransactionHashHex: invokeHashHex,
      deployAccountTransactionHashHex: deployHashHex,
      amountWei: amountWei,
      amountDecimals: amountDecimals,
      amountSymbol: amountSymbol,
      destinationAddress: destinationAddress,
      feeWei: feeWei,
      summaryActionName: summaryActionName,
      summaryTokenAddress: summaryTokenAddress,
      summaryAdditionalInfo: summaryAdditionalInfo,
      preferSummary: preferSummary,
    );

    return encodeStarknetSignRequestUrMap(requestPayload);
  }

  @override
  Future<List<StarknetTransferEvent>> fetchTransferEvents({
    required String accountAddressHex,
    required String tokenAddressHex,
    required String tokenSymbol,
    int? fromBlock,
  }) async {
    return _events.where((event) {
      final matchesToken =
          event.tokenAddressHex.toLowerCase() == tokenAddressHex.toLowerCase();
      final matchesBlock =
          fromBlock == null || (event.blockNumber ?? 0) >= fromBlock;
      return matchesToken && matchesBlock;
    }).toList();
  }

  @override
  Future<String> getTypedDataHash({
    required String accountAddressHex,
    required String typedDataJson,
  }) async {
    return _feltHashHex('typed-data:$accountAddressHex:$typedDataJson');
  }

  @override
  Future<List<String>> signTypedData({
    required String accountAddressHex,
    required String typedDataJson,
  }) async {
    await ensureStarknetRustInitialized();
    final privateKeyHex = _privateKeyHex;
    if (privateKeyHex == null) {
      throw Exception('Private key unavailable for fake typed-data signing');
    }

    final response = await rust_api.signMessageHash(
      privateKeyHex: privateKeyHex,
      messageHashHex: await getTypedDataHash(
        accountAddressHex: accountAddressHex,
        typedDataJson: typedDataJson,
      ),
    );
    final signature = unwrapSignatureResponse(response);
    return [signature.rHex, signature.sHex];
  }

  @override
  Future<int?> getBlockNumber() async => _connected ? _nextBlockNumber : null;

  @override
  Future<StarknetTransactionDetails?> getTransactionDetails({
    required String transactionHashHex,
  }) async =>
      _transactionDetailsByHash[transactionHashHex];

  @override
  Future<String> submitSignedTransactionUr(String urPayload) async {
    final responsePayload = decodeStarknetSignResponseUr(urPayload);
    final plan = _plansByJson[responsePayload.planJson];
    if (plan == null) {
      throw Exception('Unknown fake execution plan');
    }

    return _commitExecution(
      calls: plan.calls,
      feeWei: plan.feeWei,
      transactionHash: responsePayload.invokeTransactionHashHex,
      deploymentHash: responsePayload.deployAccountTransactionHashHex,
    );
  }

  rust_api.StarknetFeeQuote _buildFeeQuote() => rust_api.StarknetFeeQuote(
        overallFeeWei: _defaultFeeWei,
        executionFeeWei: _defaultFeeWei,
        deployAccountFeeWei: !_accountDeployed ? _defaultFeeWei : null,
        accountDeploymentRequired: !_accountDeployed,
      );

  Future<String> _commitExecution({
    required List<StarknetExecutionCall> calls,
    required String feeWei,
    String? transactionHash,
    String? deploymentHash,
  }) async {
    final txHash = transactionHash ?? _nextHashHex();
    lastCommittedTransactionHash = txHash;
    lastExecutionRequiredDeployment =
        !_accountDeployed || deploymentHash != null;
    final deploymentRequired = lastExecutionRequiredDeployment;
    _accountDeployed = true;

    final accountAddress = _requireAccountAddress();
    final fee = BigInt.tryParse(feeWei) ?? BigInt.zero;
    _balancesByToken[StarknetTokenAddresses.strk.toLowerCase()] =
        (_balancesByToken[StarknetTokenAddresses.strk.toLowerCase()] ??
                BigInt.zero) -
            fee;

    for (var index = 0; index < calls.length; index++) {
      final call = calls[index];
      final entrypoint = call.entrypoint.toLowerCase();
      final tokenAddress = call.contractAddressHex.toLowerCase();
      if (entrypoint == 'transfer' && call.calldataHex.length >= 3) {
        final recipient = call.calldataHex[0];
        final amount =
            _uint256FromWords(call.calldataHex[1], call.calldataHex[2]);
        _balancesByToken[tokenAddress] =
            (_balancesByToken[tokenAddress] ?? BigInt.zero) - amount;
        final metadata = _tokenMetadataByAddress[tokenAddress] ??
            rust_api.StarknetTokenMetadata(
              tokenAddressHex: tokenAddress,
              name: 'Token',
              symbol: 'TKN',
              decimals: 18,
            );
        _events.add(
          StarknetTransferEvent(
            transactionHash: txHash,
            eventId: '$txHash:$index',
            eventIndex: index,
            blockNumber: _nextBlockNumber,
            from: accountAddress,
            to: recipient,
            amountWei: amount.toString(),
            isOutgoing: true,
            tokenSymbol: metadata.symbol,
            tokenAddressHex: tokenAddress,
            blockTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            txFeeWei: feeWei,
          ),
        );
      }
    }

    _transactionDetailsByHash[txHash] = StarknetTransactionDetails(
      transactionHash: txHash,
      transactionType: deploymentRequired ? 'DEPLOY_ACCOUNT' : 'INVOKE',
      isPending: false,
      blockNumber: _nextBlockNumber,
      blockTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      actualFeeWei: feeWei,
      actionName: _inferActionName(calls),
      callCount: calls.length,
      primaryContractAddressHex:
          calls.isEmpty ? null : calls.first.contractAddressHex,
      primaryEntrypoint: calls.isEmpty ? null : calls.first.entrypoint,
      senderAddressHex: accountAddress,
      finalityStatus: 'ACCEPTED_ON_L2',
      executionStatus: 'SUCCEEDED',
      revertReason: null,
      accountDeploymentRequired: deploymentRequired,
      l1GasMaxAmount: null,
      l1GasMaxPriceWei: null,
      l2GasMaxAmount: null,
      l2GasMaxPriceWei: null,
      l1DataGasMaxAmount: null,
      l1DataGasMaxPriceWei: null,
      tip: null,
    );

    _nextBlockNumber++;
    return txHash;
  }

  String _inferActionName(List<StarknetExecutionCall> calls) {
    if (calls.isEmpty) {
      return 'contract_call';
    }

    final entrypoints = calls
        .map((call) => call.entrypoint.toLowerCase())
        .toList(growable: false);
    if (entrypoints.every((entrypoint) => entrypoint == 'transfer')) {
      return 'transfer';
    }

    if (entrypoints.every((entrypoint) => entrypoint == 'approve')) {
      return 'approval';
    }

    if (entrypoints.any((entrypoint) => entrypoint.contains('swap'))) {
      return 'swap';
    }

    return calls.length > 1 ? 'multicall' : entrypoints.first;
  }

  String _requireAccountAddress() =>
      _accountAddressHex ??
      (throw Exception('Fake account address not configured'));

  String _requirePublicKey() =>
      _publicKeyHex ?? (throw Exception('Fake public key not configured'));

  BigInt _uint256FromWords(String lowHex, String highHex) {
    final low = _feltToBigInt(lowHex);
    final high = _feltToBigInt(highHex);
    return low + (high << 128);
  }

  BigInt _feltToBigInt(String value) {
    final normalized = value.toLowerCase();
    if (normalized.startsWith('0x')) {
      return BigInt.parse(normalized.substring(2), radix: 16);
    }
    return BigInt.parse(normalized);
  }

  String _feltHashHex(String input) {
    final hashedValue = BigInt.parse(
      crypto.sha256.convert(utf8.encode(input)).toString(),
      radix: 16,
    );
    return '0x${(hashedValue % _starknetFieldPrime).toRadixString(16)}';
  }

  String _nextHashHex() =>
      '0x${(_nextHashValue++).toRadixString(16).padLeft(64, '0')}';

  Uint8List _hashBytes(String hashHex) {
    final normalized =
        hashHex.startsWith('0x') ? hashHex.substring(2) : hashHex;
    return Uint8List.fromList(HEX.decode(normalized.padLeft(64, '0')));
  }
}

class TestHardwareWalletService extends HardwareWalletService {
  TestHardwareWalletService({
    required this.privateKeyHex,
    required this.accountData,
  });

  final String privateKeyHex;
  final HardwareAccountData accountData;
  int signCount = 0;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts(
          {int index = 0, int limit = 5}) async =>
      [accountData];

  @override
  Future<Uint8List> signMessage({
    required Uint8List message,
    String? derivationPath,
  }) async {
    signCount++;
    await ensureStarknetRustInitialized();
    final messageHashHex = '0x${HEX.encode(message)}';
    final response = await rust_api.signMessageHash(
      privateKeyHex: privateKeyHex,
      messageHashHex: messageHashHex,
    );
    final signature = unwrapSignatureResponse(response);
    return Uint8List.fromList(
      [
        ...HEX.decode(signature.rHex.replaceFirst('0x', '').padLeft(64, '0')),
        ...HEX.decode(signature.sHex.replaceFirst('0x', '').padLeft(64, '0')),
      ],
    );
  }
}

class _FakeExecutionPlan {
  const _FakeExecutionPlan({
    required this.calls,
    required this.feeWei,
    required this.invokeHashHex,
    required this.deployHashHex,
  });

  final List<StarknetExecutionCall> calls;
  final String feeWei;
  final String invokeHashHex;
  final String? deployHashHex;
}

class _HarnessPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _HarnessPathProviderPlatform(this.rootPath);

  final String rootPath;

  @override
  Future<String?> getApplicationSupportPath() async => rootPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => rootPath;

  @override
  Future<String?> getTemporaryPath() async => rootPath;
}

final BigInt _starknetFieldPrime = BigInt.parse(
  '800000000000011000000000000000000000000000000000000000000000001',
  radix: 16,
);
