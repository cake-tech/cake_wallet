import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/swap_bloc.dart";
import "package:cake_wallet/new-ui/widgets/confirm_swiper.dart";
import "package:cake_wallet/new-ui/widgets/hardware_wallet/proceed_on_device_message.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_send_external_modal.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/view_model/send/send_view_model.dart";
import "package:cake_wallet/view_model/send/send_view_model_state.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";



// FIXME remove this after pr passes testing, added so i see the runtimeType without having to check myself
class UnreachableWidget extends StatelessWidget {
  const UnreachableWidget({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) =>
      Column(spacing: 4, children: [
        const Text("This message should not appear!",
          style: TextStyle(fontSize: 18, fontWeight: .w600, color: Colors.red),),
        const Text("Please screenshot and let me know immediately",
          style: TextStyle(fontSize: 14, fontWeight: .w600, color: Colors.red),),
        Text(message, style: const TextStyle(fontSize: 16),)
      ],);
}

class SwapConfirmBottomWidget extends StatelessWidget {
  const SwapConfirmBottomWidget({required this.bloc, super.key});

  final SwapBloc bloc;

  @override
  Widget build(BuildContext context) => BlocBuilder<SwapBloc, SwapState>(bloc: bloc, builder: (context, state) => Center(
      child: AnimatedSize(
        alignment: Alignment.bottomCenter,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Container(
            key: ValueKey(state.runtimeType),
            child: _buildBottomWidget(
              context,
              state
            ),
          ),
        ),
      ),
    ));

  Widget _buildBottomWidget(BuildContext context, SwapState state) => switch(state.runtimeType) {
    SwapStateCreating => LoadingBottomWidget(text: "${S.of(context).creating_trade}...",),
  SwapAwaitingWalletSwitch => LoadingBottomWidget(text: "${S.of(context).switching_to} ${(state as SwapAwaitingWalletSwitch).source.sourceWallet.name}",),
  SwapGeneratingTransaction => LoadingBottomWidget(
    text: "${S.of(context).generating_transaction}...",
  ),
  SwapAwaitingSend => ConfirmSwiper(onConfirmed: () { bloc.add(SendConfirmed()); }, swiperText: S.of(context).swipe_to_send,),
  SwapAwaitingHardwareWallet => HardwareWalletProceedOnDeviceMessage(hardwareWalletType: (state as SwapAwaitingHardwareWallet).type,),
  SwapAwaitingExternalSend => NewPrimaryButton(
      onPressed: () => _showExternalSendModal(context, state as SwapAwaitingExternalSend),
      text: S.of(context).continue_text,
      color: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary),
  SwapSending => LoadingBottomWidget(text: "${S.of(context).sending}...",),
SwapFailure => TransactionErrorActions(errorText: (state as SwapFailure).error.toString(),),

  _ => UnreachableWidget(message: state.runtimeType.toString())
  };

  void _showExternalSendModal(BuildContext context, SwapAwaitingExternalSend state) {
    if (context.mounted) {
      showMaterialModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          builder: (context) => SwapSendExternalModal(
              from: state.trade.depositAmount.currency as CryptoCurrency,
              to: state.trade.payoutAmount.currency as CryptoCurrency,
              uri: state.uri

            ));
    }
  }
}


class SendConfirmBottomWidget extends StatelessWidget {
  const SendConfirmBottomWidget({required this.sendViewModel, super.key});

  final SendViewModel sendViewModel;

  @override
  Widget build(BuildContext context) => Observer(builder: (_) => Center(
        child: AnimatedSize(
          alignment: Alignment.bottomCenter,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
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
      ));

  Widget _buildBottomWidget(BuildContext context, Type state) {
    switch (state) {
      case ExecutedSuccessfullyState:
        return ConfirmSwiper(
            onConfirmed: () {
              sendViewModel.commitTransaction(context);
            },
            swiperText: S.of(context).swipe_to_send);
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
        return HardwareWalletProceedOnDeviceMessage(
            hardwareWalletType: sendViewModel.wallet.hardwareWalletType!);
      case TransactionCommitting:
        return LoadingBottomWidget(
          text: "${S.of(context).sending}...",
        );
      case TransactionCommitted:
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}

class LoadingBottomWidget extends StatelessWidget {
  const LoadingBottomWidget({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
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

class TransactionErrorActions extends StatelessWidget {
  const TransactionErrorActions({required this.errorText, super.key});

  final String errorText;

  @override
  Widget build(BuildContext context) => Column(
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
                    CakeImageWidget(
                      imageUrl: "assets/new-ui/warning.svg",
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
