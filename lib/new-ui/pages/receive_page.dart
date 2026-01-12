import 'package:cake_wallet/new-ui/widgets/receive_page/receive_amount_display.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_amount_modal.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_info_box.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_label_modal.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_label_widget.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_qr_code.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_seed_type.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_util.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/utils/print_verbose.dart';
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

import 'package:cake_wallet/new-ui/widgets/receive_page/receive_seed_widget.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';

class NewReceivePage extends StatefulWidget {
  const NewReceivePage(
      {super.key,
      required this.addressListViewModel,
      required this.receiveOptionViewModel,
      required this.dashboardViewModel});

  final WalletAddressListViewModel addressListViewModel;
  final ReceiveOptionViewModel receiveOptionViewModel;
  final DashboardViewModel dashboardViewModel;

  @override
  State<NewReceivePage> createState() => _NewReceivePageState();
}

class _NewReceivePageState extends State<NewReceivePage> {
  bool _largeQrMode = false;
  bool _effectsInstalled = false;
  late WalletAddressListItem _addressItemWithLabel;


  @override
  void initState() {
    super.initState();

    _addressItemWithLabel = widget.addressListViewModel.forceRecomputeItems.firstWhere((item) {
      return (item is WalletAddressListItem &&
          item.address == widget.addressListViewModel.uri.address);
    }) as WalletAddressListItem;

    reaction((_) => widget.addressListViewModel.uri, (newAddress) {
          _reloadAddressWithLabel(newAddress);
    });
  }

  @override
  Widget build(BuildContext context) {
    _setEffects(context);

    final hasLabel = _addressItemWithLabel.name != null && _addressItemWithLabel.name!.isNotEmpty;
    final infoboxDismissed = widget.addressListViewModel.wallet.walletInfo.receiveInfoboxDismissed;

    return SafeArea(
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ModalTopBar(
              title: _largeQrMode ? "" : "Receive",
              leadingIcon: Icon(Icons.close),
              trailingIcon: _largeQrMode ? Icon(Icons.share) : widget.addressListViewModel.hasAddressList ? Icon(Icons.refresh) : null,
              onLeadingPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              onTrailingPressed: () {
                if(_largeQrMode) {
                  Share.share(widget.addressListViewModel.uri.address);
                } else if(widget.addressListViewModel.hasAddressList){
                  createNewAddress(widget.addressListViewModel.wallet, "");
                }
              },
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  ReceiveAmountDisplay(walletAddressListViewModel: widget.addressListViewModel, largeQrMode: _largeQrMode,),
                  ReceiveQrCode(
                    addressListViewModel: widget.addressListViewModel,
                    onTap: () {
                      setState(() {
                        _largeQrMode = !_largeQrMode;
                        // _infoboxDimissed = true;
                      });
                    },
                    largeQrMode: _largeQrMode,
                  ),
                  ReceiveSeedTypeDisplay(
                    receiveOptionViewModel: widget.receiveOptionViewModel,
                  ),
                  ReceiveSeedWidget(
                    addressListViewModel: widget.addressListViewModel,
                  ),
                    GestureDetector(
                        onTap: _showLabelModal,
                        child: ReceiveLabelWidget(name: _addressItemWithLabel.name ?? "")),
                  ReceiveBottomButtons(
                    largeQrMode: _largeQrMode,
                    showAccountsButton: widget.addressListViewModel.hasAddressList,
                    showLabelButton: widget.addressListViewModel.hasAddressList && !hasLabel,
                    onCopyButtonPressed: () {
                      printV(widget.addressListViewModel.items);
                      Clipboard.setData(
                          ClipboardData(text: widget.addressListViewModel.uri.address));
                    },
                    onAmountButtonPressed: () {
                      showMaterialModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return ReceiveAmountModal(
                              walletAddressListViewModel: widget.addressListViewModel,
                              onSubmitted: (amount) {}
                            );
                          });
                    },
                    onLabelButtonPressed: _showLabelModal,
                    onAccountsButtonPressed: () {
                      Navigator.of(context).pushNamed(Routes.receiveAddresses, arguments: false);
                    },
                  ),
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
                        child: ReceiveInfoBox.forWalletType(
                          widget.addressListViewModel.type,
                          onDismissed: _dismissInfobox,
                    )),
                  ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dismissInfobox() async {
    widget.addressListViewModel.wallet.walletInfo.receiveInfoboxDismissed = true;
    await widget.addressListViewModel.wallet.walletInfo.save();
    setState(() {});
  }



  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    reaction((_) => widget.receiveOptionViewModel.selectedReceiveOption,
        (ReceivePageOption option) {
      if (widget.dashboardViewModel.type == WalletType.bitcoin &&
          bitcoin!.isBitcoinReceivePageOption(option)) {
        widget.addressListViewModel.setAddressType(bitcoin!.getOptionToType(option));
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
      }
    });

    _effectsInstalled = true;
  }

  void _showLabelModal() {
    showMaterialModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
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
