import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_list_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';

class NodeListPage extends BasePage {
  NodeListPage(this.nodeListViewModel);

  @override
  String get title => S.current.nodes;

  final NodeListViewModel nodeListViewModel;

  @override
  Widget trailing(context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          color: Theme.of(context).accentTextTheme.title.backgroundColor),
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: FlatButton(
            onPressed: () async {
              await showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertWithTwoActions(
                        alertTitle: S.of(context).node_reset_settings_title,
                        alertContent:
                            S.of(context).nodes_list_reset_to_default_message,
                        leftButtonText: S.of(context).reset,
                        rightButtonText: S.of(context).cancel,
                        actionLeftButton: () async {
                          Navigator.of(context).pop();
                          await nodeListViewModel.reset();
                        },
                        actionRightButton: () => Navigator.of(context).pop());
                  });
            },
            child: Text(
              S.of(context).reset,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue),
            )),
      ),
    );
  }

  @override
  Widget body(context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Observer(
        builder: (_) => SectionStandardList(
            sectionCount: 2,
            context: context,
            itemBuilder: (_, sectionIndex, index) {
              if (sectionIndex == 0) {
                return NodeHeaderListRow(
                    title: S.of(context).add_new_node,
                    onTap: (_) async =>
                        await Navigator.of(context).pushNamed(Routes.newNode));
              }

              final node = nodeListViewModel.nodes[index];
              final nodeListRow = NodeListRow(
                  title: node.value.uri,
                  isSelected: node.isSelected,
                  isAlive: node.value.requestNode(),
                  onTap: (_) async {
                    if (node.isSelected) {
                      return;
                    }

                    await showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Text(
                              S.of(context).change_current_node(node.value.uri),
                              textAlign: TextAlign.center,
                            ),
                            actions: <Widget>[
                              FlatButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(S.of(context).cancel)),
                              FlatButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await nodeListViewModel
                                        .setAsCurrent(node.value);
                                  },
                                  child: Text(S.of(context).change)),
                            ],
                          );
                        });
                  });

              final dismissibleRow = Dismissible(
                  key: Key('${node.value.key}'),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertWithTwoActions(
                              alertTitle: S.of(context).remove_node,
                              alertContent: S.of(context).remove_node_message,
                              leftButtonText: S.of(context).remove,
                              rightButtonText: S.of(context).cancel,
                              actionLeftButton: () =>
                                  Navigator.pop(context, true),
                              actionRightButton: () =>
                                  Navigator.pop(context, false));
                        });
                  },
                  onDismissed: (direction) async =>
                      nodeListViewModel.delete(node.value),
                  direction: DismissDirection.endToStart,
                  background: Container(
                      padding: EdgeInsets.only(right: 10.0),
                      alignment: AlignmentDirectional.centerEnd,
                      color: Palette.red,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          const Icon(
                            CupertinoIcons.delete,
                            color: Colors.white,
                          ),
                          Text(
                            S.of(context).delete,
                            style: TextStyle(color: Colors.white),
                          )
                        ],
                      )),
                  child: nodeListRow);

              return node.isSelected ? nodeListRow : dismissibleRow;
            },
            itemCounter: (int sectionIndex) {
              if (sectionIndex == 0) {
                return 1;
              }

              return nodeListViewModel.nodes.length;
            }),
      ),
    );
  }
}
