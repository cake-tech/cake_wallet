import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DropdownRow extends StatelessWidget {
  const DropdownRow({super.key, required this.expanded, required this.text, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(18),
            bottom: expanded ? Radius.zero : Radius.circular(18),
          ),
      ),
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Advanced Settings",style: TextStyle(fontSize:14,color: Theme.of(context).colorScheme.primary),), AnimatedRotation(
                  duration:
                  Duration(milliseconds: 300),
                  turns: expanded ? 0.0 : 0.5,
                  curve: Curves.easeOut,
                  child: SvgPicture.asset("assets/new-ui/dropdown_arrow.svg",colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),))],
            ),
          ),
        ),
      ),
    );
  }
}
