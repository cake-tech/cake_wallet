import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FloatingIconButton extends StatelessWidget {
  const FloatingIconButton({super.key, required this.iconPath, required this.onPressed});

  final String iconPath;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: SvgPicture.asset(
              width: 22, height: 22,
              iconPath,
              colorFilter: ColorFilter.mode(Theme
                  .of(context)
                  .colorScheme
                  .primary, BlendMode.srcIn),
            ),
          )
      ),
    );
  }
}