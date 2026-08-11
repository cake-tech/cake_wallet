import "package:cake_wallet/anonpay/anonpay_donation_link_info.dart";
import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/payjoin_copy_modal.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_address_type.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_address_widget.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_amount_display.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_amount_modal.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_info_box.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_label_modal.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_label_widget.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_large_amount_preview.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_qr_code.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_token_display.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/receive/anonpay_receive_page.dart";
import "package:cake_wallet/utils/share_util.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/dashboard/receive_option_view_model.dart";
import "package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart";
import "package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:shared_preferences/shared_preferences.dart";

class NewReceivePage extends StatefulWidget {
  NewReceivePage({
    required this.addressListViewModel,
    required this.receiveOptionViewModel,
    required this.dashboardViewModel,
    required this.lightningMode,
    super.key,
    CryptoCurrency? initialCurrency,
  }) {
    if (initialCurrency != null && initialCurrency != addressListViewModel.selectedCurrency) {
      addressListViewModel.setTokenCurrency(initialCurrency);
    }
  }

  final WalletAddressListViewModel addressListViewModel;
  final ReceiveOptionViewModel receiveOptionViewModel;
  final DashboardViewModel dashboardViewModel;
  final bool lightningMode;

  @override
  State<NewReceivePage> createState() => _NewReceivePageState();
}

class _NewReceivePageState extends State<NewReceivePage> {
  bool _largeQrMode = false;
  late WalletAddressListItem? _addressItemWithLabel;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.lightningMode) {
        widget.receiveOptionViewModel.selectReceiveOption(
          widget.receiveOptionViewModel.options
                  .firstWhereOrNull((item) => item.value.contains("Lightning")) ??
              ReceivePageOption.mainnet,
        );
        widget.addressListViewModel.selectedCurrency = CryptoCurrency.btcln;
      } else if (widget.addressListViewModel.wallet.type == WalletType.bitcoin) {
        widget.receiveOptionViewModel.selectReceiveOption(
          widget.receiveOptionViewModel.options
                  .firstWhereOrNull((item) => item.value.contains("Standard")) ??
              ReceivePageOption.mainnet,
        );
        widget.addressListViewModel.selectedCurrency = CryptoCurrency.btc;
      }
    });

    reaction((_) => widget.addressListViewModel.uri, _reloadAddressWithLabel);

    _addressItemWithLabel = widget.addressListViewModel.forceRecomputeItems.firstWhereOrNull(
      (item) =>
          item is WalletAddressListItem && item.address == widget.addressListViewModel.uri.address,
    ) as WalletAddressListItem?;

    reaction((_) => widget.receiveOptionViewModel.selectedReceiveOption, (option) {
      // The infobox depends on the selected address type, so the page has to be
      // rebuilt when it changes.
      if (mounted) setState(() {});

      if (widget.dashboardViewModel.type == WalletType.bitcoin &&
          bitcoin!.isBitcoinReceivePageOption(option)) {
        widget.addressListViewModel.setAddressType(bitcoin!.getOptionToType(option));
        if (option.value.contains("Lightning")) {
          widget.addressListViewModel.selectedCurrency = CryptoCurrency.btcln;
        } else {
          widget.addressListViewModel.selectedCurrency = CryptoCurrency.btc;
        }
        return;
      }
      if (widget.dashboardViewModel.type == WalletType.zcash) {
        widget.addressListViewModel.setAddressType(zcash!.getOptionToType(option));
        return;
      }

      switch (option) {
        case ReceivePageOption.anonPayInvoice:
          Navigator.pushNamed(
            context,
            Routes.anonPayInvoicePage,
            arguments: [widget.addressListViewModel.address.address, option],
          );
          break;
        case ReceivePageOption.anonPayDonationLink:
          final sharedPreferences = getIt.get<SharedPreferences>();
          final clearnetUrl = sharedPreferences.getString(PreferencesKey.clearnetDonationLink);
          final onionUrl = sharedPreferences.getString(PreferencesKey.onionDonationLink);
          final donationWalletName =
              sharedPreferences.getString(PreferencesKey.donationLinkWalletName);

          if (clearnetUrl != null &&
              onionUrl != null &&
              widget.addressListViewModel.wallet.name == donationWalletName) {
            Navigator.pushNamed(
              context,
              Routes.anonPayReceivePage,
              arguments: AnonPayReceivePageArgs(
                invoiceInfo: AnonpayDonationLinkInfo(
                  clearnetUrl: clearnetUrl,
                  onionUrl: onionUrl,
                  address: widget.addressListViewModel.address.address,
                ),
                qrImage: widget.addressListViewModel.qrImage,
              ),
            );
          } else {
            Navigator.pushNamed(
              context,
              Routes.anonPayInvoicePage,
              arguments: [widget.addressListViewModel.address.address, option],
            );
          }
          break;
        default:
          if ([WalletType.bitcoin, WalletType.litecoin]
              .contains(widget.addressListViewModel.type)) {
            widget.addressListViewModel.setAddressType(bitcoin!.getBitcoinAddressType(option));
          }
          if (widget.addressListViewModel.type == WalletType.zcash) {
            printV("help me i'll kms if that wont work: ${zcash!.getZcashAddressType(option)}");
            widget.addressListViewModel.setAddressType(zcash!.getZcashAddressType(option));
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAddressTypeSelector = widget.receiveOptionViewModel.options.length > 1;
    final hasLabel = _addressItemWithLabel?.name != null && _addressItemWithLabel!.name!.isNotEmpty;
    final infoboxDismissed = widget.addressListViewModel.wallet.walletInfo.receiveInfoboxDismissed;
    final infobox = ReceiveInfoBox.forWalletType(
      widget.addressListViewModel.type,
      supportedCurrencies:
          widget.addressListViewModel.tokenCurrencies.whereType<CryptoCurrency>().toList(),
      onDismissed: () {
        widget.addressListViewModel.dismissInfobox();
        setState(() {});
      },
      autoGenerateSubaddressStatus: widget.lightningMode
          ? AutoGenerateSubaddressStatus.disabled
          : widget.dashboardViewModel.settingsStore.autoGenerateSubaddressStatus,
      addressRotates: _selectedAddressRotates,
    );

    return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ModalTopBar(
              title: _largeQrMode ? "" : S.of(context).receive,
              leadingIcon: const Icon(Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              trailingWidget: Observer(
                builder: (_) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _largeQrMode ||
                          widget.addressListViewModel.hasAddressRotation
                              /* TODO rotating is broken on mweb, disabling for now, fix after mvp*/
                              &&
                              !(widget.receiveOptionViewModel.selectedReceiveOption.description ??
                                      "")
                                  .toLowerCase()
                                  .contains("mweb")
                      ? ModernButton(
                          key: ValueKey(_largeQrMode),
                          size: 36,
                          icon: _largeQrMode
                              ? const Icon(Icons.share)
                              : widget.addressListViewModel.isRotatingAddress
                                  ? const CupertinoActivityIndicator()
                                  : const Icon(Icons.refresh),
                          semanticLabel: _largeQrMode
                              ? S.of(context).share_address
                              : S.of(context).rotate_address,
                          onPressed: () {
                            if (_largeQrMode) {
                              ShareUtil.share(
                                text: widget.addressListViewModel.uri.toString(),
                                context: context,
                              );
                            } else {
                              if (widget.addressListViewModel.hasAddressRotation) {
                                widget.addressListViewModel.rotateAddress();
                              }
                            }
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  ReceiveAmountDisplay(
                    walletAddressListViewModel: widget.addressListViewModel,
                    largeQrMode: _largeQrMode,
                  ),
                  ReceiveQrCode(
                    addressListViewModel: widget.addressListViewModel,
                    onTap: () {
                      setState(() {
                        _largeQrMode = !_largeQrMode;
                        // _infoboxDimissed = true;
                        widget.addressListViewModel.dismissInfobox();
                      });
                    },
                    largeQrMode: _largeQrMode,
                  ),
                  if (widget.addressListViewModel.tokenCurrency != null)
                    ReceiveTokenDisplay(addressListViewModel: widget.addressListViewModel),
                  if (hasAddressTypeSelector)
                    ReceiveAddressTypeDisplay(
                      lightningMode: widget.lightningMode,
                      receiveOptionViewModel: widget.receiveOptionViewModel,
                      largeQrMode: _largeQrMode,
                    ),
                  ReceiveAddressWidget(
                    addressListViewModel: widget.addressListViewModel,
                  ),
                  // The label chip animates to zero height when there is no
                  // label (or in large QR mode); keep it out of the semantics
                  // tree entirely while it is collapsed.
                  ExcludeSemantics(
                    excluding: _largeQrMode || !hasLabel,
                    child: MergeSemantics(
                      child: Semantics(
                        button: true,
                        hint: S.of(context).set_label,
                        child: GestureDetector(
                          onTap: _showLabelModal,
                          child: ReceiveLabelWidget(
                            name: _addressItemWithLabel?.name ?? "",
                            largeQrMode: _largeQrMode,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Observer(
                    builder: (_) => ReceiveBottomButtons(
                      key: const ValueKey(0),
                      largeQrMode: _largeQrMode,
                      showAccountsButton: widget.addressListViewModel.hasAddressList,
                      showLabelButton: widget.addressListViewModel.hasAddressList && !hasLabel,
                      copyData: widget.addressListViewModel.hasPayjoin
                          ? null
                          : ClipboardData(
                              text: widget.addressListViewModel.displayAmount.isEmpty
                                  ? widget.addressListViewModel.uri.address
                                  : widget.addressListViewModel.uri.toString(),
                            ),
                      onCopyButtonPressed: () {
                        if (widget.addressListViewModel.hasPayjoin) {
                          showModalBottomSheet(
                            isScrollControlled: true,
                            context: context,
                            builder: (context) =>
                                PayjoinCopyModal(uri: widget.addressListViewModel.uri),
                          );
                        }
                      },
                      onAmountButtonPressed: () {
                        showMaterialModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.black.withAlpha(80),
                          builder: (context) => ReceiveAmountModal(
                            walletAddressListViewModel: widget.addressListViewModel,
                            onSubmitted: (amount) {},
                          ),
                        );
                      },
                      onLabelButtonPressed: _showLabelModal,
                      onAccountsButtonPressed: () {
                        Navigator.of(context).pushNamed(
                          Routes.receiveAddresses,
                          arguments: false,
                        );
                      },
                    ),
                  ),
                  ReceiveLargeAmountPreview(
                    amount: widget.addressListViewModel.displayAmount,
                    currency: widget.addressListViewModel.cryptoCurrencySymbol,
                    largeQrMode: _largeQrMode,
                  ),
                  if (infobox != null && !widget.addressListViewModel.isLightning)
                    ClipRect(
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        heightFactor: infoboxDismissed ? 0 : 1,
                        alignment: Alignment.center,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: infoboxDismissed ? 0 : 1,
                          curve: Curves.easeOutCubic,
                          child: infobox,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Zcash is the only wallet type that also offers static address types, so
  /// the rotation notice must not be shown for it unless the disposable
  /// transparent type is the one currently selected.
  bool get _selectedAddressRotates =>
      widget.addressListViewModel.type != WalletType.zcash ||
      zcash!.isRotatingAddressOption(widget.receiveOptionViewModel.selectedReceiveOption);

  void _showLabelModal() {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (_) => getIt.get<ReceiveLabelModal>(param1: _addressItemWithLabel),
    ).then((value) {
      _reloadAddressWithLabel(widget.addressListViewModel.uri);
    });
  }

  void _reloadAddressWithLabel(PaymentURI newAddress) {
    // FIXME: viewmodel doesn't want to load address name here, so we make it. investigate why later
    setState(() {
      _addressItemWithLabel = widget.addressListViewModel.forceRecomputeItems.firstWhereOrNull(
        (item) => item is WalletAddressListItem && item.address == newAddress.address,
      ) as WalletAddressListItem?;
    });
  }
}
