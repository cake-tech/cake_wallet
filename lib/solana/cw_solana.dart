part of 'solana.dart';

class CWSolana extends Solana {
  @override
  List<String> getSolanaWordList(String language) => SolanaMnemonics.englishWordlist;

  WalletService createSolanaWalletService(bool isDirect) => SolanaWalletService(isDirect);

  @override
  WalletCredentials createSolanaNewWalletCredentials({
    required String name,
    String? mnemonic,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
  }) =>
      SolanaNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        mnemonic: mnemonic,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createSolanaRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      SolanaRestoreWalletFromSeedCredentials(
        name: name,
        password: password,
        mnemonic: mnemonic,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createSolanaRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      SolanaRestoreWalletFromPrivateKey(name: name, password: password, privateKey: privateKey);

  @override
  String getAddress(WalletBase wallet) => (wallet as SolanaWallet).walletAddresses.address;

  @override
  String getPrivateKey(WalletBase wallet) => (wallet as SolanaWallet).privateKey;

  @override
  String getPublicKey(WalletBase wallet) =>
      (wallet as SolanaWallet).solanaPublicKey.toAddress().address;
  Object createSolanaTransactionCredentials(
    List<Output> outputs, {
    required CryptoCurrency currency,
  }) =>
      SolanaTransactionCredentials(
        outputs
            .map((out) => OutputInfo(
                fiatAmount: out.fiatAmount,
                cryptoAmount: out.cryptoAmount,
                address: out.address,
                note: out.note,
                sendAll: out.sendAll,
                extractedAddress: out.extractedAddress,
                isParsedAddress: out.isParsedAddress,
                formattedCryptoAmount: out.formattedCryptoAmount))
            .toList(),
        currency: currency,
      );

  Object createSolanaTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    required CryptoCurrency currency,
  }) =>
      SolanaTransactionCredentials(outputs, currency: currency);

  @override
  List<SPLToken> getSPLTokenCurrencies(WalletBase wallet) {
    final solanaWallet = wallet as SolanaWallet;
    return solanaWallet.splTokenCurrencies;
  }

  @override
  Future<void> addSPLToken(
    WalletBase wallet,
    CryptoCurrency token,
    String contractAddress,
  ) async {
    final splToken = SPLToken(
      name: token.name,
      symbol: token.title,
      mintAddress: contractAddress,
      decimal: token.decimals,
      mint: token.name.toUpperCase(),
      enabled: token.enabled,
      iconPath: token.iconPath,
      isPotentialScam: token.isPotentialScam,
    );

    await (wallet as SolanaWallet).addSPLToken(splToken);
  }

  @override
  Future<void> deleteSPLToken(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as SolanaWallet).deleteSPLToken(token as SPLToken);

  @override
  Future<SPLToken?> getSPLToken(WalletBase wallet, String mintAddress) async {
    final solanaWallet = wallet as SolanaWallet;
    return await solanaWallet.getSPLToken(mintAddress);
  }

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as SolanaTransactionInfo;
    if (transaction.tokenSymbol == CryptoCurrency.sol.title) {
      return CryptoCurrency.sol;
    }

    wallet as SolanaWallet;

    return wallet.splTokenCurrencies.firstWhere(
      (element) => transaction.tokenSymbol == element.symbol,
    );
  }

  @override
  double getTransactionAmountRaw(TransactionInfo transactionInfo) {
    return (transactionInfo as SolanaTransactionInfo).solAmount.toDouble();
  }

  @override
  String getTokenAddress(CryptoCurrency asset) {
    // If it's already an SPLToken, use its mint address
    if (asset is SPLToken) return asset.mintAddress;

    // If it's not an SPLToken but has SOL tag, try to find matching SPLToken
    if (asset.tag == 'SOL') {
      final symbol = asset.title.toUpperCase();

      // Search through default tokens to find matching symbol
      final defaultTokens = DefaultSPLTokens().initialSPLTokens;
      try {
        final matchingToken = defaultTokens.firstWhere(
          (token) => token.symbol.toUpperCase() == symbol,
        );
        return matchingToken.mintAddress;
      } catch (_) {
        // Token not found in default tokens
      }
    }

    // Fallback - try to cast (will throw if not SPLToken)
    return (asset as SPLToken).mintAddress;
  }

  @override
  List<int>? getValidationLength(CryptoCurrency type) {
    if (type is SPLToken) {
      return [32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44];
    }

    return null;
  }

  @override
  double? getEstimateFees(WalletBase wallet) {
    return (wallet as SolanaWallet).estimatedFee;
  }

  @override
  List<String> getDefaultTokenContractAddresses() {
    return DefaultSPLTokens().initialSPLTokens.map((e) => e.mintAddress).toList();
  }

  @override
  bool isTokenAlreadyAdded(WalletBase wallet, String contractAddress) {
    final solanaWallet = wallet as SolanaWallet;
    return solanaWallet.splTokenCurrencies.any((element) => element.mintAddress == contractAddress);
  }

  @override
  Future<PendingTransaction> signAndPrepareJupiterSwapTransaction(
    WalletBase wallet,
    String base64Transaction,
    String requestId,
    String destinationAddress,
    double amount,
    double fee,
  ) async {
    final solanaWallet = wallet as SolanaWallet;
    final privateKey = solanaWallet.solanaPrivateKey;
    final solanaProvider = solanaWallet.solanaProvider;

    if (solanaProvider == null) {
      throw Exception('Solana provider not available');
    }

    final unsignedTransactionBytes = base64.decode(base64Transaction);
    final unsignedTransaction = SolanaTransaction.deserialize(unsignedTransactionBytes);

    final signedMessage = privateKey.sign(unsignedTransaction.serializeMessage());
    unsignedTransaction.addSignature(privateKey.publicKey().toAddress(), signedMessage);

    final signedTransactionBytes = unsignedTransaction.serialize();
    final signedTransactionBase64 = base64.encode(Uint8List.fromList(signedTransactionBytes));

    Future<String> sendTx() async {
      try {
        if (signedTransactionBase64.isEmpty) {
          throw Exception('Invalid transaction: transaction is empty');
        }

        if (requestId.isEmpty) {
          throw Exception('Invalid requestId: requestId is empty');
        }

        final jupiterProvider = JupiterExchangeProvider();

        final executeResponse = await jupiterProvider.executeSwap(
          signedTransaction: signedTransactionBase64,
          requestId: requestId,
        );

        final status = executeResponse['status'] as String?;
        final signature = executeResponse['signature'] as String?;
        final errorCode = executeResponse['code'] as num?;
        final errorMessage = executeResponse['error'] as String? ?? 'Unknown error';

        // Handle different status cases
        switch (status) {
          case 'Success':
            if (signature == null ||
                signature.isEmpty ||
                signature == '1111111111111111111111111111111111111111111111111111111111111111') {
              throw Exception(
                'Invalid transaction signature received from Jupiter. '
                'Status: $status',
              );
            }
            return signature;
          case 'Failed':
            String userFriendlyError = _getJupiterErrorMessage(errorCode, errorMessage);
            // Even when failed, Jupiter may return a signature for solscan
            if (signature != null && signature.isNotEmpty) {
              throw JupiterSwapFailedException(
                message: userFriendlyError,
                signature: signature,
                errorCode: errorCode,
                errorMessage: errorMessage,
              );
            } else {
              throw Exception(userFriendlyError);
            }
          case 'Pending':
          case 'Processing':
            throw Exception(
              'Jupiter swap is still processing. Please wait and try checking the transaction status.',
            );
          default:
            throw Exception(
              'Jupiter swap returned unknown status: $status. Error: $errorMessage. Code: $errorCode',
            );
        }
      } catch (e) {
        throw Exception('Failed to execute Jupiter swap: $e');
      }
    }

    return PendingSolanaTransaction(
      amount: amount,
      serializedTransaction: signedTransactionBase64,
      destinationAddress: destinationAddress,
      sendTransaction: sendTx,
      fee: fee,
    );
  }

  /// Get user-friendly error message based on Jupiter error code
  String _getJupiterErrorMessage(num? errorCode, String errorMessage) {
    if (errorCode == null) {
      return 'Jupiter swap failed: $errorMessage';
    }

    switch (errorCode.toInt()) {
      case -2000:
        return 'Transaction failed to land on the network. Please try again.';
      case -2001:
        return 'Unknown error occurred. Please try again.';
      case -2002:
        return 'Invalid transaction. Please try creating a new swap.';
      case -2003:
        return 'Quote expired. The swap quote is no longer valid. Please create a new swap.';
      case -2004:
        return 'Swap was rejected. This may be due to:\n'
            '- Insufficient funds for the swap or fees\n'
            '- Slippage tolerance exceeded (price moved too much)\n'
            '- Network congestion\n'
            'Please check your balance and try again with a new quote.';
      case -2005:
        return 'Internal error occurred. Please try again.';
      default:
        // Check for common program errors
        if (errorMessage.contains('SlippageToleranceExceeded') ||
            errorMessage.contains('slippage')) {
          return 'Slippage tolerance exceeded. The price moved too much during the swap. '
              'Please try again with a new quote.';
        }

        if (errorMessage.contains('InsufficientFunds') || errorMessage.contains('insufficient')) {
          return 'Insufficient funds. Please ensure you have enough SOL for the swap and fees.';
        }

        if (errorMessage.contains('Blockhash') || errorMessage.contains('expired')) {
          return 'Transaction expired. Please create a new swap.';
        }

        return 'Jupiter swap failed (code: $errorCode): $errorMessage. Please try again.';
    }
  }

  @override
  Future<void> pollForTransaction(
    WalletBase wallet,
    String signature, {
    Duration initialDelay = const Duration(seconds: 1),
    int maxRetries = 5,
  }) async {
    final solanaWallet = wallet as SolanaWallet;
    await solanaWallet.pollForTransaction(
      signature: signature,
      initialDelay: initialDelay,
      maxRetries: maxRetries,
    );
  }

  @override
  Future<void> updateTokenBalances(
    WalletBase wallet, {
    List<String>? tokenMints,
  }) async {
    final solanaWallet = wallet as SolanaWallet;
    await solanaWallet.updateTokenBalance(tokenMints: tokenMints);
  }
}
