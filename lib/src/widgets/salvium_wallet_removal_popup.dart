import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:flutter/material.dart';

class SalviumWalletRemovalPopup extends StatelessWidget {
  final List<String> affectedWalletNames;

  const SalviumWalletRemovalPopup(this.affectedWalletNames, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AlertBackground(
          child: AlertDialog(
            insetPadding: EdgeInsets.only(left: 16, right: 16, bottom: 48),
            elevation: 0.0,
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
            content: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  gradient: LinearGradient(colors: [
                    Theme.of(context).extension<DashboardPageTheme>()!.firstGradientBackgroundColor,
                    Theme.of(context)
                        .extension<DashboardPageTheme>()!
                        .secondGradientBackgroundColor,
                  ], begin: Alignment.centerLeft, end: Alignment.centerRight)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          child: DefaultTextStyle(
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                              color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                            ),
                            child: Text("Emergency Notice"),
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(top: 48, bottom: 16),
                        child: Container(
                          width: double.maxFinite,
                          child: Column(
                            children: <Widget>[
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                                ),
                                child: Text(
                                  "It looks like you have Salvium wallets in your list. Salvium is getting removed in next release of Cake Wallet, and you currently have Salvium in the following wallets:\n\n[${affectedWalletNames.join(", ")}]\n\nPlease move your funds to other wallet, as you will lose access to your Salvium funds in next update.\n\nFor assistance, please use the in-app support or email support@cakewallet.com",
                                  style: TextStyle(
                                    decoration: TextDecoration.none,
                                    fontSize: 16.0,
                                    fontFamily: 'Lato',
                                    color: Theme.of(context)
                                        .extension<DashboardPageTheme>()!
                                        .textColor,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AlertCloseButton(bottom: 30)
      ],
    );
  }
}
