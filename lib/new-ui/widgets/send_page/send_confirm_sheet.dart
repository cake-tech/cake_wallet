import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_confirm_bottom_widget.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobx/mobx.dart';

class SendConfirmSheet extends StatefulWidget {
  const SendConfirmSheet({super.key, required this.sendViewModel, this.isPage = false, this.title, this.iconPath});

  final SendViewModel sendViewModel;
  final bool isPage;
  final String? title;
  final String? iconPath;

  @override
  State<SendConfirmSheet> createState() => _SendConfirmSheetState();
}

class _SendConfirmSheetState extends State<SendConfirmSheet> {
  void initState() {
    super.initState();
    reaction((context) => widget.sendViewModel.state, (state) {
      if (state is TransactionCommitted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isPage,
      onPopInvokedWithResult: (didPop, result) {
        if (widget.isPage) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: Container(
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
                  child: SendTransactionDetails(
                      sendViewModel: widget.sendViewModel,
                      isPage: widget.isPage,
                      title: widget.title,
                      iconPath: widget.iconPath),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SendTransactionDetails extends StatelessWidget {
  const SendTransactionDetails({super.key, required this.sendViewModel, required this.isPage, this.title, this.iconPath});

  final SendViewModel sendViewModel;
  final bool isPage;
  final String? title;
  final String? iconPath;


  @override
  Widget build(BuildContext context) {
    final resolvedIconPath = iconPath ?? sendViewModel.currency.iconPath ?? "";

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
              key: ValueKey(0),
              mainAxisSize: isPage ? MainAxisSize.max : MainAxisSize.min,
              children: [
                ModalTopBar(
                  title: "",
                  leadingWidget: Row(
                    spacing: 8,
                    children: [
                      if (resolvedIconPath.toLowerCase().endsWith(".svg"))
                        SvgPicture.asset(
                          resolvedIconPath,
                          width: 28,
                          height: 28,
                        )
                      else
                        Image.asset(
                          resolvedIconPath,
                          width: 28,
                          height: 28,
                        ),
                      Text(
                        title ?? S.of(context).send,
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                      )
                    ],
                  ),
                  trailingIcon: Icon(Icons.close),
                  onTrailingPressed: Navigator.of(context).maybePop,
                ),
                isPage ? Expanded(child: _buildMainContent(context)) : _buildMainContent(context)
              ]);
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final transaction = sendViewModel.pendingTransaction;

    final amount = (transaction == null)
        ? sendViewModel.outputs.first.roundedCryptoAmount(8)
        : formatAmount(transaction.amountFormatted);

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
                    S.of(context).send_to,
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
                        Text(S.of(context).fee,
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
                  if (sendViewModel.isElectrumWallet) ...[
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
                          Text(S.of(context).network,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onSurface)),
                          Column(
                            children: [
                              Text(bitcoin!.getNetworkName(sendViewModel.wallet),
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
            SendConfirmBottomWidget(sendViewModel: sendViewModel),
            if(Platform.isAndroid) // spacing between bottom widget and system navbar
            SizedBox(),
          ],
        ),
      )
    ]);
  }

  String formatAmount(String amount) {
    try {
      return double.parse(amount).toStringAsPrecision(8).replaceFirst(RegExp(r"\.?0+$"), "");
    } catch(e) {
      return amount;
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
            S.of(context).transaction_commited,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          Image.asset(width: 256, height: 256, "assets/images/birthday_cake.png")
        ],
      ),
    );
  }
}
