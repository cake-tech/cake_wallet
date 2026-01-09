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
  PaymentViewModelBase({required this.appStore});

  final AppStore appStore;

  @observable
  WalletType? detectedWalletType;

  @observable
  AddressDetectionResult? _lastDetectionResult;

  @computed
  int? get detectedChainId {
    if (detectedWalletType == null) return null;

    if (!isEVMCompatibleChain(detectedWalletType!)) return null;

    if (_lastDetectionResult?.chainId != null) {
      return _lastDetectionResult!.chainId;
    }

    // If detected wallet type is EVM-compatible, get chainId from detected currency
    if (_lastDetectionResult?.detectedCurrency != null) {
      return getChainIdByCryptoCurrency(_lastDetectionResult!.detectedCurrency!);
    }

    return evm!.getChainIdByWalletType(detectedWalletType!);
  }

  @observable
  bool isProcessing = false;

  @computed
  WalletType get currentWalletType => appStore.wallet!.type;

  @computed
  int? get currentChainId {
    if (!isEVMCompatibleChain(currentWalletType)) return null;

    return evm!.getSelectedChainId(appStore.wallet!);
  }

  /// Main entry point - detect address type and check compatibility
  @action
  Future<PaymentFlowResult> processAddress(String addressData) async {
    try {
      detectedWalletType = null;
      isProcessing = true;

      // Detect address type
      final detectionResult = UniversalAddressDetector.detectAddress(addressData);

      _lastDetectionResult = detectionResult;
      detectedWalletType = detectionResult.detectedWalletType;

      if (!detectionResult.isValid || detectedWalletType == null) {
        return PaymentFlowResult.incompatible('Unable to detect address type');
      }

      final currentWallet = appStore.wallet;

      if (isEVMCompatibleChain(detectedWalletType!)) {
        final isRawEvmInput = !addressData.contains(':') && _isEVMAddress(detectionResult.address);

        // Check if the current wallet is also EVM
        if (currentWallet != null && isEVMCompatibleChain(currentWallet.type)) {
          final currentChainId = evm!.getSelectedChainId(currentWallet);
          final detectedChainIdValue = this.detectedChainId;

          if (detectedChainIdValue != null && currentChainId != null) {
            // For raw EVM address input that only defaulted to chainId 1,
            // always force the EVM ecosystem bottom sheet so the user
            // can pick the actual network and token.
            if (isRawEvmInput && detectedChainIdValue == 1) {
              final allEVMWallets = await getEVMCompatibleWallets();

              final currentWalletInfo = currentWallet.walletInfo;

              final otherEVMWallets =
                  allEVMWallets.where((w) => w.name != currentWallet.name).toList();

              return PaymentFlowResult.evmNetworkSelection(
                detectionResult,
                compatibleWallets: otherEVMWallets,
                wallet: currentWalletInfo,
              );
            }

            if (detectedChainIdValue == currentChainId) {
              return PaymentFlowResult.currentWalletCompatible();
            }

            final allEVMWallets = await getEVMCompatibleWallets();

            final currentWalletInfo = currentWallet.walletInfo;

            final otherEVMWallets =
                allEVMWallets.where((w) => w.name != currentWallet.name).toList();

            return PaymentFlowResult.evmNetworkSelection(
              detectionResult,
              compatibleWallets: otherEVMWallets,
              wallet: currentWalletInfo,
            );
          }
        }

        // If the current wallet is not EVM or the chainId comparison failed
        // We proceed with other checks
        if (!addressData.contains(':') && _isEVMAddress(detectionResult.address)) {
          final allEVMWallets = await getEVMCompatibleWallets();
          return PaymentFlowResult.evmNetworkSelection(
            detectionResult,
            compatibleWallets: allEVMWallets,
          );
        }

        // For EVM URIs, show network selection
        final allEVMWallets = await getEVMCompatibleWallets();
        return PaymentFlowResult.evmNetworkSelection(
          detectionResult,
          compatibleWallets: allEVMWallets,
        );
      }

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

  @action
  Future<void> selectChain() async {
    if (detectedWalletType == null) return;

    final node =
        appStore.settingsStore.getCurrentNode(detectedWalletType!, chainId: detectedChainId);

    await evm!.selectChain(appStore.wallet!, detectedChainId!, node: node);
  }

  bool _isEVMAddress(String address) {
    return RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address);
  }

  Future<List<WalletInfo>> getWalletsByType(WalletType walletType) async {
    return (await WalletInfo.getAll()).where((wallet) => wallet.type == walletType).toList();
  }

  Future<List<WalletInfo>> getEVMCompatibleWallets() async {
    final allWallets = await WalletInfo.getAll();
    return allWallets.where((wallet) => isEVMCompatibleChain(wallet.type)).toList();
  }
}

class PaymentFlowResult {
  final PaymentFlowType type;
  final String? message;
  final WalletInfo? wallet;
  final int? chainId;
  final List<WalletInfo> wallets;
  final WalletType? walletType;
  final AddressDetectionResult? addressDetectionResult;

  PaymentFlowResult._({
    required this.type,
    this.message,
    this.wallet,
    this.chainId,
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
  }) {
    int? chainId = addressDetectionResult.chainId;
    if (chainId == null && addressDetectionResult.detectedCurrency != null) {
      chainId = getChainIdByCryptoCurrency(addressDetectionResult.detectedCurrency!);
    }
    if (chainId == null && addressDetectionResult.detectedWalletType != null) {
      chainId = evm!.getChainIdByWalletType(addressDetectionResult.detectedWalletType!);
    }

    return PaymentFlowResult._(
      type: PaymentFlowType.evmNetworkSelection,
      addressDetectionResult: addressDetectionResult,
      walletType: addressDetectionResult.detectedWalletType,
      chainId: chainId,
      wallets: compatibleWallets ?? [],
      wallet: wallet,
    );
  }

  /// Current wallet is compatible
  factory PaymentFlowResult.currentWalletCompatible() =>
      PaymentFlowResult._(type: PaymentFlowType.currentWalletCompatible);

  /// Single compatible wallet available
  factory PaymentFlowResult.singleWallet(
    WalletInfo wallet,
    AddressDetectionResult addressDetectionResult,
  ) {
    int? chainId = addressDetectionResult.chainId;
    if (chainId == null && addressDetectionResult.detectedCurrency != null) {
      chainId = getChainIdByCryptoCurrency(addressDetectionResult.detectedCurrency!);
    }
    if (chainId == null) {
      chainId = evm!.getChainIdByWalletType(wallet.type);
    }

    return PaymentFlowResult._(
      type: PaymentFlowType.singleWallet,
      wallet: wallet,
      walletType: wallet.type,
      chainId: chainId,
      addressDetectionResult: addressDetectionResult,
    );
  }

  /// Multiple compatible wallets available
  factory PaymentFlowResult.multipleWallets(
    List<WalletInfo> wallets,
    AddressDetectionResult addressDetectionResult,
  ) {
    int? chainId = addressDetectionResult.chainId;
    if (chainId == null && addressDetectionResult.detectedCurrency != null) {
      chainId = getChainIdByCryptoCurrency(addressDetectionResult.detectedCurrency!);
    }
    if (chainId == null) {
      chainId = evm!.getChainIdByWalletType(wallets.first.type);
    }

    return PaymentFlowResult._(
      type: PaymentFlowType.multipleWallets,
      wallets: wallets,
      walletType: wallets.first.type,
      addressDetectionResult: addressDetectionResult,
      chainId: chainId,
    );
  }

  /// No compatible wallets available
  factory PaymentFlowResult.noWallets(
    WalletType walletType,
    AddressDetectionResult addressDetectionResult,
  ) {
    int? chainId = addressDetectionResult.chainId;
    if (chainId == null && addressDetectionResult.detectedCurrency != null) {
      chainId = getChainIdByCryptoCurrency(addressDetectionResult.detectedCurrency!);
    }
    if (chainId == null) {
      chainId = evm!.getChainIdByWalletType(walletType);
    }

    return PaymentFlowResult._(
      type: PaymentFlowType.noWallets,
      walletType: walletType,
      addressDetectionResult: addressDetectionResult,
      chainId: chainId,
    );
  }

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
