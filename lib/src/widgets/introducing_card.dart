import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class IntroducingCard extends StatelessWidget {
  IntroducingCard({this.borderColor});

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            color: Theme.of(context).textTheme.title.backgroundColor),
        child: Container(
          width: double.infinity,
          margin:
              const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AutoSizeText('Introducing Cake Pay!',
                      style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .accentTextTheme
                              .display3
                              .backgroundColor,
                          height: 1),
                      maxLines: 1,
                      textAlign: TextAlign.center),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 23,
                      width: 23,
                      decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Center(
                          child: Image.asset(
                        'assets/images/x.png',
                        color: Palette.darkBlueCraiola,
                        height: 15,
                        width: 15,
                      )),
                    ),
                  )
                ],
              ),
              SizedBox(height: 14),
              Text(
                  'instantly purchase and redeem cards in the app!\nSwipe right to learn more!',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Lato',
                      color: Theme.of(context)
                          .accentTextTheme
                          .display3
                          .backgroundColor,
                      height: 1)),
            ],
          ),
        ),
      ),
    );
  }
}
