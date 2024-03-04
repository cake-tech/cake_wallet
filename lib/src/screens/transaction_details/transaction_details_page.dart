import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:cake_wallet/src/screens/transaction_details/blockexplorer_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/widgets/textfield_list_row.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class TransactionDetailsPage extends BasePage {
  TransactionDetailsPage({required this.transactionDetailsViewModel});

  @override
  String get title => S.current.transaction_details_title;

  final TransactionDetailsViewModel transactionDetailsViewModel;

  bool _effectsInstalled = false;

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return Column(
      children: [
        Expanded(
          child: SectionStandardList(
              sectionCount: 1,
              itemCounter: (int _) => transactionDetailsViewModel.items.length,
              itemBuilder: (__, index) {
                final item = transactionDetailsViewModel.items[index];

                if (item is StandartListItem) {
                  return GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.value));
                      showBar<void>(context, S.of(context).transaction_details_copied(item.title));
                    },
                    child: ListRow(title: '${item.title}:', value: item.value),
                  );
                }

                if (item is BlockExplorerListItem) {
                  return GestureDetector(
                    onTap: item.onTap,
                    child: ListRow(title: '${item.title}:', value: item.value),
                  );
                }

                if (item is TextFieldListItem) {
                  return TextFieldListRow(
                    title: item.title,
                    value: item.value,
                    onSubmitted: item.onSubmitted,
                  );
                }

                return Container();
              }),
        ),
        Observer(
          builder: (_) {
            if (transactionDetailsViewModel.canReplaceByFee) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: PrimaryButton(
                  onPressed: () async {
                    final fee = await _setTransactionPriority(context);
                    if (fee != null) {
                      transactionDetailsViewModel.replaceByFee(fee.toString());
                    }
                  },
                  text: S.of(context).replace_by_fee,
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ],
    );
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    reaction((_) => transactionDetailsViewModel.sendViewModel.state, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext popupContext) {
                return AlertWithOneAction(
                    alertTitle: S.of(popupContext).error,
                    alertContent: state.error,
                    buttonText: S.of(popupContext).ok,
                    buttonAction: () => Navigator.of(popupContext).pop());
              });
        });
      }

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext popupContext) {
                return ConfirmSendingAlert(
                    alertTitle: S.of(popupContext).confirm_sending,
                    amount: S.of(popupContext).send_amount,
                    amountValue: transactionDetailsViewModel
                        .sendViewModel.pendingTransaction!.amountFormatted,
                    fee: S.of(popupContext).send_fee,
                    feeValue:
                        transactionDetailsViewModel.sendViewModel.pendingTransaction!.feeFormatted,
                    rightButtonText: S.of(popupContext).send,
                    leftButtonText: S.of(popupContext).cancel,
                    actionRightButton: () async {
                      Navigator.of(popupContext).pop();
                      await transactionDetailsViewModel.sendViewModel.commitTransaction();
                      // transactionStatePopup();
                    },
                    actionLeftButton: () => Navigator.of(popupContext).pop(),
                    feeFiatAmount:
                        transactionDetailsViewModel.pendingTransactionFeeFiatAmountFormatted,
                    fiatAmountValue:
                        transactionDetailsViewModel.pendingTransactionFiatAmountValueFormatted,
                    outputs: transactionDetailsViewModel.sendViewModel.outputs);
              });
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showPopUp<void>(
                context: context,
                builder: (BuildContext popupContext) {
                  return AlertWithOneAction(
                      alertTitle: S.of(popupContext).sending,
                      alertContent: S.of(popupContext).transaction_sent,
                      buttonText: S.of(popupContext).ok,
                      buttonAction: () => Navigator.of(popupContext).pop());
                });
          }
        });
      }
    });

    _effectsInstalled = true;
  }

  Future<String?> _setTransactionPriority(BuildContext context) async {
    final walletType = transactionDetailsViewModel.sendViewModel.walletType;
    final cryptoCurrency = walletTypeToCryptoCurrency(walletType);
    if (walletType != WalletType.bitcoin) return null;
    final wallet = transactionDetailsViewModel.sendViewModel.wallet as BitcoinWallet;
    final transactionAmount = transactionDetailsViewModel.items
        .firstWhere((element) => element.title == S.of(context).transaction_details_amount)
        .value;
    final formattedCryptoAmount = AmountConverter.amountStringToInt(
        cryptoCurrency, transactionAmount);

    double sliderValue = transactionDetailsViewModel.sendViewModel.customElectrumFeeRate.toDouble();
    final items = priorityForWalletType(walletType);
    final selectedItem =
        items.indexOf(transactionDetailsViewModel.sendViewModel.transactionPriority);
    BitcoinTransactionPriority transactionPriority =
        items[selectedItem] as BitcoinTransactionPriority;

    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        int selectedIdx = selectedItem;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Picker(
              items: items,
              displayItem: transactionDetailsViewModel.sendViewModel.displayFeeRate,
              selectedAtIndex: selectedIdx,
              title: S.of(context).please_select,
              headerEnabled: false,
              closeOnItemSelected: false,
              mainAxisAlignment: MainAxisAlignment.center,
              sliderValue: sliderValue,
              onSliderChanged: (double newValue) => setState(() => sliderValue = newValue),
              onItemSelected: (TransactionPriority priority) {
                transactionPriority = priority as BitcoinTransactionPriority;
                setState(() => selectedIdx = items.indexOf(priority));
              },
            );
          },
        );
      },
    );

    final fee = transactionPriority == BitcoinTransactionPriority.custom
        ? wallet.calculateEstimatedFeeWithFeeRate(sliderValue.round(), formattedCryptoAmount)
        : wallet.calculateEstimatedFee(transactionPriority, formattedCryptoAmount);



    return AmountConverter.amountIntToString(cryptoCurrency, fee);
  }
}
