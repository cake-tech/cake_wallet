import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:cake_wallet/src/screens/transaction_details/rbf_details_list_fee_picker_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_expandable_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/widgets/textfield_list_row.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/standard_expandable_list.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/standard_picker_list.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class RBFDetailsPage extends BasePage {
  RBFDetailsPage({required this.transactionDetailsViewModel, required this.rawTransaction}) {
    transactionDetailsViewModel.addBumpFeesListItems(
        transactionDetailsViewModel.transactionInfo, rawTransaction);
  }

  @override
  String get title => S.current.bump_fee;

  final TransactionDetailsViewModel transactionDetailsViewModel;
  final String rawTransaction;

  bool _effectsInstalled = false;

  @override
  Widget body(BuildContext context) {
    _setEffects(context);
    return Column(
      children: [
        Expanded(
          child: SectionStandardList(
              sectionCount: 1,
              itemCounter: (int _) => transactionDetailsViewModel.RBFListItems.length,
              itemBuilder: (__, index) {
                final item = transactionDetailsViewModel.RBFListItems[index];

                if (item is StandartListItem) {
                  return GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.value));
                      showBar<void>(context, S.of(context).transaction_details_copied(item.title));
                    },
                    child: ListRow(title: '${item.title}:', value: item.value),
                  );
                }

                if (item is StandardExpandableListItem) {
                  return StandardExpandableList(
                    title: '${item.title}: ${item.expandableItems.length}',
                    expandableItems: item.expandableItems,
                  );
                }

                if (item is StandardPickerListItem) {
                  return StandardPickerList(
                    title: item.title,
                    value: item.value,
                    items: item.items,
                    displayItem: item.displayItem,
                    onSliderChanged: item.onSliderChanged,
                    onItemSelected: item.onItemSelected,
                    selectedIdx: item.selectedIdx,
                    customItemIndex: item.customItemIndex,
                    customValue: item.customValue,
                    maxValue: item.maxValue,
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
        Padding(
            padding: const EdgeInsets.all(24),
            child: Observer(
                builder: (_) => LoadingPrimaryButton(
                      onPressed: () async {
                        transactionDetailsViewModel
                            .replaceByFee(transactionDetailsViewModel.newFee.toString());
                      },
                      text: S.of(context).send,
                      isLoading:
                          transactionDetailsViewModel.sendViewModel.state is IsExecutingState,
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                    ))),
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
      if (state is AwaitingConfirmationState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext popupContext) {
                return AlertWithTwoActions(
                    alertTitle: state.title ?? '',
                    alertContent: state.message ?? '',
                    rightButtonText: S.of(context).ok,
                    leftButtonText: S.of(context).cancel,
                    actionRightButton: () {
                      state.onConfirm?.call();
                      Navigator.of(popupContext).pop();
                    },
                    actionLeftButton: () {
                      state.onCancel?.call();
                      Navigator.of(popupContext).pop();
                    });
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
                      await transactionDetailsViewModel.sendViewModel.commitTransaction(context);
                      try {
                        Navigator.of(popupContext).pop();
                      } catch (_) {}
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
}
