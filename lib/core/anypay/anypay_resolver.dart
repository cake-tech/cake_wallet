import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/core/anypay/anypay_router.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/utils/token_utilities.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";

class AnyPayResolver {
  AnyPayResolver({AnyPayTokenLookup? tokenLookup})
      : _tokenLookup = tokenLookup ?? const TokenUtilitiesLookup();

  final AnyPayTokenLookup _tokenLookup;

  Future<AnyPayResolution> resolve(AnyPayRequest request, WalletSnapshot snapshot) async {
    if (!request.hasContract) {
      return const NoTokenRequested();
    }

    final contract = request.contractAddress!;
    final detectedType = request.detection.detectedWalletType;

    if (detectedType != null && isEVMCompatibleChain(detectedType)) {
      return _resolveEvm(request, snapshot, contract);
    }

    final token = await _tokenLookup.findTokenByAddress(
      walletType: detectedType ?? snapshot.type,
      address: contract,
    );

    if (token == null) {
      return TokenUnknown(contract);
    }

    return TokenResolved(
      token: token,
      amountOverride: request.paymentRequest.resolveTokenAmount(token),
    );
  }

  Future<AnyPayResolution> _resolveEvm(
    AnyPayRequest request,
    WalletSnapshot snapshot,
    String contract,
  ) async {
    final requestedChainId = AnyPayRouter.requestedEvmChainId(request, snapshot) ?? 1;

    final lookupType = snapshot.supportedEvmChains[requestedChainId];
    if (lookupType != null) {
      final token =
          await _tokenLookup.findTokenByAddress(walletType: lookupType, address: contract);
      if (token != null) {
        return TokenResolved(
          token: token,
          chainId: requestedChainId,
          amountOverride: request.paymentRequest.resolveTokenAmount(token),
        );
      }
    }

    // The QRs from our old app versions omit the chainId on mainnet, so a contract the target
    // network does not know may still belong to another EVM network.
    if (request.chainBinding is ChainlessEvm) {
      final reboundChainId = await _tokenLookup.findEvmChainIdForContract(
        contract,
        excludingChainId: requestedChainId,
      );
      final reboundType =
          reboundChainId != null ? snapshot.supportedEvmChains[reboundChainId] : null;
      if (reboundType != null) {
        final token =
            await _tokenLookup.findTokenByAddress(walletType: reboundType, address: contract);
        if (token != null) {
          return TokenResolved(
            token: token,
            chainId: reboundChainId,
            amountOverride: request.paymentRequest.resolveTokenAmount(token),
          );
        }
      }
    }

    return TokenUnknown(contract);
  }
}

abstract class AnyPayTokenLookup {
  Future<CryptoCurrency?> findTokenByAddress({
    required WalletType walletType,
    required String address,
  });

  Future<int?> findEvmChainIdForContract(String contractAddress, {int? excludingChainId});
}

class TokenUtilitiesLookup implements AnyPayTokenLookup {
  const TokenUtilitiesLookup();

  @override
  Future<CryptoCurrency?> findTokenByAddress({
    required WalletType walletType,
    required String address,
  }) =>
      TokenUtilities.findTokenByAddress(walletType: walletType, address: address);

  @override
  Future<int?> findEvmChainIdForContract(String contractAddress, {int? excludingChainId}) =>
      TokenUtilities.findEvmChainIdForContract(contractAddress, excludingChainId: excludingChainId);
}
