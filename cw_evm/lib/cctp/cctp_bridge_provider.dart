import "dart:convert";
import "dart:typed_data";

import "package:cw_core/amount/money.dart";
import "package:cw_core/bridge_quote.dart";
import "package:cw_core/bridge_transfer_status.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_evm/bridge_provider.dart";
import "package:cw_evm/cctp/cctp_config.dart";
import "package:cw_evm/contract/oft.dart" show addressToBytes32;
import "package:cw_evm/contract/token_messenger_v2.dart";
import "package:cw_evm/evm_chain_transaction_priority.dart";
import "package:cw_evm/evm_chain_wallet.dart";
import "package:hex/hex.dart" as hex;

class CctpBridgeProvider extends BridgeProvider {
  static const String _irisBaseUrl = "https://iris-api.circle.com/v2";

  static const int _fastTransferFinalityThreshold = 1000;

  static const Duration _approvalPollInterval = Duration(seconds: 2);
  static const Duration _approvalTimeout = Duration(minutes: 3);

  @override
  Map<int, String> get tokenAddressByChainId => CctpConfig.usdcTokenAddressByChainId;

  @override
  Future<BridgeQuote> quoteTransfer({
    required EVMChainWallet wallet,
    required Erc20Token token,
    required int sourceChainId,
    required int destinationChainId,
    required BigInt amount,
    required String recipientAddress,
  }) async {
    final sourceDomain = _getDomain(sourceChainId);
    final destinationDomain = _getDomain(destinationChainId);

    final uri = Uri.parse(
      "$_irisBaseUrl/burn/USDC/fees/$sourceDomain/$destinationDomain?forward=true",
    );
    final response = await ProxyWrapper().get(clearnetUri: uri);

    if (response.statusCode != 200) {
      throw ServerResponseException("Failed to fetch the bridge fee (${response.statusCode})");
    }

    final fees = json.decode(response.body) as List<dynamic>;
    final fastTransfer = fees.firstWhere(
      (fee) => fee["finalityThreshold"] == _fastTransferFinalityThreshold,
    );
    final minimumFee = fastTransfer["minimumFee"] as num;
    final forwardFee = fastTransfer["forwardFee"]["med"] as int;

    // round division up so that the Fast Transfer does not turn into a Standard one
    final feeRate = BigInt.from((minimumFee * 100).round());
    final protocolFee = (amount * feeRate + BigInt.from(999999)) ~/ BigInt.from(1000000);
    final maxFee = protocolFee + BigInt.from(forwardFee);

    return BridgeQuote(fee: Money(maxFee, token), receiveAmount: Money(amount - maxFee, token));
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
    final destinationDomain = _getDomain(destinationChainId);
    final mintRecipient = addressToBytes32(recipientAddress);

    await _ensureAllowance(
      wallet: wallet,
      token: token,
      amount: amount,
      priority: priority,
      useBlinkProtection: useBlinkProtection,
    );

    final dataHex = encodeDepositForBurnWithHook(
      amount: amount,
      destinationDomain: destinationDomain,
      mintRecipient: mintRecipient,
      burnToken: token.contractAddress,
      destinationCaller: Uint8List(32),
      maxFee: quote.fee.amount,
      minFinalityThreshold: _fastTransferFinalityThreshold,
      hookData: hex.HEX.decode(CctpConfig.forwardingHookData),
    );

    return wallet.createCallDataTransaction(
      CctpConfig.tokenMessenger,
      dataHex,
      Money.zero(token),
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
    final sourceDomain = _getDomain(sourceChainId);

    final uri = Uri.parse("$_irisBaseUrl/messages/$sourceDomain?transactionHash=$sourceTxHash");
    final response = await ProxyWrapper().get(clearnetUri: uri);

    if (response.statusCode != 200) return null;

    final messages = json.decode(response.body)["messages"] as List<dynamic>;
    if (messages.isEmpty) return null;

    final message = messages.first;
    final forwardState = message["forwardState"];

    if (forwardState == "COMPLETE" || message["destinationMintTxHash"] != null) {
      return const BridgeTransferStatus(
        message: "Delivered to the destination network",
        isDelivered: true,
      );
    }

    if (forwardState == "FAILED") {
      return const BridgeTransferStatus(
        message: "Circle could not deliver the transfer. The USDC is not lost. "
            "Please contact support.",
        isFailed: true,
      );
    }

    if (message["status"] == "complete") {
      return const BridgeTransferStatus(message: "Delivering to the destination network");
    }

    if (message["delayReason"] != null) {
      return const BridgeTransferStatus(
        message: "Waiting for finality on the source network, which can take about 20 minutes",
      );
    }

    return const BridgeTransferStatus(message: "Waiting for Circle to confirm the transfer");
  }

  static int _getDomain(int chainId) {
    final domain = CctpConfig.getDomain(chainId);
    if (domain == null) {
      throw BadChainIdException("CCTP not supported for chain $chainId");
    }

    return domain;
  }

  // Waits for the approval to confirm: until then the burn's gas estimate reverts, and behind a
  // private relay the burn would reuse the approval's nonce.
  static Future<void> _ensureAllowance({
    required EVMChainWallet wallet,
    required Erc20Token token,
    required BigInt amount,
    required EVMChainTransactionPriority priority,
    required bool useBlinkProtection,
  }) async {
    const spender = CctpConfig.tokenMessenger;
    if (!await wallet.isApprovalRequired(token.contractAddress, spender, amount)) return;

    final pendingApproval = await wallet.createApprovalTransaction(
      Money((BigInt.one << 256) - BigInt.one, token),
      spender,
      priority,
      useBlinkProtection: useBlinkProtection,
    );
    await pendingApproval.commit();

    final deadline = DateTime.now().add(_approvalTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(_approvalPollInterval);

      if (!await wallet.isApprovalRequired(token.contractAddress, spender, amount)) return;
    }

    throw const TransactionGenerationException(
      "The USDC approval has not confirmed yet. Try again once it has.",
    );
  }
}
