import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/interest_card_widget.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/savings_card_widget.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/savings_edit_sheet.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/confirm_sending_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/tooltip_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/integrations/deuro_savings_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DEuroSavingsPage extends BasePage {
  final DEuroSavingsViewModel _dEuroViewModel;

  DEuroSavingsPage(this._dEuroViewModel);

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (context, scaffold) => GradientBackground(scaffold: scaffold);

  @override
  String get title => S.current.deuro_savings;

  @override
  Widget body(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _setReactions(context, _dEuroViewModel));

    return RefreshIndicator(
      displacement: responsiveLayoutUtil.screenHeight * 0.1,
      onRefresh: _dEuroViewModel.reloadSavingsUserData,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverFillRemaining(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: <Widget>[
                  Observer(
                    builder: (_) => SavingsCard(
                      interestRate: "${_dEuroViewModel.interestRateFormated}%",
                      savingsBalance: _dEuroViewModel.savingsBalanceFormated,
                      fiatSavingsBalance: _dEuroViewModel.fiatSavingsBalanceFormated,
                      currency: CryptoCurrency.deuro,
                      fiatCurrency: _dEuroViewModel.isFiatDisabled ? null : _dEuroViewModel.fiat,
                      onAddSavingsPressed: () => _onSavingsAdd(context),
                      onRemoveSavingsPressed: () => _onSavingsRemove(context),
                      onApproveSavingsPressed: _dEuroViewModel.prepareApproval,
                      onTooltipPressed: () => _onSavingsTooltipPressed(context),
                      isEnabled: _dEuroViewModel.isEnabled,
                      isLoading: _dEuroViewModel.isLoading,
                    ),
                  ),
                  Observer(
                    builder: (_) => InterestCardWidget(
                      title: S.of(context).deuro_savings_collect_interest,
                      fiatAccruedInterest: _dEuroViewModel.fiatAccruedInterestFormated,
                      fiatCurrency: _dEuroViewModel.isFiatDisabled ? null : _dEuroViewModel.fiat,
                      accruedInterest: _dEuroViewModel.accruedInterestFormated,
                      onCollectInterest: _onCollectInterest,
                      onReinvestInterest: _onReinvestInterest,
                      onTooltipPressed: () => _onInterestTooltipPressed(context),
                      isEnabled: _dEuroViewModel.isSavingsActionsEnabled,
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _editSheetIsOpen = false;

  Future<void> _onSavingsAdd(BuildContext context) async {
    if (_editSheetIsOpen) return;
    _editSheetIsOpen = true;
    final amount = await _showEditBottomSheet(context, isAdding: true);
    if (amount != null) _dEuroViewModel.prepareSavingsEdit(amount, true);
    _editSheetIsOpen = false;
  }

  Future<void> _onSavingsRemove(BuildContext context) async {
    if (_editSheetIsOpen) return;
    _editSheetIsOpen = true;
    final amount = await _showEditBottomSheet(context, isAdding: false);
    if (amount != null) _dEuroViewModel.prepareSavingsEdit(amount, false);
    _editSheetIsOpen = false;
  }

  Future<void> _onReinvestInterest() async {
    if (_editSheetIsOpen) return;
    _editSheetIsOpen = true;
    await _dEuroViewModel.prepareReinvestInterest();
    _editSheetIsOpen = false;
  }

  Future<void> _onCollectInterest() async {
    if (_editSheetIsOpen) return;
    _editSheetIsOpen = true;
    await _dEuroViewModel.prepareCollectInterest();
    _editSheetIsOpen = false;
  }

  bool _isReactionsSet = false;

  void _setReactions(BuildContext context, DEuroSavingsViewModel dEuroViewModel) {
    if (_isReactionsSet) return;

    reaction((_) => dEuroViewModel.transaction, (PendingTransaction? tx) async {
      if (tx == null) return;
      String title;

      switch (_dEuroViewModel.actionType) {
        case DEuroActionType.deposit:
          title = S.of(context).deuro_savings_add;
          break;
        case DEuroActionType.withdraw:
          title = S.of(context).deuro_savings_remove;
          break;
        case DEuroActionType.reinvest:
          title = S.of(context).deuro_reinvest_interest;
          break;
        default:
          title = S.of(context).confirm_transaction;
          break;
      }

      final result = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        builder: (BuildContext bottomSheetContext) => ConfirmSendingBottomSheet(
          key: ValueKey('savings_page_confirm_sending_dialog_key'),
          footerType: FooterType.slideActionButton,
          titleText: title,
          walletType: WalletType.ethereum,
          titleIconPath: CryptoCurrency.deuro.iconPath,
          currency: CryptoCurrency.deuro,
          amount: S.of(bottomSheetContext).send_amount,
          amountValue: _dEuroViewModel.actionType == DEuroActionType.reinvest
              ? _dEuroViewModel.accruedInterestFormated
              : tx.amountFormatted,
          fiatAmountValue: _dEuroViewModel.actionType == DEuroActionType.reinvest
              ? _dEuroViewModel.fiatAccruedInterestFormated
              : _dEuroViewModel.pendingTransactionFiatAmountFormatted,
          fee: S.of(bottomSheetContext).send_estimated_fee,
          feeValue: tx.feeFormatted,
          feeFiatAmount: _dEuroViewModel.pendingTransactionFeeFiatAmountFormatted,
          outputs: [],
          onSlideActionComplete: () async {
            Navigator.of(bottomSheetContext).pop(true);
            dEuroViewModel.commitTransaction();
          },
          change: tx.change,
        ),
      );

      if (result == null) dEuroViewModel.dismissTransaction();
    });

    reaction((_) => dEuroViewModel.approvalTransaction, (PendingTransaction? tx) async {
      if (tx == null) return;
      final result = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        builder: (BuildContext bottomSheetContext) => ConfirmSendingBottomSheet(
          key: ValueKey('savings_page_confirm_approval_dialog_key'),
          footerType: FooterType.slideActionButton,
          titleText: S.of(bottomSheetContext).approve_tokens,
          walletType: WalletType.ethereum,
          titleIconPath: CryptoCurrency.deuro.iconPath,
          currency: CryptoCurrency.deuro,
          amount: S.of(bottomSheetContext).send_amount,
          amountValue: tx.amountFormatted,
          fiatAmountValue: "",
          fee: S.of(bottomSheetContext).send_estimated_fee,
          feeValue: tx.feeFormatted,
          feeFiatAmount: "",
          outputs: [],
          onSlideActionComplete: () {
            Navigator.of(bottomSheetContext).pop(true);
            dEuroViewModel.commitApprovalTransaction();
          },
          change: tx.change,
          explanation: S.of(context).deuro_savings_approve_app_description,
        ),
      );

      if (result == null) dEuroViewModel.dismissTransaction();
    });

    reaction((_) => dEuroViewModel.state, (ExecutionState state) async {
      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;

          await showModalBottomSheet<void>(
            context: context,
            isDismissible: false,
            builder: (BuildContext bottomSheetContext) => InfoBottomSheet(
              footerType: FooterType.singleActionButton,
              titleText: S.of(bottomSheetContext).transaction_sent,
              contentImage: 'assets/images/birthday_cake.png',
              content: S.of(bottomSheetContext).deuro_tx_commited_content,
              singleActionButtonText: S.of(bottomSheetContext).close,
              singleActionButtonKey: ValueKey('send_page_sent_dialog_ok_button_key'),
              onSingleActionButtonPressed: () => Navigator.of(bottomSheetContext).pop(),
            ),
          );
        });
      }

      if (state is NoEtherState) {
        WidgetsBinding.instance.addPostFrameCallback((_) async => await _showNoEthTooltip(context));
      }

      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;

          await showPopUp<void>(
            context: context,
            builder: (BuildContext popupContext) => AlertWithOneAction(
              alertTitle: S.of(popupContext).error,
              alertContent: state.error,
              buttonText: S.of(popupContext).ok,
              buttonAction: () => Navigator.of(popupContext).pop(),
            ),
          );
        });
      }
    });

    _isReactionsSet = true;
  }

  void _onSavingsTooltipPressed(BuildContext context) => _showTooltip(
        context,
        title: S.of(context).deuro_savings_balance,
        content: S.of(context).deuro_savings_balance_tooltip,
        key: 'savings_tooltip',
        onLearnMorePressed: () => launchUrlString("https://deuro.com/#faq"),
      );

  void _onInterestTooltipPressed(BuildContext context) => _showTooltip(
        context,
        title: S.of(context).deuro_savings_collect_interest,
        content: S.of(context).deuro_savings_collect_interest_tooltip,
        key: 'interest_tooltip',
        onLearnMorePressed: () => launchUrlString("https://deuro.com/#faq"),
      );

  void _showTooltip(
    BuildContext context, {
    required String title,
    required String content,
    required String key,
    required VoidCallback onLearnMorePressed,
  }) {
    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext bottomSheetContext) => TooltipSheet(
        titleText: title,
        titleIconPath: CryptoCurrency.deuro.iconPath,
        tooltip: content,
        footerType: FooterType.doubleActionButton,
        doubleActionRightButtonText: S.of(context).close,
        rightActionButtonKey: ValueKey('deuro_page_tooltip_dialog_${key}_ok_button_key'),
        onRightActionButtonPressed: () => Navigator.of(bottomSheetContext).pop(),
        doubleActionLeftButtonText: S.of(context).learn_more,
        leftActionButtonKey: ValueKey('deuro_page_tooltip_dialog_${key}_learn_more_button_key'),
        onLeftActionButtonPressed: onLearnMorePressed,
      ),
    );
  }

  Future<void> _showNoEthTooltip(BuildContext context) async {
    if (!context.mounted) return;

    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext bottomSheetContext) => InfoBottomSheet(
        titleText: title,
        titleIconPath: CryptoCurrency.deuro.iconPath,
        contentImage: 'assets/images/deuro_not_enough_eth.png',
        content: S.of(context).deuro_tooltip_no_eth,
        singleActionButtonKey: ValueKey('deuro_page_tooltip_dialog_no_eth_ok_button_key'),
        singleActionButtonText: S.of(context).close,
        onSingleActionButtonPressed: () => Navigator.of(bottomSheetContext).pop(),
        footerType: FooterType.singleActionButton,
      ),
    );
  }

  Future<String?> _showEditBottomSheet(BuildContext context, {bool isAdding = false}) async {
    if (!context.mounted) return null;

    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bottomSheetContext) => SavingsEditSheet(
        titleText: isAdding ? S.of(context).deuro_savings_add : S.of(context).deuro_savings_remove,
        titleIconPath: CryptoCurrency.deuro.iconPath,
        balanceTitle: isAdding
            ? S.of(context).deuro_savings_available_to_add
            : S.of(context).deuro_savings_available_to_remove,
        balance: isAdding
            ? _dEuroViewModel.accountBalanceFormated
            : _dEuroViewModel.savingsBalanceFormated,
        footerType: FooterType.none,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
    );
  }
}
