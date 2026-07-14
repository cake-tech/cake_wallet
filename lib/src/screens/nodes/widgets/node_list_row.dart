import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cw_core/node.dart';
import 'package:flutter/material.dart';

class NodeListRow extends StatelessWidget {
  NodeListRow(
      {required this.node,
      required this.onTap,
      required this.onEditComplete,
      required this.isSelected,
      required this.isPow,
      this.speed,
      this.vertical = 10.0,
      this.horizontal = 12.0});

  final Node node;
  final bool isPow;
  final VoidCallback onTap;
  final Future<void> Function(Object?) onEditComplete;
  final bool isSelected;
  final NodeSpeed? speed;
  final double vertical;
  final double horizontal;

  @override
  Widget build(BuildContext context) {
    final leading = buildLeading(context);
    final trailing = buildTrailing(context);

    final hasLabel = node.label != null && node.label!.isNotEmpty;
    final uriText = "${node.uri.host}:${node.uri.port}";
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
          child: Row(
            spacing: 12,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              leading,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Row(
                      spacing: 4,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          hasLabel ? node.label! : uriText,
                          style: TextStyle(fontSize: 12),
                        ),
                        if (badgePath != null)
                          CakeImageWidget(
                            imageUrl: badgePath,
                            colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                          )
                      ],
                    ),
                    if (hasLabel)
                      Text(
                        uriText,
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLeading(BuildContext context) => isSelected
      ? Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.check,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        )
      : SizedBox(width: 24, height: 24);

  Widget buildTrailing(BuildContext context) {
    return Row(
      children: [
        if (speed != null)
          CakeImageWidget(
            imageUrl: Theme.of(context).brightness == Brightness.dark
                ? speed!.darkIconPath
                : speed!.iconPath,
            width: 24,
            height: 24,
          ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final res = await Navigator.of(context).pushNamed(
                isPow ? Routes.newPowNode : Routes.newNode,
                arguments: {'editingNode': node, 'isSelected': isSelected});
            await onEditComplete(res);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 12.0),
            child: CakeImageWidget(
              imageUrl: "assets/new-ui/3dots_vertical.svg",
              colorFilter:
                  ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
            ),
          ),
        )
      ],
    );
  }

  String? get badgePath {
    if (node.isOfficial) return "assets/new-ui/official_node.svg";
    if (node.isBuiltin) return "assets/new-ui/default_node.svg";
    return null;
  }
}
