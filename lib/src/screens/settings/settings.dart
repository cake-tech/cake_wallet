import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/palette.dart';
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
// Settings widgets
import 'package:cake_wallet/src/screens/settings/widgets/settings_arrow_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_header_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_link_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switch_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_text_list_row.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_raw_widget_list_row.dart';

class SettingsPage extends BasePage {
  @override
  String get title => S.current.settings_title;

  @override
  bool get isModalBackButton => true;

  @override
  Color get backgroundColor => Palette.lightGrey2;

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
      SettingsItem(title: ItemHeaders.nodes, attribute: Attributes.header),
      SettingsItem(
          onTaped: () => Navigator.of(context).pushNamed(Routes.nodeList),
          title: ItemHeaders.currentNode,
          widget: Observer(
              builder: (_) => Text(
                    settingsStore.node == null ? '' : settingsStore.node.uri,
                    style: TextStyle(
                        fontSize: 16.0,
                        color:
                            Theme.of(context).primaryTextTheme.subtitle.color),
                  )),
          attribute: Attributes.widget),
      SettingsItem(title: ItemHeaders.wallets, attribute: Attributes.header),
      SettingsItem(
          onTaped: () => _setBalance(context),
          title: ItemHeaders.displayBalanceAs,
          widget: Observer(
              builder: (_) => Text(
                    settingsStore.balanceDisplayMode.toString(),
                    style: TextStyle(
                        fontSize: 16.0,
                        color:
                            Theme.of(context).primaryTextTheme.subtitle.color),
                  )),
          attribute: Attributes.widget),
      SettingsItem(
          onTaped: () => _setCurrency(context),
          title: ItemHeaders.currency,
          widget: Observer(
              builder: (_) => Text(
                    settingsStore.fiatCurrency.toString(),
                    style: TextStyle(
                        fontSize: 16.0,
                        color:
                            Theme.of(context).primaryTextTheme.subtitle.color),
                  )),
          attribute: Attributes.widget),
      SettingsItem(
          onTaped: () => _setTransactionPriority(context),
          title: ItemHeaders.feePriority,
          widget: Observer(
              builder: (_) => Text(
                    settingsStore.transactionPriority.toString(),
                    style: TextStyle(
                        fontSize: 16.0,
                        color:
                            Theme.of(context).primaryTextTheme.subtitle.color),
                  )),
          attribute: Attributes.widget),
      SettingsItem(
          title: ItemHeaders.saveRecipientAddress,
          attribute: Attributes.switcher),
      SettingsItem(title: ItemHeaders.personal, attribute: Attributes.header),
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
                                            .settings_transactions),
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
                                        Text(S.of(context).settings_trades),
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
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(S.of(context).settings_display_on_dashboard_list,
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .color)),
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
                                  fontSize: 16.0,
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .subtitle
                                      .color));
                        })
                      ]),
                ));
          },
          attribute: Attributes.rawWidget),
      SettingsItem(title: ItemHeaders.support, attribute: Attributes.header),
      SettingsItem(
          onTaped: () => _launchUrl(_emailUrl),
          title: 'Email',
          link: 'support@cakewallet.com',
          image: null,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () => _launchUrl(_telegramUrl),
          title: 'Telegram',
          link: 't.me/cakewallet_bot',
          image: _telegramImage,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () => _launchUrl(_twitterUrl),
          title: 'Twitter',
          link: 'twitter.com/CakewalletXMR',
          image: _twitterImage,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () => _launchUrl(_changeNowUrl),
          title: 'ChangeNow',
          link: 'support@changenow.io',
          image: _changeNowImage,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () => _launchUrl(_xmrToUrl),
          title: 'XMR.to',
          link: 'support@xmr.to',
          image: _xmrBtcImage,
          attribute: Attributes.link),
      SettingsItem(
          onTaped: () => _launchUrl(_morphUrl),
          title: 'MorphToken',
          link: 'support@morphtoken.com',
          image: _morphImage,
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

    return SingleChildScrollView(
        child: Column(
      children: <Widget>[
        ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              bool _isDrawDivider = true;

              if (item.attribute == Attributes.header || item == _items.last) {
                _isDrawDivider = false;
              } else {
                if (_items[index + 1].attribute == Attributes.header) {
                  _isDrawDivider = false;
                }
              }

              return Column(
                children: <Widget>[
                  _getWidget(item),
                  _isDrawDivider
                      ? Container(
                          color: Theme.of(context)
                              .accentTextTheme
                              .headline
                              .backgroundColor,
                          padding: EdgeInsets.only(
                            left: 20.0,
                            right: 20.0,
                          ),
                          child: Divider(
                            color: Theme.of(context).dividerColor,
                            height: 1.0,
                          ),
                        )
                      : Offstage()
                ],
              );
            }),
        ListTile(
          contentPadding: EdgeInsets.only(left: 20.0),
          title: Text(
            settingsStore.itemHeaders[ItemHeaders.version],
            style: TextStyle(
              fontSize: 14.0, color: Palette.wildDarkBlue)
          ),
        )
      ],
    ));
  }

  Future<T> _presentPicker<T extends Object>(
      BuildContext context, List<T> list) async {
    T _value = list[0];

    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(S.of(context).please_select),
            backgroundColor: Theme.of(context).backgroundColor,
            content: Container(
              height: 150.0,
              child: CupertinoPicker(
                  backgroundColor: Theme.of(context).backgroundColor,
                  itemExtent: 45.0,
                  onSelectedItemChanged: (int index) => _value = list[index],
                  children: List.generate(
                      list.length,
                      (index) => Center(
                            child: Text(
                              list[index].toString(),
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .color),
                            ),
                          ))),
            ),
            actions: <Widget>[
              FlatButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(S.of(context).cancel)),
              FlatButton(
                  onPressed: () => Navigator.of(context).pop(_value),
                  child: Text(S.of(context).ok))
            ],
          );
        });
  }

  Future<void> _setBalance(BuildContext context) async {
    final settingsStore = Provider.of<SettingsStore>(context);
    final selectedDisplayMode =
        await _presentPicker(context, BalanceDisplayMode.all);

    if (selectedDisplayMode != null) {
      await settingsStore.setCurrentBalanceDisplayMode(
          balanceDisplayMode: selectedDisplayMode);
    }
  }

  Future<void> _setCurrency(BuildContext context) async {
    final settingsStore = Provider.of<SettingsStore>(context);
    final selectedCurrency = await _presentPicker(context, FiatCurrency.all);

    if (selectedCurrency != null) {
      await settingsStore.setCurrentFiatCurrency(currency: selectedCurrency);
    }
  }

  Future<void> _setTransactionPriority(BuildContext context) async {
    final settingsStore = Provider.of<SettingsStore>(context);
    final selectedPriority =
        await _presentPicker(context, TransactionPriority.all);

    if (selectedPriority != null) {
      await settingsStore.setCurrentTransactionPriority(
          priority: selectedPriority);
    }
  }
}
