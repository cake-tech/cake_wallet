import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/payment/payment_view_model.dart';
import 'package:cake_wallet/view_model/wallet_switcher_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PaymentConfirmationBottomSheet extends BaseBottomSheet {
  PaymentConfirmationBottomSheet({
    Key? key,
    required this.paymentFlowResult,
    required this.paymentViewModel,
    required this.walletSwitcherViewModel,
    required this.paymentRequest,
    required this.onSelectWallet,
    required this.onChangeWallet,
    required this.onSwap,
  }) : super(
          titleText: '',
          footerType: FooterType.none,
          maxHeight: 900,
        );

  final PaymentFlowResult paymentFlowResult;
  final PaymentViewModel paymentViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;
  final PaymentRequest paymentRequest;
  final VoidCallback onSelectWallet;
  final VoidCallback onChangeWallet;
  final VoidCallback onSwap;

  @override
  Widget contentWidget(BuildContext context) {
    return _PaymentConfirmationContent(
      paymentFlowResult: paymentFlowResult,
      paymentViewModel: paymentViewModel,
      walletSwitcherViewModel: walletSwitcherViewModel,
      paymentRequest: paymentRequest,
      onSelectWallet: onSelectWallet,
      onChangeWallet: onChangeWallet,
      onSwap: onSwap,
    );
  }
}

class _PaymentConfirmationContent extends StatelessWidget {
  const _PaymentConfirmationContent({
    required this.paymentFlowResult,
    required this.paymentViewModel,
    required this.walletSwitcherViewModel,
    required this.paymentRequest,
    required this.onSelectWallet,
    required this.onChangeWallet,
    required this.onSwap,
  });

  final PaymentFlowResult paymentFlowResult;
  final PaymentViewModel paymentViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;
  final PaymentRequest paymentRequest;
  final VoidCallback onSelectWallet;
  final VoidCallback onChangeWallet;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final currencyName = walletTypeToString(paymentViewModel.detectedWalletType!);
        final currentWalletName = walletTypeToString(paymentViewModel.currentWalletType);

        final hasMultipleWallets = paymentFlowResult.type == PaymentFlowType.multipleWallets;
        final noAvailableWallets = paymentFlowResult.type == PaymentFlowType.noWallets;

        final hasAtLeastOneWallet =
            paymentFlowResult.type == PaymentFlowType.singleWallet || hasMultipleWallets;

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                walletTypeToCryptoCurrency(paymentViewModel.detectedWalletType!).iconPath!,
                width: 118,
                height: 118,
              ),
              const SizedBox(height: 20),
              Text(
                '$currencyName ${S.current.address_detected.toLowerCase()}',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0.0,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '''Looks like you scanned a $currencyName address.\n\n'''
                '''Would you like to ${!noAvailableWallets ? 'switch to a $currencyName wallet or' : ''} swap $currentWalletName for $currencyName for this payment?''',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 72),
              if (hasAtLeastOneWallet) ...[
                PrimaryButton(
                  onPressed: onSwap,
                  text: '${S.current.swap} $currentWalletName',
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  onPressed: hasMultipleWallets ? onSelectWallet : onChangeWallet,
                  text: S.current.switch_wallet,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 10),
              ] else ...[
                PrimaryButton(
                  onPressed: () => Navigator.of(context).pop(),
                  text: S.current.cancel,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  onPressed: onSwap,
                  text: '${S.current.swap} $currentWalletName',
                  color: hasAtLeastOneWallet
                      ? Theme.of(context).colorScheme.surfaceContainer
                      : Theme.of(context).colorScheme.primary,
                  textColor: hasAtLeastOneWallet
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        );
      },
    );
  }
}
