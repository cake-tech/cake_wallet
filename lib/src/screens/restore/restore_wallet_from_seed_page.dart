import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/stores/wallet_restoration/wallet_restoration_store.dart';
import 'package:cake_wallet/src/widgets/seed_widget.dart';

class RestoreWalletFromSeedPage extends BasePage {
  final WalletListService walletsService;
  final WalletService walletService;
  final SharedPreferences sharedPreferences;

  String get title => S.current.restore_title_from_seed;

  RestoreWalletFromSeedPage(
      {@required this.walletsService,
      @required this.walletService,
      @required this.sharedPreferences});

  @override
  Widget body(BuildContext context) => RestoreFromSeedForm();
}

class RestoreFromSeedForm extends StatefulWidget {
  @override
  createState() => _RestoreFromSeedFormState();
}

class _RestoreFromSeedFormState extends State<RestoreFromSeedForm> {
  final _seedKey = GlobalKey<SeedWidgetState>();
  bool _reactionSet = false;

  @override
  Widget build(BuildContext context) {
    final walletRestorationStore = Provider.of<WalletRestorationStore>(context);

    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _setReactions(context, walletRestorationStore));

    return GestureDetector(
      onTap: () {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
      child: Container(
        padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
        child: Column(
          children: <Widget>[
            Expanded(
                child: SeedWidget(
              key: _seedKey,
              onMnemoticChange: (seed) => walletRestorationStore.setSeed(seed),
            )),
            Container(
                alignment: Alignment.bottomCenter,
                child: PrimaryButton(
                    onPressed: () {
                      if (!walletRestorationStore.isValid) {
                        return;
                      }

                      Navigator.of(context).pushNamed(
                          Routes.restoreWalletFromSeedDetails,
                          arguments: _seedKey.currentState.items);
                    },
                    text: S.of(context).restore_next,
                    color: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .backgroundColor,
                    borderColor: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .decorationColor))
          ],
        ),
      ),
    );
  }

  void _setReactions(BuildContext context, WalletRestorationStore store) {
    if (_reactionSet) {
      return;
    }

    reaction((_) => store.errorMessage, (errorMessage) {
      if (errorMessage == null || errorMessage.isEmpty) {
        _seedKey.currentState.validated();
      } else {
        _seedKey.currentState.invalidate();
      }

      _seedKey.currentState.setErrorMessage(errorMessage);
    });

    _reactionSet = true;
  }
}
