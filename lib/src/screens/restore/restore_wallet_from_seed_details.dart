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
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';

class RestoreWalletFromSeedDetailsPage extends BasePage {
  @override
  String get title => S.current.restore_wallet_restore_description;

  @override
  Widget body(BuildContext context) => RestoreFromSeedDetailsForm();
}

class RestoreFromSeedDetailsForm extends StatefulWidget {
  @override
  _RestoreFromSeedDetailsFormState createState() =>
      _RestoreFromSeedDetailsFormState();
}

class _RestoreFromSeedDetailsFormState
    extends State<RestoreFromSeedDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _blockchainHeightKey = GlobalKey<BlockchainHeightState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletRestorationStore = Provider.of<WalletRestorationStore>(context);

    _nameController.addListener(() {
      if (_nameController.text.isNotEmpty) {
        walletRestorationStore.setDisabledState(false);
      } else {
        walletRestorationStore.setDisabledState(true);
      }
    });

    reaction((_) => walletRestorationStore.state, (WalletRestorationState state) {
      if (state is WalletRestoredSuccessfully) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      if (state is WalletRestorationFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.current.restore_title_from_seed,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop()
                );
              });
        });
      }
    });

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(bottom: 24.0),
        content: Form(
          key: _formKey,
          child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                        child: Container(
                          padding: EdgeInsets.only(top: 20.0),
                          child: TextFormField(
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Theme.of(context).primaryTextTheme.title.color
                            ),
                            controller: _nameController,
                            decoration: InputDecoration(
                                hintStyle: TextStyle(
                                    color: Theme.of(context).primaryTextTheme.caption.color,
                                    fontSize: 16
                                ),
                                hintText: S.of(context).restore_wallet_name,
                                focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                        width: 1.0)),
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context).dividerColor,
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
              ]),
        ),
        bottomSectionPadding: EdgeInsets.only(bottom: 24),
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
            color: Colors.green,
            textColor: Colors.white,
            isDisabled: walletRestorationStore.disabledState,
          );
        }),
      ),
    );
  }
}
