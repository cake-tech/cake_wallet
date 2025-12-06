import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/transaction_details/rbf_details_list_fee_picker_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_expandable_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/widgets/textfield_list_row.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/confirm_sending_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
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
                  isDisabled: transactionDetailsViewModel.sendViewModel.state is ExecutedSuccessfullyState,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ))),
      ],
    );
  }

  BuildContext? loadingBottomSheetContext;

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    reaction((_) => transactionDetailsViewModel.sendViewModel.state, (ExecutionState state) {
      if (state is! IsExecutingState &&
          loadingBottomSheetContext != null &&
          loadingBottomSheetContext!.mounted) {
        Navigator.of(loadingBottomSheetContext!).pop();
      }

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

      if (state is IsExecutingState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showModalBottomSheet<void>(
              context: context,
              isDismissible: false,
              builder: (BuildContext context) {
                loadingBottomSheetContext = context;
                return LoadingBottomSheet(
                  titleText: S.of(context).generating_transaction,
                );
              },
            );
          }
        });
      }

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (context.mounted) {
            final result = await showModalBottomSheet<bool>(
              context: context,
              isDismissible: false,
              isScrollControlled: true,
              builder: (BuildContext bottomSheetContext) {
                return ConfirmSendingBottomSheet(
                  key: ValueKey('rbf_confirm_sending_bottom_sheet'),
                  titleText: S.of(bottomSheetContext).confirm_transaction,
                  isSlideActionEnabled: transactionDetailsViewModel.sendViewModel.isReadyForSend,
                  walletType: transactionDetailsViewModel.sendViewModel.walletType,
                  titleIconPath:
                      transactionDetailsViewModel.sendViewModel.selectedCryptoCurrency.iconPath,
                  currencyTitle:
                      transactionDetailsViewModel.sendViewModel.selectedCryptoCurrency.title,
                  amount: S.of(bottomSheetContext).send_amount,
                  amountValue:
                      transactionDetailsViewModel.sendViewModel.pendingTransaction!.amountFormatted,
                  fiatAmountValue: transactionDetailsViewModel
                      .sendViewModel.pendingTransactionFiatAmountFormatted,
                  fee: S.of(bottomSheetContext).send_fee,
                  feeValue:
                      transactionDetailsViewModel.sendViewModel.pendingTransaction!.feeFormatted,
                  feeFiatAmount: transactionDetailsViewModel
                      .sendViewModel.pendingTransactionFeeFiatAmountFormatted,
                  outputs: transactionDetailsViewModel.sendViewModel.outputs,
                  footerType: FooterType.slideActionButton,
                  accessibleNavigationModeSlideActionButtonText: S.of(context).send,
                  onSlideActionComplete: () async {
                    Navigator.of(bottomSheetContext).pop();
                    await transactionDetailsViewModel.sendViewModel.commitTransaction(context);
                    try {
                      Navigator.of(bottomSheetContext).pop();
                    } catch (_) {}
                  },
                  change: transactionDetailsViewModel.sendViewModel.pendingTransaction!.change,
                );
              },
            );
            if (result == null) {
              transactionDetailsViewModel.sendViewModel.dismissTransaction();
            }
          }
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
