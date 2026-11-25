import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_list_row.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cw_core/node.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ManageNodesPage extends StatefulWidget {
  ManageNodesPage(this.isPow, {required this.nodeListViewModel, this.dashboardViewModel});

  final DashboardViewModel? dashboardViewModel;
  final NodeListViewModel nodeListViewModel;
  final bool isPow;

  @override
  State<ManageNodesPage> createState() => _ManageNodesPageState();
}

class _ManageNodesPageState extends State<ManageNodesPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 300))
        .then((_) => widget.nodeListViewModel.speedTestNodes());
  }

  @override
  Widget build(BuildContext context) {
    return ModalPageWrapper(
      topBar: ModalTopBar(
        title: S.of(context).manage_nodes,
        leadingIcon: Icon(Icons.arrow_back_ios_new),
        leadingSemanticLabel: S.of(context).seed_alert_back,
        onLeadingPressed: () => Navigator.of(context).pop(),
        trailingWidget: Row(
          spacing: 8,
          children: [
            Observer(
              builder: (_) => ModernButton(
                  size: 36,
                  icon: widget.nodeListViewModel.isTestingNodeSpeed
                      ? CupertinoActivityIndicator()
                      : Icon(Icons.refresh),
                  semanticLabel: S.of(context).test_node_speeds,
                  onPressed: () => widget.nodeListViewModel.speedTestNodes()),
            ),
            ModernButton(
                size: 36,
                icon: Icon(Icons.add),
                semanticLabel: S.of(context).add_new_node,
                onPressed: () async {
                  final res = await Navigator.of(context)
                      .pushNamed(widget.isPow ? Routes.newPowNode : Routes.newNode);
                  if (res != null && res is Node) {
                    widget.nodeListViewModel.nodes.add(res);
                  }
                })
          ],
        ),
      ),
      header: ModalHeader(
        iconPath: "assets/new-ui/settings_row_icons/nodes.svg",
        message: S.of(context).nodes_desc,
        title: S.of(context).nodes,
        bottomWidget: Observer(
            builder: (_) => NodeListRow(
                // vertical: 0,
                // horizontal: 0,
                node: widget.nodeListViewModel.currentNode,
                speed: widget.nodeListViewModel.nodeSpeedFor(widget.nodeListViewModel.currentNode),
                onEditComplete: (res) async {
                  if (res != null && res is Node) {
                    widget.nodeListViewModel.nodes.removeWhere((item) => item.id == res.id);
                    widget.nodeListViewModel.nodes.add(res);
                  }
                },
                onTap: () {},
                isSelected: true,
                isPow: widget.isPow)),
      ),
      content: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Observer(
                builder: (BuildContext context) {
                  int itemsCount = widget.nodeListViewModel.nonCurrentNodes.length;
                  return ListView.separated(
                    controller: ModalScrollController.of(context),
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    itemCount: itemsCount,
                    separatorBuilder: (context, index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        height: 1,
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      ),
                    ),
                    itemBuilder: (_, index) {
                      return Observer(
                        builder: (context) {
                          final node = widget.nodeListViewModel.nonCurrentNodes[index];
                          final nodeListRow = NodeListRow(
                            node: node,
                            isSelected: false,
                            isPow: widget.isPow,
                            speed: widget.nodeListViewModel.nodeSpeedFor(node),
                            onEditComplete: (res) async {
                              if (res != null && res is Node) {
                                widget.nodeListViewModel.nodes
                                    .removeWhere((item) => item.id == res.id);
                                widget.nodeListViewModel.nodes.add(res);
                              }
                            },
                            onTap: () async {
                              await showPopUp<void>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertWithTwoActions(
                                    alertTitle: S.of(context).change_current_node_title,
                                    alertContent:
                                        widget.nodeListViewModel.getAlertContent(node.uriRaw),
                                    leftButtonText: S.of(context).cancel,
                                    rightButtonText: S.of(context).change,
                                    actionLeftButton: () => Navigator.of(context).pop(),
                                    actionRightButton: () async {
                                      await widget.nodeListViewModel.setAsCurrent(node);
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
            ),
          ),
        ],
      ),
    );
  }
}
