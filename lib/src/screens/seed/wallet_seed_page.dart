import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/wallet_seed_view_model.dart';

class WalletSeedPage extends BasePage {
  WalletSeedPage(this.walletSeedViewModel, {@required this.isNewWalletCreated});

  static final imageLight = Image.asset('assets/images/crypto_lock_light.png');
  static final imageDark = Image.asset('assets/images/crypto_lock.png');

  @override
  String get title => S.current.seed_title;

  final bool isNewWalletCreated;
  final WalletSeedViewModel walletSeedViewModel;

  @override
  void onClose(BuildContext context) async {
    if (isNewWalletCreated) {
      final confirmed = await showPopUp<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithTwoActions(
                    alertTitle: S.of(context).seed_alert_title,
                    alertContent: S.of(context).seed_alert_content,
                    leftButtonText: S.of(context).seed_alert_back,
                    rightButtonText: S.of(context).seed_alert_yes,
                    actionLeftButton: () => Navigator.of(context).pop(false),
                    actionRightButton: () => Navigator.of(context).pop(true));
              }) ??
          false;

      if (confirmed) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget leading(BuildContext context) =>
      isNewWalletCreated ? Offstage() : super.leading(context);

  @override
  Widget trailing(BuildContext context) {
    return isNewWalletCreated
        ? GestureDetector(
            onTap: () => onClose(context),
            child: Container(
              width: 100,
              height: 32,
              alignment: Alignment.center,
              margin: EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  color: Theme.of(context).accentTextTheme.caption.color),
              child: Text(
                S.of(context).seed_language_next,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Palette.blueCraiola),
              ),
            ),
          )
        : Offstage();
  }

  @override
  Widget body(BuildContext context) {
    final image =
        getIt.get<SettingsStore>().isDarkTheme ? imageDark : imageLight;

    return Container(
        padding: EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Flexible(
                flex: 2,
                child: AspectRatio(
                    aspectRatio: 1,
                    child: FittedBox(child: image, fit: BoxFit.fill))),
            Flexible(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 33),
                      child: Observer(builder: (_) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              walletSeedViewModel.name,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .color),
                            ),
                            Padding(
                              padding:
                                  EdgeInsets.only(top: 20, left: 16, right: 16),
                              child: Text(
                                walletSeedViewModel.seed,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .color),
                              ),
                            )
                          ],
                        );
                      }),
                    ),
                    Column(
                      children: <Widget>[
                        isNewWalletCreated
                            ? Padding(
                                padding: EdgeInsets.only(
                                    bottom: 52, left: 43, right: 43),
                                child: Text(
                                  S.of(context).seed_reminder,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .overline
                                          .color),
                                ),
                              )
                            : Offstage(),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Flexible(
                                child: Container(
                              padding: EdgeInsets.only(right: 8.0),
                              child: PrimaryButton(
                                  onPressed: () => Share.text(
                                      S.of(context).seed_share,
                                      walletSeedViewModel.seed,
                                      'text/plain'),
                                  text: S.of(context).save,
                                  color: Colors.green,
                                  textColor: Colors.white),
                            )),
                            Flexible(
                                child: Container(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Builder(
                                  builder: (context) => PrimaryButton(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: walletSeedViewModel.seed));
                                        showBar<void>(context,
                                            S.of(context).copied_to_clipboard);
                                      },
                                      text: S.of(context).copy,
                                      color: Theme.of(context)
                                          .accentTextTheme
                                          .body2
                                          .color,
                                      textColor: Colors.white)),
                            ))
                          ],
                        )
                      ],
                    )
                  ],
                ))
          ],
        ));
  }
}
