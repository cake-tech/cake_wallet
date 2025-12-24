import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CoinActionButton extends StatelessWidget {
  const CoinActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.action,
  });

  final SvgPicture icon;
  final String label;
  final VoidCallback action;

  static const sizeFactor = 0.16;

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width*sizeFactor;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [context.customColors.cardGradientColorPrimary, context.customColors.cardGradientColorSecondary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              width: 1,
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: action,
            icon: icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top:8.0),
          child: Text(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface),
            label,
          ),
        ),
      ],
    );
  }
}
