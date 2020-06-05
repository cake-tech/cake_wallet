import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/subaddress_list/subaddress_list_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/screens/accounts/account_list_page.dart';
import 'package:cake_wallet/src/stores/account_list/account_list_store.dart';
import 'package:cake_wallet/src/screens/receive/widgets/header_tile.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/themes.dart';
import 'package:cake_wallet/theme_changer.dart';

class ReceivePage extends StatefulWidget {
  @override
  ReceivePageState createState() => ReceivePageState();
}

class ReceivePageState extends State<ReceivePage> {
  final amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _backArrowImage = Image.asset('assets/images/back_arrow.png');
  final _backArrowImageDarkTheme =
  Image.asset('assets/images/back_arrow_dark_theme.png');

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = Provider.of<WalletStore>(context);
    final subaddressListStore = Provider.of<SubaddressListStore>(context);
    final accountListStore = Provider.of<AccountListStore>(context);

    final shareImage = Image.asset('assets/images/share.png',
      color: Theme.of(context).primaryTextTheme.title.color,
    );
    final copyImage = Image.asset('assets/images/copy_content.png',
      color: Theme.of(context).primaryTextTheme.title.color,
    );

    final currentColor = Theme.of(context).accentTextTheme.subtitle.decorationColor;
    final notCurrentColor = Theme.of(context).backgroundColor;

    final currentTextColor = Colors.blue;
    final notCurrentTextColor = Theme.of(context).primaryTextTheme.caption.color;

    final _themeChanger = Provider.of<ThemeChanger>(context);
    Image _backButton;

    if (_themeChanger.getTheme() == Themes.darkTheme) {
      _backButton = _backArrowImageDarkTheme;
    } else {
      _backButton = _backArrowImage;
    }

    amountController.addListener(() {
      if (_formKey.currentState.validate()) {
        walletStore.onChangedAmountValue(amountController.text);
      } else {
        walletStore.onChangedAmountValue('');
      }
    });

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.only(top: 24),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).primaryColor
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight
              )
          ),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: 20,
                  left: 5,
                  right: 10
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: ButtonTheme(
                        minWidth: double.minPositive,
                        child: FlatButton(
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            padding: EdgeInsets.all(0),
                            onPressed: () => Navigator.of(context).pop(),
                            child: _backButton),
                      ),
                    ),
                    Text(
                      S.of(context).receive,
                      style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryTextTheme.title.color),
                    ),
                    SizedBox(
                      height: 44.0,
                      width: 44.0,
                      child: ButtonTheme(
                        minWidth: double.minPositive,
                        child: FlatButton(
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            padding: EdgeInsets.all(0),
                            onPressed: () => Share.text(
                                S.current.share_address, walletStore.subaddress.address, 'text/plain'),
                            child: shareImage),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Observer(builder: (_) {
                        return Row(
                          children: <Widget>[
                            Spacer(
                              flex: 1,
                            ),
                            Flexible(
                                flex: 2,
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: QrImage(
                                      data: walletStore.subaddress.address +
                                          walletStore.amountValue,
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Theme.of(context).primaryTextTheme.display4.color,
                                    ),
                                  ),
                                )),
                            Spacer(
                              flex: 1,
                            )
                          ],
                        );
                      }),
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                                child: Form(
                                    key: _formKey,
                                    child: BaseTextFormField(
                                      controller: amountController,
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        BlacklistingTextInputFormatter(
                                            RegExp('[\\-|\\ |\\,]'))
                                      ],
                                      textAlign: TextAlign.center,
                                      hintText: S.of(context).receive_amount,
                                      borderColor: Theme.of(context).primaryTextTheme.caption.color,
                                      validator: (value) {
                                        walletStore.validateAmount(value);
                                        return walletStore.errorMessage;
                                      },
                                      autovalidate: true,
                                    )
                                )
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
                        child: Builder(
                            builder: (context) => Observer(
                              builder: (context) => GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                      text: walletStore.subaddress.address));
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                      S.of(context).copied_to_clipboard,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(milliseconds: 500),
                                  ));
                                },
                                child: Container(
                                  height: 48,
                                  padding: EdgeInsets.only(left: 24, right: 24),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(24)),
                                      color: Theme.of(context).primaryTextTheme.overline.color
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          walletStore.subaddress.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).primaryTextTheme.title.color
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 12),
                                        child: copyImage,
                                      )
                                    ],
                                  ),
                                ),
                              )
                            )
                        ),
                      ),
                      Observer(
                          builder: (_) {
                            subaddressListStore.updateShortAddressShow();

                            return ListView.separated(
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: Theme.of(context).dividerColor,
                                ),
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: subaddressListStore.subaddresses.length + 2,
                                itemBuilder: (context, index) {

                                  if (index == 0) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(24),
                                          topRight: Radius.circular(24)
                                      ),
                                      child: HeaderTile(
                                          onTap: () async {
                                            await showDialog<void>(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AccountListPage(accountListStore: accountListStore);
                                                }
                                            );
                                          },
                                          title: walletStore.account.label,
                                          icon: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: Theme.of(context).primaryTextTheme.title.color,
                                          )
                                      ),
                                    );
                                  }

                                  if (index == 1) {
                                    return HeaderTile(
                                        onTap: () => Navigator.of(context)
                                            .pushNamed(Routes.newSubaddress),
                                        title: S.of(context).subaddresses,
                                        icon: Icon(
                                          Icons.add,
                                          size: 20,
                                          color: Theme.of(context).primaryTextTheme.title.color,
                                        )
                                    );
                                  }

                                  index -= 2;

                                  return Observer(
                                      builder: (_) {
                                        final subaddress = subaddressListStore.subaddresses[index];
                                        final isCurrent =
                                            walletStore.subaddress.address == subaddress.address;

                                        String shortAddress = subaddress.address;
                                        shortAddress = shortAddress.replaceRange(8, shortAddress.length - 8, '...');

                                        final content = Observer(
                                            builder: (_) {
                                              final isShortAddressShow = subaddressListStore.isShortAddressShow[index];

                                              final label = index == 0
                                                  ? 'Primary subaddress'
                                                  : subaddress.label.isNotEmpty
                                                    ? subaddress.label
                                                    : isShortAddressShow ? shortAddress : subaddress.address;

                                              return InkWell(
                                                onTap: () => walletStore.setSubaddress(subaddress),
                                                onLongPress: () {
                                                  if (subaddress.label.isNotEmpty) {
                                                    return;
                                                  }
                                                  subaddressListStore.setShortAddressShow(index, !isShortAddressShow);
                                                },
                                                child: Container(
                                                  color: isCurrent ? currentColor : notCurrentColor,
                                                  padding: EdgeInsets.only(
                                                      left: 24,
                                                      right: 24,
                                                      top: 28,
                                                      bottom: 28
                                                  ),
                                                  child: Text(
                                                    label,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: isCurrent
                                                          ? currentTextColor
                                                          : notCurrentTextColor,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                        );

                                        return isCurrent || index == 0
                                            ? content
                                            : Slidable(
                                            key: Key(subaddress.address),
                                            actionPane: SlidableDrawerActionPane(),
                                            child: content,
                                            secondaryActions: <Widget>[
                                              IconSlideAction(
                                                caption: S.of(context).edit,
                                                color: Theme.of(context).primaryTextTheme.overline.color,
                                                icon: Icons.edit,
                                                onTap: () => Navigator.of(context)
                                                    .pushNamed(Routes.newSubaddress, arguments: subaddress),
                                              )
                                            ]
                                        );
                                      }
                                  );
                                }
                            );
                          }
                      ),
                    ],
                  ),
                )
              )
            ],
          )
      ),
    );
  }
}