import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/stores/wallet_restoration/wallet_restoration_store.dart';
import 'package:cake_wallet/src/widgets/seed_widget.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';

class RestoreWalletFromSeedPage extends BasePage {
  RestoreWalletFromSeedPage(
      {@required this.walletsService,
      @required this.walletService,
      @required this.sharedPreferences});

  final WalletListService walletsService;
  final WalletService walletService;
  final SharedPreferences sharedPreferences;
  final formKey = GlobalKey<_RestoreFromSeedFormState>();

  @override
  String get title => S.current.restore_title_from_seed;

  @override
  Widget trailing(BuildContext context) => SizedBox(
      width: 80,
      height: 20,
      child: FlatButton(
          child: Text(S.of(context).clear),
          padding: EdgeInsets.all(0),
          onPressed: () => formKey?.currentState?.clear()));

  @override
  Widget body(BuildContext context) => RestoreFromSeedForm(key: formKey);
}

class RestoreFromSeedForm extends StatefulWidget {
  RestoreFromSeedForm({Key key}) : super(key: key);

  @override
  _RestoreFromSeedFormState createState() => _RestoreFromSeedFormState();
}

class _RestoreFromSeedFormState extends State<RestoreFromSeedForm> {
  final _seedKey = GlobalKey<SeedWidgetState>();
  void clear() => _seedKey.currentState.clear();

  @override
  Widget build(BuildContext context) {
    final walletRestorationStore = Provider.of<WalletRestorationStore>(context);
    final seedLanguageStore = Provider.of<SeedLanguageStore>(context);

    return GestureDetector(
      onTap: () =>
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
      child: Container(
        padding: EdgeInsets.only(left: 20.0, right: 20.0),
        child: SeedWidget(
          key: _seedKey,
          onMnemoticChange: (seed) => walletRestorationStore.setSeed(seed),
          onFinish: () => Navigator.of(context).pushNamed(
              Routes.restoreWalletFromSeedDetails,
              arguments: _seedKey.currentState.items),
          seedLanguage: seedLanguageStore.selectedSeedLanguage,
        ),
      ),
    );
  }
}
