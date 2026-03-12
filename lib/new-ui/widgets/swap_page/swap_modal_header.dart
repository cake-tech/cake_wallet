import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class SwapModalHeader extends StatelessWidget {
  const SwapModalHeader({super.key, required this.fromIconPath, required this.toIconPath});

  final String fromIconPath;
  final String toIconPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        SizedBox(
          height: 36,
          width: 36,
          child: Stack(
            children: [
              Image.asset(fromIconPath, width: 24, height: 24),
              Positioned(top: 12, left: 12, child: Image.asset(toIconPath, width: 24, height: 24)),
            ],
          ),
        ),
        Text(
          S.of(context).swap,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        )
      ],
    );
  }
}
