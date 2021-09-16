import 'package:cake_wallet/src/screens/yat/widgets/yat_bar.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/generated/i18n.dart';

class YatAlert extends StatelessWidget {
  YatAlert({this.isYatDevMode = false})
      : baseUrl = isYatDevMode ? _baseDevUrl : _baseReleaseUrl;

  final bool isYatDevMode;
  final String baseUrl;
  static const aspectRatioImage = 1.133;
  static const _baseDevUrl = 'https://yat.fyi';
  static const _baseReleaseUrl = 'https://y.at';
  static const _signInSuffix = '/partner/CW/link-email';
  static const _createSuffix = '/create';
  final image = Image.asset('assets/images/yat_crypto.png');

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
                  height: 90,
                  padding: EdgeInsets.only(left: 24, right: 24),
                  child: YatBar(onClose: () => Navigator.of(context).pop())
              ),
              AspectRatio(
                  aspectRatio: aspectRatioImage,
                  child: FittedBox(child: image, fit: BoxFit.fill)
              ),
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
          bottomSectionPadding: EdgeInsets.fromLTRB(24, 0, 24, 40),
          bottomSection: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PrimaryIconButton(
                    text: S.of(context).get_your_yat,
                    textColor: Colors.white,
                    color: Palette.protectiveBlue,
                    borderColor: Palette.protectiveBlue,
                    iconColor: Colors.white,
                    iconBackgroundColor: Colors.transparent,
                    iconData: CupertinoIcons
                        .arrow_up_right_square,
                    mainAxisAlignment: MainAxisAlignment.end,
                    onPressed: () {
                      final url = baseUrl + _createSuffix;
                      launch(url);
                    }),
                Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: PrimaryIconButton(
                      text: S.of(context).connect_an_existing_yat,
                      textColor: Colors.black,
                      color: Palette.blueAlice,
                      borderColor: Palette.blueAlice,
                      iconColor: Colors.black,
                      iconBackgroundColor: Colors.transparent,
                      iconData: CupertinoIcons
                          .arrow_up_right_square,
                      mainAxisAlignment: MainAxisAlignment.end,
                      onPressed: () {
                        final url = baseUrl + _signInSuffix;
                        launch(url);
                      })
                )
              ]
          ),
        )
    );
  }
}