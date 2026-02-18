import 'dart:ui';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/new-ui/pages/card_customizer.dart';
import 'package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart';
import 'package:cake_wallet/new-ui/widgets/modal_grab_handle.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cw_core/balance_card_style_settings.dart';
import 'package:cw_core/generate_name.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class AccountCustomizerListItem {
  final BalanceCard card;
  final int order;
  final AccountListItem accountListItem;

  AccountCustomizerListItem(
      {required this.card, required this.order, required this.accountListItem});
}

class AccountCustomizer extends StatefulWidget {
  const AccountCustomizer(
      {super.key,
      required this.accountListViewModel,
      required this.accountEditOrCreateViewModel,
      required this.dashboardViewModel});

  final MoneroAccountListViewModel accountListViewModel;
  final MoneroAccountEditOrCreateViewModel accountEditOrCreateViewModel;
  final DashboardViewModel dashboardViewModel;

  @override
  State<AccountCustomizer> createState() => _AccountCustomizerState();
}

class _AccountCustomizerState extends State<AccountCustomizer> {
  static const double _kStackVisibleFactor = 0.2;
  late final double cardWidth = MediaQuery.of(context).size.width * 0.9;

  final List<AccountCustomizerListItem> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadCards();
      final activeId = monero!.getCurrentAccount(widget.dashboardViewModel.wallet).id;
      for (int i = 0; i < _items.length-1; i++) {
        if(_items[i].accountListItem.id == activeId) {
          final lastIndex = _items.length - 1;
          final temp = _items[i];
          _items[i] = _items[lastIndex];
          _items[lastIndex] = temp;
          saveCardOrder();
          widget.dashboardViewModel.loadCardDesigns();
          break;
        }
      }

    });


  }

  @override
  void dispose() {
    saveCardOrder().then((value) => widget.dashboardViewModel.loadCardDesigns());
    super.dispose();
  }

  void loadCards() {
    _items.clear();

    final accounts = widget.accountListViewModel.accounts;
    for (int i = 0; i < accounts.length; i++) {
      final index = widget.dashboardViewModel.cardOrder[i];

      if(index == null || index >= accounts.length) {
        // db order broken.
        reset();
        break;
      }

      _items.add(AccountCustomizerListItem(
          card: BalanceCard(
            accountName: accounts[index].label,
            balance: accounts[index].balance ?? "0.00",
            accountBalance: accounts[index].balance ?? "0.00",
            assetName: widget.accountListViewModel.currency.title,
            selected: i == accounts.length - 1,
            width: cardWidth,
            design: widget.dashboardViewModel.cardDesigns[index],
          ),
          order: index,
          accountListItem: accounts[index]));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).wallet_accounts,
            leadingIcon: Icon(Icons.close),
            onLeadingPressed: Navigator.of(context).maybePop,
            trailingIcon: Icon(Icons.refresh),
            onTrailingPressed: showResetDialog,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              S.of(context).account_customizer_desc,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ReorderableListView.builder(
                  scrollController: ModalScrollController.of(context),
                  onReorder: reorder,
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
                      child: _items[index].card,
                    );
                  },
                  itemCount: _items.length,
                  itemBuilder: (BuildContext context, int index) {
                    final card = _items[index].card;

                    return Container(
                      key: ValueKey(index),
                      child: GestureDetector(
                        onTap: () {
                          reorder(index, _items.length);
                          Navigator.of(context).maybePop();
                        },
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
                                Material(
                                  borderRadius: BorderRadius.circular(999999),
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999999),
                                    onTap: () {
                                      Navigator.of(context).push(CupertinoPageRoute(
                                        builder: (context) {
                                          return BlocProvider(
                                            create: (context) => getIt.get<CardCustomizerBloc>(param1: false),
                                            child: Material(
                                              child: BlocListener<CardCustomizerBloc,
                                                      CardCustomizerState>(
                                                  listener: (context, state) async {
                                                    if (state is CardCustomizerSaved) {
                                                      await widget.dashboardViewModel
                                                          .loadCardDesigns();
                                                      loadCards();
                                                    }
                                                  },
                                                  child: CardCustomizer(
                                                    cryptoTitle: widget.dashboardViewModel.wallet
                                                            .currency.fullName ??
                                                        widget.dashboardViewModel.wallet.currency
                                                            .name,
                                                    cryptoName: widget
                                                        .dashboardViewModel.wallet.currency.name,
                                                  )),
                                            ),
                                          );
                                        },
                                      ));
                                    },
                                    child: Container(
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Row(
                                          spacing: 10,
                                          children: [
                                            Icon(Icons.edit,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 20),
                                            Text(
                                              S.of(context).edit_current,
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.w500),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999999),
                                    onTap: () async {
                                      final res = await showCupertinoModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) {
                                            final modal = getIt.get<AccountCreationModal>();
                                            return Material(
                                                child: modal);
                                          });
                                      if (res != null && res is bool && res == true) {
                                        await widget.dashboardViewModel.loadCardDesigns();
                                        loadCards();
                                        await saveCardOrder();
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

  void reorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final AccountCustomizerListItem item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    // necessary to copy all this to keep constant constructor for BalanceCard
    for (int i = 0; i < _items.length; i++) {
      _items[i] = AccountCustomizerListItem(
          card: BalanceCard(
            accountName: _items[i].card.accountName,
            balance: _items[i].card.balance,
            accountBalance: _items[i].card.accountBalance,
            assetName: _items[i].card.assetName,
            selected: i == _items.length - 1,
            width: _items[i].card.width,
            design: _items[i].card.design,
          ),
          order: i,
          accountListItem: _items[i].accountListItem);
    }

    if (newIndex == _items.length - 1 || oldIndex == _items.length - 1) {
      widget.accountListViewModel.select(_items[_items.length - 1].accountListItem);
    }
  }

  Future<void> saveCardOrder() async {
    for (int i = 0; i < _items.length; i++) {
      final idx = _items.indexWhere((element) => element.accountListItem.id == i);
      printV("$i: $idx");

      await BalanceCardStyleSettings.fromCardDesign(
              widget.dashboardViewModel.wallet.walletInfo.internalId,
              i,
              idx,
              _items[idx].card.design)
          .insert();
    }
  }

  Future<void> showResetDialog() async {
    final res = await showPopUp(
        context: context,
        builder: (context) {
          return AlertWithTwoActions(
              alertTitle: S.of(context).reset,
              alertContent: S.of(context).card_order_reset_desc,
              leftButtonText: S.of(context).yes,
              rightButtonText: S.of(context).no,
              actionLeftButton: () {
                Navigator.of(context).pop(true);
              },
              actionRightButton: Navigator.of(context).pop);
        });
    if(res != null && res is bool && res) {
      reset();
    }
  }

  Future<void> reset() async {
    _items.clear();

    final accounts = widget.accountListViewModel.accounts;
    for (int i = 0; i < widget.accountListViewModel.accounts.length; i++) {

      _items.add(AccountCustomizerListItem(
          card: BalanceCard(
            accountName: accounts[i].label,
            balance: accounts[i].balance ?? "0.00",
            accountBalance: accounts[i].balance ?? "0.00",
            assetName: widget.accountListViewModel.currency.title,
            selected: true,
            width: cardWidth,
            design: widget.dashboardViewModel.cardDesigns[i],
          ),
          order: i,
          accountListItem: accounts[i]));
    }

    saveCardOrder();
    setState(() {});
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
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalGrabHandle(),
                ModalTopBar(title: S.of(context).create_account),
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
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(hintText: S.of(context).account_name),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: GestureDetector(
                                onTap: () async {
                                  _controller.text = await generateName();
                                },
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
                              ),
                            )
                          ],
                        ),
                      ),
                      NewPrimaryButton(
                        onPressed: () async {
                          if (_loading) return;
                          setState(() {
                            _loading = true;
                          });
                          widget.accountEditOrCreateViewModel.label = _controller.text;
                          await widget.accountEditOrCreateViewModel.save();
                          Navigator.of(context).pop(true);
                        },
                        text: "Continue",
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        isLoading: _loading,
                      ),
                      SizedBox(),
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
