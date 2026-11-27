import "package:cw_core/bridge_quote.dart";
import "package:cw_core/bridge_transfer_status.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_evm/evm_chain_transaction_priority.dart";
import "package:cw_evm/evm_chain_wallet.dart";

abstract class BridgeProvider {
  Map<int, String> get tokenAddressByChainId;

  bool supportsChain(int chainId) => tokenAddressByChainId.containsKey(chainId);

  bool supportsToken(String contractAddress, int chainId) =>
      tokenAddressByChainId[chainId]?.toLowerCase() == contractAddress.toLowerCase();

  Future<BridgeQuote> quoteTransfer({
    required EVMChainWallet wallet,
    required Erc20Token token,
    required int sourceChainId,
    required int destinationChainId,
    required BigInt amount,
    required String recipientAddress,
  });

  Future<PendingTransaction> executeTransfer({
    required EVMChainWallet wallet,
    required Erc20Token token,
    required int sourceChainId,
    required int destinationChainId,
    required BigInt amount,
    required String recipientAddress,
    required BridgeQuote quote,
    required EVMChainTransactionPriority priority,
    required bool useBlinkProtection,
  });

  Future<BridgeTransferStatus?> getTransferStatus({
    required int sourceChainId,
    required String sourceTxHash,
  });
}
