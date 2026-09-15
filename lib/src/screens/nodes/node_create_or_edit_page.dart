import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/nodes/node_share_page.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_form.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

class NodeCreateOrEditPage extends StatefulWidget {
  NodeCreateOrEditPage({
    required this.nodeCreateOrEditViewModel,
    this.editingNode,
    this.isSelected,
    this.type,
  });

  final NodeCreateOrEditViewModel nodeCreateOrEditViewModel;
  final Node? editingNode;
  final bool? isSelected;
  final WalletType? type;

  @override
  State<NodeCreateOrEditPage> createState() => _NodeCreateOrEditPageState();
}

class _NodeCreateOrEditPageState extends State<NodeCreateOrEditPage> {
  final _nodeFormKey = GlobalKey<NodeFormState>();

  @override
  void initState() {
    super.initState();
    reaction(
      (_) => widget.nodeCreateOrEditViewModel.connectionState,
      (ExecutionState state) {
        if (state is ExecutedSuccessfullyState) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => showPopUp<void>(
              context: context,
              builder: (context) => AlertWithOneAction(
                alertTitle: S.of(context).new_node_testing,
                alertContent: state.payload as bool
                    ? S.of(context).node_connection_successful
                    : S.of(context).node_connection_failed,
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop(),
              ),
            ),
          );
        }

        if (state is FailureState) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => showPopUp<void>(
              context: context,
              builder: (context) => AlertWithOneAction(
                alertTitle: S.of(context).error,
                alertContent: state.error,
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop(),
              ),
            ),
          );
        }
      },
    );

    reaction((_) => widget.nodeCreateOrEditViewModel.state, (state) async {
      if (state is ExecutedSuccessfullyState) {
        await Future.delayed(Duration(milliseconds: 100));
        if (mounted) Navigator.of(context).pop(widget.nodeCreateOrEditViewModel.editingNode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            ModalTopBar(
              title: widget.editingNode != null ? S.current.edit_node : S.current.node_new,
              leadingIcon: Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.current.seed_alert_back,
              onLeadingPressed: Navigator.of(context).pop,
              trailingIcon: Icon(Icons.check),
              trailingSemanticLabel: S.current.save,
              onTrailingPressed: () async {
                if (_nodeFormKey.currentState != null && !_nodeFormKey.currentState!.validate()) {
                  return;
                }

                await widget.nodeCreateOrEditViewModel
                    .save(saveAsCurrent: widget.isSelected ?? false);
              },
            ),
            Expanded(
              child: KeyboardHideOverlay(
                child: Container(
                  padding: const EdgeInsets.only(left: 18, right: 18),
                  child: Column(spacing: 18, children: [
                    NodeForm(
                      key: _nodeFormKey,
                      nodeViewModel: widget.nodeCreateOrEditViewModel,
                    ),
                    NewListSections(sections: {
                      "": [
                        if (widget.editingNode != null)
                          ListItemRegularRow(
                              keyValue: "share",
                              label: S.of(context).share_this_node,
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              showArrow: false,
                              onTap: () {
                                Navigator.of(context).push(CupertinoPageRoute(
                                    builder: (context) => NodeSharePage(
                                        uri: widget.editingNode!.uri,
                                        currency: walletTypeToCryptoCurrency(widget.type!))));
                              }),
                        if (!(widget.editingNode == null ||
                            !widget.nodeCreateOrEditViewModel.isReady ||
                            widget.editingNode!.isBuiltin ||
                            (widget.isSelected ?? false)))
                          ListItemRegularRow(
                              keyValue: "delete",
                              label: S.of(context).delete_this_node,
                              foregroundColor: Theme.of(context).colorScheme.errorContainer,
                              showArrow: false,
                              onTap: () async {
                                final confirmed = await showPopUp<bool>(
                                      context: context,
                                      builder: (context) => AlertWithTwoActions(
                                        alertTitle: S.of(context).remove_node,
                                        alertContent: S.of(context).remove_node_message,
                                        rightButtonText: S.of(context).remove,
                                        leftButtonText: S.of(context).cancel,
                                        actionRightButton: () => Navigator.pop(context, true),
                                        actionLeftButton: () => Navigator.pop(context, false),
                                      ),
                                    ) ??
                                    false;

                                if (confirmed) {
                                  await widget.nodeCreateOrEditViewModel
                                      .delete(editingNode: widget.editingNode!);
                                  Navigator.of(context).pop();
                                }
                              })
                      ]
                    })
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
