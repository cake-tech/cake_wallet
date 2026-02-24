import 'dart:io';

import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/animated_dropdown.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_confirm_bottom_widget.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/crypto_currency.dart';
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
      child: SafeArea(
        bottom:false,
        minimum: widget.isPage ? EdgeInsets.zero : EdgeInsets.only(top: 64),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
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

    return LayoutBuilder(
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
              isPage ? Expanded(child: _buildMainContent(context)) : Flexible(child: _buildMainContent(context))
            ]);
      },
    );
  }

  double sumBy<T>(List<T> list, double Function(T) picker) =>
      list.map(picker).fold(0.0, (a, b) => a + b);

  BigInt sumByBigInt<T>(List<T> list, BigInt Function(T) picker) =>
      list.map(picker).fold(BigInt.zero, (a, b) => a + b);

  String sumStr<T>(List<T> list, double Function(T) picker) =>
      sumBy(list, picker).toString();

  String sumWithUnit<T>(List<T> list, double Function(T) picker, String unit) =>
      "${sumStr(list, picker)} $unit";


  Widget _buildMainContent(BuildContext context) {
    final transaction = sendViewModel.pendingTransaction;

    final currencySymbol = sendViewModel.amountParsingProxy.getCryptoSymbol(sendViewModel.selectedCryptoCurrency);

    final amount = (transaction == null)
        ? sendViewModel.amountParsingProxy.getDisplayCryptoStringFromBigInt(
            sumByBigInt(
              sendViewModel.outputs.where((e) => !e.sendAll).toList(),
              (o) =>
                  sendViewModel.selectedCryptoCurrency.tryParseAmount(o.cryptoAmount) ??
                  BigInt.zero,
            ),
            sendViewModel.selectedCryptoCurrency)
        : sendViewModel.amountParsingProxy.getDisplayCryptoAmount(
            formatAmount(transaction.amountFormatted), sendViewModel.selectedCryptoCurrency);

    final fee =
        "${(transaction == null) ? sendViewModel.amountParsingProxy.getDisplayCryptoStringFromBigInt(sumByBigInt(
              sendViewModel.outputs.where((e) => !e.sendAll).toList(),
              (o) =>
                  sendViewModel.currency.tryParseAmount(o.estimatedFee.replaceAll(",", "")) ??
                  BigInt.zero,
            ), sendViewModel.currency) : sendViewModel.amountParsingProxy.getDisplayCryptoAmount(transaction.feeFormattedValue, sendViewModel.currency)} ${sendViewModel.currencySymbol}";

    final fiatAmount = (transaction == null)
        ? sumWithUnit(
            sendViewModel.outputs,
            (o) => double.tryParse(o.fiatAmount.replaceAll(",", "")) ?? 0,
            sendViewModel.fiatCurrency.title,
          )
        : sendViewModel.pendingTransactionFiatAmountFormatted;

    final fiatFee = (transaction == null)
        ? sumWithUnit(
            sendViewModel.outputs,
            (o) => double.tryParse(o.estimatedFeeFiatAmount.replaceAll(",", "")) ?? 0,
            sendViewModel.fiatCurrency.title,
          )
        : sendViewModel.pendingTransactionFeeFiatAmountFormatted;

    final showAddress = !sendViewModel.outputs.any(
        (e) => RegExp(AddressValidator.bolt11InvoiceMatcher).hasMatch(e.address.toLowerCase()));

    final outputs = sendViewModel.outputs;

    return SingleChildScrollView(
      child: Padding(
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
                    Text(currencySymbol,
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
            if (outputs.length >= 1 && (outputs.first.extractedAddress.isNotEmpty || outputs.first.address.isNotEmpty) && showAddress)
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
                  if (outputs.length == 1)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: AddressFormatter.buildSegmentedAddress(
                            address: outputs.first.isParsedAddress ? outputs.first.extractedAddress : outputs.first.address,
                            evenTextStyle:
                                TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ),
                    )
                  else
                    AnimatedDropdown(
                        content: Column(
                          children: outputs
                              .map(
                                (item) => Column(children: [
                                    MultiSendAddressPreview(
                                      index: outputs.indexOf(item) + 1,
                                      address: item.isParsedAddress
                                          ? item.extractedAddress
                                          : item.address,
                                      amount:
                                          "${item.roundedCryptoAmount(8).withLocalSeperator(sendViewModel.languageCode)} ${sendViewModel.currency.title}",
                                      fiatAmount:
                                          "${item.fiatAmount.withLocalSeperator(sendViewModel.languageCode)} ${sendViewModel.fiatCurrency.title}",
                                    ),
                                    if(item != outputs.last)
                                    Container(width: double.infinity, height: 1, color: Theme.of(context).colorScheme.surfaceContainerHigh)
                                ],),
                              )
                              .toList(),
                        ),
                        dropdownText: "${outputs.length} ${S.of(context).addresses}"),
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
                              fee.withLocalSeperator(sendViewModel.languageCode),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            Text(fiatFee.withLocalSeperator(sendViewModel.languageCode),
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
                              Text(
                                  sendViewModel.selectedCryptoCurrency == CryptoCurrency.btcln
                                      ? "Lightning"
                                      : bitcoin!.getNetworkName(sendViewModel.wallet),
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
      ),
    );
  }

  String formatAmount(String amount) {
    try {
      return amount.withMaxDecimals(8);
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
            S.of(context).transaction_sent_new,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          Image.asset(width: 256, height: 256, "assets/images/birthday_cake.png")
        ],
      ),
    );
  }
}


class MultiSendAddressPreview extends StatefulWidget {
  const MultiSendAddressPreview(
      {super.key,
      required this.index,
      required this.address,
      required this.amount,
      required this.fiatAmount});

  final int index;
  final String address;
  final String amount;
  final String fiatAmount;

  @override
  State<MultiSendAddressPreview> createState() => _MultiSendAddressPreviewState();
}

class _MultiSendAddressPreviewState extends State<MultiSendAddressPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 4,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.index}:",
                  style: TextStyle(fontFamily: "IBM Plex Mono"),
                ),
                if (!_expanded)
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          _expanded = true;
                        });
                      },
                      child: Text(middleTruncate(widget.address, 8, 8),
                          style: TextStyle(
                              fontFamily: "IBM Plex Mono",
                              color: Theme.of(context).colorScheme.primary)))
                else
                  AddressFormatter.buildSegmentedAddress(
                      address: widget.address,
                      evenTextStyle: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontFamily: "IBM Plex Mono")),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(widget.amount),
              Text(
                widget.fiatAmount,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            ],
          ),
        ],
      ),
    );
  }
}
