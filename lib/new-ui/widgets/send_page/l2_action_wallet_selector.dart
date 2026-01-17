import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.showOtherWallets) {
      () async {
        items.addAll((await WalletInfo.getAll()).where((item) => item.type == WalletType.bitcoin));
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
      mainAxisSize: MainAxisSize.max,
      children: [
        ModalTopBar(
          title: widget.action == l2actions.deposit ? "Send from..." : "Receive to...",
          leadingIcon: Icon(Icons.arrow_back_ios_new),
          onLeadingPressed: Navigator.of(context).pop,
        ),
        Expanded(
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
                        Text("Current wallet"),
                        WalletRow(
                            currencyIconPath:
                                widget.sendViewModel.wallet.currency.iconPath ?? "",
                            walletName: widget.sendViewModel.wallet.name,
                            onTap: () {
                              printV(widget.sendViewModel.wallet.type);
                              if (widget.sendViewModel.wallet.type.toString() ==
                                  "WalletType.bitcoin") {
                                if(widget.action == l2actions.withdraw){
                                  widget.sendViewModel.outputs.first.address =
                                      bitcoin!.getUnusedSegwitAddress(widget.sendViewModel.wallet)!;
                                }
                                widget.onSendInitiated();
                              }
                            }),
                      ],
                    ),
                    Spacer(),
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
                                      "Select other Wallet",
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary),
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
                                onTap: () {

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
                                        "Send from External",
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary),
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
                    Observer(
                      builder: (_) {
                        printV(items);
                        return Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: items.length,
                          itemBuilder:(context,index) {
                            final item = items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: WalletRow(
                                currencyIconPath: walletTypeToCryptoCurrency(item.type).iconPath ?? "",
                                walletName: item.name,
                                onTap: () async {
                                  if(widget.action == l2actions.withdraw) {
                                    widget.sendViewModel.outputs.first.address = item.address;
                                  } else if(widget.action == l2actions.deposit) {
                                    await _handleChangeWallet(item);
                                  }
                                  widget.onSendInitiated();
                                    },
                                  ),
                                );
                              }),
                        );
                      },
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
    widget.walletSwitcherViewModel.selectWallet(wallet);
    final success = await widget.walletSwitcherViewModel.switchToSelectedWallet();
    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      await widget.sendViewModel.wallet.updateBalance();
      if(bitcoin != null) {
        await bitcoin!.updateFeeRates(widget.sendViewModel.wallet);
      }
    }
  }
}

class WalletRow extends StatelessWidget {
  const WalletRow(
      {super.key, required this.currencyIconPath, required this.walletName, required this.onTap});

  final String currencyIconPath;
  final String walletName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
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
                    Text(walletName)
                  ],
                ),
                Icon(
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
