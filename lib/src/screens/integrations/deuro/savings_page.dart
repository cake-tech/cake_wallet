import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/interest_card_widget.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/savings_card_widget.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/savings_edit_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/confirm_sending_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/integrations/deuro_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class DEuroSavingsPage extends BasePage {
  final DEuroViewModel _dEuroViewModel;

  DEuroSavingsPage(this._dEuroViewModel);

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (context, scaffold) => GradientBackground(scaffold: scaffold);

  @override
  String get title => S.current.deuro_savings;

  Widget trailing(BuildContext context) => MergeSemantics(
        child: SizedBox(
          height: 37,
          width: 37,
          child: ButtonTheme(
            minWidth: double.minPositive,
            child: Semantics(
              label: "Refresh",
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  overlayColor: WidgetStateColor.resolveWith(
                      (states) => Colors.transparent),
                ),
                onPressed: _dEuroViewModel.reloadSavingsUserData,
                child: Icon(
                  Icons.refresh,
                  color: pageIconColor(context),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget body(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _setReactions(context, _dEuroViewModel));

    return Container(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          Observer(
            builder: (_) => SavingsCard(
              isDarkTheme: currentTheme.isDark,
              interestRate: "${_dEuroViewModel.interestRate}%",
              savingsBalance: _dEuroViewModel.savingsBalance,
              currency: CryptoCurrency.deuro,
              onAddSavingsPressed: () => _onSavingsAdd(context),
              onRemoveSavingsPressed: () => _onSavingsRemove(context),
              onApproveSavingsPressed: _dEuroViewModel.prepareApproval,
              isEnabled: _dEuroViewModel.isEnabled,
            ),
          ),
          Observer(
            builder: (_) => InterestCardWidget(
              isDarkTheme: currentTheme.isDark,
              title: S.of(context).deuro_savings_collect_interest,
              collectedInterest: _dEuroViewModel.accruedInterest,
              onCollectInterest: _dEuroViewModel.prepareCollectInterest,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSavingsAdd(BuildContext context) async {
    final amount = await Navigator.of(context).push(MaterialPageRoute<String>(
        builder: (BuildContext context) => SavingEditPage(isAdding: true)));
    if (amount != null) _dEuroViewModel.prepareSavingsEdit(amount, true);
  }

  Future<void> _onSavingsRemove(BuildContext context) async {
    final amount = await Navigator.of(context).push(MaterialPageRoute<String>(
        builder: (BuildContext context) => SavingEditPage(isAdding: false)));
    if (amount != null) _dEuroViewModel.prepareSavingsEdit(amount, false);
  }

  bool _isReactionsSet = false;

  void _setReactions(BuildContext context, DEuroViewModel dEuroViewModel) {
    if (_isReactionsSet) return;

    reaction((_) => dEuroViewModel.transaction, (PendingTransaction? tx) async {
      if (tx == null) return;
      final result = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        builder: (BuildContext bottomSheetContext) => ConfirmSendingBottomSheet(
          key: ValueKey('savings_page_confirm_sending_dialog_key'),
          titleText: S.of(bottomSheetContext).confirm_transaction,
          currentTheme: currentTheme,
          walletType: WalletType.ethereum,
          titleIconPath: CryptoCurrency.deuro.iconPath,
          currency: CryptoCurrency.deuro,
          amount: S.of(bottomSheetContext).send_amount,
          amountValue: tx.amountFormatted,
          fiatAmountValue: _dEuroViewModel.pendingTransactionFiatAmountFormatted,
          fee: S.of(bottomSheetContext).send_estimated_fee,
          feeValue: tx.feeFormatted,
          feeFiatAmount: _dEuroViewModel.pendingTransactionFeeFiatAmountFormatted,
          outputs: [],
          onSlideActionComplete: () async {
            Navigator.of(bottomSheetContext).pop(true);
            dEuroViewModel.commitTransaction();
          },
          change: tx.change, footerType: FooterType.slideActionButton,
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
          titleText: S.of(bottomSheetContext).approve_tokens,
          currentTheme: currentTheme,
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
          change: tx.change, footerType: FooterType.slideActionButton,
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
              currentTheme: currentTheme,
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

      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;

          await showPopUp<void>(
            context: context,
            builder: (BuildContext popupContext) {
              return AlertWithOneAction(
                alertTitle: S.of(popupContext).error,
                alertContent: state.error,
                buttonText: S.of(popupContext).ok,
                buttonAction: () => Navigator.of(popupContext).pop(),
              );
            },
          );
        });
      }
    });

    _isReactionsSet = true;
  }
}
