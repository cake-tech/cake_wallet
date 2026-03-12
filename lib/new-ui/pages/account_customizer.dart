import 'dart:ui';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/new-ui/pages/card_customizer.dart';
import 'package:cake_wallet/new-ui/pages/hidden_accounts.dart';
import 'package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart';
import 'package:cake_wallet/new-ui/widgets/modal_grab_handle.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cw_core/balance_card_style_settings.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/generate_name.dart';
import 'package:cw_core/sync_status.dart';
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
      loadCards().then((_){
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
    });
  }

  @override
  void dispose() {
    saveCardOrder().then((value) => widget.dashboardViewModel.loadCardDesigns());
    super.dispose();
  }

  Future<void> loadCards() async {
    final List<AccountCustomizerListItem> newItems = [];

    final accounts = widget.accountListViewModel.accounts;
    final styleSettings = await BalanceCardStyleSettings.getAll(widget.dashboardViewModel.wallet.walletInfo.internalId);
    final sortedOrderKeys = widget.dashboardViewModel.cardOrder.keys.toList()..sort();
    for (final key in sortedOrderKeys) {
      final index = widget.dashboardViewModel.cardOrder[key];

      if(index == null) {
        continue;
      }

      if(index >= accounts.length) {
        // db order broken.
        reset();
        break;
      }

      final account = accounts.firstWhere((item)=>item.id==index);
      final setting = styleSettings.firstWhere((item)=>item.accountIndex == index);

      if(setting.hidden) {
        continue;
      }

      newItems.add(AccountCustomizerListItem(
          card: BalanceCard(
            accountName: account.label,
            accountIndex: account.id,
            balance: account.balance ?? "0.00",
            accountBalance: account.balance ?? "0.00",
            designSwitchDuration: Duration.zero,
            assetName: widget.accountListViewModel.currency.title,
            onCustomizeTapped: (key == accounts.length - 1) ? _openCardCustomizer : null,
            selected: key == accounts.length - 1,
            width: cardWidth,
            design: CardDesign.fromStyleSettings(setting, widget.dashboardViewModel.wallet.currency),
          ),
          order: index,
          accountListItem: account));

    }
    _items.clear();
    _items.addAll(newItems);
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
            // trailingIcon: Icon(Icons.refresh),
            // onTrailingPressed: showResetDialog,
            trailingWidget: Row(spacing:8,children: [
              ModernButton(icon: Icon(Icons.refresh), onPressed: showResetDialog, size: 36),
              ModernButton.svg(svgPath: "assets/new-ui/archived.svg", size: 36, onPressed: ()async{
                await Navigator.of(context).push(CupertinoPageRoute(
                        builder: (context) => Material(
                          child: HiddenAccountsPage(
                              accountListViewModel: widget.accountListViewModel,
                              dashboardViewModel: widget.dashboardViewModel),
                        )));
                await loadCards();
                  }, iconSize: 18,)
              ],),
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
                  padding: EdgeInsets.only(bottom: 196),
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999999),
                                  onTap: _showAddAccountModal,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainer,
                                        borderRadius: BorderRadius.circular(999999)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        spacing: 8,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            size: 28,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          Text(
                                            S.of(context).add_account,
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
                            )))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _checkReadyToManage() {
    if (widget.dashboardViewModel.status is! SyncedSyncStatus) {
      showDialog(
          context: context,
          builder: (context) => AlertWithOneAction(
              alertTitle: S.of(context).wallet_is_syncing,
              alertContent: S.of(context).cannot_manage_accounts_during_sync,
              buttonText: S.of(context).ok,
              buttonAction: Navigator.of(context).pop));
      return false;
    }
    return true;
  }

  Future<void> _showAddAccountModal() async {
    if (!_checkReadyToManage()) {
      return;
    }

    final res = await showCupertinoModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final modal = getIt.get<AccountCreationModal>();
          return Material(child: modal);
        });
    if (res != null && res is bool && res == true) {
      await widget.dashboardViewModel.loadCardDesigns();
      await loadCards();
      await saveCardOrder();
    }
  }

  void _openCardCustomizer() {
    if (!_checkReadyToManage()) {
      return;
    }
    
    widget.accountListViewModel.select(_items[_items.length-1].accountListItem);

    final bloc = getIt.get<CardCustomizerBloc>(param1: false);
    

    Navigator.of(context).push(CupertinoPageRoute(
      builder: (context) {
        return BlocProvider(
          create: (context) => bloc,
          child: Material(
            child: CardCustomizer(
              cryptoTitle: widget.dashboardViewModel.wallet.currency.fullName ??
                  widget.dashboardViewModel.wallet.currency.name,
              cryptoName: widget.dashboardViewModel.wallet.currency.name,
            ),
          ),
        );
      },
    )).then((result) async {
      final hideRequested = result != null && result is bool && result;
      bloc.add(hideRequested ? AccountHidden() : DesignSaved());
      await bloc.stream.firstWhere((item) => item is CardCustomizerSaved);
      if(hideRequested) await reset(unhide: false);
      await widget.dashboardViewModel.loadCardDesigns();
      await loadCards();
    });
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
            accountIndex: _items[i].card.accountIndex,
            accountBalance: _items[i].card.accountBalance,
            assetName: _items[i].card.assetName,
            designSwitchDuration: _items[i].card.designSwitchDuration,
            onCustomizeTapped: (i == _items.length - 1) ? _openCardCustomizer : null,
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
    final visualOrder = _items.reversed.toList();

    for (int i = 0; i < visualOrder.length; i++) {
      final item = visualOrder[i];

      await BalanceCardStyleSettings.fromCardDesign(
              widget.dashboardViewModel.wallet.walletInfo.internalId,
              item.accountListItem.id,
              i,
              item.card.design)
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
      reset(close: true);
    }
  }

  Future<void> reset({bool close = false, bool unhide = true}) async {
    _items.clear();

    final accounts = widget.accountListViewModel.accounts;
    for (int i = 0; i < widget.accountListViewModel.accounts.length; i++) {
      final styleSettings = await BalanceCardStyleSettings.get(
          widget.dashboardViewModel.wallet.walletInfo.internalId, accounts[i].id);
      if(!unhide && (styleSettings?.hidden??false)) {
        continue;
      }

      _items.add(AccountCustomizerListItem(
          card: BalanceCard(
            accountName: accounts[i].label,
            accountIndex: accounts[i].id,
            balance: accounts[i].balance ?? "0.00",
            accountBalance: accounts[i].balance ?? "0.00",
            assetName: widget.accountListViewModel.currency.title,
            selected: true,
            designSwitchDuration: Duration(milliseconds: 200),
            width: cardWidth,
            design: CardDesign.fromStyleSettings(
                styleSettings,
                widget.dashboardViewModel.wallet.currency),
          ),
          order: i,
          accountListItem: accounts[i]));
    }

    saveCardOrder();
    if(close)Navigator.of(context).maybePop();
    else setState(() {});
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
                        text: S.of(context).continue_text,
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
