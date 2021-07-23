import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/unspent_coins/widgets/unspent_coins_list_item.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';

class UnspentCoinsListPage extends BasePage {
  UnspentCoinsListPage({this.unspentCoinsListViewModel});

  @override
  String get title => S.current.unspent_coins_title;

  //@override
  //Widget trailing(BuildContext context) {
  //  final questionImage = Image.asset('assets/images/question_mark.png',
  //      color: Theme.of(context).primaryTextTheme.title.color);

  //  return SizedBox(
  //    height: 20.0,
  //    width: 20.0,
  //    child: ButtonTheme(
  //      minWidth: double.minPositive,
  //      child: FlatButton(
  //          highlightColor: Colors.transparent,
  //          splashColor: Colors.transparent,
  //          padding: EdgeInsets.all(0),
  //          onPressed: () => showUnspentCoinsAlert(context),
  //          child: questionImage),
  //    ),
  //  );
  //}

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  Widget body(BuildContext context) =>
      UnspentCoinsListForm(unspentCoinsListViewModel);
}

class UnspentCoinsListForm extends StatefulWidget {
  UnspentCoinsListForm(this.unspentCoinsListViewModel);

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  UnspentCoinsListFormState createState() =>
      UnspentCoinsListFormState(unspentCoinsListViewModel);
}

class UnspentCoinsListFormState extends State<UnspentCoinsListForm> {
  UnspentCoinsListFormState(this.unspentCoinsListViewModel);

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    //showUnspentCoinsAlert(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Observer(
            builder: (_) => ListView.separated(
                itemCount: unspentCoinsListViewModel.items.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: 15),
                itemBuilder: (_, int index) {
                  return Observer(builder: (_) {
                    final item = unspentCoinsListViewModel.items[index];

                    return GestureDetector(
                        onTap: () =>
                            Navigator.of(context)
                                .pushNamed(Routes.unspentCoinsDetails,
                                arguments: [item, unspentCoinsListViewModel]),
                        child: UnspentCoinsListItem(
                            note: item.note,
                            amount: item.amount,
                            address: item.address,
                            isSending: item.isSending,
                            isFrozen: item.isFrozen,
                            onCheckBoxTap: item.isFrozen
                              ? null
                              : () async {
                                item.isSending = !item.isSending;
                                await unspentCoinsListViewModel
                                  .saveUnspentCoinInfo(item);}));
                  });
                }
            )
        )
    );
  }
}

void showUnspentCoinsAlert(BuildContext context) {
  showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithOneAction(
            alertTitle: '',
            alertContent: 'Information about unspent coins',
            buttonText: S.of(context).ok,
            buttonAction: () => Navigator.of(context).pop());
      });
}