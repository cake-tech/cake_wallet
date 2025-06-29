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
      BorderRadius.only(bottomLeft: Radius.circular(25.0), bottomRight: Radius.circular(25.0)),
      child: Container(
        height: screenHeight * 0.50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          color: Theme.of(context).colorScheme.surfaceContainer
        ),
        child: Column(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25.0), bottomRight: Radius.circular(25.0)),
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                    ),
                    height: screenHeight * 0.38,
                    width: double.infinity,
                    child: topCardChild)),
            bottomCardChild,
          ],
        ),
      ),
    );
  }
}