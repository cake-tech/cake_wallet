import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class ReceiveLabelWidget extends StatelessWidget {
  const ReceiveLabelWidget({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return                   AnimatedContainer(
      duration: Duration(milliseconds: 200),
        height: name.isEmpty ? 0 : 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(999)
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            spacing: 8,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset("assets/new-ui/label.svg", colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),),
              Text(name, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ));
  }
}
