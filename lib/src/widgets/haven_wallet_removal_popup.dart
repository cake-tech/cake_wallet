import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:flutter/material.dart';

class HavenWalletRemovalPopup extends StatelessWidget {
  final List<String> affectedWalletNames;

  const HavenWalletRemovalPopup(this.affectedWalletNames, {Key? key}) : super(key: key);

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
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
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
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              decoration: TextDecoration.none,
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                               
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                  "It looks like you have Haven wallets in your list. Haven is getting removed in next release of Cake Wallet, and you currently have Haven in the following wallets:\n\n[${affectedWalletNames.join(", ")}]\n\nPlease move your funds to other wallet, as you will lose access to your Haven funds in next update.\n\nFor assistance, please use the in-app support or email support@cakewallet.com",
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    decoration: TextDecoration.none,
                                    fontSize: 16.0,
                                     
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
