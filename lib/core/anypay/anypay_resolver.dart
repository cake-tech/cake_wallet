import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/core/anypay/anypay_router.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/utils/token_utilities.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";

typedef TokenLookup = Future<CryptoCurrency?> Function({
  required WalletType walletType,
  required String address,
});
typedef EvmChainIdLookup = Future<int?> Function(String contractAddress, {int? excludingChainId});

class AnyPayResolver {
  AnyPayResolver({
    TokenLookup? findTokenByAddress,
    EvmChainIdLookup? findEvmChainIdForContract,
  })  : _findTokenByAddress = findTokenByAddress ?? TokenUtilities.findTokenByAddress,
        _findEvmChainIdForContract =
            findEvmChainIdForContract ?? TokenUtilities.findEvmChainIdForContract;

  final TokenLookup _findTokenByAddress;
  final EvmChainIdLookup _findEvmChainIdForContract;

  Future<AnyPayResolution> resolve(AnyPayRequest request, WalletSnapshot snapshot) async {
    if (!request.hasContract) {
      return const NoTokenRequested();
    }

    final contract = request.contractAddress!;
    final detectedType = request.detection.detectedWalletType;

    if (detectedType != null && isEVMCompatibleChain(detectedType)) {
      return _resolveEvm(request, snapshot, contract);
    }

    final token = await _findTokenByAddress(
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
      final token = await _findTokenByAddress(walletType: lookupType, address: contract);
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
      final reboundChainId =
          await _findEvmChainIdForContract(contract, excludingChainId: requestedChainId);
      final reboundType =
          reboundChainId != null ? snapshot.supportedEvmChains[reboundChainId] : null;
      if (reboundType != null) {
        final token = await _findTokenByAddress(walletType: reboundType, address: contract);
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
