import 'package:cw_core/amount/money.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_evm/contract/erc20.dart';
import 'package:cw_evm/contract/oft.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/utils/evm_chain_utils.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_evm/usdt0/usdt0_config.dart';
import 'package:cw_evm/usdt0/usdt0_quote.dart';
import 'package:web3dart/web3dart.dart' as web3;

class USDT0Service {
  static Future<USDT0Quote> quoteCrossChainTransfer({
    required web3.Web3Client client,
    required int sourceChainId,
    required int destinationChainId,
    required BigInt amount,
    required String recipientAddress,
    BigInt? minAmount,
  }) async {
    final min = minAmount ?? BigInt.zero;
    final oftAddress = USDT0Config.getOftContractAddress(sourceChainId);
    final dstEid = USDT0Config.getEndpointId(destinationChainId);

    if (oftAddress == null || dstEid == null) {
      throw Exception(
        'USDT0 not supported for chain $sourceChainId -> $destinationChainId',
      );
    }

    final toBytes32 = addressToBytes32(recipientAddress);
    final oft = OFT(
      address: web3.EthereumAddress.fromHex(oftAddress),
      client: client,
    );

    return oft.quoteSend(
      dstEid: dstEid,
      toBytes32: toBytes32,
      amountLD: amount,
      minAmountLD: min,
      payInLzToken: false,
    );
  }

  static Future<PendingTransaction> executeCrossChainTransfer({
    required EVMChainWallet wallet,
    required int sourceChainId,
    required int destinationChainId,
    required BigInt amount,
    required String recipientAddress,
    required USDT0Quote quote,
    required Erc20Token token,
    required EVMChainTransactionPriority priority,
    bool useBlinkProtection = true,
  }) async {
    final oftAddress = USDT0Config.getOftContractAddress(sourceChainId);
    final dstEid = USDT0Config.getEndpointId(destinationChainId);

    if (oftAddress == null || dstEid == null) {
      throw Exception(
        'USDT0 not supported for chain $sourceChainId -> $destinationChainId',
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
      nativeFee: quote.nativeFee,
      lzTokenFee: quote.lzTokenFee,
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
