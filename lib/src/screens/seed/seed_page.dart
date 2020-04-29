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
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class SeedPage extends BasePage {
  SeedPage({this.onCloseCallback});

  static final image = Image.asset('assets/images/crypto_lock.png');

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  String get title => S.current.seed_title;

  final VoidCallback onCloseCallback;

  @override
  void onClose(BuildContext context) =>
      onCloseCallback != null ? onCloseCallback() : Navigator.of(context).pop();

  @override
  Widget leading(BuildContext context) {
    return onCloseCallback != null ? Offstage() : super.leading(context);
  }

  @override
  Widget trailing(BuildContext context) {
    return onCloseCallback != null
        ? GestureDetector(
          onTap: () => onClose(context),
          child: Container(
            width: 70,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              color: PaletteDark.menuList
            ),
            child: Text(
              S.of(context).seed_language_next,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.blue
              ),
            ),
          ),
        )
        : Offstage();
  }

  @override
  Widget body(BuildContext context) {
    final walletSeedStore = Provider.of<WalletSeedStore>(context);
    String _seed;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: PaletteDark.historyPanel,
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(left: 40, right: 40, bottom: 20),
        content: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 33),
              child: image,
            ),
            Padding(
              padding: EdgeInsets.only(top: 33),
              child: Observer(
                builder: (_) {
                  _seed = walletSeedStore.seed;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        walletSeedStore.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                          _seed,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: PaletteDark.walletCardText
                          ),
                        ),
                      )
                    ],
                  );
                }
              ),
            )
          ],
        ),
        bottomSectionPadding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 52
        ),
        bottomSection: Container(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Flexible(
                child: Container(
                  padding: EdgeInsets.only(right: 8.0),
                  child: PrimaryButton(
                    onPressed: () => Share.text(
                        S.of(context).seed_share,
                        _seed,
                        'text/plain'),
                    text: S.of(context).save,
                    color: Colors.green,
                    textColor: Colors.white),
                )
              ),
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
                              duration: Duration(milliseconds: 1500),
                            ),
                          );
                        },
                        text: S.of(context).copy,
                        color: Colors.blue,
                        textColor: Colors.white)
                  ),
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}
