import 'package:cake_wallet/src/screens/wallet_connect/models/wc_connection_model.dart';
import 'package:flutter/material.dart';

import 'wc_connection_item_widget.dart';

class WCConnectionWidget extends StatelessWidget {
  const WCConnectionWidget({required this.title, required this.info, super.key});

  final String title;
  final List<WCConnectionModel> info;

  @override
  Widget build(BuildContext context) {
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          ...info.map((e) => WCConnectionItemWidget(model: e)),
        ],
      ),
    );
  }
}
