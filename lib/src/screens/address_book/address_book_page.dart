import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/stores/address_book/address_book_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';

class AddressBookPage extends BasePage {
  AddressBookPage({this.isEditable = true});

  final bool isEditable;

  @override
  String get title => S.current.address_book;

  @override
  Widget trailing(BuildContext context) {
    if (!isEditable) {
      return null;
    }

    final addressBookStore = Provider.of<AddressBookStore>(context);

    return Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).accentTextTheme.title.backgroundColor
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Icon(Icons.add,
                color: Theme.of(context).primaryTextTheme.title.color,
                size: 22.0),
            ButtonTheme(
              minWidth: 32.0,
              height: 32.0,
              child: FlatButton(
                  shape: CircleBorder(),
                  onPressed: () async {
                    await Navigator.of(context)
                        .pushNamed(Routes.addressBookAddContact);
                    await addressBookStore.updateContactList();
                  },
                  child: Offstage()),
            )
          ],
        ));
  }

  @override
  Widget body(BuildContext context) {
    final addressBookStore = Provider.of<AddressBookStore>(context);

    return Container(
        color: Theme.of(context).backgroundColor,
        padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
        child: Observer(
          builder: (_) {
            final count = addressBookStore.contactList == null
                ? 0
                : addressBookStore.contactList.length;

            return count > 0
            ? ListView.separated(
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  padding: EdgeInsets.only(left: 24),
                  color: Theme.of(context).accentTextTheme.title.backgroundColor,
                  child: Container(
                    height: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                itemCount: count,
                itemBuilder: (BuildContext context, int index) {
                  final contact = addressBookStore.contactList[index];
                  final image = _getCurrencyImage(contact.type);

                  final isDrawTop = index == 0 ? true : false;
                  final isDrawBottom = index == addressBookStore.contactList.length - 1 ? true : false;

                  final content = GestureDetector(
                    onTap: () async {
                      if (!isEditable) {
                        Navigator.of(context).pop(contact);
                        return;
                      }

                      final isCopied = await showNameAndAddressDialog(
                          context, contact.name, contact.address);

                      if (isCopied != null && isCopied) {
                        await Clipboard.setData(
                            ClipboardData(text: contact.address));
                        Scaffold.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              S.of(context).copied_to_clipboard,
                              style: TextStyle(
                                  color: Colors.white
                              ),
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(milliseconds: 1500),
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: <Widget>[
                        isDrawTop
                            ? Container(
                          width: double.infinity,
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        )
                            : Offstage(),
                        Container(
                          width: double.infinity,
                          color: Theme.of(context).accentTextTheme.title.backgroundColor,
                          child: Padding(
                              padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  image != null
                                      ? image
                                      : Offstage(),
                                  Padding(
                                    padding: image != null
                                        ? EdgeInsets.only(left: 12)
                                        : EdgeInsets.only(left: 0),
                                    child: Text(
                                      contact.name,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).primaryTextTheme.title.color
                                      ),
                                    ),
                                  )
                                ],
                              )
                          ),
                        ),
                        isDrawBottom
                            ? Container(
                          width: double.infinity,
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        )
                            : Offstage(),
                      ],
                    ),
                  );

                  return !isEditable
                      ? content
                      : Slidable(
                    key: Key('${contact.key}'),
                    actionPane: SlidableDrawerActionPane(),
                    child: content,
                    secondaryActions: <Widget>[
                      IconSlideAction(
                        caption: S.of(context).edit,
                        color: Colors.blue,
                        icon: Icons.edit,
                        onTap: () async {
                          await Navigator.of(context).pushNamed(
                              Routes.addressBookAddContact,
                              arguments: contact);
                          await addressBookStore.updateContactList();
                        },
                      ),
                      IconSlideAction(
                        caption: S.of(context).delete,
                        color: Colors.red,
                        icon: CupertinoIcons.delete,
                        onTap: () async {
                          await showAlertDialog(context)
                              .then((isDelete) async {
                            if (isDelete != null && isDelete) {
                              await addressBookStore.delete(
                                  contact: contact);
                              await addressBookStore.updateContactList();
                            }
                          });
                        },
                      ),
                    ],
                    dismissal: SlidableDismissal(
                      child: SlidableDrawerDismissal(),
                      onDismissed: (actionType) async {
                        await addressBookStore.delete(contact: contact);
                        await addressBookStore.updateContactList();
                      },
                      onWillDismiss: (actionType) async {
                        return await showAlertDialog(context);
                      },
                    ),
                  );
                })
            : Center(
              child: Text(
                S.of(context).placeholder_contacts,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.caption.color.withOpacity(0.5),
                    fontSize: 14
                ),
              ),
            );
          },
        ));
  }

  Image _getCurrencyImage(CryptoCurrency currency) {
    Image image;
    switch (currency) {
      case CryptoCurrency.xmr:
        image = Image.asset('assets/images/monero.png', height: 24, width: 24);
        break;
      case CryptoCurrency.ada:
        image = Image.asset('assets/images/ada.png', height: 24, width: 24);
        break;
      case CryptoCurrency.bch:
        image = Image.asset('assets/images/bch.png', height: 24, width: 24);
        break;
      case CryptoCurrency.bnb:
        image = Image.asset('assets/images/bnb.png', height: 24, width: 24);
        break;
      case CryptoCurrency.btc:
        image = Image.asset('assets/images/bitcoin.png', height: 24, width: 24);
        break;
      case CryptoCurrency.dash:
        image = Image.asset('assets/images/dash.png', height: 24, width: 24);
        break;
      case CryptoCurrency.eos:
        image = Image.asset('assets/images/eos.png', height: 24, width: 24);
        break;
      case CryptoCurrency.eth:
        image = Image.asset('assets/images/eth.png', height: 24, width: 24);
        break;
      case CryptoCurrency.ltc:
        image = Image.asset('assets/images/litecoin.png', height: 24, width: 24);
        break;
      case CryptoCurrency.nano:
        image = Image.asset('assets/images/nano.png', height: 24, width: 24);
        break;
      case CryptoCurrency.trx:
        image = Image.asset('assets/images/trx.png', height: 24, width: 24);
        break;
      case CryptoCurrency.usdt:
        image = Image.asset('assets/images/usdt.png', height: 24, width: 24);
        break;
      case CryptoCurrency.xlm:
        image = Image.asset('assets/images/xlm.png', height: 24, width: 24);
        break;
      case CryptoCurrency.xrp:
        image = Image.asset('assets/images/xrp.png', height: 24, width: 24);
        break;
      default:
        image = null;
    }
    return image;
  }

  Future<bool> showAlertDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertWithTwoActions(
              alertTitle: S.of(context).address_remove_contact,
              alertContent: S.of(context).address_remove_content,
              leftButtonText: S.of(context).remove,
              rightButtonText: S.of(context).cancel,
              actionLeftButton: () => Navigator.of(context).pop(true),
              actionRightButton: () => Navigator.of(context).pop(false)
          );
        });
  }

  Future<bool> showNameAndAddressDialog(
      BuildContext context, String name, String address) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertWithTwoActions(
              alertTitle: name,
              alertContent: address,
              leftButtonText: S.of(context).copy,
              rightButtonText: S.of(context).cancel,
              actionLeftButton: () => Navigator.of(context).pop(true),
              actionRightButton: () => Navigator.of(context).pop(false)
          );
        });
  }
}
