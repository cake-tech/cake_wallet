import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/widgets/unspent_coins_list_item.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class UnspentCoinsListPage extends BasePage {
  UnspentCoinsListPage({required this.unspentCoinsListViewModel});

  @override
  String get title => S.current.unspent_coins_title;

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  Widget body(BuildContext context) => UnspentCoinsListForm(unspentCoinsListViewModel);
}

class UnspentCoinsListForm extends StatefulWidget {
  UnspentCoinsListForm(this.unspentCoinsListViewModel);

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  UnspentCoinsListFormState createState() => UnspentCoinsListFormState(unspentCoinsListViewModel);
}

class UnspentCoinsListFormState extends State<UnspentCoinsListForm> {
  UnspentCoinsListFormState(this.unspentCoinsListViewModel);

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  late Future<void> _initialization;

  @override
  void initState() {
    _initialization = unspentCoinsListViewModel.initialSetup();
    super.initState();
  }

  @override
  void dispose() {
    unspentCoinsListViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) return Center(child: Text('Failed to load unspent coins'));

        return Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Observer(
                builder: (_) => Column(
                      children: [
                        if (unspentCoinsListViewModel.items.isNotEmpty)
                          Row(
                            children: [
                              SizedBox(width: 12),
                              StandardCheckbox(
                                  iconColor:
                                      Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor,
                                  value: unspentCoinsListViewModel.isAllSelected,
                                  onChanged: (value) =>
                                      unspentCoinsListViewModel.toggleSelectAll(value)),
                              SizedBox(width: 12),
                              Text('Select All',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                            ],
                          ),
                        SizedBox(height: 15),
                        Expanded(
                          child: unspentCoinsListViewModel.items.isEmpty
                              ? Center(child: Text('No unspent coins available'))
                              : ListView.separated(
                                  itemCount: unspentCoinsListViewModel.items.length,
                                  separatorBuilder: (_, __) => SizedBox(height: 15),
                                  itemBuilder: (_, int index) {
                                    final item = unspentCoinsListViewModel.items[index];
                                    return Observer(
                                      builder: (_) => GestureDetector(
                                        onTap: () => Navigator.of(context).pushNamed(
                                          Routes.unspentCoinsDetails,
                                          arguments: [item, unspentCoinsListViewModel],
                                        ),
                                        child: UnspentCoinsListItem(
                                          note: item.note,
                                          amount: item.amount,
                                          address: item.address,
                                          isSending: item.isSending,
                                          isFrozen: item.isFrozen,
                                          isChange: item.isChange,
                                          isSilentPayment: item.isSilentPayment,
                                          onCheckBoxTap: item.isFrozen
                                              ? null
                                              : () async {
                                                  item.isSending = !item.isSending;
                                                  await unspentCoinsListViewModel
                                                      .saveUnspentCoinInfo(item);
                                                },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    )));
      },
    );
  }
}
