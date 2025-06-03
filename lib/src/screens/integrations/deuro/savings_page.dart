import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/interest_card_widget.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/savings_card_widget.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/savings_edit_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/confirm_sending_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
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
                onPressed: () => _dEuroViewModel.reloadSavingsUserData(),
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
            ),
          ),
          Observer(
            builder: (_) => InterestCardWidget(
              isDarkTheme: currentTheme.isDark,
              title: 'Collected Interest',
              collectedInterest: _dEuroViewModel.accruedInterest,
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
          fiatAmountValue: "",
          fee: S.of(bottomSheetContext).send_estimated_fee,
          feeValue: tx.feeFormatted,
          feeFiatAmount: "",
          outputs: [],
          onSlideComplete: () async {
            Navigator.of(bottomSheetContext).pop(true);
            dEuroViewModel.commitTransaction();
          },
          change: tx.change,
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
              titleText: S.of(bottomSheetContext).transaction_sent,
              contentImage: 'assets/images/birthday_cake.png',
              actionButtonText: S.of(bottomSheetContext).close,
              actionButtonKey: ValueKey('send_page_sent_dialog_ok_button_key'),
              actionButton: () => Navigator.of(bottomSheetContext).pop(),
            ),
          );
        });
      }
    });

    _isReactionsSet = true;
  }
}
