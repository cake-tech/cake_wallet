import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ReceiveSeedTypeSelector extends StatelessWidget {
  const ReceiveSeedTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 12.0,
      children: [
        SvgPicture.asset(
          width: 32,
          height: 32,
          "assets/new-ui/switcher-bitcoin-off.svg",
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.primary,
            BlendMode.srcIn,
          ),
        ),
        Text(
          "Standard",
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999999),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () {},
            icon: (Icon(
              color: Theme.of(context).colorScheme.primary,
              size: 20,
              Icons.keyboard_arrow_down,
            )),
          ),
        ),
      ],
    );
  }
}
