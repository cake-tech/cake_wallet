import 'dart:async';

import 'package:cake_wallet/core/universal_address_detector.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:mobx/mobx.dart';

part 'payment_view_model.g.dart';

class PaymentViewModel = PaymentViewModelBase with _$PaymentViewModel;

abstract class PaymentViewModelBase with Store {
  PaymentViewModelBase({
    required this.appStore,
  });

  final AppStore appStore;

  @observable
  WalletType? detectedWalletType;

  @observable
  bool isProcessing = false;

  @computed
  WalletType get currentWalletType => appStore.wallet!.type;

  /// Main entry point - detect address type and check compatibility
  @action
  Future<PaymentFlowResult> processAddress(String addressData) async {
    try {
      detectedWalletType = null;
      isProcessing = true;

      // Detect address type
      final detectionResult = UniversalAddressDetector.detectAddress(addressData);

      detectedWalletType = detectionResult.detectedWalletType;

      if (!detectionResult.isValid || detectedWalletType == null) {
        return PaymentFlowResult.incompatible('Unable to detect address type');
      }

      if (!addressData.contains(':') && _isEVMAddress(detectionResult.address)) {
        return PaymentFlowResult.evmNetworkSelection(detectionResult);
      }

      // Check if current wallet is compatible
      final currentWallet = appStore.wallet;
      if (currentWallet != null && currentWallet.type == detectedWalletType) {
        return PaymentFlowResult.currentWalletCompatible();
      }

      final compatibleWallets = await getWalletsByType(detectedWalletType!);

      switch (compatibleWallets.length) {
        case 0:
          return PaymentFlowResult.noWallets(detectedWalletType!, detectionResult);
        case 1:
          return PaymentFlowResult.singleWallet(compatibleWallets.first, detectionResult);
        default:
          return PaymentFlowResult.multipleWallets(compatibleWallets, detectionResult);
      }
    } catch (e) {
      printV('PaymentViewModel error: $e');
      return PaymentFlowResult.error('Payment processing failed: $e');
    } finally {
      isProcessing = false;
    }
  }

  bool _isEVMAddress(String address) {
    return RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address);
  }

  Future<List<WalletInfo>> getWalletsByType(WalletType walletType) async {
    return (await WalletInfo.getAll()).where((wallet) => wallet.type == walletType).toList();
  }
}

class PaymentFlowResult {
  final PaymentFlowType type;
  final String? message;
  final WalletInfo? wallet;
  final List<WalletInfo> wallets;
  final WalletType? walletType;
  final AddressDetectionResult? addressDetectionResult;

  PaymentFlowResult._({
    required this.type,
    this.message,
    this.wallet,
    this.wallets = const [],
    this.walletType,
    this.addressDetectionResult,
  });

  /// EVM address detected - needs network selection
  /// We'll also take note of the number of compatible wallets for EVM ecosystem
  factory PaymentFlowResult.evmNetworkSelection(
    AddressDetectionResult addressDetectionResult, {
    List<WalletInfo>? compatibleWallets,
    WalletInfo? wallet,
  }) =>
      PaymentFlowResult._(
        type: PaymentFlowType.evmNetworkSelection,
        addressDetectionResult: addressDetectionResult,
        walletType: addressDetectionResult.detectedWalletType,
        wallets: compatibleWallets ?? [],
        wallet: wallet,
      );

  /// Current wallet is compatible
  factory PaymentFlowResult.currentWalletCompatible() =>
      PaymentFlowResult._(type: PaymentFlowType.currentWalletCompatible);

  /// Single compatible wallet available
  factory PaymentFlowResult.singleWallet(
    WalletInfo wallet,
    AddressDetectionResult addressDetectionResult,
  ) =>
      PaymentFlowResult._(
          type: PaymentFlowType.singleWallet,
          wallet: wallet,
          walletType: wallet.type,
          addressDetectionResult: addressDetectionResult);

  /// Multiple compatible wallets available
  factory PaymentFlowResult.multipleWallets(
          List<WalletInfo> wallets, AddressDetectionResult addressDetectionResult) =>
      PaymentFlowResult._(
          type: PaymentFlowType.multipleWallets,
          wallets: wallets,
          walletType: wallets.first.type,
          addressDetectionResult: addressDetectionResult);

  /// No compatible wallets available
  factory PaymentFlowResult.noWallets(
          WalletType walletType, AddressDetectionResult addressDetectionResult) =>
      PaymentFlowResult._(
          type: PaymentFlowType.noWallets,
          walletType: walletType,
          addressDetectionResult: addressDetectionResult);

  /// Error occurred
  factory PaymentFlowResult.error(String message) =>
      PaymentFlowResult._(type: PaymentFlowType.error, message: message);

  /// Incompatible address
  factory PaymentFlowResult.incompatible(String message) =>
      PaymentFlowResult._(type: PaymentFlowType.incompatible, message: message);

  CryptoCurrency? get detectedCurrency {
    if (type == PaymentFlowType.evmNetworkSelection) {
      return addressDetectionResult?.detectedCurrency;
    }
    if (walletType != null) {
      if (isEVMCompatibleChain(walletType!)) {
        final chainId = evm!.getChainIdByWalletType(walletType!);
        return walletTypeToCryptoCurrency(walletType!, chainId: chainId);
      }

      return walletTypeToCryptoCurrency(walletType!);
    }
    return null;
  }
}

enum PaymentFlowType {
  currentWalletCompatible,
  singleWallet,
  multipleWallets,
  noWallets,
  evmNetworkSelection,
  error,
  incompatible,
}
