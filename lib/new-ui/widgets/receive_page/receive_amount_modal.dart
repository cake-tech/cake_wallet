import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';

class ReceiveAmountModal extends StatefulWidget {
  const ReceiveAmountModal(
      {super.key, required this.walletAddressListViewModel, required this.onSubmitted});

  final WalletAddressListViewModel walletAddressListViewModel;
  final Function(String) onSubmitted;

  @override
  State<ReceiveAmountModal> createState() => _ReceiveAmountModalState();
}

class _ReceiveAmountModalState extends State<ReceiveAmountModal> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.walletAddressListViewModel.amount;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalTopBar(
                title: S.of(context).set_amount,
                onLeadingPressed: Navigator.of(context).pop,
                onTrailingPressed: () {},
                leadingIcon: Icon(Icons.close),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    if (widget.walletAddressListViewModel.tokenCurrencies.length > 1) ...[
                      Text("Token"),
                      GestureDetector(
                          onTap: () {
                            _presentTokenCurrencyPicker(context);
                          },
                          child: Observer(
                            builder: (_) => Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      spacing: 8,
                                      children: [
                                        Image.asset(
                                            widget.walletAddressListViewModel.tokenCurrency
                                                    ?.iconPath ??
                                                widget.walletAddressListViewModel.currencies.first
                                                    .iconPath ??
                                                "",
                                            width: 32,
                                            height: 32),
                                        Text((widget.walletAddressListViewModel.tokenCurrency ??
                                                widget.walletAddressListViewModel.currencies.first
                                                    as CryptoCurrency)
                                            .title
                                            .toUpperCase())
                                      ],
                                    ),
                                    RotatedBox(
                                        quarterTurns: 2,
                                        child: SvgPicture.asset("assets/new-ui/dropdown_arrow.svg"))
                                  ],
                                ),
                              ),
                            ),
                          )),
                    ],
                    SizedBox(),
                    Text(S.of(context).amount),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 75,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surfaceContainer,
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              textAlign: TextAlign.left,
                              textAlignVertical: TextAlignVertical.center,
                              controller: _amountController,
                              decoration: InputDecoration(
                                  hint: Text(
                                    "0.00000000",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: Colors.transparent),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 25,
                          child: GestureDetector(
                            onTap: () {
                              _presentFiatCurrencyPicker(context);
                            },
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(0),
                                  bottomLeft: Radius.circular(0),
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 4.0,
                                children: [
                                  Observer(
                                    builder: (_) => Text(
                                      widget.walletAddressListViewModel.selectedCurrency
                                              is CryptoCurrency
                                          ? (widget.walletAddressListViewModel.selectedCurrency
                                                  as CryptoCurrency)
                                              .title
                                              .toUpperCase()
                                          : widget.walletAddressListViewModel.selectedCurrency.name
                                              .toUpperCase(),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(),
                    NewPrimaryButton(
                      text: S.of(context).continue_text,
                      onPressed: () {
                        widget.walletAddressListViewModel.changeAmount(_amountController.text);
                        Navigator.of(context).pop();
                      },
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _presentTokenCurrencyPicker(BuildContext context) async {
    await showPopUp(
      builder: (_) => CurrencyPicker(
        selectedAtIndex: widget.walletAddressListViewModel.tokenCurrencyIndex,
        items: widget.walletAddressListViewModel.tokenCurrencies,
        hintText: S.of(context).search_currency,
        onItemSelected: widget.walletAddressListViewModel.setTokenCurrency,
      ),
      context: context,
    );
  }

  void _presentFiatCurrencyPicker(BuildContext context) async {
    await showPopUp(
      builder: (_) => CurrencyPicker(
        selectedAtIndex: widget.walletAddressListViewModel.selectedCurrencyIndex,
        items: widget.walletAddressListViewModel.currencies,
        hintText: S.of(context).search_currency,
        onItemSelected: widget.walletAddressListViewModel.selectCurrency,
      ),
      context: context,
    );
  }
}
