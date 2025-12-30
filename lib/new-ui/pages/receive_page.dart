import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_amount_input.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_amount_modal.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_info_box.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_qr_code.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_seed_type.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/anonpay/anonpay_donation_link_info.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/src/screens/receive/anonpay_receive_page.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/receive_page/receive_seed_widget.dart';
import '../widgets/receive_page/receive_top_bar.dart';

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
  bool _infoboxDimissed = false;

  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountController.addListener(() {
      widget.addressListViewModel.changeAmount(_amountController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    _setEffects(context);

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
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ModalTopBar(
              title: _largeQrMode ? "" : "Receive",
              leadingIcon: Icon(Icons.close),
              trailingIcon: _largeQrMode ? Icon(Icons.share) : Icon(Icons.refresh),
              onLeadingPressed: () {
                Navigator.of(context).pop();
              },
              onTrailingPressed: () {
                Share.share(widget.addressListViewModel.uri.address);
              },
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: [
                  ReceiveQrCode(
                    addressListViewModel: widget.addressListViewModel,
                    onTap: () {
                      setState(() {
                        _largeQrMode = !_largeQrMode;
                        _infoboxDimissed = true;
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
                  // Observer(
                  //   builder: (_) => ReceiveAmountInput(
                  //     largeQrMode: _largeQrMode,
                  //     amountController: _amountController,
                  //     selectedCurrency: widget.addressListViewModel.selectedCurrency.name,
                  //     onCurrencySelectorTap: () {
                  //       _presentCurrencyPicker(context);
                  //     },
                  //   ),
                  // ),
                  ReceiveBottomButtons(
                    largeQrMode: _largeQrMode,
                    onCopyButtonPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: widget.addressListViewModel.uri.address));
                    },
                    onAmountButtonPressed: () {
showMaterialModalBottomSheet(context: context,backgroundColor: Colors.transparent, builder: (context){return ReceiveAmountModal();});


                    },
                    onLabelButtonPressed: () {},
                    onAccountsButtonPressed: () {},
                  ),
                  ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      heightFactor: _infoboxDimissed ? 0 : 1,
                      alignment: Alignment.center,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _infoboxDimissed ? 0 : 1,
                        curve: Curves.easeOutCubic,
                        child: ReceiveInfoBox(
                          message: "Your receive address will rotate every time you close and reopen this screen",iconPath: "assets/new-ui/info.svg",
                          onDismissed: (){
                            setState(() {
                              _infoboxDimissed = true;
                            });
                          }
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _presentCurrencyPicker(BuildContext context) async {
    await showPopUp(
      builder: (_) => CurrencyPicker(
        selectedAtIndex: widget.addressListViewModel.selectedCurrencyIndex,
        items: widget.addressListViewModel.currencies,
        hintText: S.of(context).search_currency,
        onItemSelected: widget.addressListViewModel.selectCurrency,
      ),
      context: context,
    );
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
}
