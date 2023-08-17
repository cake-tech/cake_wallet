import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../models/connection_model.dart';
import 'connection_item_widget.dart';

class ConnectionWidget extends StatelessWidget {
  const ConnectionWidget({
    super.key,
    required this.title,
    required this.info,
  });

  final String title;
  final List<ConnectionModel> info;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StyleConstants.layerColor2,
        borderRadius: BorderRadius.circular(
          StyleConstants.linear16,
        ),
      ),
      padding: const EdgeInsets.all(
        StyleConstants.linear8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(title),
          const SizedBox(height: StyleConstants.linear8),
          ...info.map(
            (e) => ConnectionItemWidget(
              model: e,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Container(
      decoration: BoxDecoration(
        color: StyleConstants.layerBubbleColor2,
        borderRadius: BorderRadius.circular(
          StyleConstants.linear16,
        ),
      ),
      padding: StyleConstants.bubblePadding,
      child: Text(
        text,
        style: StyleConstants.layerTextStyle2,
      ),
    );
  }
}
