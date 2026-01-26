import 'package:cake_wallet/core/universal_address_detector.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/qr_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/utils/token_utilities.dart';
import 'package:cake_wallet/view_model/payment/payment_view_model.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class TokenSelectionBottomSheet extends BaseBottomSheet {
  TokenSelectionBottomSheet({
    Key? key,
    required this.paymentViewModel,
    required this.paymentRequest,
    required this.onNext,
    this.fixedNetwork,
  }) : super(
          titleText: '',
          footerType: FooterType.none,
          maxHeight: 900,
        );

  final PaymentViewModel paymentViewModel;
  final PaymentRequest paymentRequest;
  final Function(PaymentFlowResult) onNext;
  final WalletType? fixedNetwork;

  @override
  Widget contentWidget(BuildContext context) {
    return _TokenSelectionContent(
      paymentViewModel: paymentViewModel,
      paymentRequest: paymentRequest,
      onNext: onNext,
      fixedNetwork: fixedNetwork,
    );
  }
}

class _TokenSelectionContent extends StatefulWidget {
  const _TokenSelectionContent({
    required this.paymentViewModel,
    required this.paymentRequest,
    required this.onNext,
    this.fixedNetwork,
  });

  final PaymentViewModel paymentViewModel;
  final PaymentRequest paymentRequest;
  final Function(PaymentFlowResult) onNext;
  final WalletType? fixedNetwork;

  @override
  State<_TokenSelectionContent> createState() => _TokenSelectionContentState();
}

class _TokenSelectionContentState extends State<_TokenSelectionContent> {
  WalletType? selectedNetwork;
  CryptoCurrency? selectedToken;
  bool isLoadingTokens = false;
  String? tokenLoadError;

  @override
  void initState() {
    super.initState();
    selectedNetwork = widget.fixedNetwork ?? WalletType.ethereum;
    _autoSelectToken();
  }

  bool get _isNetworkSelectable => widget.fixedNetwork == null || isEVMCompatibleChain(widget.fixedNetwork!);

  Future<void> _autoSelectToken() async {
    if (selectedNetwork == null) return;

    setState(() {
      isLoadingTokens = true;
      tokenLoadError = null;
    });

    try {
      final tokens = await TokenUtilities.getAvailableTokensForNetwork(
        selectedNetwork!,
      );

      if (tokens.isEmpty) {
        setState(() {
          tokenLoadError = 'No tokens available';
          isLoadingTokens = false;
        });
        return;
      }

      setState(() {
        selectedToken = tokens.first;
        isLoadingTokens = false;
      });
    } catch (e) {
      printV('Auto-select token error: $e');
      setState(() {
        tokenLoadError = 'Failed to load tokens';
        isLoadingTokens = false;
        selectedToken = walletTypeToCryptoCurrency(selectedNetwork!);
      });
    }
  }

  String _getNetworkTitle() {
    if (selectedNetwork == null) return S.current.select_network;
    return walletTypeToString(selectedNetwork!);
  }

  String _getEcosystemTitle() {
    if (selectedNetwork == WalletType.solana) {
      return 'Solana\n${S.current.address_detected.toLowerCase()}';
    }
    if (selectedNetwork == WalletType.tron) {
      return 'Tron\n${S.current.address_detected.toLowerCase()}';
    }
    return '${S.current.ethereum_ecosystem}\n${S.current.address_detected.toLowerCase()}';
  }

  String _getEcosystemDescription() {
    if (selectedNetwork == WalletType.solana) {
      return 'Select a token to send on Solana network';
    }
    if (selectedNetwork == WalletType.tron) {
      return 'Select a token to send on Tron network';
    }
    return S.current.evm_ecosystem_description;
  }

  String _getNetworkIcon() {
    if (selectedNetwork == null) return 'assets/images/eth_chain_mono.svg';
    return getChainMonoImage(selectedNetwork!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CakeImageWidget(
            imageUrl: _getNetworkIcon(),
            width: 50,
            height: 50,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _getEcosystemTitle(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            _getEcosystemDescription(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.0,
                ),
          ),
          const SizedBox(height: 32),
          TokenSelectionTileWidget(
            value: _getNetworkTitle(),
            imagePath: selectedNetwork != null ? getChainMonoImage(selectedNetwork!) : null,
            color: selectedNetwork != null ? Theme.of(context).colorScheme.primary : null,
            enabled: _isNetworkSelectable,
            onTap: _isNetworkSelectable ? () => _showNetworkSelection(context) : null,
          ),
          const SizedBox(height: 16),
          TokenSelectionTileWidget(
            imagePath: selectedToken?.iconPath,
            value: selectedToken != null ? selectedToken!.title : S.current.select_token,
            enabled: selectedNetwork != null && !isLoadingTokens,
            onTap: isLoadingTokens ? null : () => _showTokenSelection(context),
            color: selectedToken == null ? Theme.of(context).colorScheme.primary : null,
          ),
          if (isLoadingTokens) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
          if (tokenLoadError != null) ...[
            const SizedBox(height: 16),
            Text(
              tokenLoadError!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          const SizedBox(height: 32),
          PrimaryButton(
            text: S.current.restore_next,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: selectedNetwork != null && selectedToken != null && !isLoadingTokens
                ? () async => await _handleNext(context)
                : null,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _showNetworkSelection(BuildContext context) async {
    if (!_isNetworkSelectable) return;

    final evmNetworks =
        availableWalletTypes.where((walletType) => isEVMCompatibleChain(walletType)).toList();
    final selectedIndex = evmNetworks.indexOf(selectedNetwork ?? WalletType.ethereum);

    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return Picker(
          items: evmNetworks,
          displayItem: (WalletType network) => walletTypeToString(network),
          selectedAtIndex: selectedIndex,
          title: S.current.select_network,
          closeOnItemSelected: true,
          hasTitleSpacing: true,
          images: evmNetworks
              .map((network) => CakeImageWidget(
                  imageUrl: getChainMonoImage(network),
                  width: 20,
                  height: 20,
                  color: Theme.of(context).colorScheme.primary))
              .toList(),
          onItemSelected: (WalletType network) {
            setState(() {
              selectedNetwork = network;
              selectedToken = null;
            });
            _autoSelectToken();
          },
        );
      },
    );
  }

  void _showTokenSelection(BuildContext context) async {
    if (selectedNetwork == null || isLoadingTokens) return;

    setState(() {
      isLoadingTokens = true;
    });

    try {
      final availableTokens = await TokenUtilities.getAvailableTokensForNetwork(
        selectedNetwork!,
      );

      if (availableTokens.isEmpty) {
        setState(() {
          isLoadingTokens = false;
        });
        await showPopUp<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(S.current.error),
            content: const Text('No tokens available for this network'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(S.current.ok),
              ),
            ],
          ),
        );
        return;
      }

      final selectedIndex = selectedToken != null ? availableTokens.indexOf(selectedToken!) : 0;

      setState(() {
        isLoadingTokens = false;
      });

      await showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return CurrencyPicker(
            selectedAtIndex: selectedIndex >= 0 ? selectedIndex : 0,
            items: availableTokens.cast<Currency>(),
            hintText: S.current.add_token,
            onItemSelected: (Currency currency) {
              setState(() {
                selectedToken = currency as CryptoCurrency;
              });
            },
          );
        },
      );
    } catch (e) {
      printV('Error showing token selection: $e');
      setState(() {
        isLoadingTokens = false;
        tokenLoadError = 'Failed to load tokens';
      });
    }
  }

  Future<void> _handleNext(BuildContext context) async {
    if (selectedNetwork == null || selectedToken == null) return;

    Navigator.of(context).pop();

    final compatibleWallets = await widget.paymentViewModel.getWalletsByType(selectedNetwork!);

    PaymentFlowResult newResult;

    if (selectedNetwork == WalletType.solana) {
      newResult = PaymentFlowResult.solanaTokenSelection(
        AddressDetectionResult(
          address: widget.paymentRequest.address,
          detectedWalletType: WalletType.solana,
          detectedCurrency: selectedToken!,
          isValid: true,
          amount: widget.paymentRequest.amount,
          note: widget.paymentRequest.note,
          scheme: widget.paymentRequest.scheme,
          pjUri: widget.paymentRequest.pjUri,
          callbackUrl: widget.paymentRequest.callbackUrl,
          callbackMessage: widget.paymentRequest.callbackMessage,
        ),
        compatibleWallets: compatibleWallets,
        wallet: compatibleWallets.isNotEmpty ? compatibleWallets.first : null,
      );
    } else if (selectedNetwork == WalletType.tron) {
      newResult = PaymentFlowResult.tronTokenSelection(
        AddressDetectionResult(
          address: widget.paymentRequest.address,
          detectedWalletType: WalletType.tron,
          detectedCurrency: selectedToken!,
          isValid: true,
          amount: widget.paymentRequest.amount,
          note: widget.paymentRequest.note,
          scheme: widget.paymentRequest.scheme,
          pjUri: widget.paymentRequest.pjUri,
          callbackUrl: widget.paymentRequest.callbackUrl,
          callbackMessage: widget.paymentRequest.callbackMessage,
        ),
        compatibleWallets: compatibleWallets,
        wallet: compatibleWallets.isNotEmpty ? compatibleWallets.first : null,
      );
    } else {
      newResult = PaymentFlowResult.evmNetworkSelection(
        AddressDetectionResult(
          address: widget.paymentRequest.address,
          detectedWalletType: selectedNetwork!,
          detectedCurrency: selectedToken!,
          isValid: true,
          amount: widget.paymentRequest.amount,
          note: widget.paymentRequest.note,
          scheme: widget.paymentRequest.scheme,
          pjUri: widget.paymentRequest.pjUri,
          callbackUrl: widget.paymentRequest.callbackUrl,
          callbackMessage: widget.paymentRequest.callbackMessage,
        ),
        compatibleWallets: compatibleWallets,
        wallet: compatibleWallets.isNotEmpty ? compatibleWallets.first : null,
      );
    }

    widget.paymentViewModel.detectedWalletType = selectedNetwork!;
    widget.onNext(newResult);
  }
}

class TokenSelectionTileWidget extends StatelessWidget {
  const TokenSelectionTileWidget({
    super.key,
    required this.value,
    required this.enabled,
    required this.onTap,
    this.imagePath,
    this.color,
  });

  final String value;
  final bool enabled;
  final VoidCallback? onTap;
  final String? imagePath;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: Row(
            children: [
              if (imagePath != null) ...[
                CakeImageWidget(
                  imageUrl: imagePath!,
                  color: color,
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
              if (enabled)
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
