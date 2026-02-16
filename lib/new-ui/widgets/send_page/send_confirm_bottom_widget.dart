import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/confirm_swiper.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';

class SendConfirmBottomWidget extends StatelessWidget {
  const SendConfirmBottomWidget({super.key, required this.sendViewModel});

  final SendViewModel sendViewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      return Center(
        child: AnimatedSize(
          alignment: Alignment.bottomCenter,
          duration: Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 150),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Container(
              key: ValueKey(sendViewModel.state.runtimeType),
              child: _buildBottomWidget(
                context,
                sendViewModel.state.runtimeType,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBottomWidget(BuildContext context, Type state) {
    switch (state) {
      case ExecutedSuccessfullyState:
        return ConfirmSwiper(
            onConfirmed: () {
              sendViewModel.commitTransaction(context);
            },
            swiperText: "${S.of(context).swipe_to_send}");
      case IsExecutingState:
        return LoadingBottomWidget(
          text: "${S.of(context).generating_transaction}...",
        );
      case FailureState:
        return TransactionErrorActions(errorText: (sendViewModel.state as FailureState).error);
      case IsDeviceSigningResponseState:
        return LoadingBottomWidget(
          text: "${S.of(context).signing_transaction}...",
        );
      case IsAwaitingDeviceResponseState:
        return HardwareWalletConfirmationMessage(
            hardwareWalletType: sendViewModel.wallet.hardwareWalletType!);
      case TransactionCommitting:
        return LoadingBottomWidget(
          text: "${S.of(context).sending}...",
        );
      case TransactionCommitted:
        return SizedBox.shrink();
      default:
        return SizedBox.shrink();
    }
  }
}

class LoadingBottomWidget extends StatelessWidget {
  const LoadingBottomWidget({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 12,
      children: [
        CupertinoActivityIndicator(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        )
      ],
    );
  }
}

class TransactionErrorActions extends StatelessWidget {
  const TransactionErrorActions({super.key, required this.errorText});

  final String errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withAlpha(64),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              spacing: 12,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    SvgPicture.asset(
                      "assets/new-ui/warning.svg",
                      height: 24,
                      width: 24,
                      colorFilter:
                          ColorFilter.mode(Theme.of(context).colorScheme.error, BlendMode.srcIn),
                    ),
                    Text(
                      S.of(context).transaction_error,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.error),
                    )
                  ],
                ),
                Text(
                  errorText,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Row(
          spacing: 8,
          children: [
            // Flexible(
            //   child: NewPrimaryButton(
            //       onPressed: () {},
            //       text: S.of(context).more_details,
            //       color: Theme.of(context).colorScheme.surfaceContainer,
            //       textColor: Theme.of(context).colorScheme.primary),
            // ),
            Flexible(
              child: NewPrimaryButton(
                  onPressed: Navigator.of(context).maybePop,
                  text: S.of(context).close,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary),
            ),
          ],
        )
      ],
    );
  }
}

class HardwareWalletConfirmationMessage extends StatelessWidget {
  const HardwareWalletConfirmationMessage({super.key, required this.hardwareWalletType});

  final HardwareWalletType hardwareWalletType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(spacing: 8, children: [
          if (hardwareWalletIcon != null)
            SvgPicture.asset(
              hardwareWalletIcon!,
              width: 36,
              height: 36,
              colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
            ),
          Text(
            S.of(context).proceed_on_device,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface),
          )
        ]),
      ),
    );
  }

  String? get hardwareWalletIcon {
    switch (hardwareWalletType) {
      case HardwareWalletType.bitbox:
        return "assets/images/hardware_wallet/device_bitbox.svg";
      case HardwareWalletType.ledger:
        return "assets/images/hardware_wallet/device_ledger_nano_x.svg";
      case HardwareWalletType.trezor:
        return "assets/images/hardware_wallet/device_trezor_safe_5.svg";
      case HardwareWalletType.cupcake:
        return "assets/images/cupcake.svg";
      case HardwareWalletType.coldcard:
      case HardwareWalletType.seedsigner:
      case HardwareWalletType.keystone:
        return "assets/images/hardware_wallet/device_qr.svg";
    }
  }
}
