import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/entities/spark_conversion.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/send_page.dart" show SendHelpPage, SendPageHelpContent;
import "package:cake_wallet/new-ui/viewmodels/spark_deposit_to_stable/spark_deposit_to_stable_bloc.dart";
import "package:cake_wallet/new-ui/widgets/animated_dropdown.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/new_future_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/fiat_amount_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_amount_input.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/src/widgets/picker.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

String? _errorOf(SparkDepositToStableLoaded state) => switch (state) {
      SparkDepositToStableReady(:final error) => error,
      SparkDepositToStableFailed(:final error) => error,
      _ => null,
    };

/// [SparkDepositToStableLoaded] is sealed, so this switch stays exhaustive as new phases are added.
SparkConversionQuote? _quoteOf(SparkDepositToStableLoaded state) => switch (state) {
      SparkDepositToStableReady(:final quote) => quote,
      SparkDepositToStableSubmitting(:final quote) => quote,
      SparkDepositToStableFailed(:final quote) => quote,
      SparkDepositToStableSucceeded(:final quote) => quote,
    };

/// Single-page "Deposit to Stable" flow: a one-off, user-initiated BTC -> stablecoin Spark token
/// conversion, reached by tapping Swap on a stablecoin asset card (see
/// `asset_details_modal.dart`). Bloc-wired, unlike `NewSendPage`'s `SendPageModes` variants -
/// this is a deliberately separate flow, not another send mode.
class SparkDepositToStablePage extends StatefulWidget {
  const SparkDepositToStablePage({required this.bloc, super.key});

  final SparkDepositToStableBloc bloc;

  @override
  State<SparkDepositToStablePage> createState() => _SparkDepositToStablePageState();

  /// Mirrors `SendPageModes.lightningDeposit`'s help content - same tone, same reused
  /// [SendHelpPage]/[SendPageHelpContent] classes (they're generic despite the "Send" naming).
  /// [token]'s real logo replaces `stable_conversion_help.svg`'s sketch-placeholder "$" circle
  /// once it's known (the page's Bloc state hasn't loaded it yet only very briefly) - composed
  /// live as a Stack rather than hand-drawn into the static asset, the same overlapping-icons
  /// pattern `history_tile.dart` already uses for a token's chain badge.
  static SendPageHelpContent helpContentFor(CryptoCurrency? token) => SendPageHelpContent(
        title: S.current.deposit_to_stable_title,
        imagePath: "assets/new-ui/stable_conversion_help.svg",
        imageWidget: token == null
            ? null
            : SizedBox(
                width: 100,
                height: 68,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 2,
                      child: TokenImageWidget(imageUrl: token.iconPath ?? "", size: 60),
                    ),
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: CakeImageWidget(
                        imageUrl: "assets/new-ui/lightning-icon.svg",
                        width: 60,
                        height: 60,
                      ),
                    ),
                  ],
                ),
              ),
        description: S.current.convert_to_stable_help_desc,
        disclaimer: S.current.convert_to_stable_help_disclaimer,
      );
}

class _SparkDepositToStablePageState extends State<SparkDepositToStablePage> {
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) => BlocProvider<SparkDepositToStableBloc>.value(
        value: widget.bloc,
        child: BlocConsumer<SparkDepositToStableBloc, SparkDepositToStableState>(
          bloc: widget.bloc,
          // Only fires a real text change after FiatEntryToggled converts the amount server-side
          // (see SparkDepositToStableBloc._onFiatEntryToggled) - during normal typing, state.amountText
          // already equals the controller's own text, so this is a no-op.
          listener: (context, state) {
            if (state is SparkDepositToStableLoaded && _amountController.text != state.amountText) {
              _amountController.text = state.amountText;
            }
          },
          builder: (context, state) => Material(
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
              child: SafeArea(
                child: Column(
                  children: [
                    ModalTopBar(
                      title: S.of(context).deposit_to_stable_title,
                      leadingIcon: const Icon(Icons.arrow_back_ios_new),
                      leadingSemanticLabel: S.of(context).seed_alert_back,
                      onLeadingPressed: Navigator.of(context).pop,
                      trailingIcon: CakeImageWidget(
                        imageUrl: "assets/new-ui/help.svg",
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      trailingSemanticLabel: S.of(context).help,
                      onTrailingPressed: () => Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (context) => Material(
                            child: SendHelpPage(
                              content: SparkDepositToStablePage.helpContentFor(
                                state is SparkDepositToStableLoaded ? state.token : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _body(context, state)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _amountController.removeListener(_onAmountFieldChanged);
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountFieldChanged);
  }

  Widget _body(BuildContext context, SparkDepositToStableState state) {
    if (state is SparkDepositToStableNotLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // A real configuration error (no stablecoin token, or no Lightning support) - shown plainly
    // rather than hidden behind a blank/loading screen, per this codebase's error-handling rules.
    if (state is SparkDepositToStableUnavailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    final loaded = state as SparkDepositToStableLoaded;

    if (loaded is SparkDepositToStableSucceeded) {
      return _SuccessView(state: loaded);
    }

    final quote = _quoteOf(loaded);
    final error = _errorOf(loaded);
    final isQuoting = loaded is SparkDepositToStableReady && loaded.isQuoting;
    final isSubmitting = loaded is SparkDepositToStableSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(S.of(context).deposit_to_stable_amount_label),
          if (loaded.direction == ConversionDirection.fromBitcoin) ...[
            NewSendAmountInput(
              currency: loaded.isFiatEntry ? widget.bloc.fiatCurrency.title : "sats",
              currencyIconPath: loaded.isFiatEntry ? "" : CryptoCurrency.btcln.iconPath ?? "",
              maxDecimals: loaded.isFiatEntry ? widget.bloc.fiatCurrency.decimals : 0,
              hasPicker: true,
              onPickerClicked: () => loaded.isFiatEntry
                  ? _presentFiatCurrencyPicker(context)
                  : _presentAssetPicker(context, loaded),
              amountController: _amountController,
            ),
            // The BTC/sats budget is the primary input (or its fiat equivalent, toggled here) -
            // the resulting stablecoin amount is only known once a quote comes back, so it's
            // shown separately below rather than in this bar. Reuses the same bar `NewSendPage`
            // shows for its own amount fields; the switch is disabled exactly when fiat display
            // is off in Settings, same as the regular Send flow.
            FiatAmountBar(
              fiatInputMode: loaded.isFiatEntry,
              switchEnabled: !widget.bloc.isFiatDisabled,
              onSwitchButtonPressed: () => widget.bloc.add(FiatEntryToggled()),
              cryptoAmount: loaded.isFiatEntry
                  ? widget.bloc
                      .convertedAmountText(loaded.amountText, isFiatEntry: loaded.isFiatEntry)
                  : loaded.amountText,
              cryptoCurrencySymbol: "sats",
              fiatAmount: loaded.isFiatEntry
                  ? loaded.amountText
                  : widget.bloc
                      .convertedAmountText(loaded.amountText, isFiatEntry: loaded.isFiatEntry),
              fiatCurrencySymbol: widget.bloc.fiatCurrency.symbol,
              allAmount: widget.bloc.availableLightningBalance?.toStringWithPrecision(
                useBaseUnit: true,
              ),
              onAllButtonPressed: () {
                final sats = widget.bloc.availableLightningBalance;
                if (sats == null) {
                  return;
                }

                final satsText = sats.toStringWithPrecision(useBaseUnit: true);
                _amountController.text = loaded.isFiatEntry
                    ? widget.bloc.convertedAmountText(satsText, isFiatEntry: false)
                    : satsText;
              },
            ),
            if (quote != null)
              Text(
                S.of(context).deposit_to_stable_quote_label(quote.amountOut.toStringWithSymbol()),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ] else ...[
            // Converting TO Bitcoin: the amount typed is always token-denominated, and the
            // secondary bar shows the estimated sats you'll receive - no fiat toggle here (see
            // SparkDepositToStableLoaded.isFiatEntry's doc comment).
            NewSendAmountInput(
              currency: loaded.token.title,
              currencyIconPath: loaded.token.iconPath ?? "",
              maxDecimals: loaded.token.decimals,
              hasPicker: true,
              onPickerClicked: () => _presentAssetPicker(context, loaded),
              amountController: _amountController,
            ),
            FiatAmountBar(
              fiatInputMode: false,
              switchEnabled: false,
              onSwitchButtonPressed: () {},
              cryptoAmount: loaded.amountText,
              cryptoCurrencySymbol: loaded.token.title,
              fiatAmount: quote?.amountOut.toStringWithPrecision(useBaseUnit: true) ?? "0",
              fiatCurrencySymbol: "sats",
              allAmount: widget.bloc.availableTokenBalance(loaded.token)?.toStringWithPrecision(),
              onAllButtonPressed: () {
                final tokenBalance = widget.bloc.availableTokenBalance(loaded.token);
                if (tokenBalance == null) {
                  return;
                }

                _amountController.text = tokenBalance.toStringWithPrecision();
              },
            ),
          ],
          if (isQuoting)
            const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (error != null)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          AnimatedDropdown(
            dropdownText: S.of(context).advanced_settings,
            content: NewListSections(
              sections: {
                "": [
                  // Redundant when converting FROM the token - it's already shown directly in the
                  // primary amount field's own currency selector in that direction.
                  if (loaded.direction == ConversionDirection.fromBitcoin)
                    ListItemRegularRow(
                      keyValue: "deposit_to_stable_token",
                      label: S.of(context).token,
                      showArrow: false,
                      trailingText: loaded.token.title,
                      trailingWidget:
                          TokenImageWidget(imageUrl: loaded.token.iconPath ?? "", size: 20),
                    ),
                  ListItemRegularRow(
                    keyValue: "deposit_to_stable_max_slippage",
                    label: S.of(context).stable_balance_max_conversion_slippage,
                    showArrow: true,
                    trailingText: widget.bloc.slippageLabel(loaded.maxSlippageBps),
                    onTap: isSubmitting ? null : () => _pickMaxSlippage(context, loaded),
                  ),
                ],
              },
            ),
          ),
          // Deliberately outside Advanced Settings - this links to a separate settings screen
          // (Stable Balance auto-convert) rather than configuring anything about this one-off
          // conversion, so it doesn't belong grouped with the flow's own advanced options.
          NewListSections(
            sections: {
              "": [
                ListItemRegularRow(
                  keyValue: "deposit_to_stable_configure_stable_balance",
                  label: S.of(context).configure_stable_balance,
                  subtitle: S.of(context).stable_balance_description,
                  showArrow: true,
                  onTap: () => Navigator.of(context).pushNamed(
                    Routes.sparkSettingsPage,
                    arguments: getIt.get<BalanceViewModel>(),
                  ),
                ),
              ],
            },
          ),
          const SizedBox(height: 8),
          NewFuturePrimaryButton(
            onPressed: () async => widget.bloc.add(ConversionRequested()),
            text: S.of(context).deposit_to_stable_confirm_button,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            disabled: isSubmitting || quote == null,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _onAmountFieldChanged() => widget.bloc.add(AmountChanged(_amountController.text));

  Future<void> _pickMaxSlippage(BuildContext context, SparkDepositToStableLoaded loaded) async {
    await showPopUp<void>(
      context: context,
      builder: (context) => Picker<int>(
        items: SparkDepositToStableBloc.maxSlippagePresetsBps,
        selectedAtIndex: SparkDepositToStableBloc.maxSlippagePresetsBps.indexOf(loaded.maxSlippageBps),
        displayItem: widget.bloc.slippageLabel,
        mainAxisAlignment: MainAxisAlignment.start,
        isSeparated: false,
        onItemSelected: (bps) => widget.bloc.add(MaxSlippageChanged(bps)),
      ),
    );
  }

  /// Lets the user pick which asset they're spending to acquire the other - BTC/sats (converting
  /// FROM Bitcoin) or the stablecoin token (converting TO Bitcoin). Only two items, but reuses
  /// the same generic picker every other asset selection in the app uses, rather than a bespoke
  /// two-way toggle.
  void _presentAssetPicker(BuildContext context, SparkDepositToStableLoaded loaded) {
    CurrencyPickerSheet.show(
      context: context,
      args: CurrencyPickerArgs(
        items: [CryptoCurrency.btcln, loaded.token],
        selected: loaded.direction == ConversionDirection.fromBitcoin
            ? CryptoCurrency.btcln
            : loaded.token,
        symbolResolver: (c) => c.title,
        onSelected: (currency) => widget.bloc.add(
          DirectionChanged(
            currency == CryptoCurrency.btcln
                ? ConversionDirection.fromBitcoin
                : ConversionDirection.toBitcoin,
          ),
        ),
      ),
    );
  }

  void _presentFiatCurrencyPicker(BuildContext context) {
    FiatCurrencyPickerSheet.show(
      context: context,
      selected: widget.bloc.fiatCurrency,
      onSelected: widget.bloc.setFiatCurrency,
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.state});

  final SparkDepositToStableSucceeded state;

  @override
  Widget build(BuildContext context) {
    final isReverse = state.direction == ConversionDirection.toBitcoin;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          Text(
            isReverse
                ? S.of(context).deposit_to_stable_success_message_reverse
                : S.of(context).deposit_to_stable_success_message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Text(
                state.quote.amountOut.toStringWithPrecision(useBaseUnit: isReverse),
                textAlign: TextAlign.center,
              ),
              CakeImageWidget(
                imageUrl:
                    isReverse ? CryptoCurrency.btcln.iconPath ?? "" : state.token.iconPath ?? "",
                width: 20,
                height: 20,
              ),
              Text(
                state.quote.amountOut.getSymbol(useBaseUnit: isReverse),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 16),
          NewFuturePrimaryButton(
            onPressed: () async => Navigator.of(context).pop(),
            text: S.of(context).done,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}
