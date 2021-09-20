import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class ChooseYatAddressAlert extends BaseAlertDialog {
  ChooseYatAddressAlert({
    @required this.alertTitle,
    @required this.alertContent,
    @required this.addresses,
  });

  final String alertTitle;
  final String alertContent;
  final List<String> addresses;

  @override
  String get titleText => alertTitle;

  @override
  String get contentText => alertContent;

  @override
  bool get barrierDismissible => false;

  @override
  Widget actionButtons(BuildContext context) {
    return Container(
      width: 300,
      height: 105,
      color: Theme.of(context).accentTextTheme.body1.backgroundColor,
      child: ListView.separated(
          padding: EdgeInsets.all(0),
          itemCount: addresses.length,
          separatorBuilder: (_, __) => Container(
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
          itemBuilder: (context, index) {
            final address = addresses[index];

            return GestureDetector(
              onTap: () => Navigator.of(context).pop<String>(address),
              child: Container(
                width: 300,
                height: 52,
                padding: EdgeInsets.only(left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        address,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                          color: Theme.of(context).primaryTextTheme.title.color,
                          decoration: TextDecoration.none,
                        ),
                      )
                    )
                  ],
                )
              ),
            );
          })
    );
  }
}