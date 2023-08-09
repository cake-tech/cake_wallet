import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_list_row.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ManageNodesPage extends BasePage {
  ManageNodesPage(this.nodeListViewModel);

  final NodeListViewModel nodeListViewModel;

  @override
  String get title => S.current.manage_nodes;

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Semantics(
            button: true,
            child: NodeHeaderListRow(
              title: S.of(context).add_new_node,
              onTap: (_) async => await Navigator.of(context).pushNamed(Routes.newNode),
            ),
          ),
          const StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SizedBox(height: 20),
          Observer(
            builder: (BuildContext context) {
              return Flexible(
                child: SectionStandardList(
                  sectionCount: 1,
                  context: context,
                  dividerPadding: EdgeInsets.symmetric(horizontal: 24),
                  itemCounter: (int sectionIndex) {
                    return nodeListViewModel.nodes.length;
                  },
                  itemBuilder: (_, sectionIndex, index) {
                    final node = nodeListViewModel.nodes[index];
                    final isSelected = node.keyIndex == nodeListViewModel.currentNode.keyIndex;
                    final nodeListRow = NodeListRow(
                      title: node.uriRaw,
                      node: node,
                      isSelected: isSelected,
                      onTap: (_) async {
                        if (isSelected) {
                          return;
                        }

                        await showPopUp<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertWithTwoActions(
                                alertTitle: S.of(context).change_current_node_title,
                                alertContent: nodeListViewModel.getAlertContent(node.uriRaw),
                                leftButtonText: S.of(context).cancel,
                                rightButtonText: S.of(context).change,
                                actionLeftButton: () => Navigator.of(context).pop(),
                                actionRightButton: () async {
                                  await nodeListViewModel.setAsCurrent(node);
                                  Navigator.of(context).pop();
                                },
                              );
                            });
                      },
                    );

                    return nodeListRow;
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
