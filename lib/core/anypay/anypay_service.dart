import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/core/anypay/anypay_parser.dart";
import "package:cake_wallet/core/anypay/anypay_resolver.dart";
import "package:cake_wallet/core/anypay/anypay_router.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/new-ui/services/wallet_switch_service.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

class AnyPayService {
  AnyPayService({
    required this.appStore,
    required this.walletSwitchService,
    AnyPayResolver? resolver,
  }) : resolver = resolver ?? AnyPayResolver();

  final AppStore appStore;
  final WalletSwitchService walletSwitchService;
  final AnyPayResolver resolver;

  Future<AnyPayEvaluation> evaluateRawInput(String input) => _evaluate(AnyPayParser.fromRaw(input));

  Future<AnyPayEvaluation> evaluatePaymentRequest(PaymentRequest request) =>
      _evaluate(AnyPayParser.fromPaymentRequest(request));

  Future<AnyPayEvaluation> evaluateForEvmChain(AnyPayRequest request, int chainId) => _evaluate(
        AnyPayRequest(
          rawInput: request.rawInput,
          paymentRequest: request.paymentRequest,
          detection: request.detection,
          chainBinding: ExplicitEvmChain(chainId),
        ),
      );

  Future<AnyPayEvaluation> _evaluate(AnyPayRequest request) async {
    try {
      final snapshot = await _buildWalletSnapshot();
      final resolution = await resolver.resolve(request, snapshot);

      return AnyPayEvaluation(
        request: request,
        decision: AnyPayRouter.route(request, snapshot, resolution),
      );
    } catch (e) {
      printV("anypay evaluation failed: $e");
      return AnyPayEvaluation(
        request: request,
        decision: const AnyPayApplyToCurrentWallet(),
      );
    }
  }

  Future<WalletSnapshot> _buildWalletSnapshot() async {
    final wallet = appStore.wallet!;
    final currentWalletIsEvm = isEVMCompatibleChain(wallet.type);

    final supportedEvmChains = <int, WalletType>{};
    if (evm != null) {
      for (final chain in evm!.getAllChains()) {
        final walletType = evm!.getWalletTypeByChainId(chain.chainId);
        if (walletType != null) {
          supportedEvmChains[chain.chainId] = walletType;
        }
      }
    }

    return WalletSnapshot(
      type: wallet.type,
      currentWalletIsEvm: currentWalletIsEvm,
      currentChainId: currentWalletIsEvm && evm != null
          ? evm!.getSelectedChainId(wallet) ?? evm!.getChainIdByWalletType(wallet.type)
          : null,
      wallets: await WalletInfo.getAll(),
      supportedEvmChains: supportedEvmChains,
      hasEvmProxy: evm != null,
      hasSolanaProxy: solana != null,
      hasTronProxy: tron != null,
    );
  }

  AnyPaySwapIntent buildSwapIntent(
    AnyPayRequest request, {
    required WalletType targetWalletType,
    int? targetChainId,
    CryptoCurrency? token,
  }) {
    final receiveCurrency = token ??
        (targetChainId != null
            ? walletTypeToCryptoCurrency(targetWalletType, chainId: targetChainId)
            : request.detection.detectedCurrency ?? walletTypeToCryptoCurrency(targetWalletType));

    final amountValue = token != null
        ? request.paymentRequest.resolveTokenAmount(token)
        : (request.amount.isNotEmpty ? request.amount : null);

    return AnyPaySwapIntent(
      request: request,
      receiveCurrency: receiveCurrency,
      targetWalletType: targetWalletType,
      receiveAmount: amountValue != null ? Money.tryParse(amountValue, receiveCurrency) : null,
    );
  }

  Future<bool> switchWalletForPayment(WalletInfo walletInfo, {int? chainId}) async {
    try {
      await walletSwitchService.switchToWallet(walletInfo);
    } catch (e) {
      printV("wallet switch failed: $e");
      return false;
    }

    final wallet = appStore.wallet!;
    if (chainId != null && evm != null && isEVMCompatibleChain(wallet.type)) {
      try {
        final node = appStore.settingsStore.getCurrentNode(wallet.type, chainId: chainId);
        await evm!.selectChain(wallet, chainId, node: node);
      } catch (e, s) {
        printV("switchWalletForPayment chain select failed: $e\n$s");
        return false;
      }
    }

    try {
      await wallet.updateBalance();
    } catch (e) {
      printV("balance refresh after wallet switch failed: $e");
    }

    return true;
  }
}
