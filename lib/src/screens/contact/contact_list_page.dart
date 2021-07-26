import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';

class ContactListPage extends BasePage {
  ContactListPage(this.contactListViewModel, {this.isEditable = true});

  final ContactListViewModel contactListViewModel;
  final bool isEditable;

  @override
  String get title => S.current.address_book;

  @override
  Widget trailing(BuildContext context) {
    if (!isEditable) {
      return null;
    }

    return Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).accentTextTheme.caption.color),
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
                  },
                  child: Offstage()),
            )
          ],
        ));
  }

  @override
  Widget body(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
        child: Observer(
          builder: (_) {
            return SectionStandardList(
              context: context,
              sectionCount: 2,
              sectionTitleBuilder: (_, int sectionIndex) {
                var title = 'Contacts';

                if (sectionIndex == 0) {
                  title = 'My wallets';
                }

                return Container(
                    padding: EdgeInsets.only(left: 24, bottom: 20),
                    child: Text(title, style: TextStyle(fontSize: 36)));
              },
              itemCounter: (int sectionIndex) => sectionIndex == 0
                  ? contactListViewModel.walletContacts.length
                  : contactListViewModel.contacts.length,
              itemBuilder: (_, sectionIndex, index) {
                if (sectionIndex == 0) {
                  final walletInfo = contactListViewModel.walletContacts[index];
                  return generateRaw(context, walletInfo);
                }

                final contact = contactListViewModel.contacts[index];
                final content = generateRaw(context, contact);

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
                              onTap: () async => await Navigator.of(context)
                                  .pushNamed(Routes.addressBookAddContact,
                                      arguments: contact),
                            ),
                            IconSlideAction(
                              caption: S.of(context).delete,
                              color: Colors.red,
                              icon: CupertinoIcons.delete,
                              onTap: () async {
                                final isDelete =
                                    await showAlertDialog(context) ?? false;

                                if (isDelete) {
                                  await contactListViewModel.delete(contact);
                                }
                              },
                            ),
                          ]);
              },
            );
          },
        ));
  }

  Widget generateRaw(BuildContext context, ContactBase contact) {
    final image = _getCurrencyImage(contact.type);

    return GestureDetector(
      onTap: () async {
        if (!isEditable) {
          Navigator.of(context).pop(contact);
          return;
        }

        final isCopied = await showNameAndAddressDialog(
            context, contact.name, contact.address);

        if (isCopied != null && isCopied) {
          await Clipboard.setData(ClipboardData(text: contact.address));
          await showBar<void>(context, S.of(context).copied_to_clipboard);
        }
      },
      child: Container(
        color: Colors.transparent,
        padding:
            const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            image ?? Offstage(),
            Expanded(
              child: Padding(
                padding: image != null
                    ? EdgeInsets.only(left: 12)
                    : EdgeInsets.only(left: 0),
                child: Text(
                  contact.name,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).primaryTextTheme.title.color),
                ),
              )
            )
          ],
        ),
      ),
    );
  }

  Image _getCurrencyImage(CryptoCurrency currency) {
    Image image;
    switch (currency) {
      case CryptoCurrency.xmr:
        image =
            Image.asset('assets/images/monero_logo.png', height: 24, width: 24);
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
      case CryptoCurrency.dai:
        image = Image.asset('assets/images/dai.png', height: 24, width: 24);
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
        image =
            Image.asset('assets/images/litecoin.png', height: 24, width: 24);
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
      case CryptoCurrency.usdterc20:
        image = Image.asset('assets/images/usdterc.png', height: 24, width: 24);
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
    return await showPopUp(
        context: context,
        builder: (BuildContext context) {
          return AlertWithTwoActions(
              alertTitle: S.of(context).address_remove_contact,
              alertContent: S.of(context).address_remove_content,
              rightButtonText: S.of(context).remove,
              leftButtonText: S.of(context).cancel,
              actionRightButton: () => Navigator.of(context).pop(true),
              actionLeftButton: () => Navigator.of(context).pop(false));
        });
  }

  Future<bool> showNameAndAddressDialog(
      BuildContext context, String name, String address) async {
    return await showPopUp(
        context: context,
        builder: (BuildContext context) {
          return AlertWithTwoActions(
              alertTitle: name,
              alertContent: address,
              rightButtonText: S.of(context).copy,
              leftButtonText: S.of(context).cancel,
              actionRightButton: () => Navigator.of(context).pop(true),
              actionLeftButton: () => Navigator.of(context).pop(false));
        });
  }
}
