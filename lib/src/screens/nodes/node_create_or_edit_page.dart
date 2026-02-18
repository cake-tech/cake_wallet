import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_form.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
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

  }

  @override
  Widget build(BuildContext context) {

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: widget.editingNode != null ? S.current.edit_node : S.current.node_new,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            onLeadingPressed: Navigator.of(context).pop,
            trailingIcon: SvgPicture.asset(
              "assets/new-ui/scan.svg",width:24,height:24,
              colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
            ),
            onTrailingPressed: () => widget.nodeCreateOrEditViewModel.scanQRCodeForNewNode(context),
          ),
          Expanded(
            child: KeyboardHideOverlay(
              child: Container(
                padding: const EdgeInsets.only(left: 18, right: 18),
                child: ScrollableWithBottomSection(
                  contentPadding: const EdgeInsets.only(bottom: 24.0, top: 8),
                  content: NodeForm(
                    key: _nodeFormKey,
                    nodeViewModel: widget.nodeCreateOrEditViewModel,
                  ),
                  bottomSectionPadding: const EdgeInsets.only(bottom: 24),
                  bottomSection: Observer(
                    builder: (_) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: LoadingPrimaryButton(
                              onPressed: () async {
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
                                  await widget.editingNode!.delete();
                                  Navigator.of(context).pop();
                                }
                              },
                              text: S.of(context).delete,
                              isDisabled: widget.editingNode == null ||
                                  !widget.nodeCreateOrEditViewModel.isReady ||
                                  (widget.isSelected ?? false),
                              color: Theme.of(context).colorScheme.errorContainer,
                              textColor: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: PrimaryButton(
                              onPressed: () async {
                                if (_nodeFormKey.currentState != null && !_nodeFormKey.currentState!.validate()) {
                                  return;
                                }

                                await widget.nodeCreateOrEditViewModel.save(
                                    editingNode: widget.editingNode, saveAsCurrent: widget.isSelected ?? false);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              text: S.of(context).save,
                              color: Theme.of(context).colorScheme.primary,
                              textColor: Theme.of(context).colorScheme.onPrimary,
                              isDisabled: (!widget.nodeCreateOrEditViewModel.isReady) ||
                                  (widget.nodeCreateOrEditViewModel.connectionState is IsExecutingState),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
