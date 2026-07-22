import "package:cake_wallet/anonpay/anonpay_donation_link_info.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/receive/widgets/receive_address_type_display.dart";
import "package:cake_wallet/new-ui/pages/receive/widgets/receive_address_type_selector.dart";
import "package:cake_wallet/new-ui/pages/receive/widgets/receive_address_widget.dart";
import "package:cake_wallet/new-ui/pages/receive/widgets/receive_amount_display.dart";
import "package:cake_wallet/new-ui/pages/receive/widgets/receive_amount_modal.dart";
import "package:cake_wallet/new-ui/pages/receive/widgets/receive_label_modal.dart";
import "package:cake_wallet/new-ui/pages/receive/widgets/receive_qr_code.dart";
import "package:cake_wallet/new-ui/pages/receive/widgets/receive_token_display.dart";
import "package:cake_wallet/new-ui/viewmodels/receive/receive_bloc.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/payjoin_copy_modal.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_info_box.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_label_widget.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_large_amount_preview.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/receive/anonpay_receive_page.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/utils/qr_util.dart";
import "package:cake_wallet/utils/share_util.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/receive_page_option.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:shared_preferences/shared_preferences.dart";

class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key, this.lightningMode = false, this.initialToken});

  final bool lightningMode;
  final CryptoCurrency? initialToken;

  @override
  Widget build(BuildContext context) => BlocProvider<ReceiveBloc>(
        create: (_) => getIt<ReceiveBloc>(param1: lightningMode, param2: initialToken),
        child: const _ReceivePageBody(),
      );
}

class _ReceivePageBody extends StatefulWidget {
  const _ReceivePageBody();

  @override
  State<_ReceivePageBody> createState() => _ReceivePageBodyState();
}

class _ReceivePageBodyState extends State<_ReceivePageBody> {
  bool _largeQrMode = false;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceBright,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: BlocBuilder<ReceiveBloc, ReceiveState>(
            builder: (context, state) => switch (state) {
              ReceiveLoading() => const _LoadingWidget(),
              ReceiveFailure() => _FailureWidget(code: state.code),
              ReceiveLoaded() => _LoadedWidget(
                  state: state,
                  largeQrMode: _largeQrMode,
                  onQrTap: () => _toggleLargeQr(context, state),
                ),
            },
          ),
        ),
      );

  void _toggleLargeQr(BuildContext context, ReceiveLoaded state) {
    setState(() => _largeQrMode = !_largeQrMode);
    if (!state.infoboxDismissed) {
      context.read<ReceiveBloc>().add(const InfoboxDismissed());
    }
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ModalTopBar(
            title: S.of(context).receive,
            leadingIcon: const Icon(Icons.close),
            onLeadingPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            onTrailingPressed: () {},
          ),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
}

class _FailureWidget extends StatelessWidget {
  const _FailureWidget({required this.code});

  final ReceiveFailureCode code;

  @override
  Widget build(BuildContext context) {
    final message = S.of(context).error_dialog_content;
    return Column(
      children: [
        ModalTopBar(
          title: S.of(context).receive,
          leadingIcon: const Icon(Icons.close),
          onLeadingPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          onTrailingPressed: () {},
        ),
        Expanded(child: Center(child: Text(message))),
      ],
    );
  }
}

class _LoadedWidget extends StatelessWidget {
  const _LoadedWidget({
    required this.state,
    required this.largeQrMode,
    required this.onQrTap,
  });

  final ReceiveLoaded state;
  final bool largeQrMode;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    final hasAddressTypeSelector = state.addressTypeOptions.length > 1;
    final hasLabel = state.addressEntry.label != null && state.addressEntry.label!.isNotEmpty;
    final infobox = ReceiveInfoBox.forWalletType(
      state.walletType,
      supportedCurrencies: state.receivableTokens,
      onDismissed: () => context.read<ReceiveBloc>().add(const InfoboxDismissed()),
      autoGenerateSubaddressStatus: state.isLightning
          ? AutoGenerateSubaddressStatus.disabled
          : state.autoGenerateSubaddressStatus,
    );
    final rotationAvailable =
        state.hasAddressRotation && !_isMwebOption(state.addressType);

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ModalTopBar(
          title: largeQrMode ? "" : S.of(context).receive,
          leadingIcon: const Icon(Icons.close),
          trailingWidget: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: largeQrMode || rotationAvailable
                ? ModernButton(
                    key: ValueKey(largeQrMode),
                    size: 36,
                    icon: largeQrMode
                        ? const Icon(Icons.share)
                        : state.isRotatingAddress
                            ? const CupertinoActivityIndicator()
                            : const Icon(Icons.refresh),
                    onPressed: () {
                      if (largeQrMode) {
                        ShareUtil.share(
                          text: state.paymentUri.toString(),
                          context: context,
                        );
                      } else if (rotationAvailable) {
                        context.read<ReceiveBloc>().add(const AddressRotated());
                      }
                    },
                  )
                : const SizedBox.shrink(),
          ),
          onLeadingPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              ReceiveAmountDisplay(
                displayAmount: state.requestedAmount?.toStringWithPrecision() ?? "",
                cryptoSymbol: _cryptoSymbol(state),
                fiatAmount: state.fiatEquivalent?.toStringWithPrecision() ?? "",
                fiatSymbol: _fiatSymbol(state),
                showFiat: state.fiatEquivalent != null,
                largeQrMode: largeQrMode,
              ),
              ReceiveQrCode(
                qrData: state.paymentUri.toString(),
                embeddedIconAsset: _qrEmbeddedIcon(state),
                hasPayjoin: state.hasPayjoin,
                largeQrMode: largeQrMode,
                isLightMode: !getIt.get<ThemeStore>().currentTheme.isDark,
                onTap: onQrTap,
                isFetching: state.fetchingInvoice,
              ),
              if (state.tokenCurrency != null)
                ReceiveTokenDisplay(
                  token: state.tokenCurrency!,
                  walletType: state.walletType,
                ),
              if (hasAddressTypeSelector && state.addressType != null)
                ReceiveAddressTypeDisplay(
                  selected: state.addressType!,
                  walletType: state.walletType,
                  largeQrMode: largeQrMode,
                  onTap: () => _showAddressTypePicker(context, state),
                  isLoading: state.isChangingAddressType,
                ),
              ReceiveAddressWidget(
                address: state.addressEntry.address,
                walletType: state.walletType,
              ),
              GestureDetector(
                onTap: () => _showLabelModal(context, state),
                child: ReceiveLabelWidget(
                  name: state.addressEntry.label ?? "",
                  largeQrMode: largeQrMode,
                ),
              ),
              ReceiveBottomButtons(
                key: const ValueKey(0),
                largeQrMode: largeQrMode,
                copyData: state.hasPayjoin ? null : ClipboardData(text: _copyText(state)),
                showAccountsButton: state.hasAddressList,
                showLabelButton: state.hasAddressList && !hasLabel,
                onCopyButtonPressed: () => _onCopy(context, state),
                onAmountButtonPressed: () => _showAmountModal(context, state),
                onLabelButtonPressed: () => _showLabelModal(context, state),
                onAccountsButtonPressed: () => _openAddressesPage(context, state),
              ),
              ReceiveLargeAmountPreview(
                amount: state.requestedAmount?.toStringWithPrecision() ?? "",
                currency: _cryptoSymbol(state),
                largeQrMode: largeQrMode,
              ),
              if (infobox != null && !state.isLightning)
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    heightFactor: state.infoboxDismissed ? 0 : 1,
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: state.infoboxDismissed ? 0 : 1,
                      curve: Curves.easeOutCubic,
                      child: infobox,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isMwebOption(ReceivePageOption? option) {
    if (option == null) {
      return false;
    }
    return (option.description ?? "").toLowerCase().contains("mweb");
  }

  String _cryptoSymbol(ReceiveLoaded state) {
    final currency = state.tokenCurrency ?? state.walletCurrency;
    return currency.title;
  }

  String _fiatSymbol(ReceiveLoaded state) => state.fiatEquivalent?.currency.name ?? "";

  String _qrEmbeddedIcon(ReceiveLoaded state) {
    if (state.tokenCurrency != null && state.tokenCurrency != CryptoCurrency.btcln) {
      return state.tokenCurrency!.iconPath ?? getQrImage(state.walletType);
    }
    if (state.isLightning) {
      return "assets/images/btc_chain_qr_lightning.svg";
    }
    return getQrImage(state.walletType);
  }

  void _onCopy(BuildContext context, ReceiveLoaded state) {
    if (!state.hasPayjoin) {
      return;
    }
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (_) => PayjoinCopyModal(uri: state.paymentUri),
    );
  }

  String _copyText(ReceiveLoaded state) =>
      state.requestedAmount == null ? state.paymentUri.address : state.paymentUri.toString();

  Future<void> _showLabelModal(BuildContext context, ReceiveLoaded state) async {
    final bloc = context.read<ReceiveBloc>();
    await showMaterialModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (_) => ReceiveLabelModal(
        initialLabel: state.addressEntry.label ?? "",
        onSubmit: (label) async => bloc.add(LabelSubmitted(label)),
      ),
    );
  }

  Future<void> _showAmountModal(BuildContext context, ReceiveLoaded initialState) async {
    final bloc = context.read<ReceiveBloc>();
    final initialAmount = initialState.inputCurrency is FiatCurrency
        ? initialState.fiatEquivalent?.toStringWithPrecision() ?? ""
        : initialState.requestedAmount?.toStringWithPrecision() ?? "";

    await showMaterialModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (_) => BlocProvider<ReceiveBloc>.value(
        value: bloc,
        child: BlocBuilder<ReceiveBloc, ReceiveState>(
          buildWhen: (a, b) => b is ReceiveLoaded,
          builder: (context, state) {
            if (state is! ReceiveLoaded) {
              return const SizedBox.shrink();
            }
            final displayCrypto = state.tokenCurrency ?? state.walletCurrency;
            final modalKey = ValueKey<String>(state.tokenCurrency?.title ?? "wallet");
            final displayInitialAmount = state.inputCurrency is FiatCurrency
                ? state.fiatEquivalent?.toStringWithPrecision() ?? ""
                : state.requestedAmount?.toStringWithPrecision() ?? "";
            return ReceiveAmountModal(
              key: modalKey,
              initialAmount:
                  displayInitialAmount.isEmpty ? initialAmount : displayInitialAmount,
              selectedCurrencySymbol: _currencySymbol(state.inputCurrency),
              selectedCurrencyDecimals: state.useSatoshi ? 0 : state.inputCurrency.decimals,
              useSatoshi: state.useSatoshi,
              showTokenPicker: state.hasTokensList,
              tokenIconPath: displayCrypto.iconPath ?? "",
              tokenTitle: displayCrypto.title,
              onAmountSubmitted: (raw) => bloc.add(AmountChanged(raw)),
              onCurrencyPickerTap: () => _pickInputCurrency(context, state, bloc),
              onTokenPickerTap: () => _pickToken(context, state, bloc),
            );
          },
        ),
      ),
    );
  }

  String _currencySymbol(Currency c) {
    if (c is CryptoCurrency) {
      return c.title;
    }
    return c.name.toUpperCase();
  }

  Future<void> _pickInputCurrency(
    BuildContext context,
    ReceiveLoaded state,
    ReceiveBloc bloc,
  ) async {
    final cryptoOption = state.tokenCurrency ?? state.walletCurrency;
    await FiatCurrencyPickerSheet.show(
      context: context,
      selected: state.inputCurrency,
      cryptoOption: cryptoOption,
      onSelected: (fiat) => bloc.add(InputCurrencySelected(fiat)),
      onCryptoSelected: (crypto) => bloc.add(InputCurrencySelected(crypto)),
    );
  }

  Future<void> _pickToken(
    BuildContext context,
    ReceiveLoaded state,
    ReceiveBloc bloc,
  ) async {
    await CurrencyPickerSheet.show(
      context: context,
      args: CurrencyPickerArgs(
        items: state.receivableTokens,
        selected: state.tokenCurrency,
        onSelected: (currency) => bloc.add(TokenPresetSelected(currency)),
        symbolResolver: (c) => c.title,
      ),
    );
  }

  Future<void> _showAddressTypePicker(BuildContext context, ReceiveLoaded state) async {
    final bloc = context.read<ReceiveBloc>();
    final currentSelected = state.addressType ?? ReceivePageOption.mainnet;
    final lightningMode = state.isLightning;
    final selected = await showCupertinoModalBottomSheet<ReceivePageOption>(
      context: context,
      barrierColor: Colors.black.withAlpha(80),
      builder: (_) => Material(
        child: ReceiveAddressTypeSelector(
          options: state.addressTypeOptions,
          selected: currentSelected,
          walletType: state.walletType,
          lightningMode: lightningMode,
        ),
      ),
    );

    if (selected == null) {
      return;
    }

    if (selected == ReceivePageOption.anonPayInvoice) {
      if (context.mounted) {
        await Navigator.of(context).pushNamed(
          Routes.anonPayInvoicePage,
          arguments: [state.addressEntry.address, selected],
        );
      }
      return;
    }

    if (selected == ReceivePageOption.anonPayDonationLink) {
      if (context.mounted) {
        await _openAnonPayDonationLink(context, state, selected);
      }
      return;
    }

    bloc.add(AddressTypeSelected(selected));
  }

  Future<void> _openAnonPayDonationLink(
    BuildContext context,
    ReceiveLoaded state,
    ReceivePageOption option,
  ) async {
    final prefs = getIt.get<SharedPreferences>();
    final clearnetUrl = prefs.getString(PreferencesKey.clearnetDonationLink);
    final onionUrl = prefs.getString(PreferencesKey.onionDonationLink);
    final donationWalletName = prefs.getString(PreferencesKey.donationLinkWalletName);
    final walletName = getIt.get<AppStore>().wallet?.name;
    final qrImage = state.isLightning
        ? "assets/images/btc_chain_qr_lightning.svg"
        : getQrImage(state.walletType);

    if (clearnetUrl != null &&
        onionUrl != null &&
        walletName != null &&
        walletName == donationWalletName) {
      await Navigator.of(context).pushNamed(
        Routes.anonPayReceivePage,
        arguments: AnonPayReceivePageArgs(
          invoiceInfo: AnonpayDonationLinkInfo(
            clearnetUrl: clearnetUrl,
            onionUrl: onionUrl,
            address: state.addressEntry.address,
          ),
          qrImage: qrImage,
        ),
      );
    } else {
      await Navigator.of(context).pushNamed(
        Routes.anonPayInvoicePage,
        arguments: [state.addressEntry.address, option],
      );
    }
  }

  Future<void> _openAddressesPage(BuildContext context, ReceiveLoaded state) async {
    final bloc = context.read<ReceiveBloc>();
    await Navigator.of(context).pushNamed(Routes.receiveAddresses, arguments: false);
    bloc.add(const AddressesPageClosed());
  }
}
