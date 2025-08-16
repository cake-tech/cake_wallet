import 'dart:async';

import 'package:cake_wallet/core/universal_address_detector.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'payment_view_model.g.dart';

class PaymentViewModel = PaymentViewModelBase with _$PaymentViewModel;

abstract class PaymentViewModelBase with Store {
  PaymentViewModelBase({
    required this.appStore,
    required this.walletInfoSource,
  });

  final AppStore appStore;
  final Box<WalletInfo> walletInfoSource;

  @observable
  WalletType? detectedWalletType;

  @observable
  bool isProcessing = false;

  @computed
  WalletType get currentWalletType => appStore.wallet!.type;

  /// Main entry point - detect address type and check compatibility
  @action
  Future<PaymentFlowResult> processAddress(String address) async {
    try {
      detectedWalletType = null;
      isProcessing = true;

      // Detect address type
      final detectionResult = UniversalAddressDetector.detectAddress(address);

      if (!detectionResult.isValid || detectionResult.detectedWalletType == null) {
        return PaymentFlowResult.incompatible('Unable to detect address type');
      }

      detectedWalletType = detectionResult.detectedWalletType!;

      // Check if current wallet is compatible
      final currentWallet = appStore.wallet;
      if (currentWallet != null && currentWallet.type == detectedWalletType) {
        return PaymentFlowResult.currentWalletCompatible();
      }

      final compatibleWallets = getWalletsByType(detectedWalletType!);

      switch (compatibleWallets.length) {
        case 0:
          return PaymentFlowResult.noWallets(detectedWalletType!);
        case 1:
          return PaymentFlowResult.singleWallet(compatibleWallets.first);
        default:
          return PaymentFlowResult.multipleWallets(compatibleWallets);
      }
    } catch (e) {
      printV('PaymentViewModel error: $e');
      return PaymentFlowResult.error('Payment processing failed: $e');
    } finally {
      isProcessing = false;
    }
  }

  List<WalletInfo> getWalletsByType(WalletType walletType) {
    return walletInfoSource.values.where((wallet) => wallet.type == walletType).toList();
  }
}

class PaymentFlowResult {
  final PaymentFlowType type;
  final String? message;
  final WalletInfo? wallet;
  final List<WalletInfo> wallets;
  final WalletType? walletType;

  PaymentFlowResult._({
    required this.type,
    this.message,
    this.wallet,
    this.wallets = const [],
    this.walletType,
  });

  /// Current wallet is compatible
  factory PaymentFlowResult.currentWalletCompatible() => PaymentFlowResult._(type: PaymentFlowType.currentWalletCompatible);

  /// Single compatible wallet available
  factory PaymentFlowResult.singleWallet(WalletInfo wallet) =>
      PaymentFlowResult._(type: PaymentFlowType.singleWallet, wallet: wallet);

  /// Multiple compatible wallets available
  factory PaymentFlowResult.multipleWallets(List<WalletInfo> wallets) =>
      PaymentFlowResult._(type: PaymentFlowType.multipleWallets, wallets: wallets);

  /// No compatible wallets available
  factory PaymentFlowResult.noWallets(WalletType walletType) =>
      PaymentFlowResult._(type: PaymentFlowType.noWallets, walletType: walletType);

  /// Error occurred
  factory PaymentFlowResult.error(String message) =>
      PaymentFlowResult._(type: PaymentFlowType.error, message: message);

  /// Incompatible address
  factory PaymentFlowResult.incompatible(String message) =>
      PaymentFlowResult._(type: PaymentFlowType.incompatible, message: message);
}

enum PaymentFlowType {
  currentWalletCompatible,
  singleWallet,
  multipleWallets,
  noWallets,
  error,
  incompatible,
}
