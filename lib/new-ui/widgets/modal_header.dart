import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class ModalHeader extends StatelessWidget {
  const ModalHeader(
      {super.key,
      required this.iconPath,
      required this.message,
      required this.title,
      this.bottomWidget});

  final String iconPath;
  final String title;
  final String message;
  final Widget? bottomWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CakeImageWidget(imageUrl: iconPath, width: 36, height: 36),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      message,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    )),
              ],
            ),
          ),
          if (bottomWidget != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child:
                  Container(height: 1, color: Theme.of(context).colorScheme.surfaceContainerHigh),
            ),
            ClipRRect(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                child: bottomWidget!)
          ]
        ],
      ),
    );
  }
}
