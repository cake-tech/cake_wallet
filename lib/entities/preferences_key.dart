class PreferencesKey {
  static const currentWalletType = 'current_wallet_type';
  static const currentWalletName = 'current_wallet_name';
  static const currentNodeIdKey = 'current_node_id';
  static const currentBitcoinElectrumSererIdKey = 'current_node_id_btc';
  static const currentLitecoinElectrumSererIdKey = 'current_node_id_ltc';
  static const currentHavenNodeIdKey = 'current_node_id_xhv';
  static const currentEthereumNodeIdKey = 'current_node_id_eth';
  static const currentFiatCurrencyKey = 'current_fiat_currency';
  static const currentTransactionPriorityKeyLegacy = 'current_fee_priority';
  static const currentBalanceDisplayModeKey = 'current_balance_display_mode';
  static const shouldSaveRecipientAddressKey = 'save_recipient_address';
  static const isAppSecureKey = 'is_app_secure';
  static const disableBuyKey = 'disable_buy';
  static const disableSellKey = 'disable_sell';
  static const currentFiatApiModeKey = 'current_fiat_api_mode';
  static const allowBiometricalAuthenticationKey =
      'allow_biometrical_authentication';
  static const useTOTP2FA = 'use_totp_2fa';
  static const failedTotpTokenTrials = 'failed_token_trials';
  static const totpSecretKey = 'totp_qr_secret_key';
  static const disableExchangeKey = 'disable_exchange';
  static const exchangeStatusKey = 'exchange_status';
  static const currentTheme = 'current_theme';
  static const isDarkThemeLegacy = 'dark_theme';
  static const displayActionListModeKey = 'display_list_mode';
  static const currentPinLength = 'current_pin_length';
  static const currentLanguageCode = 'language_code';
  static const currentDefaultSettingsMigrationVersion =
      'current_default_settings_migration_version';
  static const moneroTransactionPriority = 'current_fee_priority_monero';
  static const bitcoinTransactionPriority = 'current_fee_priority_bitcoin';
  static const havenTransactionPriority = 'current_fee_priority_haven';
  static const litecoinTransactionPriority = 'current_fee_priority_litecoin';
  static const ethereumTransactionPriority = 'current_fee_priority_ethereum';
  static const shouldShowReceiveWarning = 'should_show_receive_warning';
  static const shouldShowYatPopup = 'should_show_yat_popup';
  static const moneroWalletPasswordUpdateV1Base = 'monero_wallet_update_v1';
  static const syncModeKey = 'sync_mode';
  static const syncAllKey = 'sync_all';
  static const pinTimeOutDuration = 'pin_timeout_duration';
  static const lastAuthTimeMilliseconds = 'last_auth_time_milliseconds';
  static const lastPopupDate = 'last_popup_date';
  static const lastAppReviewDate = 'last_app_review_date';
  static const sortBalanceBy = 'sort_balance_by';
  static const pinNativeTokenAtTop = 'pin_native_token_at_top';
  static const useEtherscan = 'use_etherscan';

  static String moneroWalletUpdateV1Key(String name) =>
      '${PreferencesKey.moneroWalletPasswordUpdateV1Base}_${name}';

  static const exchangeProvidersSelection = 'exchange-providers-selection';
  static const clearnetDonationLink = 'clearnet_donation_link';
  static const onionDonationLink = 'onion_donation_link';
  static const lastSeenAppVersion = 'last_seen_app_version';
  static const shouldShowMarketPlaceInDashboard =
      'should_show_marketplace_in_dashboard';
  static const isNewInstall = 'is_new_install';
  static const shouldRequireTOTP2FAForAccessingWallet =
      'should_require_totp_2fa_for_accessing_wallets';
  static const shouldRequireTOTP2FAForSendsToContact =
      'should_require_totp_2fa_for_sends_to_contact';
  static const shouldRequireTOTP2FAForSendsToNonContact =
      'should_require_totp_2fa_for_sends_to_non_contact';
  static const shouldRequireTOTP2FAForSendsToInternalWallets =
      'should_require_totp_2fa_for_sends_to_internal_wallets';
  static const shouldRequireTOTP2FAForExchangesToInternalWallets =
      'should_require_totp_2fa_for_exchanges_to_internal_wallets';
  static const shouldRequireTOTP2FAForAddingContacts =
      'should_require_totp_2fa_for_adding_contacts';
  static const shouldRequireTOTP2FAForCreatingNewWallets =
      'should_require_totp_2fa_for_creating_new_wallets';
  static const shouldRequireTOTP2FAForAllSecurityAndBackupSettings =
      'should_require_totp_2fa_for_all_security_and_backup_settings';
  static const selectedCake2FAPreset = 'selected_cake_2fa_preset';
}
