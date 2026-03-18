import 'package:cw_core/node.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_starknet/starknet_balance.dart';
import 'package:cw_starknet/pending_starknet_transaction.dart';
import 'package:starknet/starknet.dart';

/// Lightweight representation of a parsed Transfer event.
class StarknetTransferEvent {
  final String transactionHash;
  final int? blockNumber;
  final String from;
  final String to;
  final BigInt amountLow;
  final BigInt amountHigh;
  final bool isOutgoing;
  final String tokenSymbol;

  StarknetTransferEvent({
    required this.transactionHash,
    required this.blockNumber,
    required this.from,
    required this.to,
    required this.amountLow,
    required this.amountHigh,
    required this.isOutgoing,
    required this.tokenSymbol,
  });

  BigInt get amount => (amountHigh << 128) | amountLow;

  double get amountAsDouble => amount / BigInt.from(10).pow(18);
}

class StarknetWalletClient {
  JsonRpcProvider? _provider;
  StarknetAccount? _account;
  final Map<int, int> _blockTimestampCache = {};

  bool connect(Node node) {
    try {
      _provider = JsonRpcProvider(rpcUrl: node.uri);
      return true;
    } catch (e) {
      printV('StarknetWalletClient connect error: $e');
      return false;
    }
  }

  void stop() {
    _provider?.close();
    _provider = null;
    _account = null;
  }

  JsonRpcProvider? get provider => _provider;

  void setupAccount({
    required StarkPrivateKeySigner signer,
    required Felt address,
    required Felt chainId,
  }) {
    if (_provider == null) return;

    _account = StarknetAccount(
      provider: _provider!,
      signer: signer,
      address: address,
      chainId: chainId,
    );
  }

  Future<bool> isAccountDeployed(Felt accountAddress) async {
    if (_provider == null) throw Exception('Provider not connected');

    try {
      await _provider!.getClassHashAt(BlockId.latest, accountAddress);
      return true;
    } on StarknetRpcError catch (e) {
      if (e.code == StarknetRpcErrorCodes.contractNotFound) {
        return false;
      }

      rethrow;
    }
  }

  Future<StarknetBalance> getBalance(Felt accountAddress) async {
    if (_provider == null) throw Exception('Provider not connected');

    try {
      final result = await _provider!.call(
        FunctionCall(
          contractAddress: StarknetTokens.eth,
          entryPointSelector: getSelectorFromName('balanceOf'),
          calldata: [accountAddress],
        ),
        BlockId.latest,
      );

      final low = result[0].value;
      final high = result.length > 1 ? result[1].value : BigInt.zero;
      final totalWei = (high << 128) | low;
      final balance = totalWei / BigInt.from(10).pow(18);
      return StarknetBalance(balance.toDouble());
    } catch (e) {
      printV('Error fetching balance: $e');
      rethrow;
    }
  }

  Future<StarknetBalance> getStrkBalance(Felt accountAddress) async {
    if (_provider == null) throw Exception('Provider not connected');

    try {
      final result = await _provider!.call(
        FunctionCall(
          contractAddress: StarknetTokens.strk,
          entryPointSelector: getSelectorFromName('balanceOf'),
          calldata: [accountAddress],
        ),
        BlockId.latest,
      );

      final low = result[0].value;
      final high = result.length > 1 ? result[1].value : BigInt.zero;
      final totalWei = (high << 128) | low;
      final balance = totalWei / BigInt.from(10).pow(18);
      return StarknetBalance(balance.toDouble());
    } catch (e) {
      printV('Error fetching STRK balance: $e');
      rethrow;
    }
  }

  Future<double> getEstimatedFee(
    StarkPrivateKeySigner signer,
    Felt accountAddress,
    Felt recipientAddress,
    BigInt amount,
  ) async {
    if (_provider == null || _account == null) return 0.0;

    try {
      final call = Call(
        contractAddress: StarknetTokens.eth,
        entrypoint: 'transfer',
        calldata: [recipientAddress, ...encodeUint256(amount)],
      );

      final feeEstimate = await _provider!.estimateFee(
        [
          BroadcastedInvokeTxn(
            senderAddress: accountAddress,
            calldata: encodeCalls([call]),
            nonce: await _account!.getNonce(),
            signature: const [],
            resourceBounds: const ResourceBoundsMapping(
              l1Gas: ResourceBounds(maxAmount: '0x0', maxPricePerUnit: '0x0'),
              l2Gas: ResourceBounds(maxAmount: '0x0', maxPricePerUnit: '0x0'),
              l1DataGas: ResourceBounds(maxAmount: '0x0', maxPricePerUnit: '0x0'),
            ),
            tip: Felt.zero,
            paymasterData: const [],
            nonceDataAvailabilityMode: DaMode.l1,
            feeDataAvailabilityMode: DaMode.l1,
          ).toJson(),
        ],
        [SimulationFlagForEstimateFee.skipValidate],
        BlockId.latest,
      );

      if (feeEstimate.isNotEmpty) {
        final overallFee = feeEstimate.first.overallFee.value;
        return overallFee / BigInt.from(10).pow(18);
      }

      return 0.0;
    } catch (e) {
      printV('Error estimating fee: $e');
      return 0.0;
    }
  }

  /// Estimates the fee for a standard STRK transfer.
  /// Used for pre-estimation display on the send screen.
  Future<double> getEstimatedTransferFee(Felt accountAddress) async {
    if (_provider == null || _account == null) return 0.0;

    try {
      final call = Call(
        contractAddress: StarknetTokens.strk,
        entrypoint: 'transfer',
        calldata: [
          accountAddress, // dummy recipient (self-transfer for estimation)
          ...encodeUint256(BigInt.from(1000)), // tiny amount
        ],
      );

      final feeEstimate = await _provider!.estimateFee(
        [
          BroadcastedInvokeTxn(
            senderAddress: accountAddress,
            calldata: encodeCalls([call]),
            nonce: await _account!.getNonce(),
            signature: const [],
            resourceBounds: const ResourceBoundsMapping(
              l1Gas: ResourceBounds(maxAmount: '0x0', maxPricePerUnit: '0x0'),
              l2Gas: ResourceBounds(maxAmount: '0x0', maxPricePerUnit: '0x0'),
              l1DataGas: ResourceBounds(maxAmount: '0x0', maxPricePerUnit: '0x0'),
            ),
            tip: Felt.zero,
            paymasterData: const [],
            nonceDataAvailabilityMode: DaMode.l1,
            feeDataAvailabilityMode: DaMode.l1,
          ).toJson(),
        ],
        [SimulationFlagForEstimateFee.skipValidate],
        BlockId.latest,
      );

      if (feeEstimate.isNotEmpty) {
        final overallFee = feeEstimate.first.overallFee.value;
        return overallFee / BigInt.from(10).pow(18);
      }

      return 0.0;
    } catch (e) {
      printV('Error estimating transfer fee: $e');
      return 0.0;
    }
  }

  /// Fetches ERC20 Transfer events involving the given account address for STRK token.
  /// Returns both outgoing and incoming transfer events.
  Future<List<StarknetTransferEvent>> fetchTransferEvents({
    required Felt accountAddress,
    int? fromBlock,
  }) async {
    if (_provider == null) return [];

    final transferSelector = getSelectorFromName('Transfer');
    final events = <StarknetTransferEvent>[];

    // Fetch outgoing transfers (account is 'from' in keys[1])
    await _fetchPaginatedEvents(
      filter: EventFilter(
        fromAddress: StarknetTokens.strk,
        keys: [
          [transferSelector],
          [accountAddress],
        ],
        fromBlock: fromBlock,
      ),
      isOutgoing: true,
      tokenSymbol: 'STRK',
      events: events,
    );

    // Fetch incoming transfers (account is 'to' in keys[2])
    await _fetchPaginatedEvents(
      filter: EventFilter(
        fromAddress: StarknetTokens.strk,
        keys: [
          [transferSelector],
          [], // any sender
          [accountAddress],
        ],
        fromBlock: fromBlock,
      ),
      isOutgoing: false,
      tokenSymbol: 'STRK',
      events: events,
    );

    // Deduplicate self-transfers: keep both directions but remove exact duplicates
    final seen = <String>{};
    events.removeWhere((e) => !seen.add('${e.transactionHash}_${e.isOutgoing}'));

    return events;
  }

  Future<void> _fetchPaginatedEvents({
    required EventFilter filter,
    required bool isOutgoing,
    required String tokenSymbol,
    required List<StarknetTransferEvent> events,
  }) async {
    String? continuationToken;
    const maxPages = 10; // Safety limit to avoid infinite loops
    int page = 0;

    do {
      try {
        final chunk = await _provider!.getEvents(
          filter,
          ResultPageRequest(chunkSize: 100, continuationToken: continuationToken),
        );

        for (final event in chunk.events) {
          events.add(StarknetTransferEvent(
            transactionHash: event.transactionHash.toHex(),
            blockNumber: event.blockNumber,
            from: event.keys.length > 1 ? event.keys[1].toHex() : '',
            to: event.keys.length > 2 ? event.keys[2].toHex() : '',
            amountLow: event.data.isNotEmpty ? event.data[0].value : BigInt.zero,
            amountHigh: event.data.length > 1 ? event.data[1].value : BigInt.zero,
            isOutgoing: isOutgoing,
            tokenSymbol: tokenSymbol,
          ));
        }

        continuationToken = chunk.continuationToken;
        page++;
      } catch (e) {
        printV('Error fetching events page $page: $e');
        break;
      }
    } while (continuationToken != null && page < maxPages);
  }

  /// Gets the timestamp for a given block number, with caching.
  Future<int> getBlockTimestamp(int blockNumber) async {
    if (_blockTimestampCache.containsKey(blockNumber)) {
      return _blockTimestampCache[blockNumber]!;
    }

    try {
      final block = await _provider!.getBlockWithTxHashes(
        BlockId.number(blockNumber),
      );
      final timestamp = block.header.timestamp;
      _blockTimestampCache[blockNumber] = timestamp;
      return timestamp;
    } catch (e) {
      printV('Error fetching block timestamp for block $blockNumber: $e');
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
  }

  /// Gets the actual fee paid for a transaction from its receipt.
  Future<double> getTransactionFee(Felt txHash) async {
    if (_provider == null) return 0.0;

    try {
      final receipt = await _provider!.getTransactionReceipt(txHash);
      return receipt.receipt.actualFee.value / BigInt.from(10).pow(18);
    } catch (e) {
      printV('Error fetching transaction fee: $e');
      return 0.0;
    }
  }

  Future<PendingStarknetTransaction> createTransaction({
    required Felt recipientAddress,
    required BigInt amount,
    required Felt tokenAddress,
    required String destinationAddressHex,
    required double inputAmount,
    required Felt accountClassHash,
    required Felt contractAddressSalt,
    required List<Felt> constructorCalldata,
  }) async {
    if (_account == null) throw Exception('Account not setup');

    final call = Call(
      contractAddress: tokenAddress,
      entrypoint: 'transfer',
      calldata: [recipientAddress, ...encodeUint256(amount)],
    );

    Future<String> sendTx() async {
      if (!await isAccountDeployed(_account!.address)) {
        final deployEstimate = await _provider!.estimateFee(
          [
            BroadcastedDeployAccountTxn(
              signature: const [],
              nonce: Felt.zero,
              resourceBounds: const ResourceBoundsMapping(
                l1Gas: ResourceBounds(maxAmount: '0x0', maxPricePerUnit: '0x0'),
                l2Gas: ResourceBounds(maxAmount: '0x0', maxPricePerUnit: '0x0'),
                l1DataGas: ResourceBounds(maxAmount: '0x0', maxPricePerUnit: '0x0'),
              ),
              tip: Felt.zero,
              paymasterData: const [],
              contractAddressSalt: contractAddressSalt,
              classHash: accountClassHash,
              constructorCalldata: constructorCalldata,
              nonceDataAvailabilityMode: DaMode.l1,
              feeDataAvailabilityMode: DaMode.l1,
            ).toJson(),
          ],
          [SimulationFlagForEstimateFee.skipValidate],
          BlockId.latest,
        );

        final deployResponse = await _account!.deployAccount(
          classHash: accountClassHash,
          contractAddressSalt: contractAddressSalt,
          constructorCalldata: constructorCalldata,
          feeConfig: deployEstimate.isNotEmpty
              ? FeeConfig.fromEstimate(deployEstimate.first, multiplier: 1.5)
              : FeeConfig(),
          feeMultiplier: 1.5,
        );

        await _account!.waitForTransaction(
          deployResponse['transaction_hash']!,
          timeout: const Duration(minutes: 5),
        );
      }

      final response = await _account!.execute(
        [call],
        feeMultiplier: 1.5,
      );

      await _account!.waitForTransaction(
        response.transactionHash,
        timeout: const Duration(minutes: 5),
      );

      return response.transactionHash.toHex();
    }

    return PendingStarknetTransaction(
      fee: 0.0, // Fee is estimated during execution
      amount: inputAmount,
      transactionHash: '',
      destinationAddress: destinationAddressHex,
      sendTransaction: sendTx,
    );
  }

  Future<int?> getBlockNumber() async {
    if (_provider == null) return null;

    try {
      return await _provider!.blockNumber();
    } catch (e) {
      printV('Error fetching block number: $e');
      return null;
    }
  }
}
