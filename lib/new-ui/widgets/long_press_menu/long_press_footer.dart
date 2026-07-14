import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class LongPressFooter extends StatelessWidget {
  const LongPressFooter({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.primary.withAlpha(60),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              CakeImageWidget(
                imageUrl: "assets/new-ui/info.svg",
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
              ),
              Text(
                text,
                style:
                    TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            ],
          ),
        ),
      ),
    );
  }
}
