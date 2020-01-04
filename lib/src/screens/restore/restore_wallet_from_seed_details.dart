import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/wallet_restoration/wallet_restoration_store.dart';
import 'package:cake_wallet/src/stores/wallet_restoration/wallet_restoration_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/palette.dart';

class RestoreWalletFromSeedDetailsPage extends BasePage {
  String get title => S.current.restore_wallet_restore_description;

  @override
  Widget body(BuildContext context) => RestoreFromSeedDetailsForm();
}

class RestoreFromSeedDetailsForm extends StatefulWidget {
  @override
  createState() => _RestoreFromSeedDetailsFormState();
}

class _RestoreFromSeedDetailsFormState
    extends State<RestoreFromSeedDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _blockchainHeightKey = GlobalKey<BlockchainHeightState>();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final walletRestorationStore = Provider.of<WalletRestorationStore>(context);

    reaction((_) => walletRestorationStore.state, (state) {
      if (state is WalletRestoredSuccessfully) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      if (state is WalletRestorationFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: Text(state.error),
                  actions: <Widget>[
                    FlatButton(
                      child: Text(S.of(context).ok),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              });
        });
      }
    });

    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(left: 13, right: 13),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                              child: Container(
                            padding: EdgeInsets.only(top: 20.0),
                            child: TextFormField(
                              style: TextStyle(fontSize: 14.0),
                              controller: _nameController,
                              decoration: InputDecoration(
                                  hintStyle: TextStyle(
                                      color: Theme.of(context).hintColor),
                                  hintText: S.of(context).restore_wallet_name,
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Palette.cakeGreen,
                                          width: 2.0)),
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context).focusColor,
                                          width: 1.0))),
                              validator: (value) {
                                walletRestorationStore
                                    .validateWalletName(value);
                                return walletRestorationStore.errorMessage;
                              },
                            ),
                          ))
                        ],
                      ),
                      BlockchainHeightWidget(key: _blockchainHeightKey),
                    ]))
          ],
        ),
      ),
      bottomSection: Observer(builder: (_) {
        return LoadingPrimaryButton(
            onPressed: () {
              if (_formKey.currentState.validate()) {
                walletRestorationStore.restoreFromSeed(
                    name: _nameController.text,
                    restoreHeight: _blockchainHeightKey.currentState.height);
              }
            },
            isLoading: walletRestorationStore.state is WalletIsRestoring,
            text: S.of(context).restore_recover,
            color: Theme.of(context).primaryTextTheme.button.backgroundColor,
            borderColor:
                Theme.of(context).primaryTextTheme.button.decorationColor);
      }),
    );
  }
}
