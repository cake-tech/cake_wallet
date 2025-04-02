import 'package:cake_wallet/src/screens/wallet_connect/models/connection_model.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';

class WCConnectionWidgetInfo extends StatelessWidget {
  const WCConnectionWidgetInfo({
    super.key,
    required this.model,
  });

  final WCConnectionModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsetsDirectional.only(top: 8),
      child: model.elements != null ? _buildList(context) : _buildText(),
    );
  }

  Widget _buildList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (model.title != null)
          Text(
            model.title!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
            ),
          ),
        if (model.title != null) const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          direction: Axis.horizontal,
          children: model.elements!.map((e) => _buildElement(e, context)).toList(),
        ),
      ],
    );
  }

  Widget _buildElement(String text, BuildContext context) {
    return ElevatedButton(
      onPressed: model.elementActions != null ? model.elementActions![text] : null,
      style: ButtonStyle(
        elevation: model.elementActions != null
            ? WidgetStateProperty.all(4.0)
            : WidgetStateProperty.all(0.0),
        padding: WidgetStateProperty.all(const EdgeInsets.all(0.0)),
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.all(Color(0xFF153B47)),
        overlayColor: WidgetStateProperty.all(Colors.white),
        shape: WidgetStateProperty.resolveWith<RoundedRectangleBorder>(
          (states) {
            return RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            );
          },
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return Text(
      model.text!,
      style: TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
