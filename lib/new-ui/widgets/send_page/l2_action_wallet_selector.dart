import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/l2_send_external_modal.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_address_input.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/wallet_switcher_view_model.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

enum l2actions { deposit, withdraw }

class L2ActionWalletSelector extends StatefulWidget {
  const L2ActionWalletSelector({
    super.key,
    required this.showOtherWallets,
    required this.sendViewModel,
    required this.action,
    required this.onSendInitiated,
    required this.contactListViewModel,
    required this.walletSwitcherViewModel,
  });

  final bool showOtherWallets;
  final SendViewModel sendViewModel;
  final l2actions action;
  final VoidCallback onSendInitiated;
  final ContactListViewModel contactListViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;


  @override
  State<L2ActionWalletSelector> createState() => _L2ActionWalletSelectorState();
}

class _L2ActionWalletSelectorState extends State<L2ActionWalletSelector> {
  final TextEditingController addressController = TextEditingController();
  List<WalletInfo> items = [];
  bool textEntered = false;
  String? loadingWalletName;

  @override
  void initState() {
    super.initState();
    if (widget.showOtherWallets) {
      () async {
        items.addAll((await WalletInfo.getAll()).where((item) => item.type == widget.sendViewModel.walletType));
        setState(() {});
      }.call();
    }
    addressController.addListener((){
      setState(() {
        textEntered = addressController.text.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalTopBar(
          title: widget.action == l2actions.deposit ? "${S.of(context).send_from}..." : "${S.of(context).receive_to}...",
          leadingIcon: Icon(Icons.arrow_back_ios_new),
          onLeadingPressed: Navigator.of(context).pop,
        ),
        Flexible(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.showOtherWallets) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Text(S.of(context).choose_wallet),
                        WalletRow(
                          isCurrent: true,
                            currencyIconPath:
                                widget.sendViewModel.wallet.currency.iconPath ?? "",
                            walletName: widget.sendViewModel.wallet.name,
                            onTap: () {
                              printV(widget.sendViewModel.wallet.type);
                              if (widget.sendViewModel.wallet.type == WalletType.bitcoin ||
                                  widget.sendViewModel.wallet.type == WalletType.litecoin) {
                                if(widget.action == l2actions.withdraw){
                                  widget.sendViewModel.outputs.first.address =
                                      bitcoin!.getUnusedSegwitAddress(widget.sendViewModel.wallet)!;
                                }
                                widget.onSendInitiated();
                              }
                            }),
                      ],
                    ),
                    Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    Column(
                      spacing: 12,
                      children: [
                        Container(
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context).colorScheme.surfaceContainer,
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(context).push(CupertinoPageRoute(
                                    builder: (context) => Material(
                                        child: L2ActionWalletSelector(
                                            showOtherWallets: true,
                                            sendViewModel: widget.sendViewModel,
                                            action: widget.action,
                                            onSendInitiated: widget.onSendInitiated,
                                            contactListViewModel:
                                                widget.contactListViewModel,walletSwitcherViewModel: widget.walletSwitcherViewModel,))));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Row(
                                  spacing: 10,
                                  children: [
                                    SvgPicture.asset(
                                      "assets/new-ui/select_wallet.svg",
                                      colorFilter: ColorFilter.mode(
                                          Theme.of(context).colorScheme.primary,
                                          BlendMode.srcIn),
                                    ),
                                    Text(
                                      S.of(context).select_other_wallet,
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,fontWeight: FontWeight.w500,fontSize:15),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if(widget.action == l2actions.withdraw)
                        Row(
                          children: [
                            Flexible(
                              child: NewSendAddressInput(
                                  addressController: addressController,
                                  selectedCurrency: widget.sendViewModel.selectedCryptoCurrency,
                                  onEditingComplete: () {}),
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
                                      widget.sendViewModel.outputs.first.address =
                                          addressController.text;
                                      widget.onSendInitiated();
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
                        if(widget.action == l2actions.deposit)
                          Container(
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(context).colorScheme.surfaceContainer,
                            ),
                            child: Material(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  Navigator.of(context,rootNavigator: true).pop();
                                showCupertinoModalBottomSheet(context: navigatorKey.currentContext??context, builder: (context){
                                    return Material(child: L2SendExternalModal(sendViewModel: widget.sendViewModel));
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Row(
                                    spacing: 10,
                                    children: [
                                      SvgPicture.asset(
                                        "assets/new-ui/send_from_external.svg",
                                        colorFilter: ColorFilter.mode(
                                            Theme.of(context).colorScheme.primary,
                                            BlendMode.srcIn),
                                      ),
                                      Text(
                                        S.of(context).send_from_external,
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,fontWeight: FontWeight.w500,fontSize:15),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox()
                  ],
                  if (widget.showOtherWallets)
                    Flexible(
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: WalletRow(
                                currencyIconPath:
                                    walletTypeToCryptoCurrency(item.type).iconPath ?? "",
                                walletName: item.name,
                                isLoading: loadingWalletName == item.name,
                                onTap: () async {
                                  if (widget.action == l2actions.withdraw) {
                                    widget.sendViewModel.outputs.first.address = item.address;
                                    widget.onSendInitiated();
                                  } else if (widget.action == l2actions.deposit) {
                                    setState(() {
                                      loadingWalletName = item.name;
                                    });
                                    await _handleChangeWallet(item);
                                    widget.onSendInitiated();
                                    setState(() {
                                      loadingWalletName = null;
                                    });
                                  }
                                },
                              ),
                            );
                          }),
                    )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Future<void> _handleChangeWallet(WalletInfo wallet) async {
    // this waits for the ui to animate nicely
    // if wallet switching is done alongside animations, they lag HARD
    await Future.delayed(const Duration(milliseconds: 500));
    widget.walletSwitcherViewModel.selectWallet(wallet);
    final success = await widget.walletSwitcherViewModel.switchToSelectedWallet();
    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      await widget.sendViewModel.updateWalletBalance();
      if(bitcoin != null) {
        await bitcoin!.updateFeeRates(widget.sendViewModel.wallet);
      }
    }
  }
}

class WalletRow extends StatelessWidget {
  const WalletRow(
      {super.key, required this.currencyIconPath, required this.walletName, required this.onTap, this.isLoading=false, this.isCurrent=false});

  final String currencyIconPath;
  final String walletName;
  final VoidCallback onTap;
  final bool isCurrent;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isCurrent ? 80 : 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    Image.asset(
                      currencyIconPath,
                      height: 24,
                      width: 24,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(walletName),
                        if(isCurrent)
                          Text(S.of(context).current_wallet, style: TextStyle(fontSize: 12,color: Theme.of(context).colorScheme.onSurfaceVariant),)
                      ],
                    )
                  ],
                ),
                isLoading ? CupertinoActivityIndicator() : Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
