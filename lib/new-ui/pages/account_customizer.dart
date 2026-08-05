import "dart:async";
import "dart:ui";
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/card_customizer.dart";
import "package:cake_wallet/new-ui/pages/hidden_accounts.dart";
import "package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/new-ui/widgets/modal_grab_handle.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart";
import "package:cw_core/balance_card_layout.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/generate_name.dart";
import "package:cw_core/sync_status.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class AccountCustomizerListItem {
  const AccountCustomizerListItem(
      {required this.card, required this.accountListItem, required this.settings,});

  final BalanceCard card;
  final AccountListItem accountListItem;
  final BalanceCardStyleSettings? settings;
}

class AccountCustomizer extends StatefulWidget {
  const AccountCustomizer(
      {required this.accountListViewModel, required this.accountEditOrCreateViewModel, required this.dashboardViewModel, super.key,});

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
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_bringActiveAccountToFront()));
  }

  @override
  void dispose() {
    saveCardOrder().then((value) => widget.dashboardViewModel.loadCardDesigns());
    super.dispose();
  }

  int get _walletInfoId => widget.dashboardViewModel.wallet.walletInfo.internalId;

  Future<void> _bringActiveAccountToFront() async {
    await loadCards();

    final activeAccount = widget.accountListViewModel.accounts
        .firstWhereOrNull((account) => account.isSelected);
    if (activeAccount == null || _items.isEmpty) {
      return;
    }

    final index = _items.indexWhere((item) => item.accountListItem.id == activeAccount.id);
    if (index == -1 || index == _items.length - 1 || !mounted) {
      return;
    }

    reorder(index, _items.length);
    await saveCardOrder();
    await widget.dashboardViewModel.loadCardDesigns();
  }

  Future<void> loadCards() async {
    final accounts = widget.accountListViewModel.accounts;
    final styleSettings = await BalanceCardStyleSettings.getAll(_walletInfoId);
    final layout = BalanceCardLayout.resolve(
      accountIndices: accounts.map((account) => account.id).toList(),
      settings: styleSettings,
    );

    final List<AccountCustomizerListItem> newItems = [];
    for (int position = 0; position < layout.visible.length; position++) {
      final accountIndex = layout.visible[position];
      final account = accounts.firstWhereOrNull((item) => item.id == accountIndex);

      if (account == null) {
        continue;
      }

      final setting = layout.settingFor(accountIndex);
      final isFrontCard = position == layout.visible.length - 1;

      newItems.add(AccountCustomizerListItem(
          card: BalanceCard(
            accountName: account.label,
            accountIndex: account.id,
            balance: account.balance ?? "0.00",
            accountBalance: account.balance ?? "0.00",
            designSwitchDuration: Duration.zero,
            assetName: widget.accountListViewModel.currency.title,
            onCustomizeTapped: isFrontCard ? _openCardCustomizer : null,
            selected: isFrontCard,
            width: cardWidth,
            design: CardDesign.fromStyleSettings(setting, widget.dashboardViewModel.wallet.currency),
          ),
          accountListItem: account,
          settings: setting,),);
    }

    _items.clear();
    _items.addAll(newItems);
    if (mounted) {
      setState(() {});
    }

    if (layout.needsRepair) {
      await BalanceCardStyleSettings.setVisibleOrder(_walletInfoId, layout.orders);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),),
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).wallet_accounts,
            leadingIcon: const Icon(Icons.close),
            leadingSemanticLabel: S.of(context).close,
            onLeadingPressed: Navigator.of(context).maybePop,
            // trailingIcon: Icon(Icons.refresh),
            // onTrailingPressed: showResetDialog,
            trailingWidget: Row(spacing:8,children: [
              ModernButton(semanticLabel: S.of(context).reset, icon: const Icon(Icons.refresh), onPressed: showResetDialog, size: 36),
              ModernButton.svg(semanticLabel: S.of(context).hidden_accounts, svgPath: "assets/new-ui/archived.svg", size: 36, onPressed: ()async{
                await Navigator.of(context).push(CupertinoPageRoute(
                        builder: (context) => Material(
                          child: HiddenAccountsPage(
                              accountListViewModel: widget.accountListViewModel,
                              dashboardViewModel: widget.dashboardViewModel,),
                        ),),);
                await widget.dashboardViewModel.loadCardDesigns();
                await loadCards();
                  }, iconSize: 18,),
              ],),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              S.of(context).account_customizer_desc,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 196),
                  scrollController: ModalScrollController.of(context),
                  onReorder: reorder,
                  proxyDecorator: (child, index, animation) => AnimatedBuilder(
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
                    ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final card = _items[index].card;
                    final selectedItemIndex = _items.length - 1;

                    return Container(
                      key: ValueKey(index),
                      child: Semantics(
                        button: true,
                        selected: selectedItemIndex == index,
                        label: _items[index].accountListItem.label,
                        onTap: () => reorder(index, _items.length),
                        child: GestureDetector(
                          excludeFromSemantics: true,
                          onTap: () {
                            reorder(index, _items.length);
                          },
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: _kStackVisibleFactor,
                            child: card,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SafeArea(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Material(
                                color: Colors.transparent,
                                child: MergeSemantics(
                                  child: Semantics(
                                    button: true,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(999999),
                                      onTap: _showAddAccountModal,
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainer,
                                            borderRadius: BorderRadius.circular(999999),),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 18),
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
                                                    fontWeight: FontWeight.w500,),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),),),),
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
              buttonAction: Navigator.of(context).pop,),);
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
        },);
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

    widget.accountListViewModel.select(_items[_items.length - 1].accountListItem);


    final bloc = getIt.get<CardCustomizerBloc>(
        param1: CardCustomizerBlocParams(
            lightningMode: false, amountDisplayMode: null, canHide: _items.length > 1,),);

    Navigator.of(context).push(CupertinoPageRoute(
      builder: (context) => BlocProvider(
          create: (context) => bloc,
          child: Material(
            child: CardCustomizer(
              cryptoTitle: widget.dashboardViewModel.wallet.currency.fullName ??
                  widget.dashboardViewModel.wallet.currency.name,
              cryptoName: widget.dashboardViewModel.wallet.currency.name,
            ),
          ),
        ),
    ),).then((result) async {
      final hideRequested = result != null && result is bool && result;
      bloc.add(hideRequested ? AccountHidden() : DesignSaved());
      await bloc.stream.firstWhere((item) => item is CardCustomizerSaved);
      await widget.dashboardViewModel.loadCardDesigns();
      await loadCards();

      if (hideRequested && _items.isNotEmpty) {
        widget.accountListViewModel.select(_items.last.accountListItem);
      }
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
          accountListItem: _items[i].accountListItem,
          settings: _items[i].settings,);
    }

    if (newIndex == _items.length - 1 || oldIndex == _items.length - 1) {
      widget.accountListViewModel.select(_items[_items.length - 1].accountListItem);
    }
  }

  Future<void> saveCardOrder() async {
    for (int position = 0; position < _items.length; position++) {
      final item = _items[position];

      await BalanceCardStyleSettings.fromCardDesign(
              walletInfoId: _walletInfoId,
          accountIndex: item.accountListItem.id,
          hidden: false,
          cardOrder: position,
              design: item.card.design,
              iconStyleIndex: item.settings?.iconStyleIndex ?? 0,
              gradientIndexOverride: item.settings?.gradientIndex,)
          .insert();
    }
  }

  Future<void> showResetDialog() async {
    final res = await showPopUp(
        context: context,
        builder: (context) => AlertWithTwoActions(
              alertTitle: S.of(context).reset,
              alertContent: S.of(context).card_order_reset_desc,
              leftButtonText: S.of(context).yes,
              rightButtonText: S.of(context).no,
              actionLeftButton: () {
                Navigator.of(context).pop(true);
              },
              actionRightButton: Navigator.of(context).pop,),);
    if (res != null && res is bool && res) {
      await reset(close: true);
    }
  }

  Future<void> reset({bool close = false}) async {
    final accounts = widget.accountListViewModel.accounts;
    final styleSettings = await BalanceCardStyleSettings.getAll(_walletInfoId);
    final layout = BalanceCardLayout.resolve(
      accountIndices: accounts.map((account) => account.id).toList(),
      settings: styleSettings,
    );

    for (int position = 0; position < accounts.length; position++) {
      final setting = layout.settingFor(accounts[position].id);

      await BalanceCardStyleSettings.fromCardDesign(
              walletInfoId: _walletInfoId,
              accountIndex: accounts[position].id,
              hidden: false,
              cardOrder: position,
              design: CardDesign.fromStyleSettings(
                  setting, widget.dashboardViewModel.wallet.currency,),
              iconStyleIndex: setting?.iconStyleIndex ?? 0,
              gradientIndexOverride: setting?.gradientIndex,)
          .insert();
    }

    await widget.dashboardViewModel.loadCardDesigns();
    await loadCards();

    if (close && mounted) {
      unawaited(Navigator.of(context).maybePop());
    }
  }
}

class AccountCreationModal extends StatefulWidget {
  const AccountCreationModal({required this.accountEditOrCreateViewModel, super.key});

  final MoneroAccountEditOrCreateViewModel accountEditOrCreateViewModel;

  @override
  State<AccountCreationModal> createState() => _AccountCreationModalState();
}

class _AccountCreationModalState extends State<AccountCreationModal> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  Future<void> _generateAccountName() async => _controller.text = await generateName();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ModalGrabHandle(),
                ModalTopBar(title: S.of(context).create_account),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    spacing: 50,
                    children: [
                      const SizedBox(),
                      Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(hintText: S.of(context).account_name),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Semantics(
                                button: true,
                                label: S.of(context).generate_name,
                                onTap: _generateAccountName,
                                child: ExcludeSemantics(
                                  child: GestureDetector(
                                    onTap: _generateAccountName,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(5),),
                                      child: CakeImageWidget(
                                        imageUrl: "assets/new-ui/randomize.svg",
                                        colorFilter: ColorFilter.mode(
                                            Theme.of(context).colorScheme.primary, BlendMode.srcIn,),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      NewPrimaryButton(
                        onPressed: () async {
                          if (_loading) {
                            return;
                          }
                          setState(() {
                            _loading = true;
                          });
                          widget.accountEditOrCreateViewModel.label = _controller.text;
                          await widget.accountEditOrCreateViewModel.save();
                          if(context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        text: S.of(context).continue_text,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        isLoading: _loading,
                      ),
                      const SizedBox(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),);
}
