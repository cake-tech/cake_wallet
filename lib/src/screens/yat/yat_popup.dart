import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/yat/widgets/first_introduction.dart';
import 'package:cake_wallet/src/screens/yat/widgets/second_introduction.dart';
import 'package:cake_wallet/src/screens/yat/widgets/third_introduction.dart';
import 'package:cake_wallet/src/screens/yat/widgets/yat_close_button.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';

class YatPopup extends StatelessWidget {
  YatPopup({this.dashboardViewModel, this.onClose})
      : baseUrl = isYatDevMode ? baseDevUrl : baseReleaseUrl;

  static const durationInMilliseconds = 250;

  final DashboardViewModel dashboardViewModel;
  final VoidCallback onClose;
  final String baseUrl;
  final image = Image.asset('assets/images/emoji_popup.png');

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        AlertBackground(
            child: Container()
        ),
        SlideInUp(
          from: 420,
          duration: Duration(milliseconds: durationInMilliseconds),
          child: ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24)),
              child: Container(
                  height: 420,
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(24, 15, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          children: [
                            Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  YatCloseButton(onClose: onClose)
                                ]
                            ),
                            Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                      height: 64,
                                      width: 165,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius
                                              .all(Radius.circular(32)),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 15,
                                                offset: Offset(0, 5)
                                            )
                                          ]
                                      ),
                                      child: image
                                  )
                                ]
                            )
                          ]
                      ),
                      Container(
                          padding: EdgeInsets.only(left: 6, right: 6),
                          child: Column(
                              children: [
                                Text(
                                    'Your wallet address can be emojified.',
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
                                        'You can now send and receive crypto in Cake Wallet with your Yat - a short, emoji-based username. Manage Yats at any time on the settings screen',
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
                      ),
                      PrimaryButton(
                          text: 'Learn More',
                          textColor: Colors.white,
                          color: Palette.protectiveBlue,
                          onPressed: () => dashboardViewModel
                              .isShowFirstYatIntroduction = true
                      )
                    ],
                  )
              )
          ),
        ),
        Observer(builder: (_) => dashboardViewModel.isShowFirstYatIntroduction
            ? SlideInRight(
            from: screenWidth,
            duration: Duration(milliseconds: durationInMilliseconds),
            child: FirstIntroduction(
                onClose: onClose,
                onNext: () => dashboardViewModel
                    .isShowSecondYatIntroduction = true
            ))
            : Container()
        ),
        Observer(builder: (_) => dashboardViewModel.isShowSecondYatIntroduction
            ? SlideInRight(
            from: screenWidth,
            duration: Duration(milliseconds: durationInMilliseconds),
            child: SecondIntroduction(
                onClose: onClose,
                onNext: () => dashboardViewModel
                    .isShowThirdYatIntroduction = true
            ))
            : Container()
        ),
        Observer(builder: (_) => dashboardViewModel.isShowThirdYatIntroduction
            ? SlideInRight(
            from: screenWidth,
            duration: Duration(milliseconds: durationInMilliseconds),
            child: ThirdIntroduction(
                onClose: onClose,
                onGet: () {
                  final url = baseUrl + createSuffix;
                  launch(url);
                },
                onConnect: () {
                  String url = baseUrl + signInSuffix;
                  final parameters = dashboardViewModel
                      .yatStore.defineQueryParameters();
                  if (parameters.isNotEmpty) {
                    url += queryParameter + parameters;
                  }
                  launch(url);
                }
            ))
            : Container()
        )
      ],
    );
  }
}