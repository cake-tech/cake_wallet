import 'dart:ui';
import 'package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart';
import 'package:cake_wallet/new-ui/widgets/modal_grab_handle.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class AccountCustomizer extends StatefulWidget {
  const AccountCustomizer({super.key, required this.accountListViewModel, required this.accountEditOrCreateViewModel, required this.dashboardViewModel});

  final MoneroAccountListViewModel accountListViewModel;
  final MoneroAccountEditOrCreateViewModel accountEditOrCreateViewModel;
  final DashboardViewModel dashboardViewModel;


  @override
  State<AccountCustomizer> createState() => _AccountCustomizerState();
}

class _AccountCustomizerState extends State<AccountCustomizer> {
  static const double _kStackVisibleFactor = 0.25;
  late final double cardWidth = MediaQuery.of(context).size.width * 0.9;

  final List<BalanceCard> _cards = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_)=>loadCards());
  }

  void loadCards() async {
    _cards.clear();

    for (int i = 0; i < widget.accountListViewModel.accounts.length; i++) {

      _cards.add(BalanceCard(
        accountName: widget.accountListViewModel.accounts[i].label,
        balance: widget.accountListViewModel.accounts[i].balance ?? "0.00",
        accountBalance: widget.accountListViewModel.accounts[i].balance ?? "0.00",
        assetName: widget.accountListViewModel.currency.title,
        selected: true,
        width: cardWidth,
        design: widget.dashboardViewModel.cardDesigns[i],
      ));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          ModalTopBar(
            title: "Wallet Accounts",
            leadingIcon: Icon(Icons.close),
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              "Drag and drop cards to organize accounts.",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Stack(
              children: [

                ReorderableListView.builder(
                  scrollController: ModalScrollController.of(context),
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final BalanceCard item = _cards.removeAt(oldIndex);
                      _cards.insert(newIndex, item);
                    });
                  },
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) {
                        final animValue = Curves.easeOutCubic.transform(animation.value);
                        final scale = lerpDouble(1, 1.05, animValue)!;

                        return Opacity(
                          opacity: 1 - animValue.clamp(0.0, 0.1),
                          child: Center(
                            child: SizedBox(
                              width: cardWidth,
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                      child: _cards[index],
                    );
                  },
                  itemCount: _cards.length,
                  itemBuilder: (BuildContext context, int index) {
                    final card = _cards[index];

                    return Container(
                      key: ValueKey(index),
                      child: GestureDetector(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: _kStackVisibleFactor,
                          child: card,
                        ),
                      ),
                    );
                  },
                ),
                SafeArea(
                    child: Padding(
                        padding: EdgeInsets.only(bottom: 50),
                        child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 16,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(999999)),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Row(
                                      spacing: 10,
                                      children: [
                                        Icon(Icons.edit,
                                            color: Theme.of(context).colorScheme.primary, size: 20),
                                        Text(
                                          "Edit Current",
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w500),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: ()async{
                                      final res = await showCupertinoModalBottomSheet(context: context,backgroundColor: Colors.transparent, builder: (context){
                                        return Material(child: AccountCreationModal(accountEditOrCreateViewModel: widget.accountEditOrCreateViewModel));
                                      });
                                      if(res != null && res is bool && res == true) {
                                        loadCards();
                                        widget.dashboardViewModel.loadCardDesigns();
                                      }

                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainer,
                                          borderRadius: BorderRadius.circular(999999)),
                                      child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.add,
                                            size: 28,
                                            color: Theme.of(context).colorScheme.primary,
                                          )),
                                    ),
                                  ),
                                )
                              ],
                            )))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountCreationModal extends StatefulWidget {
  const AccountCreationModal({super.key, required this.accountEditOrCreateViewModel});

  final MoneroAccountEditOrCreateViewModel accountEditOrCreateViewModel;


  @override
  State<AccountCreationModal> createState() => _AccountCreationModalState();
}

class _AccountCreationModalState extends State<AccountCreationModal> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SafeArea(
          top:false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalGrabHandle(),
              ModalTopBar(title: "Create Account"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Column(
                  spacing: 50,
                  children: [
                    SizedBox(),
                    Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(child: TextField(controller: _controller,decoration: InputDecoration(hintText: "Account Name"),)),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(5)),
                              child: SvgPicture.asset(
                                "assets/new-ui/randomize.svg",
                                colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    NewPrimaryButton(
                        onPressed: () async {
                          setState(() {
                            _loading = true;
                          });
                          widget.accountEditOrCreateViewModel.label = _controller.text;
                          await widget.accountEditOrCreateViewModel.save();
                          Navigator.of(context).pop(true);
                          },
                        text: "Continue",
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,isLoading: _loading,),
                    SizedBox(),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
