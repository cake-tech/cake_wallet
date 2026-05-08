import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class NewElevatedButton extends StatelessWidget {
  const NewElevatedButton({
    super.key,
    this.onPressed,
    this.buttonText,
  });

  final void Function()? onPressed;
  final String? buttonText;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999999),
        ),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          spacing: 6,
          children: [
            CakeImageWidget(
                imageUrl: "assets/new-ui/options_slider.svg",
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary, BlendMode.srcIn)),
            Text(
              buttonText ?? "",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            )
          ],
        ),
      ),
    );
  }
}