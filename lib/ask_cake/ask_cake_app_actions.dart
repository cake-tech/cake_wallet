import 'package:cake_wallet/ask_cake/ask_cake_app.dart';
import 'package:cake_wallet/ask_cake/ask_cake_guards.dart';
import 'package:cake_wallet/ask_cake/ask_cake_tools.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/language_service.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/new-ui/model/charts/price_store.dart';
import 'package:cake_wallet/new-ui/model/charts/util/chart_range.dart';
import 'package:cake_wallet/new-ui/pages/coin_control_page.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/settings/display_settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/mweb_settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/privacy_settings_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

/// Ask Cake's view of the running app. Reads are plain lookups; every change
/// goes through the same view-model setters the settings screens use, and only
/// after the user taps the confirm button the chat shows.
class AskCakeAppActions implements AskCakeApp {
  AskCakeAppActions(this._appStore, this._fiatConversionStore);

  final AppStore _appStore;
  final FiatConversionStore _fiatConversionStore;

  SettingsStore get _settings => _appStore.settingsStore;

  DashboardViewModel get _dashboard => getIt.get<DashboardViewModel>();

  static const _on = {'on', 'true', 'enable', 'enabled', 'yes', 'show', 'shown'};
  static const _off = {'off', 'false', 'disable', 'disabled', 'no', 'none', 'hide', 'hidden'};

  static bool? _switch(String value) {
    final v = value.trim().toLowerCase();
    if (_on.contains(v)) return true;
    if (_off.contains(v)) return false;
    return null;
  }

  @override
  String status() {
    final wallet = _appStore.wallet;
    if (wallet == null) return 'No wallet is open.';
    String node;
    try {
      node = _settings.getCurrentNode(wallet.type, chainId: wallet.chainId).uriRaw;
    } catch (_) {
      node = 'unknown';
    }
    return [
      'Wallet: ${wallet.name} (${wallet.currency.title})',
      'Sync: ${_sync(wallet.syncStatus)}',
      'Node: $node',
      'Tor: ${_settings.currentBuiltinTor ? 'on' : 'off'}',
      'Display currency: ${_settings.fiatCurrency.title}',
      'Language: ${LanguageService.list[_settings.languageCode] ?? _settings.languageCode}',
      'Balance hidden: ${_settings.balanceDisplayMode == BalanceDisplayMode.hiddenBalance ? 'yes' : 'no'}',
      'Price data: ${_settings.fiatApiMode.title}',
      'Swap providers: ${_settings.exchangeStatus.title}',
    ].join('\n');
  }

  static String _sync(SyncStatus status) {
    if (status is SyncedSyncStatus) return 'fully synced';
    if (status is SyncingSyncStatus) return 'syncing, ${(status.progress() * 100).toStringAsFixed(0)}% done';
    if (status is ConnectingSyncStatus || status is AttemptingSyncStatus || status is ConnectedSyncStatus) {
      return 'connecting';
    }
    if (status is NotConnectedSyncStatus || status is LostConnectionSyncStatus || status is FailedSyncStatus) {
      return 'not connected';
    }
    return 'in progress';
  }

  static String _done(String setting, String value) {
    final on = _switch(value);
    final name = AskCakeGuards.settingNames[setting] ?? setting;
    final title = '${name[0].toUpperCase()}${name.substring(1)}';
    if (setting == 'hide_balance') return on == false ? 'Done. Your balance is showing again.' : 'Done. Your balance is now hidden.';
    if (setting == 'fiat_currency') {
      return 'Done. Amounts now show in ${(_fiatNames[value.toLowerCase()] ?? value).toUpperCase()}.';
    }
    if (on != null) return 'Done. $title is now ${on ? 'on' : 'off'}.';
    return 'Done. $title is now set to $value.';
  }

  /// Friendlier wording than the generic "turn X on" for the two settings where that reads badly.
  static String _describe(String setting, String value) {
    if (setting == 'hide_balance') return _switch(value) == false ? 'show your balance' : 'hide your balance';
    if (setting == 'fiat_currency') return 'show amounts in ${(_fiatNames[value.toLowerCase()] ?? value).toUpperCase()}';
    return AskCakeGuards.describeSetting(setting, value);
  }

  static const _ranges = {
    '1d': (ChartRange.oneDay, 'the last 24 hours'),
    '7d': (ChartRange.sevenDays, 'the last 7 days'),
    '30d': (ChartRange.thirtyDays, 'the last 30 days'),
    '1y': (ChartRange.oneYear, 'the last year'),
    'all': (ChartRange.all, 'all available history'),
  };

  CryptoCurrency? _currency(String? ticker) {
    if (ticker == null || ticker.isEmpty) return _appStore.wallet?.currency;
    try {
      return CryptoCurrency.fromString(ticker.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> price(String? asset, String? range) async {
    final crypto = _currency(asset);
    if (crypto == null) return 'I don\'t have price data for ${asset ?? 'that coin'}.';
    if (_settings.fiatApiMode == FiatApiMode.disabled) {
      return 'Price data is turned off in Settings > Privacy, so I can\'t look up prices.';
    }
    final fiat = _settings.fiatCurrency;
    var current = _fiatConversionStore.prices[crypto] ?? 0;
    if (current == 0) {
      current = await FiatConversionService.fetchPrice(
          crypto: crypto, fiat: fiat, torOnly: _settings.fiatApiMode == FiatApiMode.torOnly);
    }
    final lines = <String>[
      current > 0
          ? '${crypto.title} price now: ${fiat.title} ${current.toStringAsFixed(2)}'
          : 'I could not fetch the current ${crypto.title} price.',
    ];
    final chosen = _ranges[range];
    if (chosen != null) {
      try {
        final points = await getIt.get<PriceStore>().getPrices(fiat, crypto, chosen.$1);
        final values = [for (final p in points) double.tryParse(p.quote.toString()) ?? 0].where((v) => v > 0).toList();
        if (values.length >= 2) {
          final first = values.first;
          final last = values.last;
          final change = (last - first) / first * 100;
          final low = values.reduce((a, b) => a < b ? a : b);
          final high = values.reduce((a, b) => a > b ? a : b);
          lines.add('Over ${chosen.$2}: ${change >= 0 ? 'up' : 'down'} ${change.abs().toStringAsFixed(1)}% '
              '(from ${fiat.title} ${first.toStringAsFixed(2)} to ${fiat.title} ${last.toStringAsFixed(2)}), '
              'low ${fiat.title} ${low.toStringAsFixed(2)}, high ${fiat.title} ${high.toStringAsFixed(2)}');
        } else {
          lines.add('No price history is available for ${chosen.$2}.');
        }
      } catch (_) {
        lines.add('Price history for ${chosen.$2} could not be loaded.');
      }
    }
    return lines.join('\n');
  }

  @override
  Future<String> lightningInfo() async {
    final wallet = _appStore.wallet;
    if (wallet == null || wallet.type != WalletType.bitcoin || !wallet.hasLightningSupport) {
      return 'Lightning is only available in a Bitcoin wallet; the open wallet is ${wallet?.currency.title ?? 'none'}.';
    }
    if (!bitcoin!.useLightning(wallet)) return 'Lightning is turned off for this wallet (Settings > Privacy).';
    final username = await bitcoin!.getLightningUsername(wallet);
    final balance = wallet.balance[CryptoCurrency.btcln];
    return [
      username == null || username.isEmpty
          ? 'No Lightning username is set yet.'
          : 'Lightning address: $username@cake.cash',
      if (balance != null) 'Lightning balance: ${balance.available} BTC',
    ].join('\n');
  }

  @override
  String tokens() {
    final wallet = _appStore.wallet;
    if (wallet == null) return 'No wallet is open.';
    final lines = <String>[];
    wallet.balance.forEach((currency, balance) {
      if (currency == wallet.currency || currency == CryptoCurrency.btcln) return;
      final price = _fiatConversionStore.prices[currency];
      final amount = double.tryParse('${balance.available}'.replaceAll(',', '')) ?? 0;
      lines.add('${currency.title}: ${balance.available}'
          '${price == null || price == 0 ? '' : ' (${_settings.fiatCurrency.title} ${(amount * price).toStringAsFixed(2)})'}');
    });
    if (lines.isEmpty) return 'This ${wallet.currency.title} wallet holds no tokens.';
    return 'Tokens in this wallet:\n${lines.join('\n')}';
  }

  @override
  Future<String> fees() async {
    final wallet = _appStore.wallet;
    if (wallet == null) return 'No wallet is open.';
    final current = _settings.getPriority(wallet.type, chainId: wallet.chainId);
    final lines = <String>['Default fee level for ${wallet.currency.title}: ${current?.toString() ?? 'set by the network'}'];
    if (wallet.type == WalletType.bitcoin || wallet.type == WalletType.litecoin) {
      try {
        await bitcoin!.updateFeeRates(wallet);
        for (final priority in priorityForWalletType(wallet.type)) {
          final rate = bitcoin!.getFeeRate(wallet, priority);
          if (rate > 0 && !'$priority'.toLowerCase().contains('custom')) lines.add('$priority: $rate sat/vB');
        }
      } catch (_) {
        lines.add('Current fee rates could not be loaded.');
      }
    }
    lines.add('The exact fee for a payment is shown on the Send screen before you confirm.');
    return lines.join('\n');
  }

  // --- settings ----------------------------------------------------------------

  /// Why a setting needs its own screen instead of a one-tap change, or null.
  String? _screenFor(String setting, String value) {
    final on = _switch(value);
    final v = value.toLowerCase();
    switch (setting) {
      case 'tor':
        return on == false ? Routes.connectionSync : null;
      case 'fiat_api':
      case 'swap_api':
        return v.contains('tor') || on == false ? null : Routes.connectionSync;
      case 'auto_generate_addresses':
        return on == false ? Routes.privacyPage : null;
      case 'prevent_screenshots':
        return on == false ? Routes.securityBackupPage : null;
      case 'address_lookups':
        return Routes.domainLookupsPage;
      case 'block_explorer_apis':
        return Routes.connectionSync;
      case 'background_sync':
        return Routes.backgroundSync;
    }
    return null;
  }

  @override
  AskCakeToolResult setting(String setting, String value) {
    final description = _describe(setting, value);
    if (setting == 'notifications') {
      return const AskCakeToolResult('Cake Wallet has no general notification setting to change.');
    }
    if (setting == 'background_sync' && !_dashboard.hasBackgroundSync) {
      return const AskCakeToolResult('Background sync is only available for Monero wallets on Android.');
    }
    final problem = _unavailable(setting);
    if (problem != null) return AskCakeToolResult(problem);
    final screen = _screenFor(setting, value);
    if (screen != null) {
      return AskCakeToolResult(
          'To $description, use the settings screen: that change lowers privacy or protection, so I only open it for you.',
          action: AskCakeOpenRouteAction(screen, 'Open that setting'));
    }
    if (_resolve(setting, value) == null) {
      return AskCakeToolResult('I can\'t set ${AskCakeGuards.settingNames[setting] ?? setting} to "$value".',
          action: const AskCakeOpenPageAction('settings', 'Open Settings'));
    }
    return AskCakeToolResult('Ready to $description. Nothing changes until you tap the button.',
        action: AskCakeApplySettingAction(
            setting: setting, value: value, label: '${description[0].toUpperCase()}${description.substring(1)}'));
  }

  String? _unavailable(String setting) {
    final wallet = _appStore.wallet;
    switch (setting) {
      case 'tor':
        return FeatureFlag.isInAppTorEnabled ? null : 'Built-in Tor is not available in this build.';
      case 'mweb':
        return _dashboard.hasMweb ? null : 'MWEB is only available in a Litecoin wallet.';
      case 'silent_payments_scanning':
        return _dashboard.hasSilentPayments ? null : 'Silent Payments scanning is only available in a Bitcoin wallet.';
      case 'payjoin':
        return wallet != null && wallet.hasPayjoinSupport ? null : 'PayJoin is only available in a Bitcoin wallet.';
      case 'lightning':
        return wallet != null && wallet.hasLightningSupport ? null : 'Lightning is only available in a Bitcoin wallet.';
      case 'bitcoin_unit':
        return wallet?.type == WalletType.bitcoin ? null : 'The sats/BTC unit only applies to a Bitcoin wallet.';
      case 'fee_priority':
        return wallet != null && priorityForWalletType(wallet.type).isNotEmpty
            ? null
            : 'This wallet has no adjustable fee level.';
    }
    return null;
  }

  static const _fiatNames = {
    'dollar': 'USD', 'dollars': 'USD', 'euro': 'EUR', 'euros': 'EUR', 'pound': 'GBP', 'pounds': 'GBP', //
    'sterling': 'GBP', 'yen': 'JPY', 'yuan': 'CNY', 'rupee': 'INR', 'rupees': 'INR', 'real': 'BRL', //
    'reais': 'BRL', 'franc': 'CHF', 'francs': 'CHF', 'won': 'KRW', 'lira': 'TRY', 'zloty': 'PLN', //
    'baht': 'THB', 'rand': 'ZAR', 'krona': 'SEK', 'peso': 'MXN', 'pesos': 'MXN',
  };

  /// The typed value the app would store for [setting], or null when [value] makes no sense for it.
  Object? _resolve(String setting, String value) {
    final v = value.trim().toLowerCase();
    final on = _switch(value);
    switch (setting) {
      case 'fiat_currency':
        final code = _fiatNames[v] ?? v.toUpperCase();
        return FiatCurrency.tryDeserialize(raw: code);
      case 'language':
        for (final entry in LanguageService.list.entries) {
          final name = entry.value.toLowerCase();
          if (entry.key == v || name == v || name.contains(v) || v.contains(entry.key == 'en' ? 'english' : name)) {
            return entry.key;
          }
        }
        return null;
      case 'theme':
        if (v.contains('dark') || v.contains('black') || v.contains('night') || v.contains('oled')) return ThemeMode.dark;
        if (v.contains('light') || v.contains('white') || v.contains('bright')) return ThemeMode.light;
        if (v.contains('system') || v.contains('auto')) return ThemeMode.system;
        return null;
      case 'bitcoin_unit':
        if (v.contains('sat')) return BitcoinAmountDisplayMode.satoshi;
        if (v.contains('btc') || v.contains('bitcoin')) return BitcoinAmountDisplayMode.bitcoin;
        return null;
      case 'fee_priority':
        final wallet = _appStore.wallet;
        if (wallet == null) return null;
        for (final priority in priorityForWalletType(wallet.type)) {
          final title = '$priority'.toLowerCase();
          if (!title.contains('custom') && (title == v || title.contains(v) || v.contains(title))) return priority;
        }
        return null;
      case 'fiat_api':
        if (v.contains('tor')) return FiatApiMode.torOnly;
        return on == null ? null : (on ? FiatApiMode.enabled : FiatApiMode.disabled);
      case 'swap_api':
        if (v.contains('tor')) return ExchangeApiMode.torOnly;
        return on == null ? null : (on ? ExchangeApiMode.enabled : ExchangeApiMode.disabled);
      default:
        return on;
    }
  }

  /// Applies a change the user just confirmed. Returns what to tell them.
  Future<String> apply(String setting, String value, BuildContext context) async {
    if (_unavailable(setting) != null || _screenFor(setting, value) != null) {
      return 'That change has to be made on its settings screen.';
    }
    final resolved = _resolve(setting, value);
    if (resolved == null) return 'I could not apply that value.';
    final on = resolved is bool ? resolved : false;
    switch (setting) {
      case 'tor':
        _dashboard.setBuiltinTor(on, context);
      case 'fiat_currency':
        _settings.fiatCurrency = resolved as FiatCurrency;
      case 'language':
        getIt.get<DisplaySettingsViewModel>().onLanguageSelected(resolved as String);
      case 'theme':
        await getIt.get<DisplaySettingsViewModel>().setThemeMode(resolved as ThemeMode);
      case 'hide_balance':
        _settings.balanceDisplayMode = on ? BalanceDisplayMode.hiddenBalance : BalanceDisplayMode.displayableBalance;
      case 'bitcoin_unit':
        _dashboard.setDisplayAmountsInSatoshi(resolved as BitcoinAmountDisplayMode);
      case 'show_charts_tab':
        _settings.shouldShowChartsInDashboard = on;
      case 'show_apps_tab':
        _settings.shouldShowMarketPlaceInDashboard = on;
      case 'show_buy_sell':
        _settings.disableTradeOption = !on;
      case 'fee_priority':
        final wallet = _appStore.wallet;
        if (wallet == null) return 'No wallet is open.';
        _settings.setPriority(wallet.type, resolved as TransactionPriority, chainId: wallet.chainId);
      case 'fiat_api':
        _settings.fiatApiMode = resolved as FiatApiMode;
      case 'swap_api':
        _settings.exchangeStatus = resolved as ExchangeApiMode;
      case 'payjoin':
        getIt.get<PrivacySettingsViewModel>().setUsePayjoin(on);
      case 'auto_generate_addresses':
        getIt.get<PrivacySettingsViewModel>().setAutoGenerateSubaddresses(on);
      case 'mweb':
        getIt.get<MwebSettingsViewModel>().setMwebEnabled(on);
      case 'silent_payments_scanning':
        _dashboard.setSilentPaymentsScanning(on);
      case 'prevent_screenshots':
        _settings.isAppSecure = on;
      case 'save_recipient_address':
        _settings.shouldSaveRecipientAddress = on;
      case 'lightning':
        getIt.get<PrivacySettingsViewModel>().setUseLightning(on);
      default:
        return 'That setting can only be changed on its settings screen.';
    }
    return _done(setting, value);
  }

  // --- wallets, receive, screens -------------------------------------------------

  List<WalletInfo>? _wallets;

  /// Wallet names are loaded when the chat opens so lookups here stay synchronous.
  Future<void> loadWallets() async => _wallets = await WalletInfo.getAll();

  WalletInfo? walletNamed(String name) {
    final wanted = name.trim().toLowerCase();
    final all = _wallets ?? const <WalletInfo>[];
    final current = _appStore.wallet?.name;
    final exact = all.where((w) => w.name.toLowerCase() == wanted && w.name != current).toList();
    if (exact.length == 1) return exact.single;
    final loose = all
        .where((w) =>
            w.name != current &&
            (w.name.toLowerCase().contains(wanted) || walletTypeToString(w.type).toLowerCase() == wanted))
        .toList();
    return loose.length == 1 ? loose.single : null;
  }

  @override
  AskCakeToolResult switchWallet(String? name) {
    final all = _wallets ?? const <WalletInfo>[];
    final listing = all.map((w) => '- ${w.name} (${walletTypeToString(w.type)})').join('\n');
    if (name == null || name.trim().isEmpty) return AskCakeToolResult('Which wallet? You have:\n$listing');
    final found = walletNamed(name);
    if (found == null) {
      return AskCakeToolResult('I couldn\'t pick out one wallet for "$name". You have:\n$listing');
    }
    return AskCakeToolResult(
        'Ready to switch to ${found.name} (${walletTypeToString(found.type)}). You may be asked for your PIN.',
        action: AskCakeSwitchWalletAction(found.name));
  }

  @override
  String? walletMentionedIn(String message) {
    final text = message.toLowerCase();
    final current = _appStore.wallet?.name;
    final named = [
      for (final w in _wallets ?? const <WalletInfo>[])
        if (w.name != current && text.contains(w.name.toLowerCase())) w.name
    ];
    return named.length == 1 ? named.single : null;
  }

  @override
  AskCakeToolResult receive({String? addressType, bool fresh = false, String? amount}) {
    final wallet = _appStore.wallet;
    if (wallet == null) return const AskCakeToolResult('No wallet is open.');
    final lightning = addressType == 'lightning';
    final notes = <String>[
      if (lightning) 'Opening Receive over Lightning.',
      if (addressType != null && !lightning)
        'Opening Receive. Pick ${addressType.replaceAll('_', ' ')} from the address type menu at the top; I can\'t select it for you yet.',
      if (fresh) 'Choose a fresh address there if the one shown has been used.',
      if (amount != null) 'Enter $amount as the requested amount on that screen.',
    ];
    return AskCakeToolResult(
      notes.isEmpty ? 'Your current ${wallet.currency.title} receive address is:\n${wallet.walletAddresses.address}' : notes.join(' '),
      action: AskCakeReceiveAction(lightning: lightning, addressType: addressType),
    );
  }

  @override
  AskCakeToolResult? open(String tool, Map<String, dynamic> details) {
    final wallet = _appStore.wallet;
    String? ticker(String key) => details[key] is String ? (details[key] as String).toUpperCase() : null;
    switch (tool) {
      case 'swap':
        final from = ticker('from');
        final to = ticker('to');
        return AskCakeToolResult(
            'Opening Swap${from != null || to != null ? ' for ${from ?? wallet?.currency.title ?? '?'} to ${to ?? '?'}' : ''}. '
            'You choose the amount and provider and confirm there.',
            action: AskCakeOpenPageAction('swap', 'Open Swap', from: from, to: to));
      case 'buy':
      case 'sell':
        return AskCakeToolResult(
            'Opening ${tool == 'buy' ? 'Buy' : 'Sell'}${ticker('asset') != null ? ' for ${ticker('asset')}' : ''}. '
            'You enter the amount and pick a provider there.',
            action: AskCakeOpenPageAction(tool, tool == 'buy' ? 'Open Buy' : 'Open Sell', asset: ticker('asset')));
      case 'cake_pay':
        return const AskCakeToolResult('Opening Cake Pay, where you can browse gift cards.',
            action: AskCakeOpenPageAction('cakePay', 'Open Cake Pay'));
      case 'move_funds':
        if (wallet != null && wallet.type == WalletType.bitcoin && _dashboard.hasLightning) {
          final text = '${details['_text'] ?? ''}'.toLowerCase();
          final out = RegExp(r'on-?chain|withdraw|out of lightning|off lightning|from lightning').hasMatch(text) &&
              !RegExp(r'(to|into|onto) (my )?lightning').hasMatch(text);
          return AskCakeToolResult(
              out
                  ? 'Opening the Lightning to on-chain withdrawal. You set the amount and confirm there.'
                  : 'Opening the on-chain to Lightning deposit. You set the amount and confirm there.',
              action: AskCakeOpenPageAction(out ? 'lightningWithdrawal' : 'lightningDeposit', 'Open transfer'));
        }
        if ('${details['_text'] ?? ''}'.toLowerCase().contains('lightning')) {
          return const AskCakeToolResult('Lightning is only available in a Bitcoin wallet. Switch to one first.');
        }
        if (wallet != null && wallet.type == WalletType.litecoin) {
          return const AskCakeToolResult('Moving Litecoin into or out of MWEB starts from the MWEB settings screen.',
              action: AskCakeOpenRouteAction(Routes.mwebSettings, 'Open MWEB settings'));
        }
        return const AskCakeToolResult(
            'This wallet has no second layer to move funds to. To change coins, ask me to swap instead.');
      case 'set_lightning_username':
        if (wallet == null || !wallet.hasLightningSupport) {
          return const AskCakeToolResult('Lightning is only available in a Bitcoin wallet. Switch to one first.');
        }
        return const AskCakeToolResult('Opening the Lightning username screen, where you can check a name and save it.',
            action: AskCakeOpenRouteAction(Routes.lightningUsernamePage, 'Open username', arguments: false));
      case 'manage_nodes':
        return const AskCakeToolResult('Opening node settings. Nothing changes until you pick or add a node there.',
            action: AskCakeOpenRouteAction(Routes.manageNodes, 'Open nodes'));
      case 'rescan':
        if (wallet != null && !wallet.hasRescan) return const AskCakeToolResult('This wallet type cannot be rescanned.');
        return const AskCakeToolResult('Opening Rescan. You choose the date or height and start it there.',
            action: AskCakeOpenRouteAction(Routes.rescan, 'Open Rescan'));
      case 'coin_control':
        if (wallet != null && !wallet.hasCoinControl) {
          return const AskCakeToolResult('Coin control is not available for this wallet type.');
        }
        return const AskCakeToolResult('Opening coin control, where you can freeze or select coins.',
            action: AskCakeOpenRouteAction(Routes.unspentCoinsList, 'Open coin control',
                arguments: CoinControlPageArgs(canEdit: true)));
      case 'walletconnect':
        if (!_dashboard.hasWalletConnect) return const AskCakeToolResult('WalletConnect is not available for this wallet.');
        return const AskCakeToolResult('Opening WalletConnect, where you can pair with a dApp or review sessions.',
            action: AskCakeOpenRouteAction(Routes.walletConnectConnectionsListing, 'Open WalletConnect'));
      case 'manage_wallets':
        return const AskCakeToolResult(
            'Opening your wallet list. Creating or restoring a wallet starts there, behind your PIN. '
            'Never type a recovery phrase into this chat.',
            action: AskCakeOpenRouteAction(Routes.walletList, 'Open wallets'));
      case 'security_settings':
        return const AskCakeToolResult(
            'Opening Security and Backup. PIN, biometrics and 2FA can only be changed there, after you authenticate.',
            action: AskCakeOpenRouteAction(Routes.securityBackupPage, 'Open security'));
      case 'backup':
        return const AskCakeToolResult(
            'Backups are created from Settings, behind your PIN. I\'ll open Settings; choose Backup there.',
            action: AskCakeOpenPageAction('settings', 'Open Settings'));
      case 'export_data':
        return const AskCakeToolResult('I can export this wallet\'s transaction history as a CSV file for you to save or share.',
            action: AskCakeOpenPageAction('exportTransactions', 'Export transactions'));
      case 'sign_message':
        if (wallet != null && !wallet.canSignMessages) {
          return const AskCakeToolResult('This wallet type cannot sign messages.');
        }
        return const AskCakeToolResult('Opening Sign / Verify. You enter the message and sign it there.',
            action: AskCakeOpenRouteAction(Routes.signPage, 'Open Sign / Verify'));
    }
    return null;
  }
}
