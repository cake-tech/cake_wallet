import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_list_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ConnectionSyncPage extends BasePage {
  ConnectionSyncPage(this.nodeListViewModel, this.dashboardViewModel);

  @override
  String get title => S.current.connection_sync;

  final NodeListViewModel nodeListViewModel;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsCellWithArrow(
            title: S.current.reconnect,
            handler: (context) => _presentReconnectAlert(context),
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          if (dashboardViewModel.hasRescan)
            SettingsCellWithArrow(
              title: S.current.rescan,
              handler: (context) => Navigator.of(context).pushNamed(Routes.rescan),
            ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          Semantics(
            button: true,
            child: NodeHeaderListRow(
              title: S.of(context).add_new_node,
              onTap: (_) async =>
                  await Navigator.of(context).pushNamed(Routes.newNode),
            ),
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SizedBox(height: 100),
          Observer(
            builder: (BuildContext context) {
              return Flexible(
                child: SectionStandardList(
                  sectionCount: 1,
                  dividerPadding: EdgeInsets.symmetric(horizontal: 24),
                  itemCounter: (int sectionIndex) {
                    return nodeListViewModel.nodes.length;
                  },
                  itemBuilder: (sectionIndex, index) {
                    final node = nodeListViewModel.nodes[index];
                    final isSelected = node.keyIndex == nodeListViewModel.currentNode.keyIndex;
                    final nodeListRow = Semantics(
                      label: 'Slidable',
                      selected: isSelected,
                      enabled: !isSelected,
                      child: NodeListRow(
                        title: node.uriRaw,
                        isSelected: isSelected,
                        isAlive: node.requestNode(),
                        onTap: (_) async {
                          if (isSelected) {
                            return;
                          }

                          await showPopUp<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertWithTwoActions(
                                  alertTitle:
                                      S.of(context).change_current_node_title,
                                  alertContent: nodeListViewModel
                                      .getAlertContent(node.uriRaw),
                                  leftButtonText: S.of(context).cancel,
                                  rightButtonText: S.of(context).change,
                                  actionLeftButton: () =>
                                      Navigator.of(context).pop(),
                                  actionRightButton: () async {
                                    await nodeListViewModel.setAsCurrent(node);
                                    Navigator.of(context).pop();
                                  },
                                );
                              });
                        },
                      ),
                    );

                    final dismissibleRow = Slidable(
                      key: Key('${node.keyIndex}'),
                      startActionPane: _actionPane(context, node, isSelected),
                      endActionPane: _actionPane(context, node, isSelected),
                      child: nodeListRow,
                    );

                    return dismissibleRow;
                  },
                ),
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
              await dashboardViewModel.reconnect();
            },
            actionLeftButton: () => Navigator.of(context).pop());
      },
    );
  }

  ActionPane _actionPane(BuildContext context, Node node, bool isSelected) => ActionPane(
        motion: const ScrollMotion(),
        extentRatio: isSelected ? 0.3 : 0.6,
        children: [
          if (!isSelected)
            SlidableAction(
              onPressed: (context) async {
                final confirmed = await showPopUp<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertWithTwoActions(
                              alertTitle: S.of(context).remove_node,
                              alertContent: S.of(context).remove_node_message,
                              rightButtonText: S.of(context).remove,
                              leftButtonText: S.of(context).cancel,
                              actionRightButton: () => Navigator.pop(context, true),
                              actionLeftButton: () => Navigator.pop(context, false));
                        }) ??
                    false;

                if (confirmed) {
                  await nodeListViewModel.delete(node);
                }
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: CupertinoIcons.delete,
              label: S.of(context).delete,
            ),
          SlidableAction(
            onPressed: (_) => Navigator.of(context).pushNamed(Routes.newNode,
                arguments: {'editingNode': node, 'isSelected': isSelected}),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: S.of(context).edit,
          ),
        ],
      );
}
