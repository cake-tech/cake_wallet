import 'package:cake_wallet/new-ui/widgets/receive_page/receive_amount_input.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_qr_code.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_seed_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../widgets/receive_page/receive_seed_widget.dart';
import '../widgets/receive_page/receive_top_bar.dart';

class NewReceivePage extends StatefulWidget {
  const NewReceivePage({super.key, required this.addressListViewModel});

  final WalletAddressListViewModel addressListViewModel;

  @override
  State<NewReceivePage> createState() => _NewReceivePageState();
}

class _NewReceivePageState extends State<NewReceivePage> {
  bool _largeQrMode = false;

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
        child: OverflowBox(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 12),
              ModalTopBar(title: "Receive", onLeadingPressed: (){Navigator.of(context).pop();}, onTrailingPressed: (){
              Share.share(widget.addressListViewModel.uri.address);

              },),
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
                        });
                      },
                      largeQrMode: _largeQrMode,
                    ),
                    ReceiveSeedTypeSelector(),
                    ReceiveSeedWidget(addressListViewModel: widget.addressListViewModel,),
                   Observer(
                     builder:(_)=> ReceiveAmountInput(largeQrMode: _largeQrMode, amountController: _amountController,
                     selectedCurrency: widget.addressListViewModel.selectedCurrency.name, onCurrencySelectorTap: (){_presentPicker(context);},),
                   ),
                    ReceiveBottomButtons(largeQrMode: _largeQrMode, onCopyButtonPressed: (){
                      Clipboard.setData(ClipboardData(text: widget.addressListViewModel.uri.address));
                    }, onAccountsButtonPressed: (){},),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _presentPicker(BuildContext context) async {
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
}
