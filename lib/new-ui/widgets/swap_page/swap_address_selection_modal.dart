import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/swap_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/swap_wallet_list_service.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_address_input.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_simple_checkbox.dart";
import "package:cake_wallet/view_model/exchange/exchange_view_model.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart" show WalletType;
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";


class SwapAddressSelectionModal extends StatefulWidget {
  const SwapAddressSelectionModal(
      {required this.isSelectingReceiver, required this.bloc, super.key});

  final bool isSelectingReceiver;
  final SwapBloc bloc;

  @override
  State<SwapAddressSelectionModal> createState() => _SwapAddressSelectionModalState();
}

class _SwapAddressSelectionModalState extends State<SwapAddressSelectionModal> {
  List<WalletInfo> items = [];
  Map<String, List<WalletInfoAddressInfo>> accounts = {};
  final addressController = TextEditingController();
  bool textEntered = false;

  bool _itemsLoaded = false;

  @override
  void initState() {
    super.initState();

    addressController.addListener(() {
      setState(() {
        textEntered = addressController.text.isNotEmpty;
      });
    });

    () async {
      if(widget.bloc.state case final SwapStateWithInputs s) {
        items = await SwapWalletListService.getWallets(widget.isSelectingReceiver
            ? s.payoutAmount.currency
                : s.depositAmount.currency);
        for (final item in items) {
          if (item.type == WalletType.monero) {
            accounts[item.id] = await SwapWalletListService.addressesForAccountsWallet(item);
          }
        }
      }

      setState(() {
        _itemsLoaded = true;
      });
    }.call();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SwapBloc, SwapState>(
      bloc: widget.bloc,
      builder: (context, state) {

        if(_itemsLoaded) {
          if(state case final SwapStateWithInputs s) {
            final currency = widget.isSelectingReceiver
                ? s.payoutAmount.currency
                : s.depositAmount.currency;
            return Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ModalTopBar(
                        title: widget.isSelectingReceiver
                            ? "${S.of(context).receive_to}..."
                            : "${S.of(context).send_from}...",
                        leadingIcon: Icon(Icons.close),
                        onLeadingPressed: Navigator.of(context).pop,
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: items.isEmpty
                              ? Center(
                              child: Text(
                                "${S.of(context).no_wallets_for} ${widget.isSelectingReceiver ? currency.fullName : currency.fullName}.",
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ))
                              : ListView.builder(
                            padding: EdgeInsets.only(bottom: 12),
                            shrinkWrap: true,
                            controller: ModalScrollController.of(context),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];

                              late final bool selected;
                              if (widget.isSelectingReceiver) {
                                selected = s.payoutAddress is InternalWalletSwapAddress && (s.payoutAddress! as InternalWalletSwapAddress).walletInfo.internalId == item.internalId;
                              } else {
                                selected = s.source is InternalSwapSource && (s.source as InternalSwapSource).sourceWallet.internalId == item.internalId;
                              }

                              final String currencyIconPath =
                              getCryptoCurrencyIconForWalletListItem(item.type);

                              final bool hasAccounts =
                                  item.type == WalletType.monero && widget.isSelectingReceiver;

                              List<WalletInfoAddressInfo>? accounts =
                              hasAccounts ? this.accounts[item.id] : null;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: SwapAddressSelectionModalRow(
                                  wallet: item,
                                  iconPath: currencyIconPath,
                                  isSelected: selected,
                                  accounts: accounts,
                                  onAddressChosen: (address, accountName) {
                                    if(accountName == null) {
                                      widget.bloc.add(PayoutAddressChanged(InternalWalletSwapAddress(item)));
                                    } else {
                                      widget.bloc.add(PayoutAddressChanged(InternalAccountSwapAddress(address: address, accountName: accountName, walletName: item.name)));

                                    }
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        height: 1,
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        child: !widget.isSelectingReceiver
                            ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            widget.bloc.add(const SourceChanged(ExternalSwapSource("")));
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 10,
                              children: [
                                CakeImageWidget(
                                    imageUrl: "assets/new-ui/send_from_external.svg",
                                    colorFilter: ColorFilter.mode(
                                        Theme.of(context).colorScheme.primary, BlendMode.srcIn)),
                                Text(S.of(context).send_from_external,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.primary))
                              ],
                            ),
                          ),
                        )
                            : Row(
                          children: [
                            Flexible(
                              child: NewSendAddressInput(
                                addressController: addressController,
                                selectedCurrency: s.payoutAmount.currency,
                                onEditingComplete: () {},
                                bottomPadding: true,
                              ),
                            ),
                            AnimatedScale(
                              alignment: Alignment.centerLeft,
                              scale: textEntered ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: Row(
                                children: [
                                  SizedBox(width: textEntered ? 8 : 0),
                                  GestureDetector(
                                    onTap: () {
                                      widget.bloc.add(PayoutAddressChanged(ExternalSwapAddress(addressController.text)));
                                      Navigator.of(context).pop();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutCubic,
                                      width: textEntered ? 48 : 0,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ));
          }
        }
        return SizedBox.shrink();



      }
    );
}

class SwapAddressSelectionModalRow extends StatefulWidget {
  const SwapAddressSelectionModalRow(
      {required this.wallet, required this.iconPath, required this.isSelected, required this.onAddressChosen, super.key,
      this.accounts});

  final WalletInfo wallet;
  final String iconPath;
  final bool isSelected;
  final Function(String, String?) onAddressChosen;
  final List<WalletInfoAddressInfo>? accounts;

  @override
  State<SwapAddressSelectionModalRow> createState() => _SwapAddressSelectionModalRowState();
}

class _SwapAddressSelectionModalRowState extends State<SwapAddressSelectionModalRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (widget.accounts != null) {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                } else {
                  widget.onAddressChosen(widget.wallet.address, null);
                }
              },
              child: Container(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 12,
                      children: [
                        CakeImageWidget(imageUrl: widget.iconPath, width: 24, height: 24),
                        Text(widget.wallet.name)
                      ],
                    ),
                    widget.accounts != null
                        ? AnimatedRotation(
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            turns: _isExpanded ? 0 : 0.5,
                            child: CakeImageWidget(
                              imageUrl: "assets/new-ui/dropdown_arrow.svg",
                              colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
                            ))
                        : NewSimpleCheckbox(value: widget.isSelected, onChanged: (value) {}),
                  ],
                ),
              ),
            ),
            if (widget.accounts != null)
              AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1.0,
                      child: child,
                    );
                  },
                  child: Container(
                    key: ValueKey(_isExpanded),
                    height: _isExpanded ? null : 0,
                    width: double.infinity,
                    child: Column(
                      children: widget.accounts!.map((item) {
                        return Column(
                          children: [
                            Container(
                              height: 1,
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                widget.onAddressChosen(item.address, item.label);
                              },
                              child: SizedBox(
                                height: 48,
                                child: Row(
                                  spacing: 12,
                                  children: [
                                    CakeImageWidget(
                                      imageUrl: "assets/new-ui/account.svg",
                                      colorFilter: ColorFilter.mode(
                                          Theme.of(context).colorScheme.onSurfaceVariant,
                                          BlendMode.srcIn),
                                    ),
                                    Text(item.label)
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ))
          ],
        ),
      ),
    );
  }
}
