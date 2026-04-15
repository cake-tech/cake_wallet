import 'dart:typed_data';

import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_starknet/pending_starknet_transaction.dart';
import 'package:cw_starknet/starknet_balance.dart';
import 'package:cw_starknet/starknet_exceptions.dart';
import 'package:cw_starknet/starknet_ur.dart';
import 'package:cw_starknet/starknet_rust.dart';
import 'package:cw_starknet/src/rust/api/starknet.dart' as rust_api;
import 'package:hex/hex.dart';

class StarknetTokenAddresses {
  static const String strk = '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d';
  static const String eth = '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7';
}

class StarknetExecutionCall {
  StarknetExecutionCall({
    required this.contractAddressHex,
    required this.entrypoint,
    required this.calldataHex,
  });

  final String contractAddressHex;
  final String entrypoint;
  final List<String> calldataHex;

  rust_api.StarknetCallInput toRust() => rust_api.StarknetCallInput(
        contractAddressHex: contractAddressHex,
        entrypoint: entrypoint,
        calldataHex: calldataHex,
      );
}

class StarknetTransferEvent {
  StarknetTransferEvent({
    required this.transactionHash,
    required this.eventId,
    required this.eventIndex,
    required this.blockNumber,
    required this.from,
    required this.to,
    required this.amountWei,
    required this.isOutgoing,
    required this.tokenSymbol,
    required this.tokenAddressHex,
    required this.blockTimestamp,
    required this.txFeeWei,
  });

  final String transactionHash;
  final String eventId;
  final int eventIndex;
  final int? blockNumber;
  final String from;
  final String to;
  final String amountWei;
  final bool isOutgoing;
  final String tokenSymbol;
  final String tokenAddressHex;
  final int? blockTimestamp;
  final String? txFeeWei;

  BigInt get amount => BigInt.parse(amountWei);
}

class StarknetWalletClient {
  static const String mainnetChainIdHex = '0x534e5f4d41494e';
  static const List<String> _fallbackNodeUrls = [
    'https://starknet.api.onfinality.io/public',
    'https://api.cartridge.gg/x/starknet/mainnet',
  ];

  String? _nodeUrl;
  String? _accountPrivateKeyHex;
  String? _accountAddressHex;
  String? _accountPublicKeyHex;
  String? _hardwareDerivationPath;
  HardwareWalletService? _hardwareWalletService;

  bool connect(Node node) {
    try {
      _nodeUrl = node.uri.toString();
      return true;
    } catch (e) {
      printV('StarknetWalletClient connect error: $e');
      return false;
    }
  }

  void stop() {
    _nodeUrl = null;
    _accountPrivateKeyHex = null;
    _accountAddressHex = null;
    _accountPublicKeyHex = null;
    _hardwareDerivationPath = null;
    _hardwareWalletService = null;
  }

  void setupAccount({
    required String privateKeyHex,
    required String addressHex,
  }) {
    _accountPrivateKeyHex = privateKeyHex;
    _accountAddressHex = addressHex;
    _accountPublicKeyHex = null;
    _hardwareDerivationPath = null;
    _hardwareWalletService = null;
  }

  void setupHardwareAccount({
    required String addressHex,
    required String publicKeyHex,
    required String derivationPath,
    HardwareWalletService? service,
  }) {
    _accountPrivateKeyHex = null;
    _accountAddressHex = addressHex;
    _accountPublicKeyHex = publicKeyHex;
    _hardwareDerivationPath = derivationPath;
    _hardwareWalletService = service ?? _hardwareWalletService;
  }

  void setHardwareWalletService(HardwareWalletService service) {
    _hardwareWalletService = service;
  }

  void setupExternalSignerAccount({
    required String addressHex,
    required String publicKeyHex,
  }) {
    _accountPrivateKeyHex = null;
    _accountAddressHex = addressHex;
    _accountPublicKeyHex = publicKeyHex;
    _hardwareDerivationPath = null;
    _hardwareWalletService = null;
  }

  Future<StarknetBalance> getTokenBalance({
    required String accountAddressHex,
    required String tokenAddressHex,
    required int decimals,
  }) async {
    await ensureStarknetRustInitialized();

    final balanceWei = await _withFallbackNodeUrls(
      (nodeUrl) async {
        final response = await rust_api.getTokenBalance(
          nodeUrl: nodeUrl,
          accountAddressHex: accountAddressHex,
          tokenAddressHex: tokenAddressHex,
        );
        return unwrapStringResponse(response);
      },
    );

    return StarknetBalance(
      BigInt.parse(balanceWei),
      decimals: decimals,
    );
  }

  Future<rust_api.StarknetTokenMetadata> getTokenMetadata(
    String tokenAddressHex,
  ) async {
    await ensureStarknetRustInitialized();
    return _withFallbackNodeUrls(
      (nodeUrl) async {
        final response = await rust_api.getTokenMetadata(
          nodeUrl: nodeUrl,
          tokenAddressHex: tokenAddressHex,
        );
        return unwrapTokenMetadataResponse(response);
      },
    );
  }

  Future<rust_api.StarknetFeeQuote> estimateExecuteFee({
    required String accountAddressHex,
    required String accountClassHashHex,
    required List<StarknetExecutionCall> calls,
  }) async {
    await ensureStarknetRustInitialized();

    return _withFallbackNodeUrls(
      (nodeUrl) async {
        final response = await rust_api.estimateExecuteFee(
          nodeUrl: nodeUrl,
          privateKeyHex: _requirePrivateKey(),
          accountAddressHex: accountAddressHex,
          accountClassHashHex: accountClassHashHex,
          calls: calls.map((call) => call.toRust()).toList(),
          chainIdHex: mainnetChainIdHex,
        );
        return unwrapFeeQuoteResponse(response);
      },
    );
  }

  Future<rust_api.StarknetFeeQuote> estimateHardwareExecuteFee({
    required String accountAddressHex,
    required String publicKeyHex,
    required String accountClassHashHex,
    required List<StarknetExecutionCall> calls,
  }) async {
    await ensureStarknetRustInitialized();

    return _withFallbackNodeUrls(
      (nodeUrl) async {
        final response = await rust_api.estimateExecuteFeeExternalSigner(
          nodeUrl: nodeUrl,
          publicKeyHex: publicKeyHex,
          accountAddressHex: accountAddressHex,
          accountClassHashHex: accountClassHashHex,
          calls: calls.map((call) => call.toRust()).toList(),
          chainIdHex: mainnetChainIdHex,
        );
        return unwrapFeeQuoteResponse(response);
      },
    );
  }

  Future<PendingStarknetTransaction> createTransaction({
    required List<StarknetExecutionCall> calls,
    required String amountWei,
    required int amountDecimals,
    required String amountSymbol,
    required String destinationAddress,
    required String accountClassHashHex,
    required String feeWei,
  }) async {
    final privateKeyHex = _requirePrivateKey();
    final accountAddressHex = _requireAccountAddress();

    return PendingStarknetTransaction(
      amountWei: amountWei,
      amountDecimals: amountDecimals,
      amountSymbol: amountSymbol,
      destinationAddress: destinationAddress,
      feeWei: feeWei,
      sendTransaction: () async {
        await ensureStarknetRustInitialized();
        return _withFallbackNodeUrls(
          (nodeUrl) async {
            final response = await rust_api.executeCalls(
              nodeUrl: nodeUrl,
              privateKeyHex: privateKeyHex,
              accountAddressHex: accountAddressHex,
              accountClassHashHex: accountClassHashHex,
              calls: calls.map((call) => call.toRust()).toList(),
              chainIdHex: mainnetChainIdHex,
            );
            return unwrapStringResponse(response);
          },
        );
      },
    );
  }

  Future<PendingStarknetTransaction> createHardwareTransaction({
    required List<StarknetExecutionCall> calls,
    required String amountWei,
    required int amountDecimals,
    required String amountSymbol,
    required String destinationAddress,
    required String accountClassHashHex,
    required String feeWei,
  }) async {
    final accountAddressHex = _requireAccountAddress();
    final publicKeyHex = _requirePublicKey();
    final derivationPath = _requireHardwareDerivationPath();
    final hardwareWalletService = _requireHardwareWalletService();

    return PendingStarknetTransaction(
      amountWei: amountWei,
      amountDecimals: amountDecimals,
      amountSymbol: amountSymbol,
      destinationAddress: destinationAddress,
      feeWei: feeWei,
      sendTransaction: () async {
        await ensureStarknetRustInitialized();
        return _withFallbackNodeUrls(
          (nodeUrl) async {
            final hashesResponse = await rust_api.getExecuteTransactionHashesExternalSigner(
              nodeUrl: nodeUrl,
              publicKeyHex: publicKeyHex,
              accountAddressHex: accountAddressHex,
              accountClassHashHex: accountClassHashHex,
              calls: calls.map((call) => call.toRust()).toList(),
              chainIdHex: mainnetChainIdHex,
            );
            final hashes = unwrapExecutionPlanResponse(hashesResponse);

            final invokeSignature = await _signHashWithHardwareWallet(
              hardwareWalletService,
              derivationPath,
              hashes.invokeTransactionHashHex,
            );
            final deploySignature = hashes.deployAccountTransactionHashHex == null
                ? null
                : await _signHashWithHardwareWallet(
                    hardwareWalletService,
                    derivationPath,
                    hashes.deployAccountTransactionHashHex!,
                  );

            final response = await rust_api.executeCallsExternalSigner(
              nodeUrl: nodeUrl,
              planJson: hashes.planJson,
              invokeRHex: invokeSignature.$1,
              invokeSHex: invokeSignature.$2,
              deployRHex: deploySignature?.$1,
              deploySHex: deploySignature?.$2,
            );

            return unwrapStringResponse(response);
          },
        );
      },
    );
  }

  Future<PendingStarknetTransaction> createOfflineTransaction({
    required List<StarknetExecutionCall> calls,
    required String amountWei,
    required int amountDecimals,
    required String amountSymbol,
    required String destinationAddress,
    required String accountClassHashHex,
    required String feeWei,
  }) async {
    await ensureStarknetRustInitialized();

    final accountAddressHex = _requireAccountAddress();
    final publicKeyHex = _requirePublicKey();

    final executionPlan = await _withFallbackNodeUrls(
      (nodeUrl) async {
        final response = await rust_api.getExecuteTransactionHashesExternalSigner(
          nodeUrl: nodeUrl,
          publicKeyHex: publicKeyHex,
          accountAddressHex: accountAddressHex,
          accountClassHashHex: accountClassHashHex,
          calls: calls.map((call) => call.toRust()).toList(),
          chainIdHex: mainnetChainIdHex,
        );
        return unwrapExecutionPlanResponse(response);
      },
    );

    final requestPayload = StarknetSignRequestUrPayload(
      planJson: executionPlan.planJson,
      accountAddressHex: accountAddressHex,
      publicKeyHex: publicKeyHex,
      accountClassHashHex: accountClassHashHex,
      invokeTransactionHashHex: executionPlan.invokeTransactionHashHex,
      deployAccountTransactionHashHex: executionPlan.deployAccountTransactionHashHex,
      amountWei: amountWei,
      amountDecimals: amountDecimals,
      amountSymbol: amountSymbol,
      destinationAddress: destinationAddress,
      feeWei: feeWei,
    );

    return PendingStarknetTransaction(
      amountWei: amountWei,
      amountDecimals: amountDecimals,
      amountSymbol: amountSymbol,
      destinationAddress: destinationAddress,
      feeWei: feeWei,
      transactionHash: executionPlan.invokeTransactionHashHex,
      sendTransaction: () async => throw UnsupportedError(
        'Offline Starknet transactions must be completed via commitUR().',
      ),
      buildUnsignedTransactionUr: () async => encodeStarknetSignRequestUrMap(requestPayload),
    );
  }

  Future<List<StarknetTransferEvent>> fetchTransferEvents({
    required String accountAddressHex,
    required String tokenAddressHex,
    required String tokenSymbol,
    int? fromBlock,
  }) async {
    if (_nodeUrl == null) {
      return [];
    }

    try {
      await ensureStarknetRustInitialized();
      final items = await _withFallbackNodeUrls(
        (nodeUrl) async {
          final response = await rust_api.fetchTransferHistory(
            nodeUrl: nodeUrl,
            accountAddressHex: accountAddressHex,
            tokenAddressHex: tokenAddressHex,
            tokenSymbol: tokenSymbol,
            fromBlock: fromBlock,
            maxPages: 10,
          );
          return unwrapTransferHistoryResponse(response);
        },
      );

      return items
          .map(
            (item) => StarknetTransferEvent(
              transactionHash: item.transactionHash,
              eventId: item.eventId,
              eventIndex: item.eventIndex.toInt(),
              blockNumber: item.blockNumber?.toInt(),
              from: item.from,
              to: item.to,
              amountWei: item.amountWei,
              isOutgoing: item.isOutgoing,
              tokenSymbol: item.tokenSymbol,
              tokenAddressHex: item.tokenAddressHex,
              blockTimestamp: item.blockTimestamp?.toInt(),
              txFeeWei: item.txFeeWei,
            ),
          )
          .toList();
    } catch (e) {
      printV('Error fetching Starknet transfer history: $e');
      return [];
    }
  }

  Future<String> getTypedDataHash({
    required String accountAddressHex,
    required String typedDataJson,
  }) async {
    await ensureStarknetRustInitialized();
    final response = await rust_api.getTypedDataMessageHash(
      accountAddressHex: accountAddressHex,
      typedDataJson: typedDataJson,
    );
    return unwrapStringResponse(response);
  }

  Future<List<String>> signTypedData({
    required String accountAddressHex,
    required String typedDataJson,
  }) async {
    await ensureStarknetRustInitialized();
    final response = await rust_api.signTypedData(
      privateKeyHex: _requirePrivateKey(),
      accountAddressHex: accountAddressHex,
      typedDataJson: typedDataJson,
    );
    return unwrapStringListResponse(response);
  }

  Future<int?> getBlockNumber() async {
    if (_nodeUrl == null) {
      return null;
    }

    try {
      await ensureStarknetRustInitialized();
      return _withFallbackNodeUrls(
        (nodeUrl) async {
          final response = await rust_api.getBlockNumber(nodeUrl: nodeUrl);
          return unwrapI64Response(response);
        },
      );
    } catch (e) {
      printV('Error fetching Starknet block number: $e');
      return null;
    }
  }

  static bool isValidAddress(String address) {
    final regex = RegExp(r'^0x[0-9a-fA-F]{1,64}$');
    return regex.hasMatch(address);
  }

  Future<String> submitSignedTransactionUr(String urPayload) async {
    await ensureStarknetRustInitialized();
    final responsePayload = decodeStarknetSignResponseUr(urPayload);

    if (responsePayload.invokeSignature.rHex.isEmpty ||
        responsePayload.invokeSignature.sHex.isEmpty) {
      throw Exception('Missing Starknet invoke signature in UR response');
    }

    return _withFallbackNodeUrls(
      (nodeUrl) async {
        final response = await rust_api.executeCallsExternalSigner(
          nodeUrl: nodeUrl,
          planJson: responsePayload.planJson,
          invokeRHex: responsePayload.invokeSignature.rHex,
          invokeSHex: responsePayload.invokeSignature.sHex,
          deployRHex: responsePayload.deploySignature?.rHex,
          deploySHex: responsePayload.deploySignature?.sHex,
        );
        return unwrapStringResponse(response);
      },
    );
  }

  String _requireNodeUrl() {
    final nodeUrl = _nodeUrl;
    if (nodeUrl == null) {
      throw StarknetProviderNotConnectedException();
    }

    return nodeUrl;
  }

  String _requirePrivateKey() {
    final privateKeyHex = _accountPrivateKeyHex;
    if (privateKeyHex == null || privateKeyHex.isEmpty) {
      throw StarknetTransactionCreationException.fromMessage(
        'Account private key not configured',
      );
    }

    return privateKeyHex;
  }

  String _requireAccountAddress() {
    final accountAddressHex = _accountAddressHex;
    if (accountAddressHex == null || accountAddressHex.isEmpty) {
      throw StarknetTransactionCreationException.fromMessage(
        'Account address not configured',
      );
    }

    return accountAddressHex;
  }

  String _requirePublicKey() {
    final publicKeyHex = _accountPublicKeyHex;
    if (publicKeyHex == null || publicKeyHex.isEmpty) {
      throw StarknetTransactionCreationException.fromMessage(
        'Account public key not configured',
      );
    }

    return publicKeyHex;
  }

  String _requireHardwareDerivationPath() {
    final derivationPath = _hardwareDerivationPath;
    if (derivationPath == null || derivationPath.isEmpty) {
      throw StarknetTransactionCreationException.fromMessage(
        'Hardware wallet derivation path not configured',
      );
    }

    return derivationPath;
  }

  HardwareWalletService _requireHardwareWalletService() {
    final service = _hardwareWalletService;
    if (service == null) {
      throw StarknetTransactionCreationException.fromMessage(
        'Starknet hardware wallet is not connected',
      );
    }

    return service;
  }

  Future<(String, String)> _signHashWithHardwareWallet(
    HardwareWalletService service,
    String derivationPath,
    String messageHashHex,
  ) async {
    final signatureBytes = await service.signMessage(
      message: _messageHashBytes(messageHashHex),
      derivationPath: derivationPath,
    );
    if (signatureBytes.length != 64) {
      throw StarknetTransactionCreationException.fromMessage(
        'Unexpected Starknet hardware signature length: ${signatureBytes.length}',
      );
    }

    return (
      '0x${HEX.encode(signatureBytes.sublist(0, 32))}',
      '0x${HEX.encode(signatureBytes.sublist(32, 64))}',
    );
  }

  Uint8List _messageHashBytes(String messageHashHex) {
    final normalized =
        messageHashHex.startsWith('0x') ? messageHashHex.substring(2) : messageHashHex;
    final decoded = HEX.decode(normalized.padLeft(64, '0'));
    if (decoded.length == 32) {
      return Uint8List.fromList(decoded);
    }

    final result = Uint8List(32);
    result.setRange(32 - decoded.length, 32, decoded);
    return result;
  }

  Future<T> _withFallbackNodeUrls<T>(
    Future<T> Function(String nodeUrl) action,
  ) async {
    final attemptedErrors = <String>[];

    for (final nodeUrl in _candidateNodeUrls()) {
      try {
        final result = await action(nodeUrl);
        if (_nodeUrl != nodeUrl) {
          printV('Promoting Starknet RPC endpoint to $nodeUrl');
          _nodeUrl = nodeUrl;
        }
        return result;
      } catch (error) {
        attemptedErrors.add('$nodeUrl -> $error');
      }
    }

    throw Exception('All Starknet RPC endpoints failed: ${attemptedErrors.join(' | ')}');
  }

  List<String> _candidateNodeUrls() {
    final urls = <String>[
      _requireNodeUrl(),
      ..._fallbackNodeUrls,
    ];

    final seen = <String>{};
    return urls.where((url) => seen.add(url)).toList();
  }
}
