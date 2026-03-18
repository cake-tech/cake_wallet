import 'package:cw_core/node.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_starknet/pending_starknet_transaction.dart';
import 'package:cw_starknet/starknet_balance.dart';
import 'package:cw_starknet/starknet_rust.dart';
import 'package:cw_starknet/src/rust/api/starknet.dart' as rust_api;

class StarknetTokenAddresses {
  static const String strk =
      '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d';
  static const String eth =
      '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7';
}

class StarknetTransferEvent {
  final String transactionHash;
  final int? blockNumber;
  final String from;
  final String to;
  final String amountWei;
  final bool isOutgoing;
  final String tokenSymbol;
  final int? blockTimestamp;
  final String? txFeeWei;

  StarknetTransferEvent({
    required this.transactionHash,
    required this.blockNumber,
    required this.from,
    required this.to,
    required this.amountWei,
    required this.isOutgoing,
    required this.tokenSymbol,
    required this.blockTimestamp,
    required this.txFeeWei,
  });

  BigInt get amount => BigInt.parse(amountWei);

  double get amountAsDouble =>
      amount / BigInt.from(10).pow(18);

  double get txFeeAsDouble =>
      txFeeWei == null ? 0.0 : BigInt.parse(txFeeWei!) / BigInt.from(10).pow(18);
}

class StarknetWalletClient {
  static const String mainnetChainIdHex = '0x534e5f4d41494e';

  String? _nodeUrl;
  String? _accountPrivateKeyHex;
  String? _accountAddressHex;

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
  }

  void setupAccount({
    required String privateKeyHex,
    required String addressHex,
  }) {
    _accountPrivateKeyHex = privateKeyHex;
    _accountAddressHex = addressHex;
  }

  Future<StarknetBalance> getTokenBalance(
    String accountAddressHex,
    String tokenAddressHex,
  ) async {
    await ensureStarknetRustInitialized();

    try {
      final response = await rust_api.getTokenBalance(
        nodeUrl: _requireNodeUrl(),
        accountAddressHex: accountAddressHex,
        tokenAddressHex: tokenAddressHex,
      );

      return StarknetBalance(_weiToDouble(unwrapStringResponse(response)));
    } catch (e) {
      printV('Error fetching Starknet token balance: $e');
      rethrow;
    }
  }

  Future<StarknetBalance> getStrkBalance(String accountAddressHex) =>
      getTokenBalance(accountAddressHex, StarknetTokenAddresses.strk);

  Future<double> getEstimatedTransferFee(
    String accountAddressHex, {
    String tokenAddressHex = StarknetTokenAddresses.strk,
  }) async {
    if (_nodeUrl == null || _accountPrivateKeyHex == null) {
      return 0.0;
    }

    try {
      await ensureStarknetRustInitialized();
      final response = await rust_api.estimateStandardTransferFee(
        nodeUrl: _nodeUrl!,
        privateKeyHex: _accountPrivateKeyHex!,
        accountAddressHex: accountAddressHex,
        tokenAddressHex: tokenAddressHex,
        chainIdHex: mainnetChainIdHex,
      );

      return _weiToDouble(unwrapStringResponse(response));
    } catch (e) {
      printV('Error estimating Starknet transfer fee: $e');
      return 0.0;
    }
  }

  Future<List<StarknetTransferEvent>> fetchTransferEvents({
    required String accountAddressHex,
    int? fromBlock,
  }) async {
    if (_nodeUrl == null) {
      return [];
    }

    try {
      await ensureStarknetRustInitialized();
      final response = await rust_api.fetchTransferHistory(
        nodeUrl: _nodeUrl!,
        accountAddressHex: accountAddressHex,
        tokenAddressHex: StarknetTokenAddresses.strk,
        tokenSymbol: 'STRK',
        fromBlock: fromBlock,
        maxPages: 10,
      );

      return unwrapTransferHistoryResponse(response)
          .map(
            (item) => StarknetTransferEvent(
              transactionHash: item.transactionHash,
              blockNumber: item.blockNumber?.toInt(),
              from: item.from,
              to: item.to,
              amountWei: item.amountWei,
              isOutgoing: item.isOutgoing,
              tokenSymbol: item.tokenSymbol,
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

  Future<PendingStarknetTransaction> createTransaction({
    required String recipientAddressHex,
    required String amountWei,
    required String tokenAddressHex,
    required String destinationAddressHex,
    required double inputAmount,
    required String accountClassHashHex,
  }) async {
    final nodeUrl = _requireNodeUrl();
    final privateKeyHex = _requirePrivateKey();
    final accountAddressHex = _requireAccountAddress();

    return PendingStarknetTransaction(
      fee: 0.0,
      amount: inputAmount,
      transactionHash: '',
      destinationAddress: destinationAddressHex,
      sendTransaction: () async {
        await ensureStarknetRustInitialized();
        final response = await rust_api.sendTransfer(
          nodeUrl: nodeUrl,
          privateKeyHex: privateKeyHex,
          accountAddressHex: accountAddressHex,
          recipientAddressHex: recipientAddressHex,
          tokenAddressHex: tokenAddressHex,
          amountWei: amountWei,
          accountClassHashHex: accountClassHashHex,
          chainIdHex: mainnetChainIdHex,
        );

        return unwrapStringResponse(response);
      },
    );
  }

  Future<int?> getBlockNumber() async {
    if (_nodeUrl == null) {
      return null;
    }

    try {
      await ensureStarknetRustInitialized();
      final response = await rust_api.getBlockNumber(nodeUrl: _nodeUrl!);
      return unwrapI64Response(response);
    } catch (e) {
      printV('Error fetching Starknet block number: $e');
      return null;
    }
  }

  String _requireNodeUrl() {
    final nodeUrl = _nodeUrl;
    if (nodeUrl == null) {
      throw Exception('Provider not connected');
    }

    return nodeUrl;
  }

  String _requirePrivateKey() {
    final privateKeyHex = _accountPrivateKeyHex;
    if (privateKeyHex == null || privateKeyHex.isEmpty) {
      throw Exception('Account private key not configured');
    }

    return privateKeyHex;
  }

  String _requireAccountAddress() {
    final accountAddressHex = _accountAddressHex;
    if (accountAddressHex == null || accountAddressHex.isEmpty) {
      throw Exception('Account address not configured');
    }

    return accountAddressHex;
  }

  static double _weiToDouble(String amountWei) =>
      BigInt.parse(amountWei) / BigInt.from(10).pow(18);
}
