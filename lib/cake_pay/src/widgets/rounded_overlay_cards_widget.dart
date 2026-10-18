import 'package:flutter/material.dart';

class RoundedOverlayCards extends StatelessWidget {
  const RoundedOverlayCards({
    this.topCardChild = const SizedBox(),
    this.bottomCardChild = const SizedBox(),
  });

  final Widget topCardChild;
  final Widget bottomCardChild;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius:
          BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.38,
                  ),
                  width: double.infinity,
                  child: topCardChild,
                ),
              ),
            ),
            Flexible(
              child: bottomCardChild,
            ),
          ],
        ),
      ),
    );
  }
}
