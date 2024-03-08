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
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
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
                    final fee =
                    await transactionDetailsViewModel.setBitcoinRBFTransactionPriority(context);
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
}
