import 'package:cake_wallet/new-ui/widgets/navbar/navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NavbarButton extends StatelessWidget {
  const NavbarButton({
    super.key,
    required this.data,
    required this.selected,
    required this.onPressed,
  });

  final NavbarItemData data;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      curve: Curves.easeOut,
      duration: Duration(milliseconds: 100),
      child: AnimatedContainer(
        curve: Curves.easeOut,
        duration: Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: selected
              ? Color(0x79BDCFFF)
              : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(0),
          borderRadius: BorderRadius.circular(1242357),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              constraints: BoxConstraints(),
              padding: EdgeInsets.zero,
              icon: SvgPicture.asset(
                data.iconPath,
                width: selected ? 24 : 36,
                height: selected ? 24 : 36,
                colorFilter: ColorFilter.mode(
                  selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: onPressed,
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                child: Text(
                  data.text,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
