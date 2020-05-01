import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/stores/wallet_restoration/wallet_restoration_store.dart';
import 'package:cake_wallet/src/stores/wallet_restoration/wallet_restoration_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';
import 'package:cake_wallet/src/screens/restore/widgets/restore_alert_dialog.dart';

class RestoreWalletFromKeysPage extends BasePage {
  RestoreWalletFromKeysPage(
      {@required this.walletsService,
      @required this.sharedPreferences,
      @required this.walletService});

  final WalletListService walletsService;
  final WalletService walletService;
  final SharedPreferences sharedPreferences;

  @override
  String get title => S.current.restore_title_from_keys;

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  Widget body(BuildContext context) => RestoreFromKeysFrom();
}

class RestoreFromKeysFrom extends StatefulWidget {
  @override
  _RestoreFromKeysFromState createState() => _RestoreFromKeysFromState();
}

class _RestoreFromKeysFromState extends State<RestoreFromKeysFrom> {
  final _formKey = GlobalKey<FormState>();
  final _blockchainHeightKey = GlobalKey<BlockchainHeightState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _viewKeyController = TextEditingController();
  final _spendKeyController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _viewKeyController.dispose();
    _spendKeyController.dispose();
    super.dispose();
  }

  void onHandleControllers(WalletRestorationStore walletRestorationStore) {
    if (_nameController.text.isNotEmpty &&
    _addressController.text.isNotEmpty &&
    _viewKeyController.text.isNotEmpty &&
    _spendKeyController.text.isNotEmpty) {
      walletRestorationStore.setDisabledState(false);
    } else {
      walletRestorationStore.setDisabledState(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletRestorationStore = Provider.of<WalletRestorationStore>(context);
    final seedLanguageStore = Provider.of<SeedLanguageStore>(context);

    _nameController.addListener(() {onHandleControllers(walletRestorationStore);});
    _addressController.addListener(() {onHandleControllers(walletRestorationStore);});
    _viewKeyController.addListener(() {onHandleControllers(walletRestorationStore);});
    _spendKeyController.addListener(() {onHandleControllers(walletRestorationStore);});

    reaction((_) => walletRestorationStore.state, (WalletRestorationState state) {
      if (state is WalletRestoredSuccessfully) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      if (state is WalletRestorationFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return RestoreAlertDialog(
                  restoreTitle: S.current.restore_title_from_keys,
                  restoreContent: state.error,
                  restoreButtonText: S.of(context).ok,
                  restoreButtonAction: () => Navigator.of(context).pop(),
                );
              });
        });
      }
    });

    return Container(
      color: PaletteDark.historyPanel,
      padding: EdgeInsets.only(left: 24, right: 24),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(bottom: 24.0),
        content: Form(
          key: _formKey,
          child: Column(children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                    child: Container(
                      padding: EdgeInsets.only(top: 20.0),
                      child: TextFormField(
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white
                        ),
                        controller: _nameController,
                        decoration: InputDecoration(
                            hintStyle: TextStyle(
                                color: PaletteDark.walletCardText,
                                fontSize: 16
                            ),
                            hintText: S.of(context).restore_wallet_name,
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: PaletteDark.menuList,
                                    width: 1.0)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: PaletteDark.menuList,
                                    width: 1.0))),
                        validator: (value) {
                          walletRestorationStore.validateWalletName(value);
                          return walletRestorationStore.errorMessage;
                        },
                      ),
                    ))
              ],
            ),
            Row(
              children: <Widget>[
                Flexible(
                    child: Container(
                      padding: EdgeInsets.only(top: 20.0),
                      child: TextFormField(
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white
                        ),
                        controller: _addressController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: InputDecoration(
                            hintStyle: TextStyle(
                                color: PaletteDark.walletCardText,
                                fontSize: 16
                            ),
                            hintText: S.of(context).restore_address,
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: PaletteDark.menuList,
                                    width: 1.0)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: PaletteDark.menuList,
                                    width: 1.0))),
                        validator: (value) {
                          walletRestorationStore.validateAddress(value);
                          return walletRestorationStore.errorMessage;
                        },
                      ),
                    ))
              ],
            ),
            Row(
              children: <Widget>[
                Flexible(
                    child: Container(
                      padding: EdgeInsets.only(top: 20.0),
                      child: TextFormField(
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white
                        ),
                        controller: _viewKeyController,
                        decoration: InputDecoration(
                            hintStyle: TextStyle(
                                color: PaletteDark.walletCardText,
                                fontSize: 16
                            ),
                            hintText: S.of(context).restore_view_key_private,
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: PaletteDark.menuList,
                                    width: 1.0)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: PaletteDark.menuList,
                                    width: 1.0))),
                        validator: (value) {
                          walletRestorationStore.validateKeys(value);
                          return walletRestorationStore.errorMessage;
                        },
                      ),
                    ))
              ],
            ),
            Row(
              children: <Widget>[
                Flexible(
                    child: Container(
                      padding: EdgeInsets.only(top: 20.0),
                      child: TextFormField(
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white
                        ),
                        controller: _spendKeyController,
                        decoration: InputDecoration(
                            hintStyle: TextStyle(
                                color: PaletteDark.walletCardText,
                                fontSize: 16
                            ),
                            hintText: S.of(context).restore_spend_key_private,
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: PaletteDark.menuList,
                                    width: 1.0)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: PaletteDark.menuList,
                                    width: 1.0))),
                        validator: (value) {
                          walletRestorationStore.validateKeys(value);
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
                walletRestorationStore.restoreFromKeys(
                    name: _nameController.text,
                    language: seedLanguageStore.selectedSeedLanguage,
                    address: _addressController.text,
                    viewKey: _viewKeyController.text,
                    spendKey: _spendKeyController.text,
                    restoreHeight: _blockchainHeightKey.currentState.height);
              }
            },
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
