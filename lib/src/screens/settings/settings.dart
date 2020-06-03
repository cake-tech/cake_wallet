import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_display_mode.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/attributes.dart';
import 'package:cake_wallet/src/screens/disclaimer/disclaimer_page.dart';
import 'package:cake_wallet/src/screens/settings/items/settings_item.dart';
import 'package:cake_wallet/src/screens/settings/items/item_headers.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
// Settings widgets
import 'package:cake_wallet/src/screens/settings/widgets/settings_arrow_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_header_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_link_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switch_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_text_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_raw_widget_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/fiat_currency_picker.dart';

class SettingsPage extends BasePage {
  @override
  String get title => S.current.settings_title;

  @override
  Widget body(BuildContext context) {
    return SettingsForm();
  }
}

class SettingsForm extends StatefulWidget {
  @override
  SettingsFormState createState() => SettingsFormState();
}

class SettingsFormState extends State<SettingsForm> {
  final _telegramImage = Image.asset('assets/images/Telegram.png');
  final _twitterImage = Image.asset('assets/images/Twitter.png');
  final _changeNowImage = Image.asset('assets/images/change_now.png');
  final _xmrBtcImage = Image.asset('assets/images/xmr_btc.png');
  final _morphImage = Image.asset('assets/images/morph_icon.png');

  final _emailUrl = 'mailto:support@cakewallet.com';
  final _telegramUrl = 'https:t.me/cakewallet_bot';
  final _twitterUrl = 'https:twitter.com/CakewalletXMR';
  final _changeNowUrl = 'mailto:support@changenow.io';
  final _xmrToUrl = 'mailto:support@xmr.to';
  final _morphUrl = 'mailto:support@morphtoken.com';

  final _items = List<SettingsItem>();

  void _launchUrl(String url) async {
    if (await canLaunch(url)) await launch(url);
  }

  void _setSettingsList() {
    final settingsStore = Provider.of<SettingsStore>(context);

    settingsStore.setItemHeaders();

    _items.addAll([
      SettingsItem(
          onTaped: () => _setBalance(context),
          title: ItemHeaders.displayBalanceAs,
          widget: Observer(
              builder: (_) => Text(
                    settingsStore.balanceDisplayMode.toString(),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 14.0,
                        color: Theme.of(context).primaryTextTheme.caption.color),
                  )),
          attribute: Attributes.widget),
      SettingsItem(
          onTaped: () => _setCurrency(context),
          title: ItemHeaders.currency,
          widget: Observer(
              builder: (_) => Text(
                    settingsStore.fiatCurrency.toString(),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 14.0,
                        color: Theme.of(context).primaryTextTheme.caption.color),
                  )),
          attribute: Attributes.widget),
      SettingsItem(
          onTaped: () => _setTransactionPriority(context),
          title: ItemHeaders.feePriority,
          widget: Observer(
              builder: (_) => Text(
                    settingsStore.transactionPriority.toString(),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 14.0,
                        color: Theme.of(context).primaryTextTheme.caption.color),
                  )),
          attribute: Attributes.widget),
      SettingsItem(
          title: ItemHeaders.saveRecipientAddress,
          attribute: Attributes.switcher),
      SettingsItem(title: '', attribute: Attributes.header),
      SettingsItem(
          onTaped: () {
            Navigator.of(context).pushNamed(Routes.auth,
                arguments: (bool isAuthenticatedSuccessfully,
                        AuthPageState auth) =>
                    isAuthenticatedSuccessfully
                        ? Navigator.of(context).popAndPushNamed(Routes.setupPin,
                            arguments:
                                (BuildContext setupPinContext, String _) =>
                                    Navigator.of(context).pop())
                        : null);
          },
          title: ItemHeaders.changePIN,
          attribute: Attributes.arrow),
      SettingsItem(
          onTaped: () => Navigator.pushNamed(context, Routes.changeLanguage),
          title: ItemHeaders.changeLanguage,
          attribute: Attributes.arrow),
      SettingsItem(
          title: ItemHeaders.allowBiometricalAuthentication,
          attribute: Attributes.switcher),
      SettingsItem(title: ItemHeaders.darkMode, attribute: Attributes.switcher),
      SettingsItem(
          widgetBuilder: (context) {
            return PopupMenuButton<ActionListDisplayMode>(
                itemBuilder: (context) => [
                      PopupMenuItem(
                          value: ActionListDisplayMode.transactions,
                          child: Observer(
                              builder: (_) => Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(S
                                            .of(context)
                                            .settings_transactions,
                                          style: TextStyle(
                                              color: Theme.of(context).primaryTextTheme.title.color
                                          ),
                                        ),
                                        Checkbox(
                                          value: settingsStore
                                              .actionlistDisplayMode
                                              .contains(ActionListDisplayMode
                                                  .transactions),
                                          onChanged: (value) => settingsStore
                                              .toggleTransactionsDisplay(),
                                        )
                                      ]))),
                      PopupMenuItem(
                          value: ActionListDisplayMode.trades,
                          child: Observer(
                              builder: (_) => Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            S.of(context).settings_trades,
                                          style: TextStyle(
                                            color: Theme.of(context).primaryTextTheme.title.color
                                          ),
                                        ),
                                        Checkbox(
                                          value: settingsStore
                                              .actionlistDisplayMode
                                              .contains(
                                                  ActionListDisplayMode.trades),
                                          onChanged: (value) => settingsStore
                                              .toggleTradesDisplay(),
                                        )
                                      ])))
                    ],
                child: Container(
                  height: 56,
                  padding: EdgeInsets.only(left: 24, right: 24),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(S.of(context).settings_display_on_dashboard_list,
                            style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).primaryTextTheme.title.color)),
                        Observer(builder: (_) {
                          var title = '';

                          if (settingsStore.actionlistDisplayMode.length ==
                              ActionListDisplayMode.values.length) {
                            title = S.of(context).settings_all;
                          }

                          if (title.isEmpty &&
                              settingsStore.actionlistDisplayMode
                                  .contains(ActionListDisplayMode.trades)) {
                            title = S.of(context).settings_only_trades;
                          }

                          if (title.isEmpty &&
                              settingsStore.actionlistDisplayMode.contains(
                                  ActionListDisplayMode.transactions)) {
                            title = S.of(context).settings_only_transactions;
                          }

                          if (title.isEmpty) {
                            title = S.of(context).settings_none;
                          }

                          return Text(title,
                              style: TextStyle(
                                  fontSize: 14.0,
                                  color: Theme.of(context).primaryTextTheme.caption.color));
                        })
                      ]),
                ));
          },
          attribute: Attributes.rawWidget),
      SettingsItem(title: '', attribute: Attributes.header),
      SettingsItem(
          onTaped: () => _launchUrl(_emailUrl),
          title: 'Email',
          link: 'support@cakewallet.com',
          image: null,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () => _launchUrl(_telegramUrl),
          title: 'Telegram',
          link: 'Cake_Wallet',
          image: _telegramImage,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () => _launchUrl(_twitterUrl),
          title: 'Twitter',
          link: '@CakeWalletXMR',
          image: _twitterImage,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () => _launchUrl(_changeNowUrl),
          title: 'ChangeNow',
          link: 'support@changenow.io',
          image: _changeNowImage,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () => _launchUrl(_morphUrl),
          title: 'Morph',
          link: 'support@morphtoken.com',
          image: _morphImage,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () => _launchUrl(_xmrToUrl),
          title: 'XMR.to',
          link: 'support@xmr.to',
          image: _xmrBtcImage,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () {
            Navigator.push(
                context,
                CupertinoPageRoute<void>(
                    builder: (BuildContext context) => DisclaimerPage()));
          },
          title: ItemHeaders.termsAndConditions,
          attribute: Attributes.arrow),
      SettingsItem(
          onTaped: () => Navigator.pushNamed(context, Routes.faq),
          title: ItemHeaders.faq,
          attribute: Attributes.arrow)
    ]);
    setState(() {});
  }

  void _afterLayout(dynamic _) => _setSettingsList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
  }

  Widget _getWidget(SettingsItem item) {
    switch (item.attribute) {
      case Attributes.arrow:
        return SettingsArrowListRow(
          onTaped: item.onTaped,
          title: item.title,
        );
      case Attributes.header:
        return SettingsHeaderListRow(
          title: item.title,
        );
      case Attributes.link:
        return SettingsLinktListRow(
          onTaped: item.onTaped,
          title: item.title,
          link: item.link,
          image: item.image,
        );
      case Attributes.switcher:
        return SettingsSwitchListRow(
          title: item.title,
        );
      case Attributes.widget:
        return SettingsTextListRow(
          onTaped: item.onTaped,
          title: item.title,
          widget: item.widget,
        );
      case Attributes.rawWidget:
        return SettingRawWidgetListRow(widgetBuilder: item.widgetBuilder);
      default:
        return Offstage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);
    settingsStore.setItemHeaders();

    final shortDivider = Container(
      height: 1,
      padding: EdgeInsets.only(left: 24),
      color: Theme.of(context).accentTextTheme.title.backgroundColor,
      child: Container(
        height: 1,
        color: Theme.of(context).dividerColor,
      ),
    );

    final longDivider = Container(
      height: 1,
      color: Theme.of(context).dividerColor,
    );

    return Container(
      padding: EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              longDivider,
              ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];

                    Widget divider;

                    if (item.attribute == Attributes.header || item == _items.last) {
                      divider = longDivider;
                    } else if (_items[index + 1].attribute == Attributes.header){
                      divider = longDivider;
                    } else {
                      divider = shortDivider;
                    }

                    return Column(
                      children: <Widget>[
                        _getWidget(item),
                        divider
                      ],
                    );
                  }),
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: ListTile(
                  title: Center(
                    child: Text(
                        settingsStore.itemHeaders[ItemHeaders.version],
                        style: TextStyle(
                            fontSize: 14.0,
                            color: Theme.of(context).primaryTextTheme.caption.color)
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }

  Future<void> _setBalance(BuildContext context) async {
    final settingsStore = Provider.of<SettingsStore>(context);
    final items = BalanceDisplayMode.all;
    final selectedItem = items.indexOf(settingsStore.balanceDisplayMode);

    await showDialog<void>(
        builder: (_) => Picker(
            items: items,
            selectedAtIndex: selectedItem,
            title: S.of(context).please_select,
            mainAxisAlignment: MainAxisAlignment.center,
            onItemSelected: (BalanceDisplayMode mode) async =>
            await settingsStore.setCurrentBalanceDisplayMode(
            balanceDisplayMode: mode)),
        context: context);
  }

  Future<void> _setCurrency(BuildContext context) async {
    final settingsStore = Provider.of<SettingsStore>(context);
    final items = FiatCurrency.all;
    final selectedItem = items.indexOf(settingsStore.fiatCurrency);

    await showDialog<void>(
        builder: (_) => FiatCurrencyPicker(
          selectedAtIndex: selectedItem,
          items: items,
          title: S.of(context).please_select,
          onItemSelected: (currency) async =>
          await settingsStore.setCurrentFiatCurrency(currency: currency)
        ),
        context: context);
  }

  Future<void> _setTransactionPriority(BuildContext context) async {
    final settingsStore = Provider.of<SettingsStore>(context);
    final items = TransactionPriority.all;
    final selectedItem = items.indexOf(settingsStore.transactionPriority);

    await showDialog<void>(
        builder: (_) => Picker(
            items: items,
            selectedAtIndex: selectedItem,
            title: S.of(context).please_select,
            mainAxisAlignment: MainAxisAlignment.center,
            onItemSelected: (TransactionPriority priority) async =>
            await settingsStore.setCurrentTransactionPriority(
                priority: priority)),
        context: context);
  }
}
