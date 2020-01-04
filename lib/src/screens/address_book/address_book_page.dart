import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/stores/address_book/address_book_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class AddressBookPage extends BasePage {
  bool get isModalBackButton => true;
  String get title => S.current.address_book;
  AppBarStyle get appBarStyle => AppBarStyle.withShadow;

  final bool isEditable;

  AddressBookPage({this.isEditable = true});

  @override
  Widget trailing(BuildContext context) {
    if (!isEditable) {
      return null;
    }

    final addressBookStore = Provider.of<AddressBookStore>(context);

    return Container(
        width: 28.0,
        height: 28.0,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).selectedRowColor),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Icon(Icons.add, color: Palette.violet, size: 22.0),
            ButtonTheme(
              minWidth: 28.0,
              height: 28.0,
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
        padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
        child: Observer(
          builder: (_) => ListView.separated(
              separatorBuilder: (_, __) => Divider(
                    color: Theme.of(context).dividerTheme.color,
                    height: 1.0,
                  ),
              itemCount: addressBookStore.contactList == null
                  ? 0
                  : addressBookStore.contactList.length,
              itemBuilder: (BuildContext context, int index) {
                final contact = addressBookStore.contactList[index];

                final content = ListTile(
                  onTap: () async {
                    if (!isEditable) {
                      Navigator.of(context).pop(contact);
                      return;
                    }

                    bool isCopied = await showNameAndAddressDialog(context, contact.name, contact.address);
                    if (isCopied) {
                      Clipboard.setData(ClipboardData(text: contact.address));
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
                          content:
                          Text('Copied to Clipboard'),
                          backgroundColor: Colors.green,
                          duration:
                          Duration(milliseconds: 1500),
                        ),
                      );
                    }
                  },
                  leading: Container(
                    height: 25.0,
                    width: 48.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _getCurrencyBackgroundColor(contact.type),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      contact.type.toString(),
                      style: TextStyle(
                        fontSize: 11.0,
                        color: _getCurrencyTextColor(contact.type),
                      ),
                    ),
                  ),
                  title: Text(
                    contact.name,
                    style: TextStyle(
                        fontSize: 16.0,
                        color: Theme.of(context).primaryTextTheme.title.color),
                  ),
                );

                return !isEditable ? content
                : Slidable(
                    key: Key('1'),// Key(contact.id.toString()),
                    actionPane: SlidableDrawerActionPane(),
                    child: content,
                    secondaryActions: <Widget>[
                      IconSlideAction(
                        caption: 'Edit',
                        color: Colors.blue,
                        icon: Icons.edit,
                        onTap: () async {
                          await Navigator.of(context)
                              .pushNamed(Routes.addressBookAddContact, arguments: contact);
                          await addressBookStore.updateContactList();
                        },
                      ),
                      IconSlideAction(
                        caption: 'Delete',
                        color: Colors.red,
                        icon: CupertinoIcons.delete,
                        onTap: () async {
                          await showAlertDialog(context).then((isDelete) async{
                            if (isDelete != null && isDelete) {
                              await addressBookStore.delete(contact: contact);
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
              }),
        ));
  }

  Color _getCurrencyBackgroundColor(CryptoCurrency currency) {
    Color color;
    switch (currency) {
      case CryptoCurrency.xmr:
        color = Palette.cakeGreenWithOpacity;
        break;
      case CryptoCurrency.btc:
        color = Colors.orange;
        break;
      case CryptoCurrency.eth:
        color = Colors.black;
        break;
      case CryptoCurrency.ltc:
        color = Colors.blue[200];
        break;
      case CryptoCurrency.bch:
        color = Colors.orangeAccent;
        break;
      case CryptoCurrency.dash:
        color = Colors.blue;
        break;
      default:
        color = Colors.white;
    }
    return color;
  }

  Color _getCurrencyTextColor(CryptoCurrency currency) {
    Color color;
    switch (currency) {
      case CryptoCurrency.xmr:
        color = Palette.cakeGreen;
        break;
      case CryptoCurrency.ltc:
        color = Palette.lightBlue;
        break;
      default:
        color = Colors.white;
    }
    return color;
  }

  Future<bool> showAlertDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Remove contact',
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'Are you sure that you want to remove selected contact?',
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              FlatButton(
                  onPressed: () =>
                      Navigator.pop(context, false),
                  child: const Text('Cancel')),
              FlatButton(
                  onPressed: () =>
                      Navigator.pop(context, true),
                  child: const Text('Remove')),
            ],
          );
        });
  }

  showNameAndAddressDialog(BuildContext context, String name, String address) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            address,
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel')),
            FlatButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Copy'))
          ],
        );
      }
    );
  }
}
