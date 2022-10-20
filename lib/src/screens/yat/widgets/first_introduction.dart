import 'package:cake_wallet/src/screens/yat/widgets/yat_bar.dart';
import 'package:cake_wallet/src/screens/yat/widgets/yat_page_indicator.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:lottie/lottie.dart';
import 'package:cake_wallet/generated/i18n.dart';

class FirstIntroduction extends StatelessWidget {
  FirstIntroduction({required this.onNext, this.onClose});

  static const aspectRatioImage = 1.133;
  final VoidCallback? onClose;
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
                              S.of(context).yat_alert_title,
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
                                  S.of(context).yat_alert_content,
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
                    text: S.of(context).restore_next,
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