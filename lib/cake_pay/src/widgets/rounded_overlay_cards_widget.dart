import 'package:cake_wallet/palette.dart';
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
        color: PaletteDark.nightBlue,
        height: screenHeight * 0.53,
        child: Column(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25.0), bottomRight: Radius.circular(25.0)),
                child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Palette.nightBlue,
                          Palette.nightBlue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    height: screenHeight * 0.35,
                    width: double.infinity,
                    child: topCardChild)),
            bottomCardChild,
          ],
        ),
      ),
    );
  }
}