import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/receive/widgets/receive_address_type_display.dart";
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
import "package:cake_wallet/new-ui/widgets/receive_page/payjoin_copy_modal.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_info_box.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_label_widget.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_large_amount_preview.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/utils/qr_util.dart";
import "package:cake_wallet/utils/share_util.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/receive_page_option.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key, this.typeOverride, this.initialToken});

  final ReceivePageOption? typeOverride;
  final CryptoCurrency? initialToken;

  @override
  Widget build(BuildContext context) => BlocProvider<ReceiveBloc>(
        create: (_) => getIt<ReceiveBloc>(param1: typeOverride, param2: initialToken),
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
      autoGenerateSubaddressStatus: state.isAutoGenerateSubaddressEnabled
          ? AutoGenerateSubaddressStatus.enabled
          : AutoGenerateSubaddressStatus.disabled,
    );
    final canRotate =
        state.hasAddressRotation && !_isMwebOption(state.addressType) && !state.isRotatingAddress;

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ModalTopBar(
          title: largeQrMode ? "" : S.of(context).receive,
          leadingIcon: const Icon(Icons.close),
          trailingIcon: largeQrMode
              ? const Icon(Icons.share)
              : canRotate
                  ? const Icon(Icons.refresh)
                  : null,
          onLeadingPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          onTrailingPressed: () {
            if (largeQrMode) {
              ShareUtil.share(text: state.paymentUri.toString(), context: context);
            } else if (canRotate) {
              context.read<ReceiveBloc>().add(const AddressRotated());
            }
          },
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
    final c = state.tokenCurrency ?? state.inputCurrency;
    if (c is CryptoCurrency) {
      return c.title;
    }
    return c.name.toUpperCase();
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
    if (state.hasPayjoin) {
      showModalBottomSheet<void>(
        isScrollControlled: true,
        context: context,
        builder: (_) => PayjoinCopyModal(uri: state.paymentUri),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: _copyText(state)));
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

  Future<void> _showAmountModal(BuildContext context, ReceiveLoaded state) async {
    final bloc = context.read<ReceiveBloc>();
    final showTokenPicker = state.receivableTokens.length > 1;
    final displayCrypto = state.tokenCurrency ?? state.receivableTokens.firstOrNull;

    await showMaterialModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (_) => ReceiveAmountModal(
        initialAmount: state.requestedAmount?.toStringWithPrecision() ?? "",
        selectedCurrencySymbol: _currencySymbol(state.inputCurrency),
        selectedCurrencyDecimals: state.inputCurrency.decimals,
        useSatoshi: false,
        showTokenPicker: showTokenPicker,
        tokenIconPath: displayCrypto?.iconPath ?? "",
        tokenTitle: displayCrypto?.title ?? "",
        onAmountSubmitted: (raw) => bloc.add(AmountChanged(raw)),
        onCurrencyPickerTap: () => _pickInputCurrency(context, state, bloc),
        onTokenPickerTap: () => _pickToken(context, state, bloc),
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
    final cryptoOption = state.tokenCurrency ?? state.receivableTokens.firstOrNull;
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
    final selected = await showModalBottomSheet<ReceivePageOption>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: state.addressTypeOptions
              .map(
                (option) => ListTile(
                  title: Text(option.value),
                  subtitle: option.description != null ? Text(option.description!) : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected == null) {
      return;
    }

    if (selected == ReceivePageOption.anonPayInvoice ||
        selected == ReceivePageOption.anonPayDonationLink) {
      if (context.mounted) {
        await Navigator.of(context).pushNamed(
          Routes.anonPayInvoicePage,
          arguments: [state.addressEntry.address, selected],
        );
      }
      return;
    }

    bloc.add(AddressTypeSelected(selected));
  }

  Future<void> _openAddressesPage(BuildContext context, ReceiveLoaded state) async {
    final bloc = context.read<ReceiveBloc>();
    await Navigator.of(context).pushNamed(Routes.receiveAddresses, arguments: false);
    bloc.add(const AddressesPageClosed());
  }
}
