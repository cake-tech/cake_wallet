import 'package:cw_core/amount/money.dart';
import "package:cw_core/bridge_quote.dart";
import "package:cw_core/bridge_transfer_status.dart";
import 'package:cw_core/erc20_token.dart';
import "package:cw_core/exceptions/cake_exception.dart";
import 'package:cw_core/pending_transaction.dart';
import "package:cw_evm/bridge_provider.dart";
import 'package:cw_evm/contract/erc20.dart';
import 'package:cw_evm/contract/oft.dart';
import "package:cw_evm/evm_chain_registry.dart";
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import "package:cw_evm/usdt0/layerzero_scan_service.dart";
import 'package:cw_evm/usdt0/usdt0_config.dart';
import 'package:web3dart/web3dart.dart' as web3;

class USDT0BridgeProvider extends BridgeProvider {
  @override
  Map<int, String> get tokenAddressByChainId => USDT0Config.usdt0TokenAddressByChainId;

  @override
  Future<BridgeQuote> quoteTransfer({
    required EVMChainWallet wallet,
    required Erc20Token token,
    required int sourceChainId,
    required int destinationChainId,
    required BigInt amount,
    required String recipientAddress,
  }) async {
    final oftAddress = USDT0Config.getOftContractAddress(sourceChainId);
    final dstEid = USDT0Config.getEndpointId(destinationChainId);

    if (oftAddress == null) {
      throw BadChainIdException(
          'USDT0 not supported for chain $sourceChainId'
      );
    }

    if(dstEid == null) {
      throw BadChainIdException(
          'USDT0 not supported for chain $destinationChainId'
      );
    }

    final client = wallet.getWeb3Client();
    if (client == null) {
      throw StateError('Wallet not connected to node');
    }

    final toBytes32 = addressToBytes32(recipientAddress);
    final oft = OFT(
      address: web3.EthereumAddress.fromHex(oftAddress),
      client: client,
    );

    final quote = await oft.quoteSend(
      dstEid: dstEid,
      toBytes32: toBytes32,
      amountLD: amount,
      minAmountLD: BigInt.zero,
      payInLzToken: false,
    );

    return BridgeQuote(
      fee: Money(
        quote.nativeFee,
        EvmChainRegistry().getChainConfig(sourceChainId)!.nativeCurrency,
      ),
      receiveAmount: Money(amount, token),
    );
  }

  @override
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
  }) async {
    final oftAddress = USDT0Config.getOftContractAddress(sourceChainId);
    final dstEid = USDT0Config.getEndpointId(destinationChainId);

    if (oftAddress == null) {
      throw BadChainIdException(
        'USDT0 not supported for chain $sourceChainId'
      );
    }

    if(dstEid == null) {
      throw BadChainIdException(
          'USDT0 not supported for chain $destinationChainId'
      );
    }

    if (sourceChainId == USDT0Config.ethereumChainId) {
      final adapter = USDT0Config.getOftAdapterAddress(sourceChainId);
      if (adapter != null) {
        final needsApproval = await _isApprovalRequired(
          wallet: wallet,
          token: token,
          spender: adapter,
          amount: amount,
        );

        if (needsApproval) {
          final maxUint = BigInt.parse(
            'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
            radix: 16,
          );

          final pendingApproval = await wallet.createApprovalTransaction(
            Money(maxUint, token),
            adapter,
            priority,
            useBlinkProtection: useBlinkProtection,
          );
          await pendingApproval.commit();
        }
      }
    }

    final client = wallet.getWeb3Client();
    if (client == null) {
      throw StateError('Wallet not connected to node');
    }

    final toBytes32 = addressToBytes32(recipientAddress);
    final oft = OFT(
      address: web3.EthereumAddress.fromHex(oftAddress),
      client: client,
    );

    final encoded = oft.encodeSend(
      dstEid: dstEid,
      toBytes32: toBytes32,
      amountLD: amount,
      minAmountLD: BigInt.zero,
      nativeFee: quote.fee.amount,
      lzTokenFee: BigInt.zero,
      refundAddress: wallet.walletAddresses.primaryAddress,
    );

    return wallet.createCallDataTransaction(
      oftAddress,
      encoded.dataHex,
      Money(encoded.valueWei, token),
      priority,
      token.contractAddress,
      amount,
      useBlinkProtection: useBlinkProtection,
    );
  }

  @override
  Future<BridgeTransferStatus?> getTransferStatus({
    required int sourceChainId,
    required String sourceTxHash,
  }) async {
    final status = await LayerZeroScanService.getMessageStatus(sourceTxHash);
    if (status == null) return null;

    return BridgeTransferStatus(
      isDelivered: status.isDelivered,
      isFailed: status.isFailed,
      message: status.status?.message,
    );
  }

  static Future<bool> _isApprovalRequired({
    required EVMChainWallet wallet,
    required Erc20Token token,
    required String spender,
    required BigInt amount,
  }) async {
    final client = wallet.getWeb3Client();
    if (client == null) return true;

    final erc20 = ERC20(
      address: web3.EthereumAddress.fromHex(token.contractAddress),
      client: client,
    );
    final current = await erc20.allowance(
      web3.EthereumAddress.fromHex(wallet.walletAddresses.primaryAddress),
      web3.EthereumAddress.fromHex(spender),
    );
    return current < amount;
  }
}
