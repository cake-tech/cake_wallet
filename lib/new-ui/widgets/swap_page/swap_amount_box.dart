import "package:cake_wallet/core/amount_validator.dart";
import "package:cake_wallet/entities/qr_scanner.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/send_page/fiat_amount_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_memo_input.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/refund_address_modal.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_address_selection_modal.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/decimal_input_formatter.dart";
import "package:cake_wallet/utils/permission_handler.dart";
import "package:cake_wallet/view_model/exchange/exchange_view_model.dart";
import "package:cake_wallet/view_model/wallet_switcher_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currencies_with_memo.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart" as mobx;
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:permission_handler/permission_handler.dart";

class SwapAmountBox extends StatefulWidget {
  SwapAmountBox({
    required this.exchangeViewModel,
    required this.isReceiverCard,
    required this.walletSwitcherViewModel,
    required this.currency,
    required this.currencies,
    required this.onCurrencySelected,
    this.currencyValueValidator,
    this.addressTextFieldValidator,
    this.title = "",
    this.hasRefundAddress = false,
    this.hasAllAmount = false,
    this.useBaseUnit = false,
    this.allAmount,
    this.onPushPasteButton,
    this.onPushAddressBookButton,
    this.filteredNetwork,
    this.sourceSelectorMode = false,
    this.walletName,
    this.balanceByAsset,
    this.useSingleNetworkLayout = false,
    super.key,
  });

  final List<Currency> currencies;
  final Function(Currency) onCurrencySelected;
  final String title;
  final bool isReceiverCard;
  final Currency currency;
  final bool useBaseUnit;
  final bool hasRefundAddress;
  final FormFieldValidator<String>? currencyValueValidator;
  final FormFieldValidator<String>? addressTextFieldValidator;
  final FormFieldValidator<String> allAmountValidator = AllAmountValidator();
  final bool hasAllAmount;
  final VoidCallback? allAmount;
  final void Function(BuildContext context)? onPushPasteButton;
  final void Function(BuildContext context)? onPushAddressBookButton;
  final ExchangeViewModel exchangeViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;
  final WalletType? filteredNetwork;
  final bool sourceSelectorMode;
  final String? walletName;
  final Map<CryptoCurrency, CurrencyPickerBalance>? balanceByAsset;
  final bool useSingleNetworkLayout;

  @override
  State<SwapAmountBox> createState() => SwapAmountBoxState();
}

class SwapAmountBoxState extends State<SwapAmountBox> {
  final addressController = TextEditingController();
  final amountController = TextEditingController();
  final fiatAmountController = TextEditingController();
  final amountFocusNode = FocusNode();
  final memoController = TextEditingController();
  mobx.ReactionDisposer? _memoReactionDisposer;

  @override
  void initState() {
    if (widget.isReceiverCard) {
      memoController.text = widget.exchangeViewModel.receiveAddressExtraId;

      memoController.addListener(() {
        if (widget.exchangeViewModel.receiveAddressExtraId != memoController.text) {
          widget.exchangeViewModel.receiveAddressExtraId = memoController.text;
        }
      });

      _memoReactionDisposer =
          mobx.reaction((_) => widget.exchangeViewModel.receiveAddressExtraId, (String value) {
        if (memoController.text != value) {
          memoController.text = value;
        }
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    _memoReactionDisposer?.call();
    memoController.dispose();
    addressController.dispose();
    amountController.dispose();
    fiatAmountController.dispose();
    amountFocusNode.dispose();
    super.dispose();
  }

  bool _fiatInputMode = false;

  /// Whether the amount field is currently taking fiat input, the page's
  /// best-rate reaction needs this to know which controller holds the amount.
  bool get fiatInputMode => _fiatInputMode;

  CurrencyPickerBalance? _sourceBalance() {
    final selected = widget.currency;
    if (selected is! CryptoCurrency) {
      return null;
    }
    return balanceForAsset(widget.balanceByAsset, selected);
  }

  @override
  Widget build(BuildContext context) {
    final currencyToShow = (widget.currency is CryptoCurrency)
        ? widget.exchangeViewModel.amountParsingProxy
            .getCryptoSymbol(widget.currency as CryptoCurrency)
        : widget.currency.name.toUpperCase();

    final chainIconPath = (widget.currency is CryptoCurrency)
        ? _getCurrencyChainIconPath(widget.currency as CryptoCurrency)
        : null;

    final colors = Theme.of(context).colorScheme;

    if (widget.sourceSelectorMode) {
      final available = _sourceBalance()?.amount.split(" ").first ?? "—";
      return Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _presentCurrencyPicker,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CakeImageWidget(
                    imageUrl: widget.currency.iconPath ?? "",
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currencyToShow,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(letterSpacing: -0.08),
                  ),
                  if (chainIconPath != null && chainIconPath.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    CakeImageWidget(
                      imageUrl: chainIconPath,
                      width: 12,
                      height: 12,
                      colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                    ),
                  ],
                  const Spacer(),
                  CakeImageWidget(
                    imageUrl: "assets/new-ui/chooser.svg",
                    width: 12,
                    height: 12,
                    colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CakeImageWidget(
                        imageUrl: "assets/new-ui/wallet_filled.svg",
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.walletName ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.06,
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${S.of(context).avl}: $available",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.06,
                        color: colors.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        Container(
          decoration: ShapeDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 12,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: amountFocusNode.requestFocus,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 4,
                    children: [
                      Expanded(
                        child: Row(
                          spacing: 4,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: IntrinsicWidth(
                                child: Observer(
                                  builder: (_) {
                                    final showFetching = !widget.isReceiverCard &&
                                        widget.exchangeViewModel.isFixedRateMode &&
                                        widget.exchangeViewModel.receiveAmount.isNotEmpty &&
                                        widget.exchangeViewModel.depositAmount.isEmpty;
                                    return TextFormField(
                                      keyboardType: TextInputType.numberWithOptions(
                                        signed: false,
                                        decimal: !widget.useBaseUnit,
                                      ),
                                      validator:
                                          _fiatInputMode ? null : widget.currencyValueValidator,
                                      controller:
                                          _fiatInputMode ? fiatAmountController : amountController,
                                      focusNode: amountFocusNode,
                                      style: TextStyle(
                                        fontSize: 28,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                        hintText: showFetching ? S.of(context).fetching : "0",
                                        fillColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                      ),
                                      inputFormatters: <TextInputFormatter>[
                                        DecimalInputFormatter(
                                          maxDecimals:
                                              widget.useBaseUnit ? 0 : widget.currency.decimals,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (_fiatInputMode)
                              Center(
                                child: Text(
                                  widget.exchangeViewModel.fiat.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _presentCurrencyPicker,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(999999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4, left: 4, right: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CakeImageWidget(
                                  imageUrl: widget.currency.iconPath ?? "",
                                  width: 28,
                                  height: 28,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  currencyToShow,
                                  textAlign: TextAlign.center,
                                ),
                                if (chainIconPath != null && chainIconPath.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  CakeImageWidget(
                                    imageUrl: chainIconPath,
                                    width: 12,
                                    height: 12,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).colorScheme.onSurfaceVariant,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ] else
                                  const SizedBox(width: 10),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9999999999),
                                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: RotatedBox(
                                      quarterTurns: 2,
                                      child: CakeImageWidget(
                                        imageUrl: "assets/new-ui/dropdown_arrow.svg",
                                        width: 4,
                                        height: 4,
                                        colorFilter: ColorFilter.mode(
                                          Theme.of(context).colorScheme.primary,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Observer(
                  builder: (_) {
                    final hasAllAmount = !(widget.isReceiverCard ||
                        widget.exchangeViewModel.isSendFromExternal ||
                        !widget.exchangeViewModel.hasAllAmount);

                    return FiatAmountBar(
                      foregroundElementColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      allAmountColor: hasAllAmount ? null : Colors.transparent,
                      allAmountTextColor:
                          hasAllAmount ? null : Theme.of(context).colorScheme.onSurfaceVariant,
                      fiatInputMode: _fiatInputMode,
                      allAmount: !hasAllAmount
                          ? widget.isReceiverCard
                              ? null
                              : widget.exchangeViewModel.balanceDisplay
                          : widget.exchangeViewModel.depositAvailableAmount,
                      onSwitchButtonPressed: () {
                        setState(() => _fiatInputMode = !_fiatInputMode);
                        if (_fiatInputMode) {
                          updateFiatAmount();
                        } else {
                          amountController.text = widget.isReceiverCard
                              ? widget.exchangeViewModel.receiveAmount
                              : widget.exchangeViewModel.depositAmount;
                        }
                      },
                      onAllButtonPressed: () {
                        setState(() {
                          _fiatInputMode = false;
                        });
                        widget.allAmount?.call();
                      },
                      cryptoAmount: widget.isReceiverCard
                          ? widget.exchangeViewModel.roundedReceiveAmount(6)
                          : widget.exchangeViewModel.roundedDepositAmount(6),
                      fiatAmount: widget.isReceiverCard
                          ? widget.exchangeViewModel.roundedReceiveAmountFiat(6)
                          : widget.exchangeViewModel.roundedDepositAmountFiat(6),
                      cryptoCurrencySymbol: currencyToShow,
                      fiatCurrencySymbol: widget.exchangeViewModel.fiat.symbol,
                    );
                  },
                ),
                Observer(
                  builder: (_) {
                    final addressEmpty = (widget.isReceiverCard &&
                            widget.exchangeViewModel.receiveAddress.isEmpty) ||
                        (!widget.isReceiverCard && widget.exchangeViewModel.depositAddress.isEmpty);
                    final addressPickerText = widget.isReceiverCard
                        ? (addressEmpty ? S.of(context).select_receiver : S.of(context).to)
                        : S.of(context).from;
                    final addressDescription = widget.isReceiverCard
                        ? widget.exchangeViewModel.receiveAddressDisplayName ??
                            _middleTruncate(widget.exchangeViewModel.receiveAddress, 8, 8)
                        : widget.exchangeViewModel.isSendFromExternal
                            ? S.of(context).external
                            : widget.exchangeViewModel.wallet.name;
                    return Row(
                      spacing: 8,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: _presentWalletPicker,
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: (addressEmpty && widget.isReceiverCard)
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Observer(
                                  builder: (_) => Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        spacing: 8,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Text(
                                            addressPickerText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: (addressEmpty && widget.isReceiverCard)
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            addressDescription,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      RotatedBox(
                                        quarterTurns: 2,
                                        child: CakeImageWidget(
                                          imageUrl: "assets/new-ui/dropdown_arrow.svg",
                                          colorFilter: ColorFilter.mode(
                                            (addressEmpty && widget.isReceiverCard)
                                                ? Theme.of(context).colorScheme.onPrimary
                                                : Theme.of(context).colorScheme.onSurface,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!widget.isReceiverCard &&
                            widget.exchangeViewModel.isSendFromExternal &&
                            widget.exchangeViewModel.depositAddress.isEmpty)
                          ModernButton.svg(
                            svgPath: "assets/new-ui/refund_address.svg",
                            onPressed: askForRefundAddress,
                            size: 36,
                            iconSize: 18,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            semanticLabel: S.of(context).refund_address,
                          ),
                        if (widget.isReceiverCard &&
                            widget.exchangeViewModel.receiveAddress.isEmpty) ...[
                          ModernButton.svg(
                            svgPath: "assets/new-ui/paste.svg",
                            onPressed: () => widget.onPushPasteButton?.call(context),
                            size: 36,
                            iconSize: 20,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            semanticLabel: S.of(context).paste,
                          ),
                          ModernButton.svg(
                            svgPath: "assets/new-ui/scan.svg",
                            onPressed: () => _presentQRScanner(context),
                            size: 36,
                            iconSize: 20,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            semanticLabel: S.of(context).scan,
                          ),
                        ],
                      ],
                    );
                  },
                ),
                if (widget.isReceiverCard)
                  Observer(
                    builder: (_) {
                      final selected = widget.exchangeViewModel.receiveCurrency;
                      final labelType = memoLabelTypeFor(selected);
                      if (labelType == null) {
                        return const SizedBox.shrink();
                      }

                      final isDestinationTag = labelType == MemoLabelType.destinationTag;
                      final hint = isDestinationTag
                          ? S.of(context).destination_tag_optional
                          : S.of(context).memo_optional;
                      final disclaimer = isDestinationTag
                          ? S.of(context).destination_tag_swap_disclaimer
                          : S.of(context).memo_swap_disclaimer;

                      return NewSendMemoInput(
                        memoController: memoController,
                        maxMemoLength: isDestinationTag ? 20 : 256,
                        memoLength: memoController.text.length,
                        hintText: hint,
                        disclaimerText: disclaimer,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void changeAddress({required String address}) {
    setState(() => addressController.text = _normalizeAddressFormat(address));
  }

  void changeAmount({required String amount}) {
    setState(() => amountController.text = amount);
  }

  String _normalizeAddressFormat(String address) {
    if (address.startsWith("bitcoincash:")) {
      address = address.substring(12);
    }
    return address;
  }

  void _presentCurrencyPicker() {
    final rawCurrencies = widget.isReceiverCard
        ? widget.exchangeViewModel.receiveCurrencies
        : widget.exchangeViewModel.depositCurrencies;
    final currencies = rawCurrencies.whereType<CryptoCurrency>().toList();
    final restrictToCurrentBalances = !widget.isReceiverCard &&
        widget.balanceByAsset != null &&
        widget.balanceByAsset!.isNotEmpty;
    if (!restrictToCurrentBalances) {
      appendEvmDefaultTokens(currencies);
    }
    if (widget.exchangeViewModel.wallet.type == WalletType.bitcoin) {
      currencies.sort((a, b) {
        if (a == CryptoCurrency.btcln) {
          return -1;
        }
        if (b == CryptoCurrency.btcln) {
          return 1;
        }
        return 0;
      });
    }

    List<CryptoCurrency> items = currencies;
    if (restrictToCurrentBalances) {
      final allowed = {
        for (final asset in widget.balanceByAsset!.keys) asset.title.toUpperCase(),
      };
      items = currencies.where((c) => allowed.contains(c.title.toUpperCase())).toList();
    }

    if (widget.isReceiverCard && widget.filteredNetwork != null) {
      final network = widget.filteredNetwork!;
      items = items.where((c) => cryptoCurrencyOrTokenToWalletType(c) == network).toList();
    }

    if (items.length <= 1) {
      return;
    }

    final selected = widget.isReceiverCard
        ? widget.exchangeViewModel.receiveCurrency
        : widget.exchangeViewModel.depositCurrency;

    CurrencyPickerSheet.show(
      context: context,
      args: CurrencyPickerArgs(
        items: items,
        selected: selected,
        filterByNetwork: widget.filteredNetwork,
        balanceByAsset: widget.balanceByAsset,
        useSingleNetworkLayout: widget.useSingleNetworkLayout,
        recentsSource: RecentsSource.trades,
        onSelected: widget.onCurrencySelected,
        symbolResolver: widget.exchangeViewModel.amountParsingProxy.getCryptoSymbol,
      ),
    );
  }

  Future<void> _presentQRScanner(BuildContext context) async {
    final isCameraPermissionGranted =
        await PermissionHandler.checkPermission(Permission.camera, context);
    if (!isCameraPermissionGranted) {
      return;
    }
    final code = await presentQRScanner(context);
    if (code == null) {
      return;
    }
    if (code.isEmpty) {
      return;
    }

    try {
      final uri = Uri.parse(code);
      widget.exchangeViewModel.receiveAddress = uri.path;
    } catch (_) {}
  }

  void _presentWalletPicker() async {
    final res = await showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SwapAddressSelectionModal(
          isSelectingReceiver: widget.isReceiverCard,
          exchangeViewModel: widget.exchangeViewModel,
        ),
      ),
    );
    if (res != null && res is SwapAddressSelectionResult) {
      if (widget.isReceiverCard) {
        widget.exchangeViewModel.selectedAddressBookWallet = res.walletInfo;
        widget.exchangeViewModel.receiveAddress = res.address!;
        if (res.walletInfo?.name != null) {
          if (res.accountName != null) {
            widget.exchangeViewModel.receiveAddressDisplayName =
                "${res.walletInfo!.name} → ${res.accountName}";
          } else {
            widget.exchangeViewModel.receiveAddressDisplayName = res.walletInfo!.name;
          }
        }
      } else if (res.address == null || res.address!.isEmpty) {
        widget.exchangeViewModel.isSendFromExternal = true;
        askForRefundAddress();
      } else {
        widget.exchangeViewModel.isSendFromExternal = false;
        switchToDepositWallet(res.walletInfo!.name);
      }
    }
  }

  void switchToDepositWallet(String walletName) async {
    final walletType = cryptoCurrencyOrTokenToWalletType(widget.exchangeViewModel.depositCurrency);
    if (walletType == null) {
      return;
    }
    final wallet = await WalletInfo.get(walletName, walletType);
    if (wallet == null) {
      return;
    }
    widget.exchangeViewModel.depositAddress = wallet.address;
    addressController.text = _normalizeAddressFormat(wallet.address);
    widget.walletSwitcherViewModel.selectWallet(wallet);
    await widget.walletSwitcherViewModel.switchToSelectedWallet();
  }

  void askForRefundAddress() async {
    final refundAddress = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RefundAddressModal(
        selectedCurrency: widget.exchangeViewModel.depositCurrency,
        isFromWalletSelection: true,
      ),
    );
    if (refundAddress != null && refundAddress is String) {
      widget.exchangeViewModel.depositAddress = refundAddress;
    } else {
      widget.exchangeViewModel.depositAddress = "";
    }
  }

  void updateFiatAmount() {
    final newText = widget.isReceiverCard
        ? widget.exchangeViewModel.receiveAmountFiat
        : widget.exchangeViewModel.depositAmountFiat;

    if (double.tryParse(fiatAmountController.text) != double.tryParse(newText)) {
      if (newText == "0.00") {
        fiatAmountController.text = "";
      } else {
        fiatAmountController.text =
            newText.replaceAll(RegExp(r"(?<=\.\d*)0+$"), "").replaceAll(RegExp(r"\.$"), "");
      }
    }
  }

  String _middleTruncate(String s, int head, int tail) {
    if (s.length <= head + tail + 3) {
      return s;
    }
    return s.substring(0, head) + "..." + s.substring(s.length - tail);
  }

  String? _getCurrencyChainIconPath(CryptoCurrency curr) {
    try {
      if (curr.chainIconPath != null) {
        return curr.chainIconPath!;
      }

      if (curr.tag != null) {
        final currencyFromTag = CryptoCurrency.fromString(curr.tag!);

        if (currencyFromTag.chainIconPath != null) {
          return currencyFromTag.chainIconPath!;
        }
      }
    } catch (_) {}
    return null;
  }
}
