import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';

import '../models/connection_model.dart';
import 'connection_item_widget.dart';

class ConnectionWidget extends StatelessWidget {
  const ConnectionWidget({required this.title, required this.info, super.key});

  final String title;
  final List<ConnectionModel> info;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...info.map((e) => ConnectionItemWidget(model: e)),
        ],
      ),
    );
  }
}
