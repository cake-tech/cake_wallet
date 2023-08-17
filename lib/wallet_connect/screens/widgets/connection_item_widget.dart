import 'package:flutter/material.dart';

import '../../models/connection_model.dart';

class ConnectionItemWidget extends StatelessWidget {
  const ConnectionItemWidget({
    Key? key,
    required this.model,
  }) : super(key: key);

  final ConnectionModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsetsDirectional.only(top: 8),
      child: model.elements != null ? _buildList() : _buildText(),
    );
  }

  Widget _buildList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          model.title!,
          // style: StyleConstants.layerTextStyle3,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          direction: Axis.horizontal,
          children: model.elements!.map((e) => _buildElement(e)).toList(),
        ),
      ],
    );
  }

  Widget _buildElement(String text) {
    return InkWell(
      onTap: model.elementActions != null ? model.elementActions![text] : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          text,
          // style: StyleConstants.layerTextStyle4,
          maxLines: 10,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildText() {
    return Text(
      model.text!,
      // style: StyleConstants.layerTextStyle3,
      // textAlign: TextAlign.center,
    );
  }
}
