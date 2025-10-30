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
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class EVMPaymentFlowBottomSheet extends BaseBottomSheet {
  EVMPaymentFlowBottomSheet({
    Key? key,
    required this.paymentViewModel,
    required this.paymentRequest,
    required this.onNext,
  }) : super(
          titleText: '',
          footerType: FooterType.none,
          maxHeight: 900,
        );

  final PaymentViewModel paymentViewModel;
  final PaymentRequest paymentRequest;
  final Function(PaymentFlowResult) onNext;

  @override
  Widget contentWidget(BuildContext context) {
    return _EVMPaymentFlowContent(
      paymentViewModel: paymentViewModel,
      paymentRequest: paymentRequest,
      onNext: onNext,
    );
  }
}

class _EVMPaymentFlowContent extends StatefulWidget {
  const _EVMPaymentFlowContent({
    required this.paymentViewModel,
    required this.paymentRequest,
    required this.onNext,
  });

  final PaymentViewModel paymentViewModel;
  final PaymentRequest paymentRequest;
  final Function(PaymentFlowResult) onNext;

  @override
  State<_EVMPaymentFlowContent> createState() => _EVMPaymentFlowContentState();
}

class _EVMPaymentFlowContentState extends State<_EVMPaymentFlowContent> {
  WalletType? selectedNetwork;
  CryptoCurrency? selectedToken;

  @override
  void initState() {
    super.initState();
    selectedNetwork = WalletType.ethereum;
    _autoSelectToken();
  }

  Future<void> _autoSelectToken() async {
    if (selectedNetwork == null) return;

    try {
      final tokens = await TokenUtilities.getAvailableTokensForNetwork(
        selectedNetwork!,
        widget.paymentViewModel.walletInfoSource,
      );
      if (tokens.isNotEmpty) {
        setState(() {
          selectedToken = tokens.first;
        });
      }
    } catch (e) {
      printV('Auto-select token error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CakeImageWidget(
            imageUrl: 'assets/images/eth_chain_mono.svg',
            width: 50,
            height: 50,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${S.current.ethereum_ecosystem}\n${S.current.address_detected.toLowerCase()}',
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
            S.current.evm_ecosystem_description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.0,
                ),
          ),
          const SizedBox(height: 32),
          EVMTileWidget(
            value: selectedNetwork != null
                ? walletTypeToString(selectedNetwork!)
                : S.current.select_network,
            imagePath: selectedNetwork != null ? getChainMonoImage(selectedNetwork!) : null,
            color: selectedNetwork != null ? Theme.of(context).colorScheme.primary : null,
            enabled: true,
            onTap: () => _showNetworkSelection(context),
          ),
          const SizedBox(height: 16),
          EVMTileWidget(
            imagePath: selectedToken != null ? selectedToken!.iconPath : null,
            value: selectedToken != null ? selectedToken!.title : S.current.select_token,
            enabled: selectedNetwork != null,
            onTap: () => _showTokenSelection(context),
            color: selectedToken == null ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: S.current.restore_next,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: selectedNetwork != null && selectedToken != null
                ? () => _handleNext(context)
                : null,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _showNetworkSelection(BuildContext context) async {
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
    if (selectedNetwork == null) return;

    try {
      final availableTokens = await TokenUtilities.getAvailableTokensForNetwork(
        selectedNetwork!,
        widget.paymentViewModel.walletInfoSource,
      );

      if (availableTokens.isEmpty) return;

      final selectedIndex = selectedToken != null ? availableTokens.indexOf(selectedToken!) : 0;

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
    }
  }

  void _handleNext(BuildContext context) {
    if (selectedNetwork == null || selectedToken == null) return;

    Navigator.of(context).pop();

    final compatibleWallets = widget.paymentViewModel.getWalletsByType(selectedNetwork!);

    final newResult = PaymentFlowResult.evmNetworkSelection(
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

    widget.paymentViewModel.detectedWalletType = selectedNetwork!;
    widget.onNext(newResult);
  }
}

class EVMTileWidget extends StatelessWidget {
  const EVMTileWidget({
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
            Icon(
              Icons.keyboard_arrow_down,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
