import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/subaddress_list/subaddress_list_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/accounts/account_list_page.dart';
import 'package:cake_wallet/src/stores/account_list/account_list_store.dart';
import 'package:cake_wallet/src/screens/receive/widgets/header_tile.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';

class ReceivePage extends BasePage {
  @override
  Color get backgroundColor => PaletteDark.mainBackgroundColor;

  @override
  bool get resizeToAvoidBottomPadding => false;

  @override
  String get title => S.current.receive;

  @override
  Widget trailing(BuildContext context) {
    final walletStore = Provider.of<WalletStore>(context);
    final shareImage = Image.asset('assets/images/share.png');

    return SizedBox(
      height: 37.0,
      width: 37.0,
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
    );
  }

  @override
  Widget body(BuildContext context) => ReceiveBody();
}

class ReceiveBody extends StatefulWidget {
  @override
  ReceiveBodyState createState() => ReceiveBodyState();
}

class ReceiveBodyState extends State<ReceiveBody> {
  final amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

    final copyImage = Image.asset('assets/images/copy_content.png');

    final currentColor = PaletteDark.menuList;
    final notCurrentColor = Colors.transparent;

    amountController.addListener(() {
      if (_formKey.currentState.validate()) {
        walletStore.onChangedAmountValue(amountController.text);
      } else {
        walletStore.onChangedAmountValue('');
      }
    });

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: PaletteDark.mainBackgroundColor,
      padding: EdgeInsets.only(top: 24),
      child: Column(
        children: <Widget>[
          Flexible(
            flex: 2,
            child: Observer(builder: (_) {
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
                            foregroundColor: PaletteDark.walletCardText,
                          ),
                        ),
                      )),
                  Spacer(
                    flex: 1,
                  )
                ],
              );
            }),
          ),
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
                          borderColor: PaletteDark.walletCardText,
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
            child: Observer(
                builder: (_) => GestureDetector(
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
                    height: 54,
                    padding: EdgeInsets.only(left: 24, right: 24),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(27)),
                        color: PaletteDark.walletCardSubAddressField
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
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white
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
            ),
          ),
          Flexible(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Container(
                  color: PaletteDark.historyPanel,
                  child: Observer(
                      builder: (_) => ListView.separated(
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: PaletteDark.menuList,
                          ),
                          itemCount: subaddressListStore.subaddresses.length + 2,
                          itemBuilder: (context, index) {

                            if (index == 0) {
                              return HeaderTile(
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
                                    color: Colors.white,
                                  )
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
                                    color: Colors.white,
                                  )
                              );
                            }

                            index -= 2;

                            return Observer(
                                builder: (_) {
                                  final subaddress = subaddressListStore.subaddresses[index];
                                  final isCurrent =
                                      walletStore.subaddress.address == subaddress.address;

                                  final label = subaddress.label;
                                  final address = subaddress.address;

                                  return InkWell(
                                    onTap: () => walletStore.setSubaddress(subaddress),
                                    child: Container(
                                      color: isCurrent ? currentColor : notCurrentColor,
                                      padding: EdgeInsets.only(
                                          left: 24,
                                          right: 24,
                                          top: 32,
                                          bottom: 32
                                      ),
                                      child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            label.isNotEmpty
                                            ? Text(
                                              label,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: PaletteDark.walletCardText
                                              ),
                                            )
                                            : Offstage(),
                                            Padding(
                                              padding: label.isNotEmpty
                                              ? EdgeInsets.only(top: 10)
                                              : EdgeInsets.only(top: 0),
                                              child: Text(
                                                address,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white
                                                ),
                                              ),
                                            )
                                          ]),
                                    ),
                                  );
                                }
                            );
                          }
                      )
                  ),
                ),
              )
          )
        ],
      ),
    );
  }
}