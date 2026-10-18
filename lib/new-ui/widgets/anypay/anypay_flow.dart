import "package:cake_wallet/core/address_resolver/address_resolver_service.dart";
import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/core/anypay/anypay_service.dart";
import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/swap_page.dart";
import "package:cake_wallet/new-ui/widgets/anypay/evm_address_detected_sheet.dart";
import "package:cake_wallet/new-ui/widgets/anypay/network_decision_page.dart";
import "package:cake_wallet/new-ui/widgets/anypay/select_recipient_network_sheet.dart";
import "package:cake_wallet/new-ui/widgets/anypay/switch_network_wallet_page.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_from_send_args.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/exchange/exchange_view_model.dart";
import "package:cake_wallet/view_model/send/send_view_model.dart";
import "package:cake_wallet/view_model/wallet_switcher_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class AnyPayFormFill {
  const AnyPayFormFill({
    required this.request,
    this.token,
    this.fallbackCurrency,
    this.amountOverride,
  });

  final AnyPayRequest request;
  final CryptoCurrency? token;
  final CryptoCurrency? fallbackCurrency;
  final String? amountOverride;
}

class AnyPayFlow {
  AnyPayFlow({
    required this.anyPayService,
    required this.sendViewModel,
    required this.authService,
    required this.walletSwitcherViewModel,
  });

  final AnyPayService anyPayService;
  final SendViewModel sendViewModel;
  final AuthService authService;
  final WalletSwitcherViewModel walletSwitcherViewModel;

  bool _isSwitchingWallet = false;

  bool get isSwitchingWallet => _isSwitchingWallet;

  Future<AnyPayFormFill?> handleEvaluation(
    BuildContext context,
    AnyPayEvaluation evaluation, {
    CryptoCurrency? fallbackCurrency,
  }) async {
    final request = evaluation.request;

    if (!request.rawInput.toLowerCase().startsWith("ethereum:") &&
        (request.rawInput.contains("@") || request.address.contains("@"))) {
      return null;
    }

    try {
      return await _handleDecision(context, evaluation, fallbackCurrency);
    } catch (e) {
      printV("Payment flow error: $e");
      return AnyPayFormFill(request: request);
    }
  }

  Future<AnyPayFormFill?> _handleDecision(
    BuildContext context,
    AnyPayEvaluation evaluation,
    CryptoCurrency? fallbackCurrency,
  ) async {
    final request = evaluation.request;

    switch (evaluation.decision) {
      case final AnyPayApplyToCurrentWallet decision:
        if (request.isLightning) {
          _enterLightningMode();
        }
        return AnyPayFormFill(
          request: request,
          token: decision.token,
          fallbackCurrency: fallbackCurrency ?? decision.fallbackCurrency,
          amountOverride: decision.amountOverride,
        );
      case AnyPayEvmNetworkChoice():
        return _pickEvmNetwork(context, request);
      case final AnyPayCrossChainPayment decision:
        return _handleCrossChain(context, request, decision, fallbackCurrency);
      case final AnyPayUnsupportedNetwork decision:
        _showError(
          context,
          S.of(context).unsupported_network_requested(decision.chainId.toString()),
        );
        return null;
      case AnyPayUnsupportedToken():
        _showError(context, S.of(context).unsupported_token_requested);
        return null;
      case AnyPayEmptyInput():
        return null;
    }
  }

  Future<AnyPayFormFill?> _pickEvmNetwork(BuildContext context, AnyPayRequest request) async {
    final chains = evm!.getAllChains();
    final networks = chains.map((chain) {
      final walletType = evm!.getWalletTypeByChainId(chain.chainId) ?? sendViewModel.wallet.type;
      return RecipientNetworkItem(
        chainId: chain.chainId,
        name: chain.name,
        iconPath: getCryptoCurrencyIconForWalletListItem(walletType, chainId: chain.chainId),
        chainBadgeIconPath: symbolIconPathForWalletType(walletType),
      );
    }).toList();

    final selectedChainId =
        await EvmAddressDetectedSheet.show(context: context, networks: networks);
    if (!context.mounted || selectedChainId == null) {
      return null;
    }

    final target = chains.firstWhere(
      (chain) => chain.chainId == selectedChainId,
      orElse: () => chains.first,
    );

    final evaluation = await anyPayService.evaluateForEvmChain(request, target.chainId);
    if (!context.mounted) {
      return null;
    }
    return handleEvaluation(context, evaluation, fallbackCurrency: target.currency);
  }

  Future<AnyPayFormFill?> _handleCrossChain(
    BuildContext context,
    AnyPayRequest request,
    AnyPayCrossChainPayment decision,
    CryptoCurrency? fallbackCurrency,
  ) async {
    final destinationType = decision.targetWalletType;
    final isEvmTarget = isEVMCompatibleChain(destinationType);
    final destinationNetworkName = networkDisplayName(destinationType, decision.targetChainId);
    final destinationNetworkIcon = symbolIconPathForWalletType(destinationType) ?? "";

    if (!decision.canSwap && !decision.hasCompatibleWallet) {
      _showError(
        context,
        S.of(context).swap_unavailable_needs_network_wallet(destinationNetworkName),
      );
      return null;
    }

    final currentType = sendViewModel.wallet.type;
    final currentChainId = isEVMCompatibleChain(currentType) ? _currentEvmChainId() : null;
    final currentNetworkName = networkDisplayName(currentType, currentChainId);
    final currentNetworkIcon = symbolIconPathForWalletType(currentType) ?? "";

    if (!decision.hasCompatibleWallet) {
      final swapConfirmTitle = isEvmTarget
          ? S.of(context).swap_from_network(currentNetworkName)
          : S.of(context).network_address_detected(destinationNetworkName);
      final swapConfirmPrimary = isEvmTarget
          ? S.of(context).continue_to_swap
          : S.of(context).swap_from_network(currentNetworkName);

      await Navigator.of(context).push<void>(
        CupertinoPageRoute(
          builder: (pageContext) => NetworkDecisionPage(
            title: swapConfirmTitle,
            description: S.of(context).swap_from_network_description(
                  destinationNetworkName,
                  currentNetworkName,
                ),
            destinationIconPath: destinationNetworkIcon,
            currentIconPath: currentNetworkIcon,
            primaryText: swapConfirmPrimary,
            primaryIconPath: isEvmTarget ? null : "assets/new-ui/swap_arrows.svg",
            onPrimary: () => _openSwap(pageContext, request, decision),
            secondaryText: S.of(context).cancel,
          ),
        ),
      );
      return null;
    }

    final decisionTitle = isEvmTarget
        ? S.of(context).send_to_network(destinationNetworkName)
        : S.of(context).network_address_detected(destinationNetworkName);

    final selectedWallet = await Navigator.of(context).push<WalletInfo>(
      CupertinoPageRoute(
        builder: (pageContext) => NetworkDecisionPage(
          title: decisionTitle,
          description: decision.canSwap
              ? S.of(context).send_to_network_description(
                    destinationNetworkName,
                    currentNetworkName,
                  )
              : S.of(context).swap_unavailable_switch_to_network(destinationNetworkName),
          destinationIconPath: destinationNetworkIcon,
          primaryText: S.of(context).switch_to_x_wallet(destinationNetworkName),
          primaryIconPath: "assets/new-ui/wallet_filled.svg",
          onPrimary: () => _pickDestinationWallet(pageContext, decision, destinationNetworkName),
          secondaryText: decision.canSwap
              ? S.of(context).swap_from_network(currentNetworkName)
              : S.of(context).cancel,
          secondaryIconPath: decision.canSwap ? "assets/new-ui/swap_arrows.svg" : null,
          onSecondary: decision.canSwap ? () => _openSwap(pageContext, request, decision) : null,
        ),
      ),
    );

    if (selectedWallet == null || !context.mounted) {
      return null;
    }

    return _switchWallet(context, selectedWallet, request, decision, fallbackCurrency);
  }

  Future<void> _pickDestinationWallet(
    BuildContext pageContext,
    AnyPayCrossChainPayment decision,
    String networkName,
  ) async {
    WalletInfo? destinationWalletInfo;
    if (decision.wallets.length > 1) {
      destinationWalletInfo = await SwitchNetworkWalletPage.push(
        context: pageContext,
        networkName: networkName,
        targetIconPath: symbolIconPathForWalletType(decision.targetWalletType) ?? "",
        wallets: decision.wallets,
      );
    } else {
      destinationWalletInfo = decision.wallets.first;
    }

    if (destinationWalletInfo == null || !pageContext.mounted) {
      return;
    }

    Navigator.of(pageContext).pop(destinationWalletInfo);
  }

  Future<AnyPayFormFill?> _switchWallet(
    BuildContext context,
    WalletInfo walletInfo,
    AnyPayRequest request,
    AnyPayCrossChainPayment decision,
    CryptoCurrency? fallbackCurrency,
  ) async {
    if (request.isLightning) {
      _enterLightningMode();
    }

    _isSwitchingWallet = true;
    BuildContext? loadingSheetContext;
    bool completedFlow = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || completedFlow) {
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        builder: (sheetContext) {
          if (completedFlow) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(sheetContext)) {
                Navigator.of(sheetContext).pop();
              }
            });
            return const SizedBox.shrink();
          }
          loadingSheetContext = sheetContext;
          return LoadingBottomSheet(titleText: S.of(sheetContext).loading_your_wallet);
        },
      );
    });

    bool success = false;
    try {
      success = await anyPayService.switchWalletForPayment(
        walletInfo,
        chainId: decision.targetChainId,
      );
    } finally {
      _isSwitchingWallet = false;
      completedFlow = true;
      if (loadingSheetContext != null &&
          loadingSheetContext!.mounted &&
          Navigator.canPop(loadingSheetContext!)) {
        Navigator.of(loadingSheetContext!).pop();
      }
      loadingSheetContext = null;
    }

    if (!context.mounted) {
      return null;
    }

    if (!success) {
      _showError(context, S.of(context).network_switch_failed);
      return null;
    }

    return AnyPayFormFill(
      request: request,
      token: decision.token,
      fallbackCurrency: fallbackCurrency ?? request.detection.detectedCurrency,
      amountOverride: decision.amountOverride,
    );
  }

  Future<void> _openSwap(
    BuildContext presentContext,
    AnyPayRequest request,
    AnyPayCrossChainPayment decision,
  ) async {
    if (!presentContext.mounted) {
      return;
    }

    if (request.hasContract && decision.token == null) {
      _showError(presentContext, S.of(presentContext).unsupported_token_requested);
      return;
    }

    final intent = anyPayService.buildSwapIntent(
      request,
      targetWalletType: decision.targetWalletType,
      targetChainId: decision.targetChainId,
      token: decision.token,
    );

    final page = NewSwapPage(
      getIt.get<ExchangeViewModel>(),
      authService,
      getIt.get<AddressResolverService>(),
      null,
      walletSwitcherViewModel: walletSwitcherViewModel,
      fromSend: SwapFromSendArgs.fromIntent(intent),
      balanceViewModel: sendViewModel.balanceViewModel,
    );
    await Navigator.of(presentContext).push<void>(
      CupertinoPageRoute(
        builder: (context) => Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(bottom: false, child: page),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }

    showPopUp<void>(
      context: context,
      builder: (context) => AlertWithOneAction(
        alertTitle: S.of(context).error,
        alertContent: message,
        buttonText: S.of(context).ok,
        buttonAction: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _enterLightningMode() {
    sendViewModel.selectedCryptoCurrency = CryptoCurrency.btcln;
    sendViewModel.coinTypeToSpendFrom = UnspentCoinType.lightning;
  }

  int _currentEvmChainId() {
    final wallet = sendViewModel.wallet;
    return evm!.getSelectedChainId(wallet) ?? evm!.getChainIdByWalletType(wallet.type);
  }
}
