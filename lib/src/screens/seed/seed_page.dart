import 'package:provider/provider.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/stores/wallet_seed/wallet_seed_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class SeedPage extends BasePage {
  static final image = Image.asset('assets/images/seed_image.png');
  bool get isModalBackButton => true;
  String get title => S.current.seed_title;

  final VoidCallback onCloseCallback;

  SeedPage({this.onCloseCallback});

  void onClose(BuildContext context) =>
      onCloseCallback != null ? onCloseCallback() : Navigator.of(context).pop();

  @override
  Widget leading(BuildContext context) {
    return onCloseCallback != null ? Offstage() : super.leading(context);
  }

  @override
  Widget body(BuildContext context) {
    final walletSeedStore = Provider.of<WalletSeedStore>(context);
    String _seed;

    return Container(
      padding: EdgeInsets.all(30.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  image,
                  Container(
                    margin: EdgeInsets.only(left: 30.0, top: 10.0, right: 30.0),
                    child: Observer(builder: (_) {
                      _seed = walletSeedStore.seed;
                      return Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                  child: Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            width: 1.0,
                                            color: Theme.of(context)
                                                .dividerColor))),
                                padding: EdgeInsets.only(bottom: 20.0),
                                margin: EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  walletSeedStore.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18.0,
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .button
                                          .color),
                                ),
                              ))
                            ],
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Text(
                            walletSeedStore.seed,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14.0,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .color),
                          )
                        ],
                      );
                    }),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 30.0),
                    child: Row(
                      children: <Widget>[
                        Flexible(
                            child: Container(
                          padding: EdgeInsets.only(right: 8.0),
                          child: PrimaryButton(
                              onPressed: () => Share.text(
                                  S.of(context).seed_share,
                                  _seed,
                                  'text/plain'),
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .button
                                  .backgroundColor,
                              borderColor: Theme.of(context)
                                  .primaryTextTheme
                                  .button
                                  .decorationColor,
                              text: S.of(context).save),
                        )),
                        Flexible(
                            child: Container(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Builder(
                                  builder: (context) => PrimaryButton(
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: _seed));
                                        Scaffold.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(S
                                                .of(context)
                                                .copied_to_clipboard),
                                            backgroundColor: Colors.green,
                                            duration:
                                                Duration(milliseconds: 1500),
                                          ),
                                        );
                                      },
                                      text: S.of(context).copy,
                                      color: Theme.of(context)
                                          .accentTextTheme
                                          .caption
                                          .backgroundColor,
                                      borderColor: Theme.of(context)
                                          .accentTextTheme
                                          .caption
                                          .decorationColor),
                                )))
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          onCloseCallback != null
              ? PrimaryButton(
                  onPressed: () => onClose(context),
                  text: S.of(context).restore_next,
                  color: Palette.darkGrey,
                  borderColor: Palette.darkGrey)
              : Offstage()
        ],
      ),
    );
  }
}
