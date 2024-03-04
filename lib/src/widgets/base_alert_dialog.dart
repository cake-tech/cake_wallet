import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'dart:ui';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/themes/extensions/alert_theme.dart';
import 'package:flutter/material.dart';

class BaseAlertDialog extends StatelessWidget {
  String? get headerText => '';

  String get titleText => '';

  String get contentText => '';

  String get leftActionButtonText => '';

  String get rightActionButtonText => '';

  bool get isDividerExists => false;

  VoidCallback get actionLeft => () {};

  VoidCallback get actionRight => () {};

  bool get barrierDismissible => true;

  Color? get leftActionButtonTextColor => null;

  Color? get rightActionButtonTextColor => null;

  Color? get leftActionButtonColor => null;

  Color? get rightActionButtonColor => null;

  String? get headerImageUrl => null;

  Widget title(BuildContext context) {
    return Text(
      titleText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w600,
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget headerTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Text(
        headerText!,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 25,
          fontFamily: 'Lato',
          fontWeight: FontWeight.w600,
          color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget content(BuildContext context) {
    return Text(
      contentText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        fontFamily: 'Lato',
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget actionButtons(BuildContext context) {
    return Container(
        height: 60,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: TextButton(
                  onPressed: actionLeft,
                  style: TextButton.styleFrom(
                      backgroundColor:
                          leftActionButtonColor ?? Theme.of(context).dialogBackgroundColor,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.zero))),
                  child: Text(
                    leftActionButtonText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w600,
                      color: leftActionButtonTextColor ??
                          Theme.of(context).extension<AlertTheme>()!.leftButtonTextColor,
                      decoration: TextDecoration.none,
                    ),
                  )),
            ),
            const VerticalSectionDivider(),
            Expanded(
              child: TextButton(
                  onPressed: actionRight,
                  style: TextButton.styleFrom(
                      backgroundColor:
                          rightActionButtonColor ?? Theme.of(context).dialogBackgroundColor,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.zero))),
                  child: Text(
                    rightActionButtonText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w600,
                      color: rightActionButtonTextColor ?? Theme.of(context).primaryColor,
                      decoration: TextDecoration.none,
                    ),
                  )),
            ),
          ],
        ));
  }

  Widget headerImage(BuildContext context, String imageUrl) {
    return Positioned(
      top: -50,
      left: 0,
      right: 0,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => barrierDismissible ? Navigator.of(context).pop() : null,
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            decoration:
                BoxDecoration(color: Theme.of(context).extension<AlertTheme>()!.backdropColor),
            child: Center(
              child: GestureDetector(
                onTap: () => null,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Theme.of(context).dialogBackgroundColor),
                  width: 300,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (headerImageUrl != null) headerImage(context, headerImageUrl!),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (headerImageUrl != null) const SizedBox(height: 50),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              if (headerText != null) headerTitle(context),
                              Padding(
                                padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
                                child: title(context),
                              ),
                              isDividerExists
                                  ? Padding(
                                      padding: EdgeInsets.only(top: 16, bottom: 8),
                                      child: const HorizontalSectionDivider(),
                                    )
                                  : Offstage(),
                              Padding(
                                padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
                                child: content(context),
                              )
                            ],
                          ),
                          const HorizontalSectionDivider(),
                          ClipRRect(
                              borderRadius: BorderRadius.all(Radius.circular(30)),
                              child: actionButtons(context))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
