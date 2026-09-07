import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/nodes/widgets/node_list_row.dart";
import "package:cake_wallet/src/screens/settings/manage_nodes_page.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class ManageNodesPageRobot extends BaseRobot {
  ManageNodesPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<ManageNodesPage>();
  }

  String currentNodeUri() {
    final page = tester.widget<ManageNodesPage>(find.byType(ManageNodesPage));

    return page.nodeListViewModel.currentNode.uriRaw;
  }

  Future<void> switchToAnotherNode() async {
    final rows = find.byType(NodeListRow);

    await pumpUntilFound(rows.first);

    expect(
      tester.widgetList(rows).length,
      greaterThan(1),
      reason: "Only the current node is listed, there is nothing to switch to",
    );

    await tapWhenVisible(rows.at(1));

    await tapWhenVisible(find.text(S.current.change));

    await settle();
  }
}
