import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/widgets/unspent_coins_list_item.dart';
import 'package:cake_wallet/src/widgets/alert_with_no_action.dart.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class UnspentCoinsListPage extends BasePage {
  UnspentCoinsListPage({required this.unspentCoinsListViewModel});

  @override
  String get title => S.current.unspent_coins_title;

  @override
  Widget leading(BuildContext context) {
    return MergeSemantics(
      child: SizedBox(
        height: 37,
        width: 37,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: Semantics(
            label: S.of(context).seed_alert_back,
            child: TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateColor.resolveWith((states) => Colors.transparent),
              ),
              onPressed: () async => await handleOnPopInvoked(context),
              child: backButton(context),
            ),
          ),
        ),
      ),
    );
  }

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  Future<void> handleOnPopInvoked(BuildContext context) async {
    final hasChanged = unspentCoinsListViewModel.hasAdjustableFieldChanged;
    if (unspentCoinsListViewModel.items.isEmpty || !hasChanged) {
      Navigator.of(context).pop();
    } else {
      unspentCoinsListViewModel.setIsDisposing(true);
      await unspentCoinsListViewModel.dispose();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget body(BuildContext context) =>
      UnspentCoinsListForm(unspentCoinsListViewModel, handleOnPopInvoked);
}

class UnspentCoinsListForm extends StatefulWidget {
  UnspentCoinsListForm(this.unspentCoinsListViewModel, this.handleOnPopInvoked);

  final UnspentCoinsListViewModel unspentCoinsListViewModel;
  final Future<void> Function(BuildContext context) handleOnPopInvoked;

  @override
  UnspentCoinsListFormState createState() => UnspentCoinsListFormState(unspentCoinsListViewModel);
}

class UnspentCoinsListFormState extends State<UnspentCoinsListForm> {
  UnspentCoinsListFormState(this.unspentCoinsListViewModel);

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  late Future<void> _initialization;
  ReactionDisposer? _disposer;

  @override
  void initState() {
    super.initState();
    _initialization = unspentCoinsListViewModel.initialSetup();
    _setupReactions();
  }

  void _setupReactions() {
    _disposer = reaction<bool>(
      (_) => unspentCoinsListViewModel.isDisposing,
      (isDisposing) {
        if (isDisposing) {
          _showSavingDataAlert();
        }
      },
    );
  }

  void _showSavingDataAlert() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithNoAction(
          alertContent: 'Updating, please wait…',
          alertBarrierDismissible: false,
        );
      },
    );
  }

  @override
  void dispose() {
    _disposer?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if(mounted)
        await widget.handleOnPopInvoked(context);
      },
      child: FutureBuilder<void>(
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
                          iconColor: Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor,
                          value: unspentCoinsListViewModel.isAllSelected,
                          onChanged: (value) => unspentCoinsListViewModel.toggleSelectAll(value),
                        ),
                        SizedBox(width: 12),
                        Text(
                          S.current.all_coins,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  SizedBox(height: 15),
                  Expanded(
                    child: unspentCoinsListViewModel.items.isEmpty
                        ? Center(child: Text('No unspent coins available\ntry to reconnect',textAlign: TextAlign.center))
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
              ),
            ),
          );
        },
      ),
    );
  }
}
