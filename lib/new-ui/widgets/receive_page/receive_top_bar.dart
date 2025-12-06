import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:flutter/material.dart';

class ReceiveTopBar extends StatelessWidget {
  const ReceiveTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ModernButton(size: 52, onPressed: () {
        Navigator.of(context).pop();
      }, icon: Icon(Icons.close)),

          Text("Receive", style: TextStyle(fontSize: 22)),
          ModernButton(size: 52, onPressed: () {
            Navigator.of(context).pop();
          }, icon: Icon(Icons.share)),
        ],
      ),
    );
  }
}
