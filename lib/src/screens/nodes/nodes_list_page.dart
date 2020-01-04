import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/nodes/node_indicator.dart';
import 'package:cake_wallet/src/stores/node_list/node_list_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class NodeListPage extends BasePage {
  NodeListPage();

  String get title => S.current.nodes;

  @override
  Widget trailing(context) {
    final nodeList = Provider.of<NodeListStore>(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ButtonTheme(
          minWidth: double.minPositive,
          child: FlatButton(
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          S.of(context).node_reset_settings_title,
                          textAlign: TextAlign.center,
                        ),
                        content: Text(
                          S.of(context).nodes_list_reset_to_default_message,
                          textAlign: TextAlign.center,
                        ),
                        actions: <Widget>[
                          FlatButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(S.of(context).cancel)),
                          FlatButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await nodeList.reset();
                              },
                              child: Text(S.of(context).reset))
                        ],
                      );
                    });
              },
              child: Text(
                S.of(context).reset,
                style: TextStyle(
                    fontSize: 16.0,
                    color: Theme.of(context).primaryTextTheme.subtitle.color),
              )),
        ),
        Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).selectedRowColor),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(Icons.add, color: Palette.violet, size: 22.0),
                ButtonTheme(
                  minWidth: 28.0,
                  height: 28.0,
                  child: FlatButton(
                      shape: CircleBorder(),
                      onPressed: () async {
                        await Navigator.of(context).pushNamed(Routes.newNode);
                        nodeList.update();
                      },
                      child: Offstage()),
                )
              ],
            )),
      ],
    );
  }

  @override
  Widget body(context) => NodeListPageBody();
}

class NodeListPageBody extends StatefulWidget {
  @override
  createState() => NodeListPageBodyState();
}

class NodeListPageBodyState extends State<NodeListPageBody> {
  @override
  Widget build(BuildContext context) {
    final nodeList = Provider.of<NodeListStore>(context);
    final settings = Provider.of<SettingsStore>(context);

    final currentColor = Theme.of(context).selectedRowColor;
    final notCurrentColor = Theme.of(context).backgroundColor;

    return Container(
      padding: EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: <Widget>[
          Expanded(child: Observer(builder: (context) {
            return ListView.separated(
                separatorBuilder: (_, __) => Divider(
                    color: Theme.of(context).dividerTheme.color, height: 1),
                itemCount: nodeList.nodes.length,
                itemBuilder: (BuildContext context, int index) {
                  final node = nodeList.nodes[index];

                  return Observer(builder: (_) {
                    final isCurrent = settings.node == null
                        ? false
                        : node.key == settings.node.key;

                    final content = Container(
                        color: isCurrent ? currentColor : notCurrentColor,
                        child: ListTile(
                          title: Text(
                            node.uri,
                            style: TextStyle(
                                fontSize: 16.0,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .color),
                          ),
                          trailing: FutureBuilder(
                              future: nodeList.isNodeOnline(node),
                              builder: (context, snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.done:
                                    return NodeIndicator(
                                        color: snapshot.data
                                            ? Palette.green
                                            : Palette.red);
                                  default:
                                    return NodeIndicator();
                                }
                              }),
                          onTap: () async {
                            if (!isCurrent) {
                              await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Text(
                                        S
                                            .of(context)
                                            .change_current_node(node.uri),
                                        textAlign: TextAlign.center,
                                      ),
                                      actions: <Widget>[
                                        FlatButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(S.of(context).cancel)),
                                        FlatButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              await settings.setCurrentNode(
                                                  node: node);
                                            },
                                            child: Text(S.of(context).change)),
                                      ],
                                    );
                                  });
                            }
                          },
                        ));

                    return isCurrent
                        ? content
                        : Dismissible(
                            key: Key('${node.key}'),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        S.of(context).remove_node,
                                        textAlign: TextAlign.center,
                                      ),
                                      content: Text(
                                        S.of(context).remove_node_message,
                                        textAlign: TextAlign.center,
                                      ),
                                      actions: <Widget>[
                                        FlatButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(S.of(context).cancel)),
                                        FlatButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(S.of(context).remove)),
                                      ],
                                    );
                                  });
                            },
                            onDismissed: (direction) async =>
                                await nodeList.remove(node: node),
                            direction: DismissDirection.endToStart,
                            background: Container(
                                padding: EdgeInsets.only(right: 10.0),
                                alignment: AlignmentDirectional.centerEnd,
                                color: Palette.red,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                            child: content);
                  });
                });
          }))
        ],
      ),
    );
  }
}
