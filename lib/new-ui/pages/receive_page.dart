import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_address_type.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_address_widget.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_amount_display.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_amount_modal.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_info_box.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_label_modal.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_label_widget.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_large_amount_preview.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_qr_code.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/anonpay/anonpay_donation_link_info.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/src/screens/receive/anonpay_receive_page.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';

class NewReceivePage extends StatefulWidget {
  NewReceivePage(
      {super.key,
      required this.addressListViewModel,
      required this.receiveOptionViewModel,
      required this.dashboardViewModel,
      required this.lightningMode,
      CryptoCurrency? initialCurrency}) {
    if (initialCurrency != null) {
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
        widget.receiveOptionViewModel.selectReceiveOption(widget.receiveOptionViewModel.options
            .firstWhere((item) => item.value.contains("Lightning")));
        widget.addressListViewModel.setTokenCurrency(CryptoCurrency.btcln);
      } else if (widget.addressListViewModel.wallet.type == WalletType.bitcoin) {
        widget.receiveOptionViewModel.selectReceiveOption(widget.receiveOptionViewModel.options
            .firstWhere((item) => item.value.contains("Standard")));
      }
    });

    reaction((_) => widget.addressListViewModel.uri, (newAddress) {
      _reloadAddressWithLabel(newAddress);
    });

    _addressItemWithLabel =
        widget.addressListViewModel.forceRecomputeItems.firstWhereOrNull((item) {
      return (item is WalletAddressListItem &&
          item.address == widget.addressListViewModel.uri.address);
    }) as WalletAddressListItem?;


    reaction((_) => widget.receiveOptionViewModel.selectedReceiveOption,
            (ReceivePageOption option) {
          if (widget.dashboardViewModel.type == WalletType.bitcoin &&
              bitcoin!.isBitcoinReceivePageOption(option)) {
            widget.addressListViewModel.setAddressType(bitcoin!.getOptionToType(option));
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
    final infobox = ReceiveInfoBox.forWalletType(widget.addressListViewModel.type,
        onDismissed: () {
          widget.addressListViewModel.dismissInfobox();
          setState(() {});
        }, autoGenerateSubaddressStatus: widget.dashboardViewModel.settingsStore.autoGenerateSubaddressStatus);

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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ModalTopBar(
              title: _largeQrMode ? "" : S.of(context).receive,
              leadingIcon: Icon(Icons.close),
              trailingIcon: _largeQrMode
                  ? Icon(Icons.share)
                  : widget.addressListViewModel.hasAddressRotation
                          /* TODO rotating is broken on mweb, disabling for now, fix after mvp*/
                          &&
                          !(widget.receiveOptionViewModel.selectedReceiveOption.description ?? "")
                              .toLowerCase()
                              .contains("mweb")
                      ? Icon(Icons.refresh)
                      : null,
              onLeadingPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              onTrailingPressed: () {
                if (_largeQrMode) {
                  Share.share(widget.addressListViewModel.uri.toString());
                } else if (widget.addressListViewModel.hasAddressRotation) {
                  widget.addressListViewModel.rotateAddress();
                }
              },
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
                  if (hasAddressTypeSelector)
                  ReceiveAddressTypeDisplay(
                    lightningMode: widget.lightningMode,
                    receiveOptionViewModel: widget.receiveOptionViewModel,
                    largeQrMode: _largeQrMode,
                  ),
                  ReceiveAddressWidget(
                    addressListViewModel: widget.addressListViewModel,
                  ),
                  GestureDetector(
                      onTap: _showLabelModal,
                      child: ReceiveLabelWidget(
                        name: _addressItemWithLabel?.name ?? "",
                        largeQrMode: _largeQrMode,
                      )),
                  Observer(
                    builder: (_) => ReceiveBottomButtons(
                      key: const ValueKey(0),
                      largeQrMode: _largeQrMode,
                      showAccountsButton: widget.addressListViewModel.hasAddressList,
                      showLabelButton: widget.addressListViewModel.hasAddressList && !hasLabel,
                      onCopyButtonPressed: () {
                        printV(widget.addressListViewModel.hasAddressList);
                        Clipboard.setData(
                          ClipboardData(text: widget.addressListViewModel.uri.address),
                        );
                      },
                      onAmountButtonPressed: () {
                        showMaterialModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.black.withAlpha(80),
                          builder: (context) {
                            return ReceiveAmountModal(
                              walletAddressListViewModel: widget.addressListViewModel,
                              onSubmitted: (amount) {},
                            );
                          },
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
                      largeQrMode: _largeQrMode),
                  if (infobox != null)
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
                          child: infobox),
                    ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLabelModal() {
    showMaterialModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withAlpha(80),
        builder: (context) {
          return getIt.get<ReceiveLabelModal>(param1: _addressItemWithLabel);
        }).then((value) {
      _reloadAddressWithLabel(widget.addressListViewModel.uri);
    });
  }

  void _reloadAddressWithLabel(PaymentURI newAddress) {
    // FIXME: viewmodel doesn't want to load address name here, so we make it. investigate why later
    setState(() {
      _addressItemWithLabel = widget.addressListViewModel.forceRecomputeItems.firstWhere(
              (item) => (item is WalletAddressListItem && item.address == newAddress.address))
          as WalletAddressListItem;
    });
  }
}
