import 'package:cake_wallet/src/screens/yat/widgets/yat_bar.dart';
import 'package:cake_wallet/src/screens/yat/widgets/yat_page_indicator.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:lottie/lottie.dart';

class FirstIntroduction extends StatelessWidget {
  FirstIntroduction({this.onClose, this.onNext});

  static const aspectRatioImage = 1.133;
  final VoidCallback onClose;
  final VoidCallback onNext;
  final animation = Lottie.asset('assets/animation/anim1.json');

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
        height: screenHeight,
        width: screenWidth,
        color: Colors.white,
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(top: 40, bottom: 40),
          content: Column(
              children: [
                Container(
                    height: 45,
                    padding: EdgeInsets.only(left: 24, right: 24),
                    child: YatBar(onClose: () => Navigator.of(context).pop())
                ),
                animation,
                Container(
                    padding: EdgeInsets.only(left: 30, right: 30),
                    child: Column(
                        children: [
                          Text(
                              'Send and receive crypto more easily with Yat',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                                color: Colors.black,
                                decoration: TextDecoration.none,
                              )
                          ),
                          Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                  'Cake Wallet users can now send and receive all their favorite currencies with a one-of-a-kind emoji-based username.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Lato',
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                  )
                              )
                          )
                        ]
                    )
                )
              ]
          ),
          bottomSectionPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
          bottomSection: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PrimaryButton(
                    text: 'Next',
                    textColor: Colors.white,
                    color: Palette.protectiveBlue,
                    onPressed: onNext
                ),
                Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: YatPageIndicator(filled: 0)
                )
              ]
          ),
        )
    );
  }
}