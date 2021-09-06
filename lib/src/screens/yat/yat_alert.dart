import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/yat/widgets/yat_bar.dart';
import 'package:cake_wallet/src/screens/yat/yat_webview_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:url_launcher/url_launcher.dart';

class YatAlert extends StatelessWidget {
  static const aspectRatioImage = 1.133;
  static const _baseUrl = 'https://yat.fyi';
  static const _signInSuffix = '/sign-in';
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
          bottomSectionPadding: EdgeInsets.fromLTRB(24, 0, 24, 40),
          bottomSection: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PrimaryIconButton(
                    text: 'Get your Yat',
                    textColor: Colors.white,
                    color: Palette.protectiveBlue,
                    borderColor: Palette.protectiveBlue,
                    iconColor: Colors.white,
                    iconBackgroundColor: Colors.transparent,
                    iconData: CupertinoIcons
                        .arrow_up_right_square,
                    mainAxisAlignment: MainAxisAlignment.end,
                    onPressed: () {
                      //Navigator.of(context)
                      //    .popAndPushNamed(Routes.yat, arguments: YatMode.create);
                      final url = _baseUrl + _createSuffix;
                      launch(url);
                    }),
                Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: PrimaryIconButton(
                      text: 'Connect an existing Yat',
                      textColor: Colors.black,
                      color: Palette.blueAlice,
                      borderColor: Palette.blueAlice,
                      iconColor: Colors.black,
                      iconBackgroundColor: Colors.transparent,
                      iconData: CupertinoIcons
                          .arrow_up_right_square,
                      mainAxisAlignment: MainAxisAlignment.end,
                      onPressed: () {
                        //Navigator.of(context)
                        //    .popAndPushNamed(Routes.yat, arguments: YatMode.connect);
                        final url = _baseUrl + _signInSuffix;
                        launch(url);
                      })
                )
              ]
          ),
        )
    );
  }
}