import 'dart:io';

import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/animated_dropdown.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/transaction_details_modal.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_confirm_bottom_widget.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class SendConfirmSheet extends StatefulWidget {
  const SendConfirmSheet(
      {super.key, required this.sendViewModel, this.isPage = false, this.title, this.iconPath});

  final SendViewModel sendViewModel;
  final bool isPage;
  final String? title;
  final String? iconPath;

  @override
  State<SendConfirmSheet> createState() => _SendConfirmSheetState();
}

class _SendConfirmSheetState extends State<SendConfirmSheet> {
  bool _committed = false;

  void initState() {
    super.initState();
    reaction((_) => widget.sendViewModel.state, (state) {
      if (state is TransactionCommitted) {
        setState(() {
          _committed = true;
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
        bottom: false,
        minimum: widget.isPage ? EdgeInsets.zero : EdgeInsets.only(top: 64),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(child: Observer(
            builder: (_) {
              return AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _committed ? 0.0 : 1.0,
                      child: AnimatedSlide(
                        offset: _committed ? const Offset(-1, 0) : Offset.zero,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        // Both screens stay mounted; only the visible one may be reachable.
                        child: ExcludeSemantics(
                          excluding: _committed,
                          child: SendTransactionDetails(
                            sendViewModel: widget.sendViewModel,
                            isPage: widget.isPage,
                            title: widget.title,
                            iconPath: widget.iconPath,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _committed ? 1.0 : 0.0,
                      child: AnimatedSlide(
                        offset: _committed ? Offset.zero : const Offset(1, 0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: ExcludeSemantics(
                          excluding: !_committed,
                          child: TransactionCommitedScreen(
                            sendViewModel: widget.sendViewModel,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )),
        ),
      ),
    );
  }
}

class SendTransactionDetails extends StatelessWidget {
  const SendTransactionDetails(
      {super.key, required this.sendViewModel, required this.isPage, this.title, this.iconPath});

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
                      CakeImageWidget(
                        imageUrl: resolvedIconPath,
                        width: 28,
                        height: 28,
                      )
                    else
                      Image.asset(
                        resolvedIconPath,
                        width: 28,
                        height: 28,
                      ),
                    Semantics(
                      header: true,
                      // Android reads the heading from headingLevel since the
                      // Flutter 3.41 engine; header: alone only covers iOS.
                      headingLevel: 1,
                      child: Text(
                        title ?? S.of(context).send,
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                      ),
                    )
                  ],
                ),
                trailingIcon: Icon(Icons.close),
                trailingSemanticLabel: S.of(context).close,
                onTrailingPressed: Navigator.of(context).maybePop,
              ),
              isPage
                  ? Expanded(child: _buildMainContent(context))
                  : Flexible(child: _buildMainContent(context))
            ]);
      },
    );
  }

  double sumBy<T>(List<T> list, double Function(T) picker) =>
      list.map(picker).fold(0.0, (a, b) => a + b);

  Money sumByMoney<T>(List<T> list, Money Function(T) picker, CryptoCurrency currency) =>
      list.map(picker).fold(Money.zero(currency), (a, b) => a + b);

  String sumStr<T>(List<T> list, double Function(T) picker) => sumBy(list, picker).toString();

  String sumWithUnit<T>(List<T> list, double Function(T) picker, String unit, {int? decimals}) {
    final str = sumStr(list, picker);
    return "${decimals == null ? str : str.withDecimals(decimals)} $unit";
  }

  Widget _buildMainContent(BuildContext context) {
    return Observer(builder: (context) {
      final transaction = sendViewModel.pendingTransaction;

      final currencySymbol =
          sendViewModel.amountParsingProxy.getCryptoSymbol(sendViewModel.selectedCryptoCurrency);

      final amount = (transaction == null)
          ? sendViewModel.amountParsingProxy.asDisplayString(sumByMoney(sendViewModel.outputs, (o) {
              final zero = Money.zero(sendViewModel.selectedCryptoCurrency);
              if (o.sendAll)
                return sendViewModel.amountParsingProxy.tryParseCryptoString(
                        sendViewModel.balance, sendViewModel.selectedCryptoCurrency) ??
                    zero;

              return sendViewModel.selectedCryptoCurrency.tryParseAmount(o.cryptoAmount) ?? zero;
            }, sendViewModel.selectedCryptoCurrency))
          : sendViewModel.amountParsingProxy.asDisplayString(transaction.amount);

      final fee = (transaction == null)
          ? sendViewModel.amountParsingProxy.asDisplayString(sumByMoney(
              sendViewModel.outputs,
              (o) => o.estimatedFee,
              sendViewModel.currency,
            ))
          : sendViewModel.amountParsingProxy.asDisplayString(transaction.fee);

      final fiatAmount = (transaction == null)
          ? sumWithUnit(
              sendViewModel.outputs,
              (o) => double.tryParse(o.fiatAmount.replaceAll(",", "")) ?? 0,
              sendViewModel.fiatCurrency.title,
              decimals: 2)
          : sendViewModel.pendingTransactionFiatAmountFormatted;

      final fiatFee = (transaction == null)
          ? sumWithUnit(
              sendViewModel.outputs,
              (o) => double.tryParse(o.estimatedFeeFiatAmount.replaceAll(",", "")) ?? 0,
              sendViewModel.fiatCurrency.title,
              decimals: 2)
          : sendViewModel.pendingTransactionFeeFiatAmountFormatted;

      final showAddress = !sendViewModel.outputs.any((e) =>
          RegExp(AddressValidator.bolt11InvoiceMatcher).hasMatch(e.address.toLowerCase()) ||
          RegExp(AddressValidator.lnurlMatcher).hasMatch(e.address.toLowerCase()) ||
          (e.isParsedAddress &&
              e.parsedAddress.parsedAddressByCurrencyMap[sendViewModel.selectedCryptoCurrency] !=
                  null &&
              e.parsedAddress.parsedAddressByCurrencyMap[sendViewModel.selectedCryptoCurrency]!
                  .isNotEmpty &&
              RegExp(AddressValidator.lnurlMatcher).hasMatch(e
                  .parsedAddress.parsedAddressByCurrencyMap[sendViewModel.selectedCryptoCurrency]!
                  .toLowerCase())));

      final outputs = sendViewModel.outputs;

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 24,
            children: [
              // The amount being sent is the value under review: announce it as one group.
              MergeSemantics(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 4,
                      children: [
                        Flexible(
                          child: Text(
                            amount,
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
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
              ),
              if (outputs.length >= 1 &&
                  (outputs.first.extractedAddress.isNotEmpty || outputs.first.address.isNotEmpty) &&
                  showAddress)
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
                              address: outputs.first.isParsedAddress
                                  ? outputs.first.extractedAddress
                                  : outputs.first.address,
                              evenTextStyle:
                                  TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        ),
                      )
                    else
                      AnimatedDropdown(
                          content: Column(
                            children: outputs
                                .map(
                                  (item) => Column(
                                    children: [
                                      MultiSendAddressPreview(
                                        index: outputs.indexOf(item) + 1,
                                        address: item.isParsedAddress
                                            ? item.extractedAddress
                                            : item.address,
                                        amount:
                                            "${item.roundedCryptoAmount(8).withLocalSeperator(sendViewModel.languageCode)} ${sendViewModel.currency.title}",
                                        fiatAmount:
                                            "${item.fiatAmount.withDecimals(2).withLocalSeperator(sendViewModel.languageCode)} ${sendViewModel.fiatCurrency.title}",
                                      ),
                                      if (item != outputs.last)
                                        Container(
                                            width: double.infinity,
                                            height: 1,
                                            color:
                                                Theme.of(context).colorScheme.surfaceContainerHigh)
                                    ],
                                  ),
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
                      child: MergeSemantics(
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
                                  "${fee.withLocalSeperator(sendViewModel.languageCode)} ${sendViewModel.currencySymbol}",
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
                        child: MergeSemantics(
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
                        ),
                      )
                    ],
                  ],
                ),
              ),
              SendConfirmBottomWidget(sendViewModel: sendViewModel),
              if (Platform.isAndroid) // spacing between bottom widget and system navbar
                SizedBox(),
            ],
          ),
        ),
      );
    });
  }

  String formatAmount(String amount) {
    try {
      return amount.withMaxDecimals(8);
    } catch (e) {
      return amount;
    }
  }
}

class TransactionCommitedScreen extends StatefulWidget {
  const TransactionCommitedScreen({super.key, this.sendViewModel});

  final SendViewModel? sendViewModel;

  @override
  State<TransactionCommitedScreen> createState() => _TransactionCommitedScreenState();
}

class _TransactionCommitedScreenState extends State<TransactionCommitedScreen> {
  bool _isNoteButtonLoading = false;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Column(
        spacing: 12,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            height: 12,
          ),
          // The sheet swaps its content in place, so this title becoming visible is what
          // tells a screen reader that the transaction went through.
          Semantics(
            liveRegion: true,
            child: Text(
              S.of(context).transaction_sent_new,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(),
          CakeImageWidget(width: 200, height: 200, imageUrl: "assets/new-ui/birthday_cake.svg"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              spacing: 12,
              children: [
                if (widget.sendViewModel != null)
                  Row(
                    spacing: 8,
                    children: [
                      if (!(widget.sendViewModel!.checkIfAddressIsAContact(
                              widget.sendViewModel!.outputs.first.address)) &&
                          !(widget.sendViewModel!.outputs.first.isParsedAddress))
                        TransactionCommittedScreenActionButton(
                            text: S.of(context).save_contact,
                            iconPath: "assets/new-ui/save_contact.svg",
                            onTap: () {
                              Navigator.of(context).pushNamed(Routes.addressBookAddContact,
                                  arguments: ContactRecord(
                                      CakeHive.box<Contact>(Contact.boxName),
                                      Contact(
                                          name: "",
                                          address: widget.sendViewModel!.outputs.first.address,
                                          type: widget.sendViewModel!.wallet.currency)));
                            }),
                      // lightning has to be hacked in here as it doesn't get added to tx history for a few secs after committing.
                      if (widget.sendViewModel!.transactionInfo != null ||
                          widget.sendViewModel!.currency == CryptoCurrency.btcln)
                        TransactionCommittedScreenActionButton(
                            text: S.of(context).add_a_note,
                            iconPath: "assets/new-ui/add_note.svg",
                            isLoading: _isNoteButtonLoading,
                            onTap: () async {
                              setState(() {
                                _isNoteButtonLoading = true;
                              });

                              // for ln, we want to show the button and just have it wait until it appears in tx history
                              // for other currs this is instant
                              await asyncWhen((_) => widget.sendViewModel!.transactionInfo != null);

                              setState(() {
                                _isNoteButtonLoading = false;
                              });

                              final page = getIt.get<TransactionDetailsModal>(
                                  param1: widget.sendViewModel!.transactionInfo!, param2: true);
                              showModalBottomSheet(
                                  isScrollControlled: true,
                                  context: context,
                                  builder: (context) =>
                                      FractionallySizedBox(heightFactor: 0.9, child: page));
                            }),
                    ],
                  ),
                NewPrimaryButton(
                    onPressed: Navigator.of(context).maybePop,
                    text: S.of(context).done,
                    color: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary),
                SizedBox(
                  height: 12,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionCommittedScreenActionButton extends StatelessWidget {
  const TransactionCommittedScreenActionButton(
      {super.key,
      required this.text,
      required this.iconPath,
      required this.onTap,
      this.isLoading = false});

  final String text;
  final String iconPath;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Flexible(
        child: Semantics(
            button: true,
            enabled: !isLoading,
            label: text,
            value: isLoading ? S.of(context).loading : null,
            onTap: isLoading ? null : onTap,
            excludeSemantics: true,
            child: GestureDetector(
                onTap: isLoading ? null : onTap,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.surfaceContainer),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        isLoading
                            ? CupertinoActivityIndicator()
                            : CakeImageWidget(
                                imageUrl: iconPath,
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                              ),
                        Text(
                          text,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500),
                        )
                      ],
                    ),
                  ),
                ))));
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
                  Semantics(
                    button: true,
                    // Read the whole address rather than the truncated form.
                    label: widget.address,
                    hint: S.of(context).show_full_address,
                    onTap: () {
                      setState(() {
                        _expanded = true;
                      });
                    },
                    excludeSemantics: true,
                    child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _expanded = true;
                          });
                        },
                        child: Text(middleTruncate(widget.address, 8, 8),
                            style: TextStyle(
                                fontFamily: "IBM Plex Mono",
                                color: Theme.of(context).colorScheme.primary))),
                  )
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
