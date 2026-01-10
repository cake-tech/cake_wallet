import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/new-ui/widgets/confirm_swiper.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobx/mobx.dart';

class SendConfirmSheet extends StatefulWidget {
  const SendConfirmSheet({super.key, required this.sendViewModel});

  final SendViewModel sendViewModel;

  @override
  State<SendConfirmSheet> createState() => _SendConfirmSheetState();
}

class _SendConfirmSheetState extends State<SendConfirmSheet> {
  void initState() {
    super.initState();
    reaction((context) => widget.sendViewModel.state, (state) {
      if (state is TransactionCommitted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Observer(
        builder: (_) {
          final commited = widget.sendViewModel.state is TransactionCommitted;
          return Stack(
            fit: StackFit.loose,
            children: [
              Positioned.fill(
                  child: AnimatedSlide(
                offset: commited ? Offset.zero : const Offset(1, 0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: const TransactionCommitedScreen(),
              )),
              AnimatedSlide(
                offset: commited ? const Offset(-1, 0) : Offset.zero,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: SendTransactionDetails(sendViewModel: widget.sendViewModel),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SendTransactionDetails extends StatelessWidget {
  const SendTransactionDetails({super.key, required this.sendViewModel});

  final SendViewModel sendViewModel;

  @override
  Widget build(BuildContext context) {
    final transaction = sendViewModel.pendingTransaction;

    final amount = (transaction == null)
        ? sendViewModel.outputs.first.cryptoAmount
        : transaction.amountFormatted;

    final fee = (transaction == null)
        ? sendViewModel.outputs.first.estimatedFee + " " + sendViewModel.currency.title
        : transaction.feeFormatted;

    final fiatAmount = (transaction == null)
        ? sendViewModel.outputs.first.fiatAmount + " " + sendViewModel.fiatCurrency.title
        : sendViewModel.pendingTransactionFiatAmountFormatted;

    final fiatFee = (transaction == null)
        ? sendViewModel.outputs.first.estimatedFeeFiatAmount +
            " " +
            sendViewModel.fiatCurrency.title
        : sendViewModel.pendingTransactionFeeFiatAmountFormatted;

    final address = sendViewModel.outputs.first.extractedAddress;

    return Column(key: ValueKey(0), mainAxisSize: MainAxisSize.min, children: [
      ModalTopBar(
        title: "",
        leadingWidget: Row(
          spacing: 8,
          children: [
            if (sendViewModel.currency.iconPath != null)
              Image.asset(
                sendViewModel.currency.iconPath!,
                width: 28,
                height: 28,
              ),
            Text(
              "Send",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            )
          ],
        ),
        trailingIcon: Icon(Icons.close),
        onTrailingPressed: Navigator.of(context).pop,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 24,
          children: [
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    Text(sendViewModel.currency.title,
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.onSurfaceVariant))
                  ],
                ),
                Text(
                  fiatAmount,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            if (address.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text(
                    "Send to",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: AddressFormatter.buildSegmentedAddress(
                          address: address,
                          evenTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    ),
                  ),
                ],
              ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Fee",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fee,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            Text(fiatFee,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant))
                          ],
                        )
                      ],
                    ),
                  ),
                  if (sendViewModel.wallet is ElectrumWallet) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        height: 1,
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Network",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onSurface)),
                          Column(
                            children: [
                              Text((sendViewModel.wallet as ElectrumWallet).network.value,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant))
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ],
              ),
            ),
            Observer(builder: (_) {
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
            }),
            SizedBox(height: 24),
          ],
        ),
      )
    ]);
  }

  Widget _buildBottomWidget(BuildContext context, Type state) {
    switch (state) {
      case ExecutedSuccessfullyState:
        return ConfirmSwiper(
            onConfirmed: () {
              sendViewModel.commitTransaction(context);
            },
            swiperText: "Swipe to send");
      case IsExecutingState:
        return LoadingBottomWidget(
          text: "Generating transaction...",
        );
      case FailureState:
        return TransactionErrorActions(errorText: (sendViewModel.state as FailureState).error);
      case IsDeviceSigningResponseState:
        return LoadingBottomWidget(
          text: "Signing Transaction...",
        );
      case IsAwaitingDeviceResponseState:
        return HardwareWalletConfirmationMessage(
            hardwareWalletType: sendViewModel.wallet.hardwareWalletType!);
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
                      "Transaction Error",
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
            NewPrimaryButton(
                onPressed: () {},
                text: "More details",
                color: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.primary),
            NewPrimaryButton(
                onPressed: Navigator.of(context).pop,
                text: "Close",
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary),
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
            "Proceed on your device",
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

class TransactionCommitedScreen extends StatelessWidget {
  const TransactionCommitedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        spacing: 12,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Transaction commited",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          Image.asset(width: 256, height: 256, "assets/images/birthday_cake.png")
        ],
      ),
    );
  }
}
