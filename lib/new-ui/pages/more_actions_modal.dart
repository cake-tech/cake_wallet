import "dart:async";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/cake_pay/src/cards/cake_pay_cards_page.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/buy_sell/buy_sell_amount_page.dart";
import "package:cake_wallet/new-ui/pages/send_page.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/screens/contact/contact_list_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cake_wallet/view_model/buy/buy_sell_view_model.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

bool _trueFunc(_) => true;

class ExtraAction {
  const ExtraAction({
    required this.isModal,
    required this.destinationBuilder,
    required this.name,
    required this.iconPath,
    this.modalHeightFactor,
    this.applicable = _trueFunc,
  });

  final String Function(DashboardViewModel) name;
  final String iconPath;
  final bool Function(DashboardViewModel) applicable;
  final bool isModal;
  final double? modalHeightFactor;
  final FutureOr<Widget> Function(DashboardViewModel) destinationBuilder;

  static final buy = ExtraAction(
    name: (vm) =>
        "${S.current.buy} ${vm.wallet.balance.length > 1 ? S.current.crypto : vm.wallet.currency.fullName}",
    iconPath: "assets/lottie/buy_bitcoin.json",
    isModal: true,
    destinationBuilder: (_) =>
        getIt.get<NewBuySellAmountPage>(param1: NewBuySellParams(mode: BuySellPageMode.buy)),
  );

  static final sell = ExtraAction(
    name: (vm) =>
        "${S.current.sell} ${vm.wallet.balance.length > 1 ? S.current.crypto : vm.wallet.currency.fullName}",
    iconPath: "assets/lottie/sell_bitcoin.json",
    isModal: true,
    destinationBuilder: (_) =>
        getIt.get<NewBuySellAmountPage>(param1: NewBuySellParams(mode: BuySellPageMode.sell)),
  );

  static final depositFromOnChain = ExtraAction(
    name: (vm) => S.current.deposit_from_on_chain,
    iconPath: "assets/lottie/deposit_from_onchain.json",
    isModal: true,
    modalHeightFactor: 0.6,
    applicable: (vm) => vm.wallet.type == WalletType.bitcoin,
    destinationBuilder: (vm) async {
      PaymentRequest? paymentRequest;
      final depositAddress = await bitcoin!.getUnusedSpakDepositAddress(vm.wallet);
      if (depositAddress?.isNotEmpty ?? false) {
        paymentRequest = PaymentRequest.fromUri(Uri.parse("bitcoin:$depositAddress"));
      }
      return getIt.get<NewSendPage>(
        param1: SendPageParams(
          initialPaymentRequest: paymentRequest,
          unspentCoinType: UnspentCoinType.nonMweb,
          mode: SendPageModes.lightningDeposit,
        ),
      );
    },
  );

  static final withdrawToOnChain = ExtraAction(
    name: (vm) => S.current.withdraw_to_onchain,
    iconPath: "assets/lottie/withdraw_to_onchain.json",
    isModal: true,
    modalHeightFactor: 0.6,
    applicable: (vm) => vm.wallet.type == WalletType.bitcoin,
    destinationBuilder: (vm) {
      PaymentRequest? paymentRequest;
      final withdrawAddress = bitcoin!.getUnusedSegwitAddress(vm.wallet);

      if (withdrawAddress?.isNotEmpty ?? false) {
        paymentRequest = PaymentRequest.fromUri(Uri.parse("bitcoin:$withdrawAddress"));
      }
      return getIt.get<NewSendPage>(
        param1: SendPageParams(
          initialPaymentRequest: paymentRequest,
          unspentCoinType: UnspentCoinType.lightning,
          mode: SendPageModes.lightningWithdrawal,
        ),
      );
    },
  );

  static final cakePay = ExtraAction(
    isModal: false,
    destinationBuilder: (_) => getIt.get<CakePayCardsPage>(),
    name: (_) => S.current.gift_cards_and_debit_cards,
    iconPath: "assets/lottie/giftcards_debit_cards.json",
  );

  static final contacts = ExtraAction(
    isModal: false,
    destinationBuilder: (_) => getIt.get<ContactListPage>(),
    name: (_) => S.current.contacts,
    iconPath: "assets/lottie/contacts.json",
  );

  static final all = [buy, sell, depositFromOnChain, withdrawToOnChain, cakePay, contacts];
}

class MoreActionsModal extends StatelessWidget {
  const MoreActionsModal({required this.dashboardViewModel, super.key});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTopBar(
                title: S.of(context).more_actions,
                leadingIcon: const Icon(Icons.close),
                onLeadingPressed: Navigator.of(context).pop,
                leadingSemanticLabel: S.of(context).close,
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: MoreActionsGrid(
                  actions:
                      ExtraAction.all.where((item) => item.applicable(dashboardViewModel)).toList(),
                  dashboardViewModel: dashboardViewModel,
                  onActionOpened: Navigator.of(context).pop,
                ),
              ),
            ],
          ),
        ),
      );
}

class MoreActionsGrid extends StatelessWidget {
  const MoreActionsGrid({
    required this.actions,
    required this.dashboardViewModel,
    required this.onActionOpened,
    super.key,
  });

  final List<ExtraAction> actions;
  final DashboardViewModel dashboardViewModel;
  final VoidCallback onActionOpened;

  static const crossAxisCount = 2;
  static const itemExtent = 105.0;
  static const spacing = 12.0;
  static const rowAnimDelay = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: itemExtent,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) => ExtraActionButton(
          actions[index],
          dashboardViewModel: dashboardViewModel,
          onOpened: onActionOpened,
          animDelay: rowAnimDelay * (index ~/ crossAxisCount),
        ),
      );
}

class ExtraActionButton extends StatelessWidget {
  const ExtraActionButton(
    this.action, {
    required this.dashboardViewModel,
    required this.onOpened,
    this.animDelay = Duration.zero,
    super.key,
  });

  final ExtraAction action;
  final DashboardViewModel dashboardViewModel;
  final VoidCallback onOpened;
  final Duration animDelay;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _openAction(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                CakeImageWidget(
                  imageUrl: action.iconPath,
                  height: 36,
                  animDelay: animDelay,
                  colorFilter:
                      ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                ),
                Text(
                  action.name(dashboardViewModel),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _openAction(BuildContext context) async {
    final page = await action.destinationBuilder(dashboardViewModel);

    if (action.isModal && context.mounted) {
      onOpened();
      await showMaterialModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          builder: (context) => FractionallySizedBox(
              heightFactor: action.modalHeightFactor ?? 1,
              child: ModalNavigator(parentContext: context, rootPage: page)));
    } else if (context.mounted) {
      onOpened();
      await Navigator.of(context).push(CupertinoPageRoute(builder: (context) => page));
    }
  }
}
