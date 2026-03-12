import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cake_wallet/view_model/node_list/pow_node_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ManageNodesPage extends BasePage {
  ManageNodesPage(this.isPow, {this.nodeListViewModel, this.powNodeListViewModel, this.dashboardViewModel})
      : assert((isPow && powNodeListViewModel != null) || (!isPow && nodeListViewModel != null));

  final DashboardViewModel? dashboardViewModel;
  final NodeListViewModel? nodeListViewModel;
  final PowNodeListViewModel? powNodeListViewModel;
  final bool isPow;

  @override
  bool get hideAppBar => true;

  @override
  String get title => S.current.manage_nodes;

  @override
  Widget body(BuildContext context) {
    return ModalPageWrapper(
      horizontalPadding: 0,
      topBar: ModalTopBar(
        title: S.of(context).manage_nodes,
        leadingIcon: Icon(Icons.arrow_back_ios_new),
        onLeadingPressed: () => Navigator.of(context).pop(),
        trailingWidget: Row(
          spacing: 8,
          children: [
            if (dashboardViewModel?.hasRescan ?? true)
              ModernButton(
                  size: 36,
                  icon: Icon(Icons.history),
                  onPressed: () => Navigator.of(context).pushNamed(Routes.rescan)),
            ModernButton(
                size: 36,
                icon: Icon(Icons.add),
                onPressed: () => Navigator.of(context).pushNamed(Routes.newNode))
          ],
        ),
      ),
      content: Column(
        children: [
          if (FeatureFlag.isAutomaticNodeSwitchingEnabled)
            Observer(
              builder: (_) => SettingsSwitcherCell(
                key: ValueKey('manage_nodes_page_enable_auto_node_switching_button_key'),
                title: S.current.enable_auto_node_switching,
                value: isPow
                    ? powNodeListViewModel!.enableAutomaticNodeSwitching
                    : nodeListViewModel!.enableAutomaticNodeSwitching,
                onValueChange: (BuildContext context, bool value) {
                  if (isPow) {
                    powNodeListViewModel!.setEnableAutomaticNodeSwitching(value);
                  } else {
                    nodeListViewModel!.setEnableAutomaticNodeSwitching(value);
                  }
                },
              ),
            ),
          if (FeatureFlag.isAutomaticNodeSwitchingEnabled) SizedBox(height: 8),
          Observer(
            builder: (BuildContext context) {
              int itemsCount =
                  nodeListViewModel?.nodes.length ?? powNodeListViewModel!.nodes.length;
              return SectionStandardList(
                sectionCount: 1,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                dividerPadding: EdgeInsets.symmetric(horizontal: 24),
                itemCounter: (int sectionIndex) => itemsCount,
                itemBuilder: (_, index) {
                  return Observer(
                    builder: (context) {
                      final node =
                          nodeListViewModel?.nodes[index] ?? powNodeListViewModel!.nodes[index];
                      late bool isSelected;
                      if (isPow) {
                        isSelected = node.keyIndex == powNodeListViewModel!.currentNode.keyIndex;
                      } else {
                        isSelected = node.keyIndex == nodeListViewModel!.currentNode.keyIndex;
                      }
                      final nodeListRow = NodeListRow(
                        title: node.uriRaw,
                        subtitle: node.label!,
                        node: node,
                        isSelected: isSelected,
                        isPow: false,
                        onTap: (_) async {
                          if (isSelected) {
                            return;
                          }

                          await showPopUp<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertWithTwoActions(
                                alertTitle: S.of(context).change_current_node_title,
                                alertContent: nodeListViewModel?.getAlertContent(node.uriRaw) ??
                                    powNodeListViewModel!.getAlertContent(node.uriRaw),
                                leftButtonText: S.of(context).cancel,
                                rightButtonText: S.of(context).change,
                                actionLeftButton: () => Navigator.of(context).pop(),
                                actionRightButton: () async {
                                  if (isPow) {
                                    await powNodeListViewModel!.setAsCurrent(node);
                                  } else {
                                    await nodeListViewModel!.setAsCurrent(node);
                                  }
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          );
                        },
                      );
                      return nodeListRow;
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
  Future<void> _presentReconnectAlert(BuildContext context) async {
    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithTwoActions(
            alertTitle: S.of(context).reconnection,
            alertContent: S.of(context).reconnect_alert_text,
            rightButtonText: S.of(context).ok,
            leftButtonText: S.of(context).cancel,
            actionRightButton: () async {
              Navigator.of(context).pop();
              await dashboardViewModel!.reconnect();
            },
            actionLeftButton: () => Navigator.of(context).pop());
      },
    );
  }
}
