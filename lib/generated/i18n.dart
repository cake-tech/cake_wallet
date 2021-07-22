import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class S implements WidgetsLocalizations {
  const S();

  static S current;

  static const GeneratedLocalizationsDelegate delegate =
    GeneratedLocalizationsDelegate();

  static S of(BuildContext context) => Localizations.of<S>(context, S);  
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  String get welcome => """Welcome to""";
  String get cake_wallet => """Cake Wallet""";
  String get first_wallet_text => """Awesome wallet for Monero and Bitcoin""";
  String get please_make_selection => """Please make a selection below to create or recover your wallet.""";
  String get create_new => """Create New Wallet""";
  String get restore_wallet => """Restore Wallet""";
  String get accounts => """Accounts""";
  String get edit => """Edit""";
  String get account => """Account""";
  String get add => """Add""";
  String get address_book => """Address Book""";
  String get contact => """Contact""";
  String get please_select => """Please select:""";
  String get cancel => """Cancel""";
  String get ok => """OK""";
  String get contact_name => """Contact Name""";
  String get reset => """Reset""";
  String get save => """Save""";
  String get address_remove_contact => """Remove contact""";
  String get address_remove_content => """Are you sure that you want to remove selected contact?""";
  String get authenticated => """Authenticated""";
  String get authentication => """Authentication""";
  String failed_authentication(String state_error) => """Failed authentication. ${state_error}""";
  String get wallet_menu => """Menu""";
  String Blocks_remaining(String status) => """${status} Blocks Remaining""";
  String get please_try_to_connect_to_another_node => """Please try to connect to another node""";
  String get xmr_hidden => """Hidden""";
  String get xmr_available_balance => """Available Balance""";
  String get xmr_full_balance => """Full Balance""";
  String get send => """Send""";
  String get receive => """Receive""";
  String get transactions => """Transactions""";
  String get incoming => """Incoming""";
  String get outgoing => """Outgoing""";
  String get transactions_by_date => """Transactions by date""";
  String get trades => """Trades""";
  String get filters => """Filter""";
  String get today => """Today""";
  String get yesterday => """Yesterday""";
  String get received => """Received""";
  String get sent => """Sent""";
  String get pending => """ (pending)""";
  String get rescan => """Rescan""";
  String get reconnect => """Reconnect""";
  String get wallets => """Wallets""";
  String get show_seed => """Show seed""";
  String get show_keys => """Show seed/keys""";
  String get address_book_menu => """Address book""";
  String get reconnection => """Reconnection""";
  String get reconnect_alert_text => """Are you sure you want to reconnect?""";
  String get exchange => """Exchange""";
  String get clear => """Clear""";
  String get refund_address => """Refund address""";
  String get change_exchange_provider => """Change Exchange Provider""";
  String get you_will_send => """Convert from""";
  String get you_will_get => """Convert to""";
  String get amount_is_guaranteed => """The receive amount is guaranteed""";
  String get amount_is_estimate => """The receive amount is an estimate""";
  String powered_by(String title) => """Powered by ${title}""";
  String get error => """Error""";
  String get estimated => """Estimated""";
  String min_value(String value, String currency) => """Min: ${value} ${currency}""";
  String max_value(String value, String currency) => """Max: ${value} ${currency}""";
  String get change_currency => """Change Currency""";
  String get copy_id => """Copy ID""";
  String get exchange_result_write_down_trade_id => """Please copy or write down the trade ID to continue.""";
  String get trade_id => """Trade ID:""";
  String get copied_to_clipboard => """Copied to Clipboard""";
  String get saved_the_trade_id => """I've saved the trade ID""";
  String get fetching => """Fetching""";
  String get id => """ID: """;
  String get amount => """Amount: """;
  String get payment_id => """Payment ID: """;
  String get status => """Status: """;
  String get offer_expires_in => """Offer expires in: """;
  String trade_is_powered_by(String provider) => """This trade is powered by ${provider}""";
  String get copy_address => """Copy Address""";
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """By pressing confirm, you will be sending ${fetchingLabel} ${from} from your wallet called ${walletName} to the address shown below. Or you can send from your external wallet to the below address/QR code.

Please press confirm to continue or go back to change the amounts.""";
  String exchange_result_description(String fetchingLabel, String from) => """You must send a minimum of ${fetchingLabel} ${from} to the address shown on the next page. If you send an amount lower than ${fetchingLabel} ${from} it may not get converted and it may not be refunded.""";
  String get exchange_result_write_down_ID => """*Please copy or write down your ID shown above.""";
  String get confirm => """Confirm""";
  String get confirm_sending => """Confirm sending""";
  String commit_transaction_amount_fee(String amount, String fee) => """Commit transaction
Amount: ${amount}
Fee: ${fee}""";
  String get sending => """Sending""";
  String get transaction_sent => """Transaction sent!""";
  String get expired => """Expired""";
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  String get send_xmr => """Send XMR""";
  String get exchange_new_template => """New template""";
  String get faq => """FAQ""";
  String get enter_your_pin => """Enter your PIN""";
  String get loading_your_wallet => """Loading your wallet""";
  String get new_wallet => """New Wallet""";
  String get wallet_name => """Wallet name""";
  String get continue_text => """Continue""";
  String get choose_wallet_currency => """Please choose wallet currency:""";
  String get node_new => """New Node""";
  String get node_address => """Node Address""";
  String get node_port => """Node port""";
  String get login => """Login""";
  String get password => """Password""";
  String get nodes => """Nodes""";
  String get node_reset_settings_title => """Reset settings""";
  String get nodes_list_reset_to_default_message => """Are you sure that you want to reset settings to default?""";
  String change_current_node(String node) => """Are you sure to change current node to ${node}?""";
  String get change => """Change""";
  String get remove_node => """Remove node""";
  String get remove_node_message => """Are you sure that you want to remove selected node?""";
  String get remove => """Remove""";
  String get delete => """Delete""";
  String get add_new_node => """Add new node""";
  String get change_current_node_title => """Change current node""";
  String get node_test => """Test""";
  String get node_connection_successful => """Connection was successful""";
  String get node_connection_failed => """Connection was failed""";
  String get new_node_testing => """New node testing""";
  String get use => """Switch to """;
  String get digit_pin => """-digit PIN""";
  String get share_address => """Share address""";
  String get receive_amount => """Amount""";
  String get subaddresses => """Subaddresses""";
  String get addresses => """Addresses""";
  String get scan_qr_code => """Scan the QR code to get the address""";
  String get rename => """Rename""";
  String get choose_account => """Choose account""";
  String get create_new_account => """Create new account""";
  String get accounts_subaddresses => """Accounts and subaddresses""";
  String get restore_restore_wallet => """Restore Wallet""";
  String get restore_title_from_seed_keys => """Restore from seed/keys""";
  String get restore_description_from_seed_keys => """Get back your wallet from seed/keys that you've saved to secure place""";
  String get restore_next => """Next""";
  String get restore_title_from_backup => """Restore from backup""";
  String get restore_description_from_backup => """You can restore the whole Cake Wallet app from your back-up file""";
  String get restore_seed_keys_restore => """Seed/Keys Restore""";
  String get restore_title_from_seed => """Restore from seed""";
  String get restore_description_from_seed => """Restore your wallet from either the 25 word or 13 word combination code""";
  String get restore_title_from_keys => """Restore from keys""";
  String get restore_description_from_keys => """Restore your wallet from generated keystrokes saved from your private keys""";
  String get restore_wallet_name => """Wallet name""";
  String get restore_address => """Address""";
  String get restore_view_key_private => """View key (private)""";
  String get restore_spend_key_private => """Spend key (private)""";
  String get restore_recover => """Restore""";
  String get restore_wallet_restore_description => """Wallet restore description""";
  String get restore_new_seed => """New seed""";
  String get restore_active_seed => """Active seed""";
  String get restore_bitcoin_description_from_seed => """Restore your wallet from 24 word combination code""";
  String get restore_bitcoin_description_from_keys => """Restore your wallet from generated WIF string from your private keys""";
  String get restore_bitcoin_title_from_keys => """Restore from WIF""";
  String get restore_from_date_or_blockheight => """Please enter a date a few days before you created this wallet. Or if you know the blockheight, please enter it instead""";
  String get seed_reminder => """Please write these down in case you lose or wipe your phone""";
  String get seed_title => """Seed""";
  String get seed_share => """Share seed""";
  String get copy => """Copy""";
  String get seed_language_choose => """Please choose seed language:""";
  String get seed_choose => """Choose seed language""";
  String get seed_language_next => """Next""";
  String get seed_language_english => """English""";
  String get seed_language_chinese => """Chinese""";
  String get seed_language_dutch => """Dutch""";
  String get seed_language_german => """German""";
  String get seed_language_japanese => """Japanese""";
  String get seed_language_portuguese => """Portuguese""";
  String get seed_language_russian => """Russian""";
  String get seed_language_spanish => """Spanish""";
  String get send_title => """Send""";
  String get send_your_wallet => """Your wallet""";
  String send_address(String cryptoCurrency) => """${cryptoCurrency} address""";
  String get send_payment_id => """Payment ID (optional)""";
  String get all => """ALL""";
  String get send_error_minimum_value => """Minimum value of amount is 0.01""";
  String get send_error_currency => """Currency can only contain numbers""";
  String get send_estimated_fee => """Estimated fee:""";
  String send_priority(String transactionPriority) => """Currently the fee is set at ${transactionPriority} priority.
Transaction priority can be adjusted in the settings""";
  String get send_creating_transaction => """Creating transaction""";
  String get send_templates => """Templates""";
  String get send_new => """New""";
  String get send_amount => """Amount:""";
  String get send_fee => """Fee:""";
  String get send_name => """Name""";
  String get send_got_it => """Got it""";
  String get send_sending => """Sending...""";
  String send_success(String crypto) => """Your ${crypto} was successfully sent""";
  String get settings_title => """Settings""";
  String get settings_nodes => """Nodes""";
  String get settings_current_node => """Current node""";
  String get settings_wallets => """Wallets""";
  String get settings_display_balance_as => """Display balance as""";
  String get settings_currency => """Currency""";
  String get settings_fee_priority => """Fee priority""";
  String get settings_save_recipient_address => """Save recipient address""";
  String get settings_personal => """Personal""";
  String get settings_change_pin => """Change PIN""";
  String get settings_change_language => """Change language""";
  String get settings_allow_biometrical_authentication => """Allow biometrical authentication""";
  String get settings_dark_mode => """Dark mode""";
  String get settings_transactions => """Transactions""";
  String get settings_trades => """Trades""";
  String get settings_display_on_dashboard_list => """Display on dashboard list""";
  String get settings_all => """ALL""";
  String get settings_only_trades => """Only trades""";
  String get settings_only_transactions => """Only transactions""";
  String get settings_none => """None""";
  String get settings_support => """Support""";
  String get settings_terms_and_conditions => """Terms and conditions""";
  String get pin_is_incorrect => """PIN is incorrect""";
  String get setup_pin => """Setup PIN""";
  String get enter_your_pin_again => """Enter your pin again""";
  String get setup_successful => """Your PIN has been set up successfully!""";
  String get wallet_keys => """Wallet seed/keys""";
  String get wallet_seed => """Wallet seed""";
  String get private_key => """Private key""";
  String get public_key => """Public key""";
  String get view_key_private => """View key (private)""";
  String get view_key_public => """View key (public)""";
  String get spend_key_private => """Spend key (private)""";
  String get spend_key_public => """Spend key (public)""";
  String copied_key_to_clipboard(String key) => """Copied ${key} to Clipboard""";
  String get new_subaddress_title => """New address""";
  String get new_subaddress_label_name => """Label name""";
  String get new_subaddress_create => """Create""";
  String get subaddress_title => """Subaddress list""";
  String get trade_details_title => """Trade Details""";
  String get trade_details_id => """ID""";
  String get trade_details_state => """State""";
  String get trade_details_fetching => """Fetching""";
  String get trade_details_provider => """Provider""";
  String get trade_details_created_at => """Created at""";
  String get trade_details_pair => """Pair""";
  String trade_details_copied(String title) => """${title} copied to Clipboard""";
  String get trade_history_title => """Trade history""";
  String get transaction_details_title => """Transaction Details""";
  String get transaction_details_transaction_id => """Transaction ID""";
  String get transaction_details_date => """Date""";
  String get transaction_details_height => """Height""";
  String get transaction_details_amount => """Amount""";
  String get transaction_details_fee => """Fee""";
  String transaction_details_copied(String title) => """${title} copied to Clipboard""";
  String get transaction_details_recipient_address => """Recipient address""";
  String get wallet_list_title => """Monero Wallet""";
  String get wallet_list_create_new_wallet => """Create New Wallet""";
  String get wallet_list_restore_wallet => """Restore Wallet""";
  String get wallet_list_load_wallet => """Load wallet""";
  String wallet_list_loading_wallet(String wallet_name) => """Loading ${wallet_name} wallet""";
  String wallet_list_failed_to_load(String wallet_name, String error) => """Failed to load ${wallet_name} wallet. ${error}""";
  String wallet_list_removing_wallet(String wallet_name) => """Removing ${wallet_name} wallet""";
  String wallet_list_failed_to_remove(String wallet_name, String error) => """Failed to remove ${wallet_name} wallet. ${error}""";
  String get widgets_address => """Address""";
  String get widgets_restore_from_blockheight => """Restore from blockheight""";
  String get widgets_restore_from_date => """Restore from date""";
  String get widgets_or => """or""";
  String get widgets_seed => """Seed""";
  String router_no_route(String name) => """No route defined for ${name}""";
  String get error_text_account_name => """Account name can only contain letters, numbers
and must be between 1 and 15 characters long""";
  String get error_text_contact_name => """Contact name can't contain ` , ' " symbols
and must be between 1 and 32 characters long""";
  String get error_text_address => """Wallet address must correspond to the type
of cryptocurrency""";
  String get error_text_node_address => """Please enter a iPv4 address""";
  String get error_text_node_port => """Node port can only contain numbers between 0 and 65535""";
  String get error_text_payment_id => """Payment ID can only contain from 16 to 64 chars in hex""";
  String get error_text_xmr => """XMR value can't exceed available balance.
The number of fraction digits must be less or equal to 12""";
  String get error_text_fiat => """Value of amount can't exceed available balance.
The number of fraction digits must be less or equal to 2""";
  String get error_text_subaddress_name => """Subaddress name can't contain ` , ' " symbols
and must be between 1 and 20 characters long""";
  String get error_text_amount => """Amount can only contain numbers""";
  String get error_text_wallet_name => """Wallet name can only contain letters, numbers
and must be between 1 and 20 characters long""";
  String get error_text_keys => """Wallet keys can only contain 64 chars in hex""";
  String get error_text_crypto_currency => """The number of fraction digits
must be less or equal to 12""";
  String error_text_minimal_limit(String provider, String min, String currency) => """Trade for ${provider} is not created. Amount is less then minimal: ${min} ${currency}""";
  String error_text_maximum_limit(String provider, String max, String currency) => """Trade for ${provider} is not created. Amount is more then maximum: ${max} ${currency}""";
  String error_text_limits_loading_failed(String provider) => """Trade for ${provider} is not created. Limits loading failed""";
  String get error_text_template => """Template name and address can't contain ` , ' " symbols
and must be between 1 and 106 characters long""";
  String get auth_store_ban_timeout => """ban_timeout""";
  String get auth_store_banned_for => """Banned for """;
  String get auth_store_banned_minutes => """ minutes""";
  String get auth_store_incorrect_password => """Wrong PIN""";
  String get wallet_store_monero_wallet => """Monero Wallet""";
  String get wallet_restoration_store_incorrect_seed_length => """Incorrect seed length""";
  String get full_balance => """Full Balance""";
  String get available_balance => """Available Balance""";
  String get hidden_balance => """Hidden Balance""";
  String get sync_status_syncronizing => """SYNCHRONIZING""";
  String get sync_status_syncronized => """SYNCHRONIZED""";
  String get sync_status_not_connected => """NOT CONNECTED""";
  String get sync_status_starting_sync => """STARTING SYNC""";
  String get sync_status_failed_connect => """DISCONNECTED""";
  String get sync_status_connecting => """CONNECTING""";
  String get sync_status_connected => """CONNECTED""";
  String get transaction_priority_slow => """Slow""";
  String get transaction_priority_regular => """Regular""";
  String get transaction_priority_medium => """Medium""";
  String get transaction_priority_fast => """Fast""";
  String get transaction_priority_fastest => """Fastest""";
  String trade_for_not_created(String title) => """Trade for ${title} is not created.""";
  String get trade_not_created => """Trade not created.""";
  String trade_id_not_found(String tradeId, String title) => """Trade ${tradeId} of ${title} not found.""";
  String get trade_not_found => """Trade not found.""";
  String get trade_state_pending => """Pending""";
  String get trade_state_confirming => """Confirming""";
  String get trade_state_trading => """Trading""";
  String get trade_state_traded => """Traded""";
  String get trade_state_complete => """Complete""";
  String get trade_state_to_be_created => """To be created""";
  String get trade_state_unpaid => """Unpaid""";
  String get trade_state_underpaid => """Underpaid""";
  String get trade_state_paid_unconfirmed => """Paid unconfirmed""";
  String get trade_state_paid => """Paid""";
  String get trade_state_btc_sent => """Btc sent""";
  String get trade_state_timeout => """Timeout""";
  String get trade_state_created => """Created""";
  String get trade_state_finished => """Finished""";
  String get change_language => """Change language""";
  String change_language_to(String language) => """Change language to ${language}?""";
  String get paste => """Paste""";
  String get restore_from_seed_placeholder => """Please enter or paste your seed here""";
  String get add_new_word => """Add new word""";
  String get incorrect_seed => """The text entered is not valid.""";
  String get biometric_auth_reason => """Scan your fingerprint to authenticate""";
  String version(String currentVersion) => """Version ${currentVersion}""";
  String get openalias_alert_title => """XMR Recipient Detected""";
  String openalias_alert_content(String recipient_name) => """You will be sending funds to
${recipient_name}""";
  String get card_address => """Address:""";
  String get buy => """Buy""";
  String get placeholder_transactions => """Your transactions will be displayed here""";
  String get placeholder_contacts => """Your contacts will be displayed here""";
  String get template => """Template""";
  String get confirm_delete_template => """This action will delete this template. Do you wish to continue?""";
  String get confirm_delete_wallet => """This action will delete this wallet. Do you wish to continue?""";
  String get picker_description => """To choose ChangeNOW  or MorphToken, please change your trading pair first""";
  String get change_wallet_alert_title => """Change current wallet""";
  String change_wallet_alert_content(String wallet_name) => """Do you want to change current wallet to ${wallet_name}?""";
  String get creating_new_wallet => """Creating new wallet""";
  String creating_new_wallet_error(String description) => """Error: ${description}""";
  String get seed_alert_title => """Attention""";
  String get seed_alert_content => """The seed is the only way to recover your wallet. Have you written it down?""";
  String get seed_alert_back => """Go back""";
  String get seed_alert_yes => """Yes, I have""";
  String get wallet_name_alert_content => """Wallet with the same name is exists""";
  String get exchange_sync_alert_content => """Please wait until your wallet is synchronized""";
  String get pre_seed_title => """IMPORTANT""";
  String pre_seed_description(String words) => """On the next page you will see a series of ${words} words. This is your unique and private seed and it is the ONLY way to recover your wallet in case of loss or malfunction. It is YOUR responsibility to write it down and store it in a safe place outside of the Cake Wallet app.""";
  String get pre_seed_button_text => """I understand. Show me my seed""";
  String get xmr_to_error => """XMR.TO error""";
  String get xmr_to_error_description => """Invalid amount. Maximum limit 8 digits after the decimal point""";
  String provider_error(String provider) => """${provider} error""";
  String get use_ssl => """Use SSL""";
  String get color_theme => """Color theme""";
  String get light_theme => """Light""";
  String get bright_theme => """Bright""";
  String get dark_theme => """Dark""";
  String get enter_your_note => """Enter your note…""";
  String get note_optional => """Note (optional)""";
  String get note_tap_to_change => """Note (tap to change)""";
  String get transaction_key => """Transaction Key""";
  String get confirmations => """Confirmations""";
  String get recipient_address => """Recipient address""";
  String get extra_id => """Extra ID:""";
  String get destination_tag => """Destination tag:""";
  String get memo => """Memo:""";
  String get backup => """Backup""";
  String get change_password => """Change password""";
  String get backup_password => """Backup password""";
  String get write_down_backup_password => """Please write down your backup password, which is used for the import of your backup files.""";
  String get export_backup => """Export backup""";
  String get save_backup_password => """Please make sure that you have saved your backup password.  You will not be able to import your backup files without it.""";
  String get backup_file => """Backup file""";
  String get edit_backup_password => """Edit Backup Password""";
  String get save_backup_password_alert => """Save backup password""";
  String get change_backup_password_alert => """Your previous backup files will be not available to import with new backup password. New backup password will be used only for new backup files. Are you sure that you want to change backup password?""";
  String get enter_backup_password => """Enter backup password here""";
  String get select_backup_file => """Select backup file""";
  String get import => """Import""";
  String get please_select_backup_file => """Please select backup file and enter backup password.""";
  String get fixed_rate => """Fixed rate""";
  String get fixed_rate_alert => """You will be able to enter receive amount when fixed rate mode is checked. Do you want to switch to fixed rate mode?""";
  String get xlm_extra_info => """Please don’t forget to specify the Memo ID while sending the XLM transaction for the exchange""";
  String get xrp_extra_info => """Please don’t forget to specify the Destination Tag while sending the XRP transaction for the exchange""";
  String get exchange_incorrect_current_wallet_for_xmr => """If you want to exchange XMR from your Cake Wallet Monero balance, please switch to your Monero wallet first.""";
  String get confirmed => """Confirmed""";
  String get unconfirmed => """Unconfirmed""";
  String get displayable => """Displayable""";
  String get submit_request => """submit a request""";
  String get buy_alert_content => """Currently we only support the purchase of Bitcoin and Litecoin. To buy Bitcoin or Litecoin, please create or switch to your Bitcoin or Litecoin wallet.""";
  String get outdated_electrum_wallet_description => """New Bitcoin wallets created in Cake now have a 24-word seed. It is mandatory that you create a new Bitcoin wallet and transfer all of your funds to the new 24-word wallet, and stop using wallets with a 12-word seed. Please do this immediately to secure your funds.""";
  String get understand => """I understand""";
  String get apk_update => """APK update""";
  String get buy_bitcoin => """Buy Bitcoin""";
  String get buy_with => """Buy with""";
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """Value of the amount must be more or equal to ${minAmount} ${fiatCurrency}""";
  String get outdated_electrum_wallet_receive_warning => """If this wallet has a 12-word seed and was created in Cake, DO NOT deposit Bitcoin into this wallet. Any BTC transferred to this wallet may be lost. Create a new 24-word wallet (tap the menu at the top right, select Wallets, choose Create New Wallet, then select Bitcoin) and IMMEDIATELY move your BTC there. New (24-word) BTC wallets from Cake are secure""";
  String get do_not_show_me => """Do not show me this again""";
  String get unspent_coins_title => """Unspent coins""";
  String get unspent_coins_details_title => """Unspent coins details""";
  String get freeze => """Freeze""";
  String get coin_control => """Coin control (optional)""";
  String get address_detected => """Address detected""";
  String address_from_domain(String domain) => """You got address from unstoppable domain ${domain}""";
}

class $nl extends S {
  const $nl();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """Welkom bij""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """Geweldige portemonnee voor Monero en Bitcoin""";
  @override
  String get please_make_selection => """Maak hieronder uw keuze tot maak of herstel je portemonnee.""";
  @override
  String get create_new => """Maak een nieuwe portemonnee""";
  @override
  String get restore_wallet => """Portemonnee herstellen""";
  @override
  String get accounts => """Accounts""";
  @override
  String get edit => """Bewerk""";
  @override
  String get account => """Account""";
  @override
  String get add => """Toevoegen""";
  @override
  String get address_book => """Adresboek""";
  @override
  String get contact => """Contact""";
  @override
  String get please_select => """Selecteer alstublieft:""";
  @override
  String get cancel => """Annuleer""";
  @override
  String get ok => """OK""";
  @override
  String get contact_name => """Contactnaam""";
  @override
  String get reset => """Reset""";
  @override
  String get save => """Opslaan""";
  @override
  String get address_remove_contact => """Contact verwijderen""";
  @override
  String get address_remove_content => """Weet u zeker dat u het geselecteerde contact wilt verwijderen?""";
  @override
  String get authenticated => """Authenticated""";
  @override
  String get authentication => """Authenticatie""";
  @override
  String failed_authentication(String state_error) => """Mislukte authenticatie. ${state_error}""";
  @override
  String get wallet_menu => """Portemonnee-menu""";
  @override
  String Blocks_remaining(String status) => """${status} Resterende blokken""";
  @override
  String get please_try_to_connect_to_another_node => """Probeer verbinding te maken met een ander knooppunt""";
  @override
  String get xmr_hidden => """Verborgen""";
  @override
  String get xmr_available_balance => """Beschikbaar saldo""";
  @override
  String get xmr_full_balance => """Volledig saldo""";
  @override
  String get send => """Sturen""";
  @override
  String get receive => """Krijgen""";
  @override
  String get transactions => """Transacties""";
  @override
  String get incoming => """inkomend""";
  @override
  String get outgoing => """Uitgaande""";
  @override
  String get transactions_by_date => """Transacties op datum""";
  @override
  String get trades => """Trades""";
  @override
  String get filters => """Filter""";
  @override
  String get today => """Vandaag""";
  @override
  String get yesterday => """Gisteren""";
  @override
  String get received => """Ontvangen""";
  @override
  String get sent => """Verzonden""";
  @override
  String get pending => """ (in afwachting)""";
  @override
  String get rescan => """Opnieuw scannen""";
  @override
  String get reconnect => """Sluit""";
  @override
  String get wallets => """Portefeuilles""";
  @override
  String get show_seed => """Toon zaad""";
  @override
  String get show_keys => """Toon zaad/sleutels""";
  @override
  String get address_book_menu => """Adresboek""";
  @override
  String get reconnection => """Reconnection""";
  @override
  String get reconnect_alert_text => """Weet u zeker dat u opnieuw verbinding wilt maken?""";
  @override
  String get exchange => """Uitwisseling""";
  @override
  String get clear => """Duidelijk""";
  @override
  String get refund_address => """Adres voor terugbetaling""";
  @override
  String get change_exchange_provider => """Wijzig Exchange Provider""";
  @override
  String get you_will_send => """Converteren van""";
  @override
  String get you_will_get => """Converteren naar""";
  @override
  String get amount_is_guaranteed => """Het ontvangen bedrag is gegarandeerd""";
  @override
  String get amount_is_estimate => """Het ontvangen bedrag is een schatting""";
  @override
  String powered_by(String title) => """Aangedreven door ${title}""";
  @override
  String get error => """Fout""";
  @override
  String get estimated => """Geschatte""";
  @override
  String min_value(String value, String currency) => """Min: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """Max: ${value} ${currency}""";
  @override
  String get change_currency => """Verander valuta""";
  @override
  String get copy_id => """ID kopiëren""";
  @override
  String get exchange_result_write_down_trade_id => """Kopieer of noteer de handels-ID om door te gaan.""";
  @override
  String get trade_id => """Trade ID:""";
  @override
  String get copied_to_clipboard => """Gekopieerd naar het klembord""";
  @override
  String get saved_the_trade_id => """Ik heb de ruil-ID opgeslagen""";
  @override
  String get fetching => """Ophalen""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """Bedrag: """;
  @override
  String get payment_id => """Betaling ID: """;
  @override
  String get status => """Staat: """;
  @override
  String get offer_expires_in => """Aanbieding verloopt over: """;
  @override
  String trade_is_powered_by(String provider) => """Deze transactie wordt mogelijk gemaakt door ${provider}""";
  @override
  String get copy_address => """Adres kopiëren""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """Door op bevestigen te drukken, wordt u verzonden ${fetchingLabel} ${from} uit je portemonnee genoemd ${walletName} naar het onderstaande adres. Of u kunt vanuit uw externe portemonnee naar het onderstaande adres verzenden / QR-code sturen.

Druk op bevestigen om door te gaan of terug te gaan om de bedragen te wijzigen.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """U moet minimaal ${fetchingLabel} ${from} verzenden naar het adres dat op de volgende pagina wordt weergegeven. Als u een bedrag verzendt dat lager is dan ${fetchingLabel} ${from}, wordt het mogelijk niet omgezet en wordt het mogelijk niet terugbetaald.""";
  @override
  String get exchange_result_write_down_ID => """*Kopieer of noteer uw hierboven getoonde ID.""";
  @override
  String get confirm => """Bevestigen""";
  @override
  String get confirm_sending => """Bevestig verzending""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """Verricht transactie
Bedrag: ${amount}
honorarium: ${fee}""";
  @override
  String get sending => """Bezig met verzenden""";
  @override
  String get transaction_sent => """Transactie verzonden!""";
  @override
  String get expired => """Verlopen""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """Sturen XMR""";
  @override
  String get exchange_new_template => """Nieuwe sjabloon""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """Voer uw pincode in""";
  @override
  String get loading_your_wallet => """Uw portemonnee laden""";
  @override
  String get new_wallet => """Nieuwe portemonnee""";
  @override
  String get wallet_name => """Portemonnee naam""";
  @override
  String get continue_text => """Doorgaan met""";
  @override
  String get choose_wallet_currency => """Kies een portemonnee-valuta:""";
  @override
  String get node_new => """Nieuw knooppunt""";
  @override
  String get node_address => """Knooppunt adres""";
  @override
  String get node_port => """Knooppunt poort""";
  @override
  String get login => """Log in""";
  @override
  String get password => """Wachtwoord""";
  @override
  String get nodes => """Knooppunten""";
  @override
  String get node_reset_settings_title => """Reset instellingen""";
  @override
  String get nodes_list_reset_to_default_message => """Weet u zeker dat u de standaardinstellingen wilt herstellen?""";
  @override
  String change_current_node(String node) => """Weet u zeker dat u het huidige knooppunt wilt wijzigen in ${node}?""";
  @override
  String get change => """Verandering""";
  @override
  String get remove_node => """Knoop verwijderen""";
  @override
  String get remove_node_message => """Weet u zeker dat u het geselecteerde knooppunt wilt verwijderen?""";
  @override
  String get remove => """Verwijderen""";
  @override
  String get delete => """Delete""";
  @override
  String get add_new_node => """Voeg een nieuw knooppunt toe""";
  @override
  String get change_current_node_title => """Wijzig het huidige knooppunt""";
  @override
  String get node_test => """Test""";
  @override
  String get node_connection_successful => """Verbinding is gelukt""";
  @override
  String get node_connection_failed => """De verbinding is mislukt""";
  @override
  String get new_node_testing => """Nieuwe knooppunttest""";
  @override
  String get use => """Gebruik """;
  @override
  String get digit_pin => """-cijferige PIN""";
  @override
  String get share_address => """Deel adres""";
  @override
  String get receive_amount => """Bedrag""";
  @override
  String get subaddresses => """Subadressen""";
  @override
  String get rename => """Hernoemen""";
  @override
  String get addresses => """Adressen""";
  @override
  String get scan_qr_code => """Scan de QR-code om het adres te krijgen""";
  @override
  String get choose_account => """Kies account""";
  @override
  String get create_new_account => """Creëer een nieuw account""";
  @override
  String get accounts_subaddresses => """Accounts en subadressen""";
  @override
  String get restore_restore_wallet => """Portemonnee herstellen""";
  @override
  String get restore_title_from_seed_keys => """Herstel van zaad / sleutels""";
  @override
  String get restore_description_from_seed_keys => """Ontvang uw portemonnee terug uit seed / keys die u hebt opgeslagen op een veilige plaats""";
  @override
  String get restore_next => """Volgende""";
  @override
  String get restore_title_from_backup => """Herstellen vanuit een back-upbestand""";
  @override
  String get restore_description_from_backup => """Je kunt de hele Cake Wallet-app herstellen van uw back-upbestand""";
  @override
  String get restore_seed_keys_restore => """Zaad / sleutels herstellen""";
  @override
  String get restore_title_from_seed => """Herstel van zaad""";
  @override
  String get restore_description_from_seed => """Herstel uw portemonnee van het 25 woord of 13 woord combinatiecode""";
  @override
  String get restore_title_from_keys => """Herstel van sleutels""";
  @override
  String get restore_description_from_keys => """Herstel uw portemonnee van gegenereerd toetsaanslagen opgeslagen van uw privésleutels""";
  @override
  String get restore_wallet_name => """Portemonnee naam""";
  @override
  String get restore_address => """Adres""";
  @override
  String get restore_view_key_private => """Bekijk sleutel (privaat)""";
  @override
  String get restore_spend_key_private => """Sleutel uitgeven (privaat)""";
  @override
  String get restore_recover => """Herstellen""";
  @override
  String get restore_wallet_restore_description => """Portemonnee-herstelbeschrijving""";
  @override
  String get restore_new_seed => """Nieuw zaad""";
  @override
  String get restore_active_seed => """Actief zaad""";
  @override
  String get restore_bitcoin_description_from_seed => """Herstel uw portemonnee met een combinatiecode van 24 woorden""";
  @override
  String get restore_bitcoin_description_from_keys => """Herstel uw portemonnee van de gegenereerde WIF-string van uw privésleutels""";
  @override
  String get restore_bitcoin_title_from_keys => """Herstel van WIF""";
  @override
  String get restore_from_date_or_blockheight => """Voer een datum in een paar dagen voordat u deze portemonnee heeft gemaakt. Of als u de blokhoogte kent, voert u deze in""";
  @override
  String get seed_reminder => """Schrijf deze op voor het geval u uw telefoon kwijtraakt of veegt""";
  @override
  String get seed_title => """Zaad""";
  @override
  String get seed_share => """Deel zaad""";
  @override
  String get copy => """Kopiëren""";
  @override
  String get seed_language_choose => """Kies een starttaal:""";
  @override
  String get seed_choose => """Kies een starttaal""";
  @override
  String get seed_language_next => """Volgende""";
  @override
  String get seed_language_english => """Engels""";
  @override
  String get seed_language_chinese => """Chinese""";
  @override
  String get seed_language_dutch => """Nederlands""";
  @override
  String get seed_language_german => """Duitse""";
  @override
  String get seed_language_japanese => """Japans""";
  @override
  String get seed_language_portuguese => """Portugees""";
  @override
  String get seed_language_russian => """Russisch""";
  @override
  String get seed_language_spanish => """Spaans""";
  @override
  String get send_title => """Stuur""";
  @override
  String get send_your_wallet => """Uw portemonnee""";
  @override
  String send_address(String cryptoCurrency) => """${cryptoCurrency}-adres""";
  @override
  String get send_payment_id => """Betaling ID (facultatief)""";
  @override
  String get all => """ALLE""";
  @override
  String get send_error_minimum_value => """Minimale waarde van bedrag is 0,01""";
  @override
  String get send_error_currency => """Valuta kan alleen cijfers bevatten""";
  @override
  String get send_estimated_fee => """Geschatte vergoeding:""";
  @override
  String send_priority(String transactionPriority) => """Momenteel is de vergoeding vastgesteld op ${transactionPriority} prioriteit.
Transactieprioriteit kan worden aangepast in de instellingen""";
  @override
  String get send_creating_transaction => """Transactie maken""";
  @override
  String get send_templates => """Sjablonen""";
  @override
  String get send_new => """Nieuw""";
  @override
  String get send_amount => """Bedrag:""";
  @override
  String get send_fee => """Vergoeding:""";
  @override
  String get send_name => """Naam""";
  @override
  String get send_got_it => """Ik snap het""";
  @override
  String get send_sending => """Bezig met verzenden...""";
  @override
  String send_success(String crypto) => """Uw ${crypto} is succesvol verzonden""";
  @override
  String get settings_title => """Instellingen""";
  @override
  String get settings_nodes => """knooppunten""";
  @override
  String get settings_current_node => """Huidige knooppunt""";
  @override
  String get settings_wallets => """Portemonnee""";
  @override
  String get settings_display_balance_as => """Toon saldo als""";
  @override
  String get settings_currency => """Valuta""";
  @override
  String get settings_fee_priority => """Tariefprioriteit""";
  @override
  String get settings_save_recipient_address => """Adres ontvanger opslaan""";
  @override
  String get settings_personal => """Persoonlijk""";
  @override
  String get settings_change_pin => """Verander pincode""";
  @override
  String get settings_change_language => """Verander de taal""";
  @override
  String get settings_allow_biometrical_authentication => """Biometrische authenticatie toestaan""";
  @override
  String get settings_dark_mode => """Donkere modus""";
  @override
  String get settings_transactions => """Transacties""";
  @override
  String get settings_trades => """Trades""";
  @override
  String get settings_display_on_dashboard_list => """Weergeven op dashboardlijst""";
  @override
  String get settings_all => """ALLE""";
  @override
  String get settings_only_trades => """Alleen handel""";
  @override
  String get settings_only_transactions => """Alleen transacties""";
  @override
  String get settings_none => """Geen""";
  @override
  String get settings_support => """Ondersteuning""";
  @override
  String get settings_terms_and_conditions => """Voorwaarden""";
  @override
  String get pin_is_incorrect => """PIN is onjuist""";
  @override
  String get setup_pin => """PIN instellen""";
  @override
  String get enter_your_pin_again => """Voer uw PIN opnieuw in""";
  @override
  String get setup_successful => """Uw PIN is succesvol ingesteld!""";
  @override
  String get wallet_keys => """Portemonnee zaad/sleutels""";
  @override
  String get wallet_seed => """Portemonnee zaad""";
  @override
  String get private_key => """Prive sleutel""";
  @override
  String get public_key => """Publieke sleutel""";
  @override
  String get view_key_private => """Bekijk sleutel (privaat)""";
  @override
  String get view_key_public => """Bekijk sleutel (openbaar)""";
  @override
  String get spend_key_private => """Sleutel uitgeven (privaat)""";
  @override
  String get spend_key_public => """Sleutel uitgeven (openbaar)""";
  @override
  String copied_key_to_clipboard(String key) => """Gekopieerd ${key} naar het klembord""";
  @override
  String get new_subaddress_title => """Nieuw adres""";
  @override
  String get new_subaddress_label_name => """Label naam""";
  @override
  String get new_subaddress_create => """Creëren""";
  @override
  String get subaddress_title => """Subadreslijst""";
  @override
  String get trade_details_title => """Handelsgegevens""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """Staat""";
  @override
  String get trade_details_fetching => """Ophalen""";
  @override
  String get trade_details_provider => """Leverancier""";
  @override
  String get trade_details_created_at => """Gemaakt bij""";
  @override
  String get trade_details_pair => """Paar""";
  @override
  String trade_details_copied(String title) => """${title} gekopieerd naar het klembord""";
  @override
  String get trade_history_title => """Handelsgeschiedenis""";
  @override
  String get transaction_details_title => """Transactie details""";
  @override
  String get transaction_details_transaction_id => """Transactie ID""";
  @override
  String get transaction_details_date => """Datum""";
  @override
  String get transaction_details_height => """Hoogte""";
  @override
  String get transaction_details_amount => """Bedrag""";
  @override
  String get transaction_details_fee => """Vergoeding""";
  @override
  String transaction_details_copied(String title) => """${title} gekopieerd naar het klembord""";
  @override
  String get transaction_details_recipient_address => """Adres van de ontvanger""";
  @override
  String get wallet_list_title => """Monero portemonnee""";
  @override
  String get wallet_list_create_new_wallet => """Maak een nieuwe portemonnee""";
  @override
  String get wallet_list_restore_wallet => """Portemonnee herstellen""";
  @override
  String get wallet_list_load_wallet => """Portemonnee laden""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """Bezig met laden ${wallet_name} portemonnee""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """Laden mislukt ${wallet_name} portemonnee. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """Verwijderen ${wallet_name} portemonnee""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """Verwijderen mislukt ${wallet_name} portemonnee. ${error}""";
  @override
  String get widgets_address => """Adres""";
  @override
  String get widgets_restore_from_blockheight => """Herstel vanaf blockheight""";
  @override
  String get widgets_restore_from_date => """Herstel vanaf datum""";
  @override
  String get widgets_or => """of""";
  @override
  String get widgets_seed => """Zaad""";
  @override
  String router_no_route(String name) => """Geen route gedefinieerd voor ${name}""";
  @override
  String get error_text_account_name => """Accountnaam mag alleen letters, cijfers bevatten
en moet tussen de 1 en 15 tekens lang zijn""";
  @override
  String get error_text_contact_name => """Naam contactpersoon kan niet bevatten ` , ' " symbolen
en moet tussen de 1 en 32 tekens lang zijn""";
  @override
  String get error_text_address => """Portemonnee-adres moet overeenkomen met het type
van cryptocurrency""";
  @override
  String get error_text_node_address => """Voer een iPv4-adres in""";
  @override
  String get error_text_node_port => """Knooppuntpoort kan alleen nummers tussen 0 en 65535 bevatten""";
  @override
  String get error_text_payment_id => """Betalings-ID kan alleen 16 tot 64 tekens bevatten in hexadecimale volgorde""";
  @override
  String get error_text_xmr => """XMR-waarde kan het beschikbare saldo niet overschrijden.
Het aantal breukcijfers moet kleiner zijn dan of gelijk zijn aan 12""";
  @override
  String get error_text_fiat => """Waarde van bedrag kan het beschikbare saldo niet overschrijden.
Het aantal breukcijfers moet kleiner zijn dan of gelijk zijn aan 2""";
  @override
  String get error_text_subaddress_name => """Naam subadres mag niet bevatten ` , ' " symbolen
en moet tussen de 1 en 20 tekens lang zijn""";
  @override
  String get error_text_amount => """Bedrag kan alleen cijfers bevatten""";
  @override
  String get error_text_wallet_name => """Naam portemonnee kan alleen letters, cijfers bevatten
en moet tussen de 1 en 20 tekens lang zijn""";
  @override
  String get error_text_keys => """Portefeuillesleutels kunnen maximaal 64 tekens bevatten in hexadecimale volgorde""";
  @override
  String get error_text_crypto_currency => """Het aantal breukcijfers
moet kleiner zijn dan of gelijk zijn aan 12""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """Ruil voor ${provider} is niet gemaakt. Bedrag is minder dan minimaal: ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """Ruil voor ${provider} is niet gemaakt. Bedrag is meer dan maximaal: ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """Ruil voor ${provider} is niet gemaakt. Beperkingen laden mislukt""";
  @override
  String get error_text_template => """Sjabloonnaam en -adres mogen niet bevatten ` , ' " symbolen
en moet tussen de 1 en 106 tekens lang zijn""";
  @override
  String get auth_store_ban_timeout => """time-out verbieden""";
  @override
  String get auth_store_banned_for => """Verboden voor """;
  @override
  String get auth_store_banned_minutes => """ notulen""";
  @override
  String get auth_store_incorrect_password => """Incorrect PIN""";
  @override
  String get wallet_store_monero_wallet => """Monero portemonnee""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """Onjuiste zaadlengte""";
  @override
  String get full_balance => """Volledig saldo""";
  @override
  String get available_balance => """Beschikbaar saldo""";
  @override
  String get hidden_balance => """Verborgen balans""";
  @override
  String get sync_status_syncronizing => """SYNCHRONISEREN""";
  @override
  String get sync_status_syncronized => """SYNCHRONIZED""";
  @override
  String get sync_status_not_connected => """NIET VERBONDEN""";
  @override
  String get sync_status_starting_sync => """BEGINNEN MET SYNCHRONISEREN""";
  @override
  String get sync_status_failed_connect => """LOSGEKOPPELD""";
  @override
  String get sync_status_connecting => """AANSLUITING""";
  @override
  String get sync_status_connected => """VERBONDEN""";
  @override
  String get transaction_priority_slow => """Langzaam""";
  @override
  String get transaction_priority_regular => """Regelmatig""";
  @override
  String get transaction_priority_medium => """Medium""";
  @override
  String get transaction_priority_fast => """Snel""";
  @override
  String get transaction_priority_fastest => """Snelste""";
  @override
  String trade_for_not_created(String title) => """Ruilen voor ${title} is niet gemaakt.""";
  @override
  String get trade_not_created => """Handel niet gecreëerd.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """Handel ${tradeId} van ${title} niet gevonden.""";
  @override
  String get trade_not_found => """Handel niet gevonden.""";
  @override
  String get trade_state_pending => """In afwachting""";
  @override
  String get trade_state_confirming => """Bevestiging""";
  @override
  String get trade_state_trading => """Handel""";
  @override
  String get trade_state_traded => """Traded""";
  @override
  String get trade_state_complete => """Compleet""";
  @override
  String get trade_state_to_be_created => """Om gecreëerd te worden""";
  @override
  String get trade_state_unpaid => """Onbetaald""";
  @override
  String get trade_state_underpaid => """Slecht betaald""";
  @override
  String get trade_state_paid_unconfirmed => """Niet bevestigd""";
  @override
  String get trade_state_paid => """Betaald""";
  @override
  String get trade_state_btc_sent => """Verzonden""";
  @override
  String get trade_state_timeout => """Time-out""";
  @override
  String get trade_state_created => """Gemaakt""";
  @override
  String get trade_state_finished => """Afgewerkt""";
  @override
  String get change_language => """Verander de taal""";
  @override
  String change_language_to(String language) => """Verander de taal in ${language}?""";
  @override
  String get paste => """Plakken""";
  @override
  String get restore_from_seed_placeholder => """Voer hier uw codefrase in of plak deze""";
  @override
  String get add_new_word => """Nieuw woord toevoegen""";
  @override
  String get incorrect_seed => """De ingevoerde tekst is niet geldig.""";
  @override
  String get biometric_auth_reason => """Scan uw vingerafdruk om te verifiëren""";
  @override
  String version(String currentVersion) => """Versie ${currentVersion}""";
  @override
  String get openalias_alert_title => """XMR-ontvanger gedetecteerd""";
  @override
  String openalias_alert_content(String recipient_name) => """U stuurt geld naar
${recipient_name}""";
  @override
  String get card_address => """Adres:""";
  @override
  String get buy => """Kopen""";
  @override
  String get placeholder_transactions => """Uw transacties worden hier weergegeven""";
  @override
  String get placeholder_contacts => """Je contacten worden hier weergegeven""";
  @override
  String get template => """Sjabloon""";
  @override
  String get confirm_delete_template => """Met deze actie wordt deze sjabloon verwijderd. Wilt u doorgaan?""";
  @override
  String get confirm_delete_wallet => """Met deze actie wordt deze portemonnee verwijderd. Wilt u doorgaan?""";
  @override
  String get picker_description => """Om ChangeNOW of MorphToken te kiezen, moet u eerst uw handelspaar wijzigen""";
  @override
  String get change_wallet_alert_title => """Wijzig huidige portemonnee""";
  @override
  String change_wallet_alert_content(String wallet_name) => """Wilt u de huidige portemonnee wijzigen in ${wallet_name}?""";
  @override
  String get creating_new_wallet => """Nieuwe portemonnee aanmaken""";
  @override
  String creating_new_wallet_error(String description) => """Fout: ${description}""";
  @override
  String get seed_alert_title => """Aandacht""";
  @override
  String get seed_alert_content => """Het zaad is de enige manier om uw portemonnee te herstellen. Heb je het opgeschreven?""";
  @override
  String get seed_alert_back => """Ga terug""";
  @override
  String get seed_alert_yes => """Ja ik heb""";
  @override
  String get wallet_name_alert_content => """Portemonnee met dezelfde naam bestaat""";
  @override
  String get exchange_sync_alert_content => """Wacht tot uw portemonnee is gesynchroniseerd""";
  @override
  String get pre_seed_title => """BELANGRIJK""";
  @override
  String pre_seed_description(String words) => """Op de volgende pagina ziet u een reeks van ${words} woorden. Dit is uw unieke en persoonlijke zaadje en het is de ENIGE manier om uw portemonnee te herstellen in geval van verlies of storing. Het is JOUW verantwoordelijkheid om het op te schrijven en op een veilige plaats op te slaan buiten de Cake Wallet app.""";
  @override
  String get pre_seed_button_text => """Ik begrijp het. Laat me mijn zaad zien""";
  @override
  String get xmr_to_error => """XMR.TO-fout""";
  @override
  String get xmr_to_error_description => """Ongeldige hoeveelheid. Maximaal 8 cijfers achter de komma""";
  @override
  String provider_error(String provider) => """${provider} fout""";
  @override
  String get use_ssl => """Gebruik SSL""";
  @override
  String get color_theme => """Kleur thema""";
  @override
  String get light_theme => """Licht""";
  @override
  String get bright_theme => """Helder""";
  @override
  String get dark_theme => """Donker""";
  @override
  String get enter_your_note => """Voer uw notitie in ...""";
  @override
  String get note_optional => """Opmerking (optioneel)""";
  @override
  String get note_tap_to_change => """Opmerking (tik om te wijzigen)""";
  @override
  String get transaction_key => """Transactiesleutel""";
  @override
  String get confirmations => """Bevestigingen""";
  @override
  String get recipient_address => """Adres ontvanger""";
  @override
  String get extra_id => """Extra ID:""";
  @override
  String get destination_tag => """Bestemmingstag:""";
  @override
  String get memo => """Memo:""";
  @override
  String get backup => """Back-up""";
  @override
  String get change_password => """Wachtwoord wijzigen""";
  @override
  String get backup_password => """Reservewachtwoord""";
  @override
  String get write_down_backup_password => """Noteer uw back-upwachtwoord, dat wordt gebruikt voor het importeren van uw back-upbestanden.""";
  @override
  String get export_backup => """Back-up exporteren""";
  @override
  String get save_backup_password => """Zorg ervoor dat u uw reservewachtwoord heeft opgeslagen. Zonder dit kunt u uw back-upbestanden niet importeren.""";
  @override
  String get backup_file => """Backup bestand""";
  @override
  String get edit_backup_password => """Bewerk back-upwachtwoord""";
  @override
  String get save_backup_password_alert => """Bewaar back-upwachtwoord""";
  @override
  String get change_backup_password_alert => """Uw vorige back-upbestanden kunnen niet worden geïmporteerd met een nieuw back-upwachtwoord. Het nieuwe back-upwachtwoord wordt alleen gebruikt voor nieuwe back-upbestanden. Weet u zeker dat u het back-upwachtwoord wilt wijzigen?""";
  @override
  String get enter_backup_password => """Voer hier een back-upwachtwoord in""";
  @override
  String get select_backup_file => """Selecteer een back-upbestand""";
  @override
  String get import => """Importeren""";
  @override
  String get please_select_backup_file => """Selecteer een back-upbestand en voer een back-upwachtwoord in.""";
  @override
  String get fixed_rate => """Vast tarief""";
  @override
  String get fixed_rate_alert => """U kunt het ontvangen bedrag invoeren wanneer de modus voor vaste tarieven is aangevinkt. Wilt u overschakelen naar de vaste-tariefmodus?""";
  @override
  String get xlm_extra_info => """Vergeet niet om de Memo-ID op te geven tijdens het verzenden van de XLM-transactie voor de uitwisseling""";
  @override
  String get xrp_extra_info => """Vergeet niet om de Destination Tag op te geven tijdens het verzenden van de XRP-transactie voor de uitwisseling""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Als u XMR wilt omwisselen van uw Cake Wallet Monero-saldo, moet u eerst overschakelen naar uw Monero-portemonnee.""";
  @override
  String get confirmed => """Bevestigd""";
  @override
  String get unconfirmed => """Niet bevestigd""";
  @override
  String get displayable => """Weer te geven""";
  @override
  String get submit_request => """een verzoek indienen""";
  @override
  String get buy_alert_content => """Momenteel ondersteunen we alleen de aankoop van Bitcoin en Litecoin. Om Bitcoin of Litecoin te kopen, maakt u uw Bitcoin- of Litecoin-portemonnee aan of schakelt u over naar deze.""";
  @override
  String get outdated_electrum_wallet_description => """Nieuwe Bitcoin-portefeuilles die in Cake zijn gemaakt, hebben nu een zaadje van 24 woorden. Het is verplicht dat u een nieuwe Bitcoin-portemonnee maakt en al uw geld overmaakt naar de nieuwe portemonnee van 24 woorden, en stopt met het gebruik van wallets met een seed van 12 woorden. Doe dit onmiddellijk om uw geld veilig te stellen.""";
  @override
  String get understand => """Ik begrijp het""";
  @override
  String get apk_update => """APK-update""";
  @override
  String get buy_bitcoin => """Koop Bitcoin""";
  @override
  String get buy_with => """Koop met""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """Waarde van het bedrag moet meer of gelijk zijn aan ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """Als deze portemonnee een seed van 12 woorden heeft en is gemaakt in Cake, stort dan GEEN Bitcoin in deze portemonnee. Elke BTC die naar deze portemonnee is overgebracht, kan verloren gaan. Maak een nieuwe portemonnee van 24 woorden (tik op het menu rechtsboven, selecteer Portefeuilles, kies Nieuwe portemonnee maken en selecteer vervolgens Bitcoin) en verplaats je BTC ONMIDDELLIJK daar. Nieuwe (24-woorden) BTC-portefeuilles van Cake zijn veilig""";
  @override
  String get do_not_show_me => """laat me dit niet opnieuw zien""";
  @override
  String get unspent_coins_title => """Ongebruikte munten""";
  @override
  String get unspent_coins_details_title => """Details van niet-uitgegeven munten""";
  @override
  String get freeze => """Bevriezen""";
  @override
  String get coin_control => """Muntcontrole (optioneel)""";
  @override
  String get address_detected => """Adres gedetecteerd""";
  @override
  String address_from_domain(String domain) => """Je adres is van unstoppable domain ${domain}""";
}

class $zh extends S {
  const $zh();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """欢迎使用""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """很棒的门罗币和比特币钱包""";
  @override
  String get please_make_selection => """请在下面进行选择 创建或恢复您的钱包.""";
  @override
  String get create_new => """创建新钱包""";
  @override
  String get restore_wallet => """恢复钱包""";
  @override
  String get accounts => """账户""";
  @override
  String get edit => """编辑""";
  @override
  String get account => """帐户""";
  @override
  String get add => """添加""";
  @override
  String get address_book => """地址簿""";
  @override
  String get contact => """联系""";
  @override
  String get please_select => """请选择:""";
  @override
  String get cancel => """取消""";
  @override
  String get ok => """确认""";
  @override
  String get contact_name => """联系人姓名""";
  @override
  String get reset => """重置""";
  @override
  String get save => """保存""";
  @override
  String get address_remove_contact => """刪除联系人""";
  @override
  String get address_remove_content => """您确定要刪除所选的联系人吗？""";
  @override
  String get authenticated => """已认证""";
  @override
  String get authentication => """认证方式""";
  @override
  String failed_authentication(String state_error) => """身份验证失败. ${state_error}""";
  @override
  String get wallet_menu => """钱包菜单""";
  @override
  String Blocks_remaining(String status) => """${status} 剩余的块""";
  @override
  String get please_try_to_connect_to_another_node => """请尝试连接到其他节点""";
  @override
  String get xmr_hidden => """隐藏""";
  @override
  String get xmr_available_balance => """可用余额 """;
  @override
  String get xmr_full_balance => """全部余额""";
  @override
  String get send => """发送""";
  @override
  String get receive => """接收""";
  @override
  String get transactions => """交易情况""";
  @override
  String get incoming => """收到""";
  @override
  String get outgoing => """发送""";
  @override
  String get transactions_by_date => """按日期交易""";
  @override
  String get trades => """交易""";
  @override
  String get filters => """过滤""";
  @override
  String get today => """今天""";
  @override
  String get yesterday => """昨天""";
  @override
  String get received => """已收到""";
  @override
  String get sent => """已发送""";
  @override
  String get pending => """ (待定)""";
  @override
  String get rescan => """重新扫描""";
  @override
  String get reconnect => """重新连接""";
  @override
  String get wallets => """钱包""";
  @override
  String get show_seed => """显示种子""";
  @override
  String get show_keys => """显示种子/密钥""";
  @override
  String get address_book_menu => """地址簿""";
  @override
  String get reconnection => """重新连接""";
  @override
  String get reconnect_alert_text => """您确定要重新连接吗？""";
  @override
  String get exchange => """兑换""";
  @override
  String get clear => """清空""";
  @override
  String get refund_address => """退款地址""";
  @override
  String get change_exchange_provider => """更改交易所""";
  @override
  String get you_will_send => """转换自""";
  @override
  String get you_will_get => """转换到""";
  @override
  String get amount_is_guaranteed => """保证收到的金额""";
  @override
  String get amount_is_estimate => """收款金额为估算值""";
  @override
  String powered_by(String title) => """Powered by ${title}""";
  @override
  String get error => """错误""";
  @override
  String get estimated => """估计值""";
  @override
  String min_value(String value, String currency) => """最低: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """最高: ${value} ${currency}""";
  @override
  String get change_currency => """更改币种""";
  @override
  String get copy_id => """复制ID""";
  @override
  String get exchange_result_write_down_trade_id => """请复制或写下交易编号以继续.""";
  @override
  String get trade_id => """交易编号:""";
  @override
  String get copied_to_clipboard => """复制到剪贴板""";
  @override
  String get saved_the_trade_id => """我已经保存了交易编号""";
  @override
  String get fetching => """正在获取""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """金额: """;
  @override
  String get payment_id => """付款 ID: """;
  @override
  String get status => """状态: """;
  @override
  String get offer_expires_in => """优惠有效期至 """;
  @override
  String trade_is_powered_by(String provider) => """该交易由 ${provider}""";
  @override
  String get copy_address => """复制地址""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """点击确认 您将发送 ${fetchingLabel} ${from} 从你的钱包里 ${walletName} 到下面显示的地址。 或者您可以从外部钱包发送到以下地址/ QR码。

请按确认继续或返回以更改金额""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """您必须至少发送 ${fetchingLabel} ${from} 到下一页上显示的地址。 如果您发送的金额少于 ${fetchingLabel} ${from}，则可能无法转换，因此无法退还。""";
  @override
  String get exchange_result_write_down_ID => """*请复制或写下您上面显示的ID.""";
  @override
  String get confirm => """确认""";
  @override
  String get confirm_sending => """确认发送""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """提交交易
金额: ${amount}
手续费: ${fee}""";
  @override
  String get sending => """正在发送""";
  @override
  String get transaction_sent => """交易已发送""";
  @override
  String get expired => """已过期""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """发送 XMR""";
  @override
  String get exchange_new_template => """新模板""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """输入密码""";
  @override
  String get loading_your_wallet => """加载您的钱包""";
  @override
  String get new_wallet => """新钱包""";
  @override
  String get wallet_name => """钱包名称""";
  @override
  String get continue_text => """继续""";
  @override
  String get choose_wallet_currency => """请选择钱包货币：""";
  @override
  String get node_new => """新节点""";
  @override
  String get node_address => """节点地址""";
  @override
  String get node_port => """节点端口""";
  @override
  String get login => """登录""";
  @override
  String get password => """密码""";
  @override
  String get nodes => """节点""";
  @override
  String get node_reset_settings_title => """重新设置""";
  @override
  String get nodes_list_reset_to_default_message => """您确定要将设置重设为默认值吗？""";
  @override
  String change_current_node(String node) => """您确定将当前节点更改为 ${node}?""";
  @override
  String get change => """更改""";
  @override
  String get remove_node => """删除节点""";
  @override
  String get remove_node_message => """您确定要删除所选节点吗？""";
  @override
  String get remove => """确定""";
  @override
  String get delete => """删除""";
  @override
  String get add_new_node => """添加新节点""";
  @override
  String get change_current_node_title => """更改当前节点""";
  @override
  String get node_test => """测试""";
  @override
  String get node_connection_successful => """连接成功""";
  @override
  String get node_connection_failed => """连接失败""";
  @override
  String get new_node_testing => """新节点测试""";
  @override
  String get use => """切换使用""";
  @override
  String get digit_pin => """位 PIN""";
  @override
  String get share_address => """分享地址""";
  @override
  String get receive_amount => """金额""";
  @override
  String get subaddresses => """子地址""";
  @override
  String get addresses => """地址""";
  @override
  String get scan_qr_code => """扫描二维码获取地址""";
  @override
  String get rename => """重命名""";
  @override
  String get choose_account => """选择账户""";
  @override
  String get create_new_account => """建立新账户""";
  @override
  String get accounts_subaddresses => """账户和子地址""";
  @override
  String get restore_restore_wallet => """恢复钱包""";
  @override
  String get restore_title_from_seed_keys => """从种子/密钥还原""";
  @override
  String get restore_description_from_seed_keys => """从保存到安全地方的种子/钥匙取回钱包""";
  @override
  String get restore_next => """下一个""";
  @override
  String get restore_title_from_backup => """从备份文件还原""";
  @override
  String get restore_description_from_backup => """您可以从还原整个Cake Wallet应用您的备份文件""";
  @override
  String get restore_seed_keys_restore => """种子/密钥还原""";
  @override
  String get restore_title_from_seed => """从种子还原""";
  @override
  String get restore_description_from_seed => """从25个字中恢复您的钱包或13个字的组合码""";
  @override
  String get restore_title_from_keys => """从密钥还原""";
  @override
  String get restore_description_from_keys => """使用私钥恢复钱包""";
  @override
  String get restore_wallet_name => """钱包名称""";
  @override
  String get restore_address => """地址""";
  @override
  String get restore_view_key_private => """View私钥""";
  @override
  String get restore_spend_key_private => """Spend私钥""";
  @override
  String get restore_recover => """恢复""";
  @override
  String get restore_wallet_restore_description => """钱包还原说明""";
  @override
  String get restore_new_seed => """新种子""";
  @override
  String get restore_active_seed => """活动种子""";
  @override
  String get restore_bitcoin_description_from_seed => """从24个文字的组成码恢复您的钱包""";
  @override
  String get restore_bitcoin_description_from_keys => """从私钥中生成的WIF字符串恢复您钱包""";
  @override
  String get restore_bitcoin_title_from_keys => """从WIF还原""";
  @override
  String get restore_from_date_or_blockheight => """请输入您创建这个钱包前几天的日期。或者如果您知道区块高度，请输入区块高度""";
  @override
  String get seed_reminder => """请记下这些内容，以防丟失或数据损坏""";
  @override
  String get seed_title => """种子""";
  @override
  String get seed_share => """分享种子""";
  @override
  String get copy => """复制""";
  @override
  String get seed_language_choose => """请选择种子语言:""";
  @override
  String get seed_choose => """选择种子语言""";
  @override
  String get seed_language_next => """下一个""";
  @override
  String get seed_language_english => """英文""";
  @override
  String get seed_language_chinese => """中文""";
  @override
  String get seed_language_dutch => """荷兰文""";
  @override
  String get seed_language_german => """德文""";
  @override
  String get seed_language_japanese => """日文""";
  @override
  String get seed_language_portuguese => """葡萄牙文""";
  @override
  String get seed_language_russian => """俄文""";
  @override
  String get seed_language_spanish => """西班牙文""";
  @override
  String get send_title => """发送""";
  @override
  String get send_your_wallet => """你的钱包""";
  @override
  String send_address(String cryptoCurrency) => """${cryptoCurrency} 地址""";
  @override
  String get send_payment_id => """付款编号 (可选的)""";
  @override
  String get all => """全部""";
  @override
  String get send_error_minimum_value => """最小金额为0.01""";
  @override
  String get send_error_currency => """货币只能包含数字""";
  @override
  String get send_estimated_fee => """预估费用:""";
  @override
  String send_priority(String transactionPriority) => """目前，费用设置为 ${transactionPriority} 优先.
交易优先级可以在设置中进行调整""";
  @override
  String get send_creating_transaction => """创建交易""";
  @override
  String get send_templates => """模板""";
  @override
  String get send_new => """新建""";
  @override
  String get send_amount => """金额:""";
  @override
  String get send_fee => """手续费:""";
  @override
  String get send_name => """名称""";
  @override
  String get send_got_it => """明白""";
  @override
  String get send_sending => """正在发送...""";
  @override
  String send_success(String crypto) => """您的${crypto}已成功发送""";
  @override
  String get settings_title => """设定值""";
  @override
  String get settings_nodes => """节点数""";
  @override
  String get settings_current_node => """当前节点""";
  @override
  String get settings_wallets => """钱包""";
  @override
  String get settings_display_balance_as => """将余额显示为""";
  @override
  String get settings_currency => """货币""";
  @override
  String get settings_fee_priority => """交易优先级""";
  @override
  String get settings_save_recipient_address => """保存收件人地址""";
  @override
  String get settings_personal => """个人""";
  @override
  String get settings_change_pin => """更改密码""";
  @override
  String get settings_change_language => """修改语言""";
  @override
  String get settings_allow_biometrical_authentication => """允许生物识别认证""";
  @override
  String get settings_dark_mode => """黑暗模式""";
  @override
  String get settings_transactions => """交易情况""";
  @override
  String get settings_trades => """交易""";
  @override
  String get settings_display_on_dashboard_list => """显示在仪表板上""";
  @override
  String get settings_all => """全部""";
  @override
  String get settings_only_trades => """只交易""";
  @override
  String get settings_only_transactions => """仅交易""";
  @override
  String get settings_none => """没有""";
  @override
  String get settings_support => """帮助""";
  @override
  String get settings_terms_and_conditions => """条款和条件""";
  @override
  String get pin_is_incorrect => """PIN码不正确""";
  @override
  String get setup_pin => """设定PIN码""";
  @override
  String get enter_your_pin_again => """再次输入您的PIN码""";
  @override
  String get setup_successful => """您的PIN码已成功设置!""";
  @override
  String get wallet_keys => """钱包种子/密钥""";
  @override
  String get wallet_seed => """钱包种子""";
  @override
  String get private_key => """私钥""";
  @override
  String get public_key => """公钥""";
  @override
  String get view_key_private => """View 密钥(私钥)""";
  @override
  String get view_key_public => """View 密钥(公钥)""";
  @override
  String get spend_key_private => """Spend 密钥 (私钥)""";
  @override
  String get spend_key_public => """Spend 密钥 (公钥)""";
  @override
  String copied_key_to_clipboard(String key) => """复制 ${key} 到剪贴板""";
  @override
  String get new_subaddress_title => """新地址""";
  @override
  String get new_subaddress_label_name => """标签名称""";
  @override
  String get new_subaddress_create => """创建""";
  @override
  String get subaddress_title => """子地址列表""";
  @override
  String get trade_details_title => """交易明细""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """条件""";
  @override
  String get trade_details_fetching => """正在获取""";
  @override
  String get trade_details_provider => """提供者""";
  @override
  String get trade_details_created_at => """创建于""";
  @override
  String get trade_details_pair => """对""";
  @override
  String trade_details_copied(String title) => """${title} 复制到剪贴板""";
  @override
  String get trade_history_title => """交易历史""";
  @override
  String get transaction_details_title => """交易明细""";
  @override
  String get transaction_details_transaction_id => """交易编号""";
  @override
  String get transaction_details_date => """日期""";
  @override
  String get transaction_details_height => """区块高度""";
  @override
  String get transaction_details_amount => """金额""";
  @override
  String get transaction_details_fee => """手续费""";
  @override
  String transaction_details_copied(String title) => """${title} 复制到剪切板""";
  @override
  String get transaction_details_recipient_address => """收件人地址""";
  @override
  String get wallet_list_title => """Monero 钱包""";
  @override
  String get wallet_list_create_new_wallet => """创建新钱包""";
  @override
  String get wallet_list_restore_wallet => """恢复钱包""";
  @override
  String get wallet_list_load_wallet => """加载钱包""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """载入中 ${wallet_name} 钱包""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """加载失败 ${wallet_name} 钱包. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """删除 ${wallet_name} 钱包""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """删除失败 ${wallet_name} 钱包. ${error}""";
  @override
  String get widgets_address => """地址""";
  @override
  String get widgets_restore_from_blockheight => """从块高还原""";
  @override
  String get widgets_restore_from_date => """从日期还原""";
  @override
  String get widgets_or => """或者""";
  @override
  String get widgets_seed => """种子""";
  @override
  String router_no_route(String name) => """未定义路线 ${name}""";
  @override
  String get error_text_account_name => """帐户名称只能包含字母数字
且必须介于1到15个字符之间""";
  @override
  String get error_text_contact_name => """联系人姓名不能包含`，' " 符号
并且必须介于1到32个字符之间""";
  @override
  String get error_text_address => """钱包地址必须与类型对应
加密货币""";
  @override
  String get error_text_node_address => """请输入一个IPv4地址""";
  @override
  String get error_text_node_port => """节点端口只能包含0到65535之间的数字""";
  @override
  String get error_text_payment_id => """付款ID只能包含16到64个字符（十六进制）""";
  @override
  String get error_text_xmr => """XMR值不能超过可用余额.
小数位数必须小于或等于12""";
  @override
  String get error_text_fiat => """金额不能超过可用余额.
小数位数必须小于或等于2""";
  @override
  String get error_text_subaddress_name => """子地址名称不能包含`，' " 符号
并且必须在1到20个字符之间""";
  @override
  String get error_text_amount => """金额只能包含数字""";
  @override
  String get error_text_wallet_name => """钱包名称只能包含字母，数字
且必须介于1到20个字符之间""";
  @override
  String get error_text_keys => """钱包密钥只能包含16个字符的十六进制字符""";
  @override
  String get error_text_crypto_currency => """小数位数
必须小于或等于12""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """未创建 ${provider} 交易。 金额小于最小值：${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """未创建 ${provider} 交易。 金额大于最大值：${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """未创建 ${provider} 交易。 限制加载失败""";
  @override
  String get error_text_template => """模板名称和地址不能包含`，' " 符号
并且必须在1到106个字符之间""";
  @override
  String get auth_store_ban_timeout => """禁止超时""";
  @override
  String get auth_store_banned_for => """禁止 """;
  @override
  String get auth_store_banned_minutes => """ 分钟""";
  @override
  String get auth_store_incorrect_password => """PIN码错误""";
  @override
  String get wallet_store_monero_wallet => """Monero 钱包""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """种子长度错误""";
  @override
  String get full_balance => """全部余额""";
  @override
  String get available_balance => """可用余额""";
  @override
  String get hidden_balance => """隐藏余额""";
  @override
  String get sync_status_syncronizing => """正在同步""";
  @override
  String get sync_status_syncronized => """已同步""";
  @override
  String get sync_status_not_connected => """未连接""";
  @override
  String get sync_status_starting_sync => """开始同步""";
  @override
  String get sync_status_failed_connect => """断线""";
  @override
  String get sync_status_connecting => """连接中""";
  @override
  String get sync_status_connected => """已连接""";
  @override
  String get transaction_priority_slow => """慢速""";
  @override
  String get transaction_priority_regular => """常规""";
  @override
  String get transaction_priority_medium => """中等""";
  @override
  String get transaction_priority_fast => """快速""";
  @override
  String get transaction_priority_fastest => """最快""";
  @override
  String trade_for_not_created(String title) => """交易 ${title} 未创建.""";
  @override
  String get trade_not_created => """未建立交易.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """交易方式 ${tradeId} 的 ${title} 未找到.""";
  @override
  String get trade_not_found => """找不到交易.""";
  @override
  String get trade_state_pending => """待定""";
  @override
  String get trade_state_confirming => """确认中""";
  @override
  String get trade_state_trading => """交易""";
  @override
  String get trade_state_traded => """已交易""";
  @override
  String get trade_state_complete => """完成""";
  @override
  String get trade_state_to_be_created => """待创建""";
  @override
  String get trade_state_unpaid => """未付""";
  @override
  String get trade_state_underpaid => """支付不足""";
  @override
  String get trade_state_paid_unconfirmed => """付费未确认""";
  @override
  String get trade_state_paid => """已付费""";
  @override
  String get trade_state_btc_sent => """已发送""";
  @override
  String get trade_state_timeout => """超时""";
  @override
  String get trade_state_created => """已建立""";
  @override
  String get trade_state_finished => """已完成""";
  @override
  String get change_language => """修改语言""";
  @override
  String change_language_to(String language) => """修改语言为 ${language}?""";
  @override
  String get paste => """粘贴""";
  @override
  String get restore_from_seed_placeholder => """请在此处输入或粘贴您的代码短语""";
  @override
  String get add_new_word => """添加新词""";
  @override
  String get incorrect_seed => """输入的文字无效。""";
  @override
  String get biometric_auth_reason => """扫描指纹进行身份认证""";
  @override
  String version(String currentVersion) => """版本 ${currentVersion}""";
  @override
  String get openalias_alert_title => """检测到XMR收件人""";
  @override
  String openalias_alert_content(String recipient_name) => """您将汇款至
${recipient_name}""";
  @override
  String get card_address => """地址:""";
  @override
  String get buy => """购买""";
  @override
  String get placeholder_transactions => """您的交易将显示在这里""";
  @override
  String get placeholder_contacts => """您的联系人将显示在这里""";
  @override
  String get template => """模板""";
  @override
  String get confirm_delete_template => """此操作将刪除此模板。确定吗？""";
  @override
  String get confirm_delete_wallet => """此操作将刪除此钱包。确定吗？""";
  @override
  String get picker_description => """要选择ChangeNOW或MorphToken，请先更改您的交易币""";
  @override
  String get change_wallet_alert_title => """更换当前钱包""";
  @override
  String change_wallet_alert_content(String wallet_name) => """您是否想将当前钱包改为 ${wallet_name}?""";
  @override
  String get creating_new_wallet => """创建新钱包""";
  @override
  String creating_new_wallet_error(String description) => """错误： ${description}""";
  @override
  String get seed_alert_title => """注意""";
  @override
  String get seed_alert_content => """种子是恢复钱包的唯一方法。记住了吗？""";
  @override
  String get seed_alert_back => """返回""";
  @override
  String get seed_alert_yes => """确定""";
  @override
  String get wallet_name_alert_content => """存在同名錢包""";
  @override
  String get exchange_sync_alert_content => """请等待，直到您的钱包同步""";
  @override
  String get pre_seed_title => """重要""";
  @override
  String pre_seed_description(String words) => """在下一页上，您将看到${words}个文字。 这是您独有的种子，是丟失或出现故障时恢复钱包的唯一方法。 您有必须将其写下并储存在Cake Wallet应用程序以外的安全地方。""";
  @override
  String get pre_seed_button_text => """我明白。 查看种子""";
  @override
  String get xmr_to_error => """XMR.TO 错误""";
  @override
  String get xmr_to_error_description => """无效的金额。 小数点后最多8位数字""";
  @override
  String provider_error(String provider) => """${provider} 错误""";
  @override
  String get use_ssl => """使用SSL""";
  @override
  String get color_theme => """主题""";
  @override
  String get light_theme => """艳丽""";
  @override
  String get bright_theme => """明亮""";
  @override
  String get dark_theme => """黑暗""";
  @override
  String get enter_your_note => """输入您的笔记...""";
  @override
  String get note_optional => """注释（可选）""";
  @override
  String get note_tap_to_change => """注释（轻按即可更改）""";
  @override
  String get transaction_key => """交易密码""";
  @override
  String get confirmations => """确认""";
  @override
  String get recipient_address => """收件人地址""";
  @override
  String get extra_id => """额外ID:""";
  @override
  String get destination_tag => """目标Tag:""";
  @override
  String get memo => """备忘录:""";
  @override
  String get backup => """备份""";
  @override
  String get change_password => """更改密码""";
  @override
  String get backup_password => """备份密码""";
  @override
  String get write_down_backup_password => """请写下您的备份密码，该密码用于导入备份文件。""";
  @override
  String get export_backup => """导出备份""";
  @override
  String get save_backup_password => """请确保您已保存备份密码。 沒有它，您将无法导入备份文件。""";
  @override
  String get backup_file => """备份文件""";
  @override
  String get edit_backup_password => """编辑备份密码""";
  @override
  String get save_backup_password_alert => """保存备份密码""";
  @override
  String get change_backup_password_alert => """您以前的备份文件将无法使用新的备份密码導入。 新的备份密码将仅用于新的备份文件。 您确定要更改备份密码吗？""";
  @override
  String get enter_backup_password => """在此处输入備用密码""";
  @override
  String get select_backup_file => """选择备份文件""";
  @override
  String get import => """导入""";
  @override
  String get please_select_backup_file => """请选择备份文件，然后输入备份密码。""";
  @override
  String get fixed_rate => """固定汇率""";
  @override
  String get fixed_rate_alert => """选中固定汇率模式后，您将可以输入接收金额。 您要切换到固定汇率模式吗？""";
  @override
  String get xlm_extra_info => """发送用于交换的XLM交易时，请不要忘记指定备忘录ID""";
  @override
  String get xrp_extra_info => """发送用于交换的XRP交易时，请不要忘记指定目标Tag""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """如果要从Cake Wallet Monero余额中兑换XMR，请先切换到Monero钱包。""";
  @override
  String get confirmed => """已确认""";
  @override
  String get unconfirmed => """未经证实""";
  @override
  String get displayable => """可显示""";
  @override
  String get submit_request => """提交请求""";
  @override
  String get buy_alert_content => """目前我们只支持购买比特币和莱特币。 要购买比特币或莱特币，请创建或切换到您的比特币或莱特币钱包。""";
  @override
  String get outdated_electrum_wallet_description => """在Cake创建的新比特币钱包现在有一个24字的种子。你必须创建一个新的比特币钱包，并将你所有的资金转移到新的24字钱包，并停止使用12字种子的钱包。请立即这样做以保证你的资金安全。""";
  @override
  String get understand => """我已知晓""";
  @override
  String get apk_update => """APK更新""";
  @override
  String get buy_bitcoin => """购买比特币""";
  @override
  String get buy_with => """一起购买""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """金额的价值必须大于或等于 ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """如果这个钱包有一个 12 字的种子并且是在 Cake 中创建的，不要将比特币存入这个钱包。 任何转移到此钱包的 BTC 都可能丢失。 创建一个新的 24 字钱包（点击右上角的菜单，选择钱包，选择创建新钱包，然后选择比特币）并立即将您的 BTC 移到那里。 Cake 的新（24 字）BTC 钱包是安全的""";
  @override
  String get do_not_show_me => """不再提示""";
  @override
  String get unspent_coins_title => """未使用的硬幣""";
  @override
  String get unspent_coins_details_title => """未使用代幣詳情""";
  @override
  String get freeze => """凍結""";
  @override
  String get coin_control => """硬幣控制（可選）""";
  @override
  String get address_detected => """檢測到地址""";
  @override
  String address_from_domain(String domain) => """您有以下地址 unstoppable domain ${domain}""";
}

class $ru extends S {
  const $ru();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """Приветствуем в""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """В самом удобном кошельке для Monero и Bitcoin""";
  @override
  String get please_make_selection => """Выберите способ создания кошелька: создать новый или восстановить ваш существующий.""";
  @override
  String get create_new => """Создать новый кошелёк""";
  @override
  String get restore_wallet => """Восстановить кошелёк""";
  @override
  String get accounts => """Аккаунты""";
  @override
  String get edit => """Редактировать""";
  @override
  String get account => """Аккаунт""";
  @override
  String get add => """Добавить""";
  @override
  String get address_book => """Адресная книга""";
  @override
  String get contact => """Контакт""";
  @override
  String get please_select => """Пожалуйста, выберите:""";
  @override
  String get cancel => """Отменить""";
  @override
  String get ok => """OK""";
  @override
  String get contact_name => """Имя контакта""";
  @override
  String get reset => """Сброс""";
  @override
  String get save => """Сохранить""";
  @override
  String get address_remove_contact => """Удалить контакт""";
  @override
  String get address_remove_content => """Вы уверены, что хотите удалить выбранный контакт?""";
  @override
  String get authenticated => """Аутентифицировано""";
  @override
  String get authentication => """Аутентификация""";
  @override
  String failed_authentication(String state_error) => """Ошибка аутентификации. ${state_error}""";
  @override
  String get wallet_menu => """Меню кошелька""";
  @override
  String Blocks_remaining(String status) => """${status} Осталось блоков""";
  @override
  String get please_try_to_connect_to_another_node => """Пожалуйста, попробуйте подключиться к другой ноде""";
  @override
  String get xmr_hidden => """Скрыто""";
  @override
  String get xmr_available_balance => """Доступный баланс""";
  @override
  String get xmr_full_balance => """Весь баланс""";
  @override
  String get send => """Отправить""";
  @override
  String get receive => """Получить""";
  @override
  String get transactions => """Транзакции""";
  @override
  String get incoming => """Входящие""";
  @override
  String get outgoing => """Исходящие""";
  @override
  String get transactions_by_date => """Сортировать по дате""";
  @override
  String get trades => """Сделки""";
  @override
  String get filters => """Фильтр""";
  @override
  String get today => """Сегодня""";
  @override
  String get yesterday => """Вчера""";
  @override
  String get received => """Полученные""";
  @override
  String get sent => """Отправленные""";
  @override
  String get pending => """ (в ожидании)""";
  @override
  String get rescan => """Пересканировать""";
  @override
  String get reconnect => """Переподключиться""";
  @override
  String get wallets => """Кошельки""";
  @override
  String get show_seed => """Показать мнемоническую фразу""";
  @override
  String get show_keys => """Показать мнемоническую фразу/ключи""";
  @override
  String get address_book_menu => """Адресная книга""";
  @override
  String get reconnection => """Переподключение""";
  @override
  String get reconnect_alert_text => """Вы хотите переподключиться?""";
  @override
  String get exchange => """Обмен""";
  @override
  String get clear => """Очистить""";
  @override
  String get refund_address => """Адрес возврата""";
  @override
  String get change_exchange_provider => """Изменить провайдера обмена""";
  @override
  String get you_will_send => """Конвертировать из""";
  @override
  String get you_will_get => """Конвертировать в""";
  @override
  String get amount_is_guaranteed => """Полученная сумма гарантирована""";
  @override
  String get amount_is_estimate => """Полученная сумма является приблизительной""";
  @override
  String powered_by(String title) => """Используя ${title}""";
  @override
  String get error => """Ошибка""";
  @override
  String get estimated => """Примерно""";
  @override
  String min_value(String value, String currency) => """Мин: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """Макс: ${value} ${currency}""";
  @override
  String get change_currency => """Изменить валюту""";
  @override
  String get copy_id => """Скопировать ID""";
  @override
  String get exchange_result_write_down_trade_id => """Пожалуйста, скопируйте или запишите ID сделки.""";
  @override
  String get trade_id => """ID сделки:""";
  @override
  String get copied_to_clipboard => """Скопировано в буфер обмена""";
  @override
  String get saved_the_trade_id => """Я сохранил ID сделки""";
  @override
  String get fetching => """Загрузка""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """Сумма: """;
  @override
  String get payment_id => """ID платежа: """;
  @override
  String get status => """Статус: """;
  @override
  String get offer_expires_in => """Предложение истекает через: """;
  @override
  String trade_is_powered_by(String provider) => """Сделка выполнена через ${provider}""";
  @override
  String get copy_address => """Cкопировать адрес""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """Нажимая подтвердить, вы отправите ${fetchingLabel} ${from} с вашего кошелька ${walletName} на адрес указанный ниже. Или вы можете отправить со своего внешнего кошелька на нижеуказанный адрес/QR-код.

Пожалуйста, нажмите подтвердить для продолжения, или вернитесь назад для изменения суммы.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """Вы должны отправить минимум ${fetchingLabel} ${from} на адрес, указанный на следующей странице. Если вы отправите сумму менее ${fetchingLabel} ${from}, то она может быть не конвертирована и не возвращена.""";
  @override
  String get exchange_result_write_down_ID => """*Пожалуйста, скопируйте или запишите ID, указанный выше.""";
  @override
  String get confirm => """Подтвердить""";
  @override
  String get confirm_sending => """Подтвердить отправку""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """Подтвердить транзакцию 
Сумма: ${amount}
Комиссия: ${fee}""";
  @override
  String get sending => """Отправка""";
  @override
  String get transaction_sent => """Tранзакция отправлена!""";
  @override
  String get expired => """Истекает""";
  @override
  String time(String minutes, String seconds) => """${minutes}мин ${seconds}сек""";
  @override
  String get send_xmr => """Отправить XMR""";
  @override
  String get exchange_new_template => """Новый шаблон""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """Введите ваш PIN""";
  @override
  String get loading_your_wallet => """Загрузка кошелька""";
  @override
  String get new_wallet => """Новый кошелёк""";
  @override
  String get wallet_name => """Имя кошелька""";
  @override
  String get continue_text => """Продолжить""";
  @override
  String get choose_wallet_currency => """Пожалуйста, выберите валюту кошелька:""";
  @override
  String get node_new => """Новая нода""";
  @override
  String get node_address => """Адрес ноды""";
  @override
  String get node_port => """Порт ноды""";
  @override
  String get login => """Логин""";
  @override
  String get password => """Пароль""";
  @override
  String get nodes => """Ноды""";
  @override
  String get node_reset_settings_title => """Сбросить настройки""";
  @override
  String get nodes_list_reset_to_default_message => """Вы уверены, что хотите сбросить настройки до значений по умолчанию?""";
  @override
  String change_current_node(String node) => """Вы уверены, что хотите изменить текущую ноду на ${node}?""";
  @override
  String get change => """Изменить""";
  @override
  String get remove_node => """Удалить ноду""";
  @override
  String get remove_node_message => """Вы уверены, что хотите удалить текущую ноду?""";
  @override
  String get remove => """Удалить""";
  @override
  String get delete => """Удалить""";
  @override
  String get add_new_node => """Добавить новую ноду""";
  @override
  String get change_current_node_title => """Изменить текущую ноду""";
  @override
  String get node_test => """Тест""";
  @override
  String get node_connection_successful => """Подключение прошло успешно""";
  @override
  String get node_connection_failed => """Подключение не удалось""";
  @override
  String get new_node_testing => """Тестирование новой ноды""";
  @override
  String get use => """Использовать """;
  @override
  String get digit_pin => """-значный PIN""";
  @override
  String get share_address => """Поделиться адресом""";
  @override
  String get receive_amount => """Сумма""";
  @override
  String get subaddresses => """Субадреса""";
  @override
  String get addresses => """Адреса""";
  @override
  String get scan_qr_code => """Отсканируйте QR-код для получения адреса""";
  @override
  String get rename => """Переименовать""";
  @override
  String get choose_account => """Выберите аккаунт""";
  @override
  String get create_new_account => """Создать новый аккаунт""";
  @override
  String get accounts_subaddresses => """Аккаунты и субадреса""";
  @override
  String get restore_restore_wallet => """Восстановить кошелёк""";
  @override
  String get restore_title_from_seed_keys => """Восстановить из мнемонической фразы/ключей""";
  @override
  String get restore_description_from_seed_keys => """Вы можете восстановить кошелёк из мнемонической фразы/ключей, которые вы сохранили ранее""";
  @override
  String get restore_next => """Продолжить""";
  @override
  String get restore_title_from_backup => """Восстановить из back-up файла""";
  @override
  String get restore_description_from_backup => """Вы можете восстановить Cake Wallet из вашего back-up файла""";
  @override
  String get restore_seed_keys_restore => """Восстановить из мнемонической фразы/ключей""";
  @override
  String get restore_title_from_seed => """Восстановить из мнемонической фразы""";
  @override
  String get restore_description_from_seed => """Вы можете восстановить кошелёк используя 25-ти значную мнемоническую фразу""";
  @override
  String get restore_title_from_keys => """Восстановить с помощью ключей""";
  @override
  String get restore_description_from_keys => """Вы можете восстановить кошелёк с помощью приватных ключей""";
  @override
  String get restore_wallet_name => """Имя кошелька""";
  @override
  String get restore_address => """Адрес""";
  @override
  String get restore_view_key_private => """Приватный ключ просмотра""";
  @override
  String get restore_spend_key_private => """Приватный ключ траты""";
  @override
  String get restore_recover => """Восстановить""";
  @override
  String get restore_wallet_restore_description => """Описание восстановления кошелька""";
  @override
  String get restore_new_seed => """Новая мнемоническая фраза""";
  @override
  String get restore_active_seed => """Активная мнемоническая фраза""";
  @override
  String get restore_bitcoin_description_from_seed => """Вы можете восстановить кошелёк используя 24-ти значную мнемоническую фразу""";
  @override
  String get restore_bitcoin_description_from_keys => """Вы можете восстановить кошелёк с помощью WIF""";
  @override
  String get restore_bitcoin_title_from_keys => """Восстановить с помощью WIF""";
  @override
  String get restore_from_date_or_blockheight => """Пожалуйста, введите дату за несколько дней до создания этого кошелька. Или, если вы знаете высоту блока, введите ее значение""";
  @override
  String get seed_reminder => """Пожалуйста, запишите мнемоническую фразу на случай потери или очистки телефона""";
  @override
  String get seed_title => """Мнемоническая фраза""";
  @override
  String get seed_share => """Поделиться мнемонической фразой""";
  @override
  String get copy => """Скопировать""";
  @override
  String get seed_language_choose => """Пожалуйста, выберите язык мнемонической фразы:""";
  @override
  String get seed_choose => """Выберите язык мнемонической фразы""";
  @override
  String get seed_language_next => """Продолжить""";
  @override
  String get seed_language_english => """Английский""";
  @override
  String get seed_language_chinese => """Китайский""";
  @override
  String get seed_language_dutch => """Нидерландский""";
  @override
  String get seed_language_german => """Немецкий""";
  @override
  String get seed_language_japanese => """Японский""";
  @override
  String get seed_language_portuguese => """Португальский""";
  @override
  String get seed_language_russian => """Русский""";
  @override
  String get seed_language_spanish => """Испанский""";
  @override
  String get send_title => """Отправить""";
  @override
  String get send_your_wallet => """Ваш кошелёк""";
  @override
  String send_address(String cryptoCurrency) => """${cryptoCurrency} адрес""";
  @override
  String get send_payment_id => """ID платежа (опционально)""";
  @override
  String get all => """ВСЕ""";
  @override
  String get send_error_minimum_value => """Mинимальная сумма 0.01""";
  @override
  String get send_error_currency => """Валюта может содержать только цифры""";
  @override
  String get send_estimated_fee => """Предполагаемая комиссия:""";
  @override
  String send_priority(String transactionPriority) => """Комиссия установлена в зависимости от приоритета: ${transactionPriority}.
Приоритет транзакции может быть изменён в настройках""";
  @override
  String get send_creating_transaction => """Создать транзакцию""";
  @override
  String get send_templates => """Шаблоны""";
  @override
  String get send_new => """Новый""";
  @override
  String get send_amount => """Сумма:""";
  @override
  String get send_fee => """Комиссия:""";
  @override
  String get send_name => """Имя""";
  @override
  String get send_got_it => """Понял""";
  @override
  String get send_sending => """Отправка...""";
  @override
  String send_success(String crypto) => """Ваш ${crypto} был успешно отправлен""";
  @override
  String get settings_title => """Настройки""";
  @override
  String get settings_nodes => """Ноды""";
  @override
  String get settings_current_node => """Текущая нода""";
  @override
  String get settings_wallets => """Кошельки""";
  @override
  String get settings_display_balance_as => """Отображать баланс как""";
  @override
  String get settings_currency => """Валюта""";
  @override
  String get settings_fee_priority => """Приоритет транзакции""";
  @override
  String get settings_save_recipient_address => """Сохранять адрес получателя""";
  @override
  String get settings_personal => """Персональные""";
  @override
  String get settings_change_pin => """Изменить PIN""";
  @override
  String get settings_change_language => """Изменить язык""";
  @override
  String get settings_allow_biometrical_authentication => """Включить биометрическую аутентификацию""";
  @override
  String get settings_dark_mode => """Тёмный режим""";
  @override
  String get settings_transactions => """Транзакции""";
  @override
  String get settings_trades => """Сделки""";
  @override
  String get settings_display_on_dashboard_list => """Показывать в списке транзакций""";
  @override
  String get settings_all => """ВСЕ""";
  @override
  String get settings_only_trades => """Сделки""";
  @override
  String get settings_only_transactions => """Транзакции""";
  @override
  String get settings_none => """Ничего""";
  @override
  String get settings_support => """Поддержка""";
  @override
  String get settings_terms_and_conditions => """Условия и положения""";
  @override
  String get pin_is_incorrect => """Некорректный PIN""";
  @override
  String get setup_pin => """Настроить PIN""";
  @override
  String get enter_your_pin_again => """Введите PIN еще раз""";
  @override
  String get setup_successful => """PIN был успешно установлен!""";
  @override
  String get wallet_keys => """Мнемоническая фраза/ключи кошелька""";
  @override
  String get wallet_seed => """Мнемоническая фраза кошелька""";
  @override
  String get private_key => """Приватный ключ""";
  @override
  String get public_key => """Публичный ключ""";
  @override
  String get view_key_private => """Приватный ключ просмотра""";
  @override
  String get view_key_public => """Публичный ключ просмотра""";
  @override
  String get spend_key_private => """Приватный ключ траты""";
  @override
  String get spend_key_public => """Публичный ключ траты""";
  @override
  String copied_key_to_clipboard(String key) => """Скопировано ${key} в буфер обмена""";
  @override
  String get new_subaddress_title => """Новый адрес""";
  @override
  String get new_subaddress_label_name => """Имя""";
  @override
  String get new_subaddress_create => """Создать""";
  @override
  String get subaddress_title => """Список субадресов""";
  @override
  String get trade_details_title => """Детали сделок""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """Статус""";
  @override
  String get trade_details_fetching => """Получение""";
  @override
  String get trade_details_provider => """Провайдер""";
  @override
  String get trade_details_created_at => """Создано""";
  @override
  String get trade_details_pair => """Пара""";
  @override
  String trade_details_copied(String title) => """${title} скопировано в буфер обмена""";
  @override
  String get trade_history_title => """История сделок""";
  @override
  String get transaction_details_title => """Детали транзакции""";
  @override
  String get transaction_details_transaction_id => """ID транзакции""";
  @override
  String get transaction_details_date => """Дата""";
  @override
  String get transaction_details_height => """Высота""";
  @override
  String get transaction_details_amount => """Сумма""";
  @override
  String get transaction_details_fee => """Комиссия""";
  @override
  String transaction_details_copied(String title) => """${title} скопировано в буфер обмена""";
  @override
  String get transaction_details_recipient_address => """Адрес получателя""";
  @override
  String get wallet_list_title => """Monero Кошелёк""";
  @override
  String get wallet_list_create_new_wallet => """Создать новый кошелёк""";
  @override
  String get wallet_list_restore_wallet => """Восстановить кошелёк""";
  @override
  String get wallet_list_load_wallet => """Загрузка кошелька""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """Загрузка ${wallet_name} кошелька""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """Ошибка при загрузке ${wallet_name} кошелька. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """Удаление ${wallet_name} кошелька""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """Ошибка при удалении ${wallet_name} кошелька. ${error}""";
  @override
  String get widgets_address => """Адрес""";
  @override
  String get widgets_restore_from_blockheight => """Восстановить на высоте блока""";
  @override
  String get widgets_restore_from_date => """Восстановить с даты""";
  @override
  String get widgets_or => """или""";
  @override
  String get widgets_seed => """Мнемоническая фраза""";
  @override
  String router_no_route(String name) => """Не установлен маршрут для ${name}""";
  @override
  String get error_text_account_name => """Имя аккаунта может содержать только буквы, цифры
и должно быть от 1 до 15 символов в длину""";
  @override
  String get error_text_contact_name => """Имя контакта не может содержать ` , ' " символы
 и должно быть от 1 до 32 символов в длину""";
  @override
  String get error_text_address => """Адрес кошелька должен соответствовать типу
криптовалюты""";
  @override
  String get error_text_node_address => """Пожалуйста, введите iPv4 адрес""";
  @override
  String get error_text_node_port => """Порт ноды может содержать только цифры от 0 до 65535""";
  @override
  String get error_text_payment_id => """Идентификатор платежа может содержать от 16 до 64 символов в hex""";
  @override
  String get error_text_xmr => """Значение XMR не может превышать доступный баланс.
Количество цифр после запятой должно быть меньше или равно 12""";
  @override
  String get error_text_fiat => """Значение суммы не может превышать доступный баланс.
Количество цифр после запятой должно быть меньше или равно 2""";
  @override
  String get error_text_subaddress_name => """Имя субадреса не может содержать ` , ' " символы
и должно быть от 1 до 20 символов в длину""";
  @override
  String get error_text_amount => """Баланс может содержать только цифры""";
  @override
  String get error_text_wallet_name => """Имя кошелька может содержать только буквы, цифры
и должно быть от 1 до 20 символов в длину""";
  @override
  String get error_text_keys => """Ключи кошелька могут содержать только 64 символа в hex""";
  @override
  String get error_text_crypto_currency => """Количество цифр после запятой
должно быть меньше или равно 12""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """Сделка для ${provider} не создана. Сумма меньше минимальной: ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """Сделка для ${provider} не создана. Сумма больше максимальной: ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """Сделка для ${provider} не создана. Ошибка загрузки лимитов""";
  @override
  String get error_text_template => """Имя и адрес шаблона не может содержать ` , ' " символы
и должно быть от 1 до 106 символов в длину""";
  @override
  String get auth_store_ban_timeout => """ban_timeout""";
  @override
  String get auth_store_banned_for => """Заблокировано на """;
  @override
  String get auth_store_banned_minutes => """ минут""";
  @override
  String get auth_store_incorrect_password => """Некорректный PIN""";
  @override
  String get wallet_store_monero_wallet => """Monero Кошелёк""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """Неверная длина мнемонической фразы""";
  @override
  String get full_balance => """Весь баланс""";
  @override
  String get available_balance => """Доступный баланс""";
  @override
  String get hidden_balance => """Скрытый баланс""";
  @override
  String get sync_status_syncronizing => """СИНХРОНИЗАЦИЯ""";
  @override
  String get sync_status_syncronized => """СИНХРОНИЗИРОВАН""";
  @override
  String get sync_status_not_connected => """НЕ ПОДКЛЮЧЁН""";
  @override
  String get sync_status_starting_sync => """НАЧАЛО СИНХРОНИЗАЦИИ""";
  @override
  String get sync_status_failed_connect => """ОТКЛЮЧЕНО""";
  @override
  String get sync_status_connecting => """ПОДКЛЮЧЕНИЕ""";
  @override
  String get sync_status_connected => """ПОДКЛЮЧЕНО""";
  @override
  String get transaction_priority_slow => """Медленный""";
  @override
  String get transaction_priority_regular => """Обычный""";
  @override
  String get transaction_priority_medium => """Средний""";
  @override
  String get transaction_priority_fast => """Быстрый""";
  @override
  String get transaction_priority_fastest => """Самый быстрый""";
  @override
  String trade_for_not_created(String title) => """Сделка для ${title} не создана.""";
  @override
  String get trade_not_created => """Сделка не создана.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """Сделка ${tradeId} ${title} не найдена.""";
  @override
  String get trade_not_found => """Trade not found.""";
  @override
  String get trade_state_pending => """Ожидание""";
  @override
  String get trade_state_confirming => """Подтверждение""";
  @override
  String get trade_state_trading => """Совершение сделки""";
  @override
  String get trade_state_traded => """Сделка завершена""";
  @override
  String get trade_state_complete => """Выполнена""";
  @override
  String get trade_state_to_be_created => """Будет создана""";
  @override
  String get trade_state_unpaid => """Неоплаченная""";
  @override
  String get trade_state_underpaid => """Недоплаченная""";
  @override
  String get trade_state_paid_unconfirmed => """Оплата неподтверждена""";
  @override
  String get trade_state_paid => """Оплаченная""";
  @override
  String get trade_state_btc_sent => """BTC отправлены""";
  @override
  String get trade_state_timeout => """Таймаут""";
  @override
  String get trade_state_created => """Созданная""";
  @override
  String get trade_state_finished => """Завершена""";
  @override
  String get change_language => """Изменить язык""";
  @override
  String change_language_to(String language) => """Изменить язык на ${language}?""";
  @override
  String get paste => """Вставить""";
  @override
  String get restore_from_seed_placeholder => """Введите или вставьте мнемоническую фразу вашего кошелька""";
  @override
  String get add_new_word => """Добавить новое слово""";
  @override
  String get incorrect_seed => """Введённый текст некорректный.""";
  @override
  String get biometric_auth_reason => """Отсканируйте свой отпечаток пальца для аутентификации""";
  @override
  String version(String currentVersion) => """Версия ${currentVersion}""";
  @override
  String get openalias_alert_title => """Получатель XMR обнаружен""";
  @override
  String openalias_alert_content(String recipient_name) => """Вы будете отправлять средства
${recipient_name}""";
  @override
  String get card_address => """Адрес:""";
  @override
  String get buy => """Купить""";
  @override
  String get placeholder_transactions => """Ваши транзакции будут отображаться здесь""";
  @override
  String get placeholder_contacts => """Ваши контакты будут отображаться здесь""";
  @override
  String get template => """Шаблон""";
  @override
  String get confirm_delete_template => """Это действие удалит шаблон. Вы хотите продолжить?""";
  @override
  String get confirm_delete_wallet => """Это действие удалит кошелек. Вы хотите продолжить?""";
  @override
  String get picker_description => """Чтобы выбрать ChangeNOW или MorphToken, сначала смените пару для обмена""";
  @override
  String get change_wallet_alert_title => """Изменить текущий кошелек""";
  @override
  String change_wallet_alert_content(String wallet_name) => """Вы хотите изменить текущий кошелек на ${wallet_name}?""";
  @override
  String get creating_new_wallet => """Создание нового кошелька""";
  @override
  String creating_new_wallet_error(String description) => """Ошибка: ${description}""";
  @override
  String get seed_alert_title => """Внимание""";
  @override
  String get seed_alert_content => """Мнемоническая фраза - единственный способ восстановить ваш кошелек. Вы записали ее?""";
  @override
  String get seed_alert_back => """Назад""";
  @override
  String get seed_alert_yes => """Да""";
  @override
  String get wallet_name_alert_content => """Кошелек с таким именем существует""";
  @override
  String get exchange_sync_alert_content => """Подождите, пока ваш кошелек синхронизируется""";
  @override
  String get pre_seed_title => """ВАЖНО""";
  @override
  String pre_seed_description(String words) => """На следующей странице вы увидите серию из ${words} слов. Это ваша уникальная и личная мнемоническая фраза, и это ЕДИНСТВЕННЫЙ способ восстановить свой кошелек в случае потери или неисправности. ВАМ необходимо записать ее и хранить в надежном месте вне приложения Cake Wallet.""";
  @override
  String get pre_seed_button_text => """Понятно. Покажите мнемоническую фразу""";
  @override
  String get xmr_to_error => """Ошибка XMR.TO""";
  @override
  String get xmr_to_error_description => """Недопустимая сумма. Максимум 8 цифр после десятичной точки""";
  @override
  String provider_error(String provider) => """${provider} ошибка""";
  @override
  String get use_ssl => """Использовать SSL""";
  @override
  String get color_theme => """Цветовая тема""";
  @override
  String get light_theme => """Светлая""";
  @override
  String get bright_theme => """Яркая""";
  @override
  String get dark_theme => """Темная""";
  @override
  String get enter_your_note => """Введите примечание…""";
  @override
  String get note_optional => """Примечание (необязательно)""";
  @override
  String get note_tap_to_change => """Примечание (нажмите для изменения)""";
  @override
  String get transaction_key => """Ключ транзакции""";
  @override
  String get confirmations => """Подтверждения""";
  @override
  String get recipient_address => """Адрес получателя""";
  @override
  String get extra_id => """Дополнительный ID:""";
  @override
  String get destination_tag => """Целевой тег:""";
  @override
  String get memo => """Памятка:""";
  @override
  String get backup => """Резервная копия""";
  @override
  String get change_password => """Изменить пароль""";
  @override
  String get backup_password => """Пароль резервной копии""";
  @override
  String get write_down_backup_password => """Запишите пароль резервной копии, который используется для импорта файлов резервных копий.""";
  @override
  String get export_backup => """Экспорт резервной копии""";
  @override
  String get save_backup_password => """Убедитесь, что вы сохранили пароль резервной копии. Без него вы не сможете импортировать файлы резервных копий.""";
  @override
  String get backup_file => """Файл резервной копии""";
  @override
  String get edit_backup_password => """Изменить пароль резервной копии""";
  @override
  String get save_backup_password_alert => """Сохранить пароль резервной копии""";
  @override
  String get change_backup_password_alert => """Ваши предыдущие файлы резервных копий будут недоступны для импорта с новым паролем резервной копии. Новый пароль резервной копии будет использоваться только для новых файлов резервных копий. Вы уверены, что хотите изменить пароль резервной копии?""";
  @override
  String get enter_backup_password => """Введите пароль резервной копии""";
  @override
  String get select_backup_file => """Выберите файл резервной копии""";
  @override
  String get import => """Импортировать""";
  @override
  String get please_select_backup_file => """Выберите файл резервной копии и введите пароль резервной копии.""";
  @override
  String get fixed_rate => """Фиксированная ставка""";
  @override
  String get fixed_rate_alert => """Вы сможете ввести сумму получения тогда, когда будет установлен режим фиксированной ставки. Вы хотите перейти в режим фиксированной ставки?""";
  @override
  String get xlm_extra_info => """Не забудьте указать Memo ID (памятка) при отправке транзакции XLM для обмена""";
  @override
  String get xrp_extra_info => """Не забудьте указать целевой тег при отправке транзакции XRP для обмена""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Если вы хотите обменять XMR со своего баланса Monero в Cake Wallet, сначала переключитесь на свой кошелек Monero.""";
  @override
  String get confirmed => """Подтверждено""";
  @override
  String get unconfirmed => """Неподтвержденный""";
  @override
  String get displayable => """Отображаемый""";
  @override
  String get submit_request => """отправить запрос""";
  @override
  String get buy_alert_content => """В настоящее время мы поддерживаем только покупку Bitcoin и Litecoin. Чтобы купить Bitcoin или Litecoin, создайте или переключитесь на свой Bitcoin или Litecoin кошелек.""";
  @override
  String get outdated_electrum_wallet_description => """Новые биткойн-кошельки, созданные в Cake, теперь содержат мнемоническую фразу из 24 слов. Вы обязательно должны создать новый биткойн-кошелек и перевести все свои средства в новый кошелек из 24 слов, а также прекратить использование кошельков с мнемонической фразой из 12 слов. Пожалуйста, сделайте это немедленно, чтобы обезопасить свои средства.""";
  @override
  String get understand => """Понятно""";
  @override
  String get apk_update => """Обновление APK""";
  @override
  String get buy_bitcoin => """Купить Bitcoin""";
  @override
  String get buy_with => """Купить с помощью""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """Сумма должна быть больше или равна ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """Если этот кошелек имеет мнемоническую фразу из 12 слов и был создан в Cake, НЕ переводите биткойны на этот кошелек. Любые BTC, переведенные на этот кошелек, могут быть потеряны. Создайте новый кошелек с мнемоническои фразы из 24 слов (коснитесь меню в правом верхнем углу, выберите «Кошельки», выберите «Создать новый кошелек», затем выберите «Bitcoin») и НЕМЕДЛЕННО переведите туда свои BTC. Новые (24 слова) кошельки BTC от Cake безопасны""";
  @override
  String get do_not_show_me => """Не показывай мне это больше""";
  @override
  String get unspent_coins_title => """Неизрасходованные монеты""";
  @override
  String get unspent_coins_details_title => """Сведения о неизрасходованных монетах""";
  @override
  String get freeze => """Заморозить""";
  @override
  String get coin_control => """Контроль монет (необязательно)""";
  @override
  String get address_detected => """Обнаружен адрес""";
  @override
  String address_from_domain(String domain) => """Вы получили адрес из unstoppable domain ${domain}""";
}

class $pl extends S {
  const $pl();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """Witamy w""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """Niesamowity portfel dla Monero i Bitcoin""";
  @override
  String get please_make_selection => """Wybierz poniżej, aby cutwórz lub odzyskaj swój portfel.""";
  @override
  String get create_new => """Utwórz nowy portfel""";
  @override
  String get restore_wallet => """Przywróć portfel""";
  @override
  String get accounts => """Konta""";
  @override
  String get edit => """Edytować""";
  @override
  String get account => """Konto""";
  @override
  String get add => """Dodaj""";
  @override
  String get address_book => """Książka adresowa""";
  @override
  String get contact => """Kontakt""";
  @override
  String get please_select => """Proszę wybrać:""";
  @override
  String get cancel => """Anulować""";
  @override
  String get ok => """Dobrze""";
  @override
  String get contact_name => """Nazwa Kontaktu""";
  @override
  String get reset => """Nastawić""";
  @override
  String get save => """Zapisać""";
  @override
  String get address_remove_contact => """Usuń kontakt""";
  @override
  String get address_remove_content => """Czy na pewno chcesz usunąć wybrany kontakt?""";
  @override
  String get authenticated => """Zalegalizowany""";
  @override
  String get authentication => """Poświadczenie""";
  @override
  String failed_authentication(String state_error) => """Nieudane uwierzytelnienie. ${state_error}""";
  @override
  String get wallet_menu => """Menu portfela""";
  @override
  String Blocks_remaining(String status) => """${status} Bloki pozostałe""";
  @override
  String get please_try_to_connect_to_another_node => """Spróbuj połączyć się z innym węzłem""";
  @override
  String get xmr_hidden => """Ukryty""";
  @override
  String get xmr_available_balance => """Dostępne saldo""";
  @override
  String get xmr_full_balance => """Pełna równowaga""";
  @override
  String get send => """Wysłać""";
  @override
  String get receive => """Otrzymać""";
  @override
  String get transactions => """Transakcje""";
  @override
  String get incoming => """Przychodzące""";
  @override
  String get outgoing => """Towarzyski""";
  @override
  String get transactions_by_date => """Transakcje według daty""";
  @override
  String get trades => """Transakcje""";
  @override
  String get filters => """Filtr""";
  @override
  String get today => """Dzisiaj""";
  @override
  String get yesterday => """Wczoraj""";
  @override
  String get received => """Odebrane""";
  @override
  String get sent => """Wysłano""";
  @override
  String get pending => """ (w oczekiwaniu)""";
  @override
  String get rescan => """Skanuj ponownie""";
  @override
  String get reconnect => """Na nowo połączyć""";
  @override
  String get wallets => """Portfele""";
  @override
  String get show_seed => """Pokaż nasiona""";
  @override
  String get show_keys => """Pokaż nasiona/klucze""";
  @override
  String get address_book_menu => """Książka adresowa""";
  @override
  String get reconnection => """Ponowne połączenie""";
  @override
  String get reconnect_alert_text => """Czy na pewno ponownie się połączysz?""";
  @override
  String get exchange => """Wymieniać się""";
  @override
  String get clear => """Wyczyść""";
  @override
  String get refund_address => """Adres zwrotu""";
  @override
  String get change_exchange_provider => """Zmień dostawcę programu Exchange""";
  @override
  String get you_will_send => """Konwertuj z""";
  @override
  String get you_will_get => """Konwertuj na""";
  @override
  String get amount_is_guaranteed => """Otrzymana kwota jest gwarantowana""";
  @override
  String get amount_is_estimate => """Otrzymana kwota jest wartością szacunkową""";
  @override
  String powered_by(String title) => """Zasilany przez ${title}""";
  @override
  String get error => """Błąd""";
  @override
  String get estimated => """Oszacowano""";
  @override
  String min_value(String value, String currency) => """Min: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """Max: ${value} ${currency}""";
  @override
  String get change_currency => """Change Currency""";
  @override
  String get copy_id => """ID kopii""";
  @override
  String get exchange_result_write_down_trade_id => """Skopiuj lub zanotuj identyfikator transakcji, aby kontynuować.""";
  @override
  String get trade_id => """Identyfikator handlu:""";
  @override
  String get copied_to_clipboard => """Skopiowane do schowka""";
  @override
  String get saved_the_trade_id => """Zapisałem ID""";
  @override
  String get fetching => """Ujmujący""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """Ilość: """;
  @override
  String get payment_id => """Płatności ID: """;
  @override
  String get status => """Status: """;
  @override
  String get offer_expires_in => """Oferta wygasa za """;
  @override
  String trade_is_powered_by(String provider) => """Ten handel jest zasilany przez ${provider}""";
  @override
  String get copy_address => """Skopiuj adress""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """Naciskając Potwierdź, wyślesz ${fetchingLabel} ${from} z twojego portfela ${walletName} na adres podany poniżej. Lub możesz wysłać z zewnętrznego portfela na poniższy adres / kod QR.

Naciśnij Potwierdź, aby kontynuować lub wróć, aby zmienić kwoty.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """Musisz wysłać co najmniej ${fetchingLabel} ${from} na adres podany na następnej stronie. Jeśli wyślesz kwotę niższą niż ${fetchingLabel} ${from}, może ona nie zostać przeliczona i może nie zostać zwrócona.""";
  @override
  String get exchange_result_write_down_ID => """*Skopiuj lub zanotuj swój identyfikator pokazany powyżej.""";
  @override
  String get confirm => """Potwierdzać""";
  @override
  String get confirm_sending => """Potwierdź wysłanie""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """Zatwierdź transakcję
Ilość: ${amount}
Opłata: ${fee}""";
  @override
  String get sending => """Wysyłanie""";
  @override
  String get transaction_sent => """Transakcja wysłana!""";
  @override
  String get expired => """Przedawniony""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """Wysłać XMR""";
  @override
  String get exchange_new_template => """Nowy szablon""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """Wpisz Twój kod PIN""";
  @override
  String get loading_your_wallet => """Ładowanie portfela""";
  @override
  String get new_wallet => """Nowy portfel""";
  @override
  String get wallet_name => """Nazwa portfela""";
  @override
  String get continue_text => """Dalej""";
  @override
  String get choose_wallet_currency => """Wybierz walutę portfela:""";
  @override
  String get node_new => """Nowy węzeł""";
  @override
  String get node_address => """Adres węzła""";
  @override
  String get node_port => """Port węzła""";
  @override
  String get login => """Zaloguj Się""";
  @override
  String get password => """Hasło""";
  @override
  String get nodes => """Węzły""";
  @override
  String get node_reset_settings_title => """Resetowanie ustawień""";
  @override
  String get nodes_list_reset_to_default_message => """Czy na pewno chcesz przywrócić ustawienia domyślne?""";
  @override
  String change_current_node(String node) => """Czy na pewno chcesz przywrócić ustawienia domyślne? ${node}?""";
  @override
  String get change => """Zmiana""";
  @override
  String get remove_node => """Usuń węzeł""";
  @override
  String get remove_node_message => """Czy na pewno chcesz usunąć wybrany węzeł?""";
  @override
  String get remove => """Usunąć""";
  @override
  String get delete => """Kasować""";
  @override
  String get add_new_node => """Dodaj nowy węzeł""";
  @override
  String get change_current_node_title => """Zmień bieżący węzeł""";
  @override
  String get node_test => """Test""";
  @override
  String get node_connection_successful => """Połączenie powiodło się""";
  @override
  String get node_connection_failed => """Połączenie nie powiodło się""";
  @override
  String get new_node_testing => """Testowanie nowych węzłów""";
  @override
  String get use => """Używać """;
  @override
  String get digit_pin => """-znak PIN""";
  @override
  String get share_address => """Udostępnij adres""";
  @override
  String get receive_amount => """Ilość""";
  @override
  String get subaddresses => """Podadresy""";
  @override
  String get addresses => """Adresy""";
  @override
  String get scan_qr_code => """Zeskanuj kod QR, aby uzyskać adres""";
  @override
  String get rename => """Przemianować""";
  @override
  String get choose_account => """Wybierz konto""";
  @override
  String get create_new_account => """Stwórz nowe konto""";
  @override
  String get accounts_subaddresses => """Konta i podadresy""";
  @override
  String get restore_restore_wallet => """Przywróć portfel""";
  @override
  String get restore_title_from_seed_keys => """Przywróć z nasion / kluczy""";
  @override
  String get restore_description_from_seed_keys => """Odzyskaj swój portfel z nasion / kluczy, które zapisałeś w bezpiecznym miejscu""";
  @override
  String get restore_next => """Kolejny""";
  @override
  String get restore_title_from_backup => """Przywróć z pliku kopii zapasowej""";
  @override
  String get restore_description_from_backup => """Możesz przywrócić całą aplikację Cake Wallet z plik kopii zapasowej""";
  @override
  String get restore_seed_keys_restore => """Przywracanie nasion / kluczy""";
  @override
  String get restore_title_from_seed => """Przywróć z nasion""";
  @override
  String get restore_description_from_seed => """Przywróć swój portfel z 25 słów lub 13-słowny kod kombinacji""";
  @override
  String get restore_title_from_keys => """Przywróć z kluczy""";
  @override
  String get restore_description_from_keys => """Przywróć swój portfel z wygenerowanego naciśnięcia klawiszy zapisane z kluczy prywatnych""";
  @override
  String get restore_wallet_name => """Nazwa portfela""";
  @override
  String get restore_address => """Adres""";
  @override
  String get restore_view_key_private => """Wyświetl klucz (prywatny)""";
  @override
  String get restore_spend_key_private => """Wydaj klucz (prywatny)""";
  @override
  String get restore_recover => """Wyzdrowieć""";
  @override
  String get restore_wallet_restore_description => """Opis przywracania portfela""";
  @override
  String get restore_new_seed => """Nowe nasienie""";
  @override
  String get restore_active_seed => """Aktywne nasiona""";
  @override
  String get restore_bitcoin_description_from_seed => """Przywróć swój portfel z kodu złożonego z 24 słów""";
  @override
  String get restore_bitcoin_description_from_keys => """Przywróć swój portfel z wygenerowanego ciągu WIF z kluczy prywatnych""";
  @override
  String get restore_bitcoin_title_from_keys => """Przywróć z WIF""";
  @override
  String get restore_from_date_or_blockheight => """Wprowadź datę na kilka dni przed utworzeniem tego portfela. Lub jeśli znasz wysokość bloku, wprowadź go zamiast tego""";
  @override
  String get seed_reminder => """Zapisz je na wypadek zgubienia lub wyczyszczenia telefonu""";
  @override
  String get seed_title => """Ziarno""";
  @override
  String get seed_share => """Udostępnij ziarno""";
  @override
  String get copy => """Kopiuj""";
  @override
  String get seed_language_choose => """Proszę wybrać język początkowy:""";
  @override
  String get seed_choose => """Wybierz język początkowy""";
  @override
  String get seed_language_next => """Kolejny""";
  @override
  String get seed_language_english => """Angielski""";
  @override
  String get seed_language_chinese => """Chiński""";
  @override
  String get seed_language_dutch => """Holenderski""";
  @override
  String get seed_language_german => """Niemiecki""";
  @override
  String get seed_language_japanese => """Japoński""";
  @override
  String get seed_language_portuguese => """Portugalski""";
  @override
  String get seed_language_russian => """Rosyjski""";
  @override
  String get seed_language_spanish => """Hiszpański""";
  @override
  String get send_title => """Wyślij""";
  @override
  String get send_your_wallet => """Twój portfel""";
  @override
  String send_address(String cryptoCurrency) => """Adres ${cryptoCurrency}""";
  @override
  String get send_payment_id => """Identyfikator płatności (opcjonalny)""";
  @override
  String get all => """WSZYSTKO""";
  @override
  String get send_error_minimum_value => """Minimalna wartość kwoty to 0,01""";
  @override
  String get send_error_currency => """Waluta może zawierać tylko cyfry""";
  @override
  String get send_estimated_fee => """Szacowana opłata:""";
  @override
  String send_priority(String transactionPriority) => """Obecnie opłata ustalona jest na ${transactionPriority} priorytet.
Priorytet transakcji można zmienić w ustawieniach""";
  @override
  String get send_creating_transaction => """Tworzenie transakcji""";
  @override
  String get send_templates => """Szablony""";
  @override
  String get send_new => """Nowy""";
  @override
  String get send_amount => """Ilość:""";
  @override
  String get send_fee => """Opłata:""";
  @override
  String get send_name => """Imię""";
  @override
  String get send_got_it => """Rozumiem""";
  @override
  String get send_sending => """Wysyłanie...""";
  @override
  String send_success(String crypto) => """Twoje ${crypto} zostało pomyślnie wysłane""";
  @override
  String get settings_title => """Ustawienia""";
  @override
  String get settings_nodes => """Węzły""";
  @override
  String get settings_current_node => """Bieżący węzeł""";
  @override
  String get settings_wallets => """Portfele""";
  @override
  String get settings_display_balance_as => """Wyświetl saldo jako""";
  @override
  String get settings_currency => """Waluta""";
  @override
  String get settings_fee_priority => """Priorytet opłaty""";
  @override
  String get settings_save_recipient_address => """Zapisz adres odbiorcy""";
  @override
  String get settings_personal => """Osobisty""";
  @override
  String get settings_change_pin => """Zmień PIN""";
  @override
  String get settings_change_language => """Zmień język""";
  @override
  String get settings_allow_biometrical_authentication => """Zezwalaj na uwierzytelnianie biometryczne""";
  @override
  String get settings_dark_mode => """Tryb ciemny""";
  @override
  String get settings_transactions => """Transakcje""";
  @override
  String get settings_trades => """Transakcje""";
  @override
  String get settings_display_on_dashboard_list => """Wyświetl na liście kokpitu""";
  @override
  String get settings_all => """Cały""";
  @override
  String get settings_only_trades => """Tylko transakcje""";
  @override
  String get settings_only_transactions => """Tylko transakcje""";
  @override
  String get settings_none => """Żaden""";
  @override
  String get settings_support => """Wsparcie""";
  @override
  String get settings_terms_and_conditions => """Zasady i warunki""";
  @override
  String get pin_is_incorrect => """PPIN jest niepoprawny""";
  @override
  String get setup_pin => """Ustaw PIN""";
  @override
  String get enter_your_pin_again => """Wprowadź ponownie swój kod PIN""";
  @override
  String get setup_successful => """Twój kod PIN został pomyślnie skonfigurowany!""";
  @override
  String get wallet_keys => """Nasiono portfela/klucze""";
  @override
  String get wallet_seed => """Nasiono portfela""";
  @override
  String get private_key => """Prywatny klucz""";
  @override
  String get public_key => """Klucz publiczny""";
  @override
  String get view_key_private => """Wyświetl klucz (prywatny)""";
  @override
  String get view_key_public => """Wyświetl klucz (publiczny)""";
  @override
  String get spend_key_private => """Wydaj klucz (prywatny)""";
  @override
  String get spend_key_public => """Wydaj klucz (publiczny)""";
  @override
  String copied_key_to_clipboard(String key) => """Skopiowane ${key} do schowka""";
  @override
  String get new_subaddress_title => """Nowy adres""";
  @override
  String get new_subaddress_label_name => """Nazwa etykiety""";
  @override
  String get new_subaddress_create => """Stwórz""";
  @override
  String get subaddress_title => """Lista podadresów""";
  @override
  String get trade_details_title => """Szczegóły handlu""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """Stan""";
  @override
  String get trade_details_fetching => """Ujmujący""";
  @override
  String get trade_details_provider => """Dostawca""";
  @override
  String get trade_details_created_at => """Utworzono w""";
  @override
  String get trade_details_pair => """Para""";
  @override
  String trade_details_copied(String title) => """${title} skopiowane do schowka""";
  @override
  String get trade_history_title => """Historia handlu""";
  @override
  String get transaction_details_title => """Szczegóły transakcji""";
  @override
  String get transaction_details_transaction_id => """Transakcja ID""";
  @override
  String get transaction_details_date => """Data""";
  @override
  String get transaction_details_height => """Wysokość""";
  @override
  String get transaction_details_amount => """Ilość""";
  @override
  String get transaction_details_fee => """Opłata""";
  @override
  String transaction_details_copied(String title) => """${title} skopiowane do schowka""";
  @override
  String get transaction_details_recipient_address => """Adres odbiorcy""";
  @override
  String get wallet_list_title => """Portfel Monero""";
  @override
  String get wallet_list_create_new_wallet => """Utwórz nowy portfel""";
  @override
  String get wallet_list_restore_wallet => """Przywróć portfel""";
  @override
  String get wallet_list_load_wallet => """Załaduj portfel""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """Ładuję ${wallet_name} portfel""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """Nie udało się załadować ${wallet_name} portfel. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """Usuwanie ${wallet_name} portfel""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """Nie udało się usunąć ${wallet_name} portfel. ${error}""";
  @override
  String get widgets_address => """Adres""";
  @override
  String get widgets_restore_from_blockheight => """Przywróć z wysokości bloku""";
  @override
  String get widgets_restore_from_date => """Przywróć od daty""";
  @override
  String get widgets_or => """lub""";
  @override
  String get widgets_seed => """Ziarno""";
  @override
  String router_no_route(String name) => """Brak zdefiniowanej trasy dla ${name}""";
  @override
  String get error_text_account_name => """Nazwa konta może zawierać tylko litery, cyfry
i musi mieć od 1 do 15 znaków""";
  @override
  String get error_text_contact_name => """Nazwa kontaktu nie może zawierać` , ' " symbolika
i musi mieć od 1 do 32 znaków """;
  @override
  String get error_text_address => """Wallet address must correspond to the type
of cryptocurrency""";
  @override
  String get error_text_node_address => """Wpisz adres iPv4""";
  @override
  String get error_text_node_port => """Port węzła może zawierać tylko liczby od 0 do 65535""";
  @override
  String get error_text_payment_id => """ID może zawierać od 16 do 64 znaków w formacie szesnastkowym""";
  @override
  String get error_text_xmr => """Wartość XMR nie może przekraczać dostępnego salda.
Liczba cyfr ułamkowych musi być mniejsza lub równa 12""";
  @override
  String get error_text_fiat => """Wartość kwoty nie może przekroczyć dostępnego salda.
Liczba cyfr ułamkowych musi być mniejsza lub równa 2""";
  @override
  String get error_text_subaddress_name => """Nazwa podadresu nie może zawierać ` , ' " symbolika
i musi mieć od 1 do 20 znaków""";
  @override
  String get error_text_amount => """Kwota może zawierać tylko liczby""";
  @override
  String get error_text_wallet_name => """Nazwa portfela może zawierać tylko litery i cyfry
i musi mieć od 1 do 20 znaków""";
  @override
  String get error_text_keys => """Klucze portfela mogą zawierać tylko 64 znaki w systemie szesnastkowym""";
  @override
  String get error_text_crypto_currency => """Liczba cyfr ułamkowych
musi być mniejsza lub równa 12""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """Wymiana dla ${provider} nie została utworzona. Kwota jest mniejsza niż minimalna: ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """Wymiana dla ${provider} nie została utworzona. Kwota jest większa niż maksymalna: ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """Wymiana dla ${provider} nie została utworzona. Ładowanie limitów nie powiodło się""";
  @override
  String get error_text_template => """Nazwa i adres szablonu nie mogą zawierać ` , ' " symbolika
i musi mieć od 1 do 106 znaków""";
  @override
  String get auth_store_ban_timeout => """przekroczenie limitu czasu""";
  @override
  String get auth_store_banned_for => """Bzbanowany za """;
  @override
  String get auth_store_banned_minutes => """ minuty""";
  @override
  String get auth_store_incorrect_password => """Niepoprawny PIN""";
  @override
  String get wallet_store_monero_wallet => """Portfel Monero""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """Nieprawidłowa długość nasion""";
  @override
  String get full_balance => """Pełna równowaga""";
  @override
  String get available_balance => """Dostępne saldo""";
  @override
  String get hidden_balance => """Ukryta równowaga""";
  @override
  String get sync_status_syncronizing => """SYNCHRONIZACJA""";
  @override
  String get sync_status_syncronized => """SYNCHRONIZOWANY""";
  @override
  String get sync_status_not_connected => """NIE POŁĄCZONY""";
  @override
  String get sync_status_starting_sync => """ROZPOCZĘCIE SYNCHRONIZACJI""";
  @override
  String get sync_status_failed_connect => """NIEPOWIĄZANY""";
  @override
  String get sync_status_connecting => """ZŁĄCZONY""";
  @override
  String get sync_status_connected => """POŁĄCZONY""";
  @override
  String get transaction_priority_slow => """Powolny""";
  @override
  String get transaction_priority_regular => """Regularny""";
  @override
  String get transaction_priority_medium => """Średni""";
  @override
  String get transaction_priority_fast => """Szybki""";
  @override
  String get transaction_priority_fastest => """Najszybszy""";
  @override
  String trade_for_not_created(String title) => """Zamienić się za ${title} nie jest tworzony.""";
  @override
  String get trade_not_created => """Handel nie utworzony.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """Handel ${tradeId} of ${title} nie znaleziono.""";
  @override
  String get trade_not_found => """Nie znaleziono handlu.""";
  @override
  String get trade_state_pending => """W oczekiwaniu""";
  @override
  String get trade_state_confirming => """Potwierdzam""";
  @override
  String get trade_state_trading => """Handlowy""";
  @override
  String get trade_state_traded => """Handlowane""";
  @override
  String get trade_state_complete => """Kompletny""";
  @override
  String get trade_state_to_be_created => """Zostać stworzonym""";
  @override
  String get trade_state_unpaid => """Nie zapłacony""";
  @override
  String get trade_state_underpaid => """Niedopłacone""";
  @override
  String get trade_state_paid_unconfirmed => """Płatne niepotwierdzone""";
  @override
  String get trade_state_paid => """Płatny""";
  @override
  String get trade_state_btc_sent => """Wysłane""";
  @override
  String get trade_state_timeout => """Koniec czasu""";
  @override
  String get trade_state_created => """Stworzony""";
  @override
  String get trade_state_finished => """Skończone""";
  @override
  String get change_language => """Zmień język""";
  @override
  String change_language_to(String language) => """Zmień język na ${language}?""";
  @override
  String get paste => """Pasta""";
  @override
  String get restore_from_seed_placeholder => """Wpisz lub wklej tutaj swoją frazę kodową""";
  @override
  String get add_new_word => """Dodaj nowe słowo""";
  @override
  String get incorrect_seed => """Wprowadzony tekst jest nieprawidłowy.""";
  @override
  String get biometric_auth_reason => """Zeskanuj swój odcisk palca, aby go uwierzytelnić""";
  @override
  String version(String currentVersion) => """Wersja ${currentVersion}""";
  @override
  String get openalias_alert_title => """Wykryto odbiorcę XMR""";
  @override
  String openalias_alert_content(String recipient_name) => """Będziesz wysyłać środki na
${recipient_name}""";
  @override
  String get card_address => """Adres:""";
  @override
  String get buy => """Kup""";
  @override
  String get placeholder_transactions => """Twoje transakcje zostaną wyświetlone tutaj""";
  @override
  String get placeholder_contacts => """Twoje kontakty zostaną wyświetlone tutaj""";
  @override
  String get template => """Szablon""";
  @override
  String get confirm_delete_template => """Ta czynność usunie ten szablon. Czy chcesz kontynuować?""";
  @override
  String get confirm_delete_wallet => """Ta czynność usunie ten portfel. Czy chcesz kontynuować?""";
  @override
  String get picker_description => """Aby wybrać ChangeNOW lub MorphToken, najpierw zmień swoją parę handlową""";
  @override
  String get change_wallet_alert_title => """Zmień obecny portfel""";
  @override
  String change_wallet_alert_content(String wallet_name) => """Czy chcesz zmienić obecny portfel na ${wallet_name}?""";
  @override
  String get creating_new_wallet => """Tworzenie nowego portfela""";
  @override
  String creating_new_wallet_error(String description) => """Pomyłka: ${description}""";
  @override
  String get seed_alert_title => """Uwaga""";
  @override
  String get seed_alert_content => """Ziarno to jedyny sposób na odzyskanie portfela. Zapisałeś to?""";
  @override
  String get seed_alert_back => """Wróć""";
  @override
  String get seed_alert_yes => """Tak""";
  @override
  String get wallet_name_alert_content => """Istnieje portfel o tej samej nazwie""";
  @override
  String get exchange_sync_alert_content => """Poczekaj, aż portfel zostanie zsynchronizowany""";
  @override
  String get pre_seed_title => """WAŻNY""";
  @override
  String pre_seed_description(String words) => """Na następnej stronie zobaczysz serię ${words} słów. To jest Twoje unikalne i prywatne ziarno i jest to JEDYNY sposób na odzyskanie portfela w przypadku utraty lub awarii. Twoim obowiązkiem jest zapisanie go i przechowywanie w bezpiecznym miejscu poza aplikacją Cake Wallet.""";
  @override
  String get pre_seed_button_text => """Rozumiem. Pokaż mi moje nasienie""";
  @override
  String get xmr_to_error => """Pomyłka XMR.TO""";
  @override
  String get xmr_to_error_description => """Nieprawidłowa kwota. Maksymalny limit 8 cyfr po przecinku""";
  @override
  String provider_error(String provider) => """${provider} pomyłka""";
  @override
  String get use_ssl => """Użyj SSL""";
  @override
  String get color_theme => """Motyw kolorystyczny""";
  @override
  String get light_theme => """Lekki""";
  @override
  String get bright_theme => """Jasny""";
  @override
  String get dark_theme => """Ciemny""";
  @override
  String get enter_your_note => """Wpisz notatkę…""";
  @override
  String get note_optional => """Notatka (opcjonalnie)""";
  @override
  String get note_tap_to_change => """Notatka (dotknij, aby zmienić)""";
  @override
  String get transaction_key => """Klucz transakcji""";
  @override
  String get confirmations => """Potwierdzenia""";
  @override
  String get recipient_address => """Adres odbiorcy""";
  @override
  String get extra_id => """Dodatkowy ID:""";
  @override
  String get destination_tag => """Tag docelowy:""";
  @override
  String get memo => """Notatka:""";
  @override
  String get backup => """Kopię zapasową""";
  @override
  String get change_password => """Zmień hasło""";
  @override
  String get backup_password => """Hasło zapasowe""";
  @override
  String get write_down_backup_password => """Zapisz swoje hasło zapasowe, które jest używane do importowania plików kopii zapasowych.""";
  @override
  String get export_backup => """Eksportuj kopię zapasową""";
  @override
  String get save_backup_password => """Upewnij się, że zapisałeś swoje zapasowe hasło. Bez tego nie będziesz mógł importować plików kopii zapasowej.""";
  @override
  String get backup_file => """Plik kopii zapasowej""";
  @override
  String get edit_backup_password => """Edytuj hasło kopii zapasowej""";
  @override
  String get save_backup_password_alert => """Zapisz hasło zapasowe""";
  @override
  String get change_backup_password_alert => """Twoje poprzednie pliki kopii zapasowej nie będą dostępne do zaimportowania z nowym hasłem kopii zapasowej. Nowe hasło zapasowe będzie używane tylko dla nowych plików kopii zapasowych. Czy na pewno chcesz zmienić hasło zapasowe?""";
  @override
  String get enter_backup_password => """Wprowadź tutaj hasło zapasowe""";
  @override
  String get select_backup_file => """Wybierz plik kopii zapasowej""";
  @override
  String get import => """Import""";
  @override
  String get please_select_backup_file => """Wybierz plik kopii zapasowej i wprowadź hasło zapasowe.""";
  @override
  String get fixed_rate => """Stała stawka""";
  @override
  String get fixed_rate_alert => """Będziesz mógł wprowadzić kwotę otrzymaną, gdy zaznaczony jest tryb stałej stawki. Czy chcesz przejść do trybu stałej stawki?""";
  @override
  String get xlm_extra_info => """Nie zapomnij podać identyfikatora notatki podczas wysyłania transakcji XLM do wymiany""";
  @override
  String get xrp_extra_info => """Nie zapomnij podać tagu docelowego podczas wysyłania transakcji XRP do wymiany""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Jeśli chcesz wymienić XMR z salda Cake Wallet Monero, najpierw przełącz się na portfel Monero.""";
  @override
  String get confirmed => """Potwierdzony""";
  @override
  String get unconfirmed => """Niepotwierdzony""";
  @override
  String get displayable => """Wyświetlane""";
  @override
  String get submit_request => """złożyć wniosek""";
  @override
  String get buy_alert_content => """Obecnie obsługujemy tylko zakup Bitcoin i Litecoin. Aby kupić Bitcoin lub Litecoin, utwórz lub przełącz się na swój portfel Bitcoin lub Litecoin.""";
  @override
  String get outdated_electrum_wallet_description => """Nowe portfele Bitcoin utworzone w Cake mają teraz ziarno składające się z 24 słów. Konieczne jest utworzenie nowego portfela Bitcoin i przeniesienie wszystkich środków do nowego portfela na 24 słowa oraz zaprzestanie korzystania z portfeli z zalążkiem na 12 słów. Zrób to natychmiast, aby zabezpieczyć swoje fundusze.""";
  @override
  String get understand => """Rozumiem""";
  @override
  String get apk_update => """Aktualizacja APK""";
  @override
  String get buy_bitcoin => """Kup Bitcoin""";
  @override
  String get buy_with => """Kup za pomocą""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """Wartość kwoty musi być większa lub równa ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """Jeśli ten portfel ma 12-wyrazowy seed i został utworzony w Cake, NIE Wpłacaj Bitcoina do tego portfela. Wszelkie BTC przeniesione do tego portfela mogą zostać utracone. Utwórz nowy portfel z 24 słowami (dotknij menu w prawym górnym rogu, wybierz Portfele, wybierz Utwórz nowy portfel, a następnie Bitcoin) i NATYCHMIAST przenieś tam swoje BTC. Nowe (24 słowa) portfele BTC firmy Cake są bezpieczne""";
  @override
  String get do_not_show_me => """Nie pokazuj mi tego ponownie""";
  @override
  String get unspent_coins_title => """Niewydane monety""";
  @override
  String get unspent_coins_details_title => """Szczegóły niewydanych monet""";
  @override
  String get freeze => """Zamrażać""";
  @override
  String get coin_control => """Kontrola monet (opcjonalnie)""";
  @override
  String get address_detected => """Wykryto adres""";
  @override
  String address_from_domain(String domain) => """Dostałeś adres od unstoppable domain ${domain}""";
}

class $en extends S {
  const $en();
}

class $hi extends S {
  const $hi();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """स्वागत हे सेवा मेरे""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """Monero और Bitcoin के लिए बहुत बढ़िया बटुआ""";
  @override
  String get please_make_selection => """कृपया नीचे चयन करें अपना बटुआ बनाएं या पुनर्प्राप्त करें.""";
  @override
  String get create_new => """नया बटुआ बनाएँ""";
  @override
  String get restore_wallet => """वॉलेट को पुनर्स्थापित करें""";
  @override
  String get accounts => """हिसाब किताब""";
  @override
  String get edit => """संपादित करें""";
  @override
  String get account => """लेखा""";
  @override
  String get add => """जोड़ना""";
  @override
  String get address_book => """पता पुस्तिका""";
  @override
  String get contact => """संपर्क करें""";
  @override
  String get please_select => """कृपया चुने:""";
  @override
  String get cancel => """रद्द करना""";
  @override
  String get ok => """ठीक है""";
  @override
  String get contact_name => """संपर्क नाम""";
  @override
  String get reset => """रीसेट""";
  @override
  String get save => """बचाना""";
  @override
  String get address_remove_contact => """संपर्क हटाये""";
  @override
  String get address_remove_content => """क्या आप वाकई चयनित संपर्क को हटाना चाहते हैं?""";
  @override
  String get authenticated => """प्रमाणीकृत""";
  @override
  String get authentication => """प्रमाणीकरण""";
  @override
  String failed_authentication(String state_error) => """प्रमाणीकरण विफल. ${state_error}""";
  @override
  String get wallet_menu => """बटुआ मेनू""";
  @override
  String Blocks_remaining(String status) => """${status} शेष रहते हैं""";
  @override
  String get please_try_to_connect_to_another_node => """कृपया दूसरे नोड से कनेक्ट करने का प्रयास करें""";
  @override
  String get xmr_hidden => """छिपा हुआ""";
  @override
  String get xmr_available_balance => """उपलब्ध शेष राशि""";
  @override
  String get xmr_full_balance => """पूरा संतुलन""";
  @override
  String get send => """संदेश""";
  @override
  String get receive => """प्राप्त करना""";
  @override
  String get transactions => """लेन-देन""";
  @override
  String get incoming => """आने वाली""";
  @override
  String get outgoing => """निवर्तमान""";
  @override
  String get transactions_by_date => """तारीख से लेन-देन""";
  @override
  String get trades => """ट्रेडों""";
  @override
  String get filters => """फ़िल्टर""";
  @override
  String get today => """आज""";
  @override
  String get yesterday => """बिता कल""";
  @override
  String get received => """प्राप्त किया""";
  @override
  String get sent => """भेज दिया""";
  @override
  String get pending => """ (अपूर्ण)""";
  @override
  String get rescan => """पुन: स्कैन""";
  @override
  String get reconnect => """रिकनेक्ट""";
  @override
  String get wallets => """पर्स""";
  @override
  String get show_seed => """बीज दिखाओ""";
  @override
  String get show_keys => """बीज / कुंजियाँ दिखाएँ""";
  @override
  String get address_book_menu => """पता पुस्तिका""";
  @override
  String get reconnection => """पुनर्संयोजन""";
  @override
  String get reconnect_alert_text => """क्या आप पुन: कनेक्ट होना सुनिश्चित करते हैं?""";
  @override
  String get exchange => """अदला बदली""";
  @override
  String get clear => """स्पष्ट""";
  @override
  String get refund_address => """वापसी का पता""";
  @override
  String get change_exchange_provider => """एक्सचेंज प्रदाता बदलें""";
  @override
  String get you_will_send => """से रूपांतरित करें""";
  @override
  String get you_will_get => """में बदलें""";
  @override
  String get amount_is_guaranteed => """प्राप्त राशि की गारंटी है""";
  @override
  String get amount_is_estimate => """प्राप्त राशि एक अनुमान है""";
  @override
  String powered_by(String title) => """द्वारा संचालित ${title}""";
  @override
  String get error => """त्रुटि""";
  @override
  String get estimated => """अनुमानित""";
  @override
  String min_value(String value, String currency) => """मिन: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """मैक्स: ${value} ${currency}""";
  @override
  String get change_currency => """मुद्रा परिवर्तन करें""";
  @override
  String get copy_id => """प्रतिलिपि ID""";
  @override
  String get exchange_result_write_down_trade_id => """जारी रखने के लिए कृपया ट्रेड ID की प्रतिलिपि बनाएँ या लिखें.""";
  @override
  String get trade_id => """व्यापार ID:""";
  @override
  String get copied_to_clipboard => """क्लिपबोर्ड पर नकल""";
  @override
  String get saved_the_trade_id => """मैंने व्यापार बचा लिया है ID""";
  @override
  String get fetching => """ला रहा है""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """रकम: """;
  @override
  String get payment_id => """भुगतान ID: """;
  @override
  String get status => """स्थिति: """;
  @override
  String get offer_expires_in => """में ऑफर समाप्त हो रहा है: """;
  @override
  String trade_is_powered_by(String provider) => """यह व्यापार द्वारा संचालित है ${provider}""";
  @override
  String get copy_address => """पता कॉपी करें""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """पुष्टि दबाकर, आप भेज रहे होंगे ${fetchingLabel} ${from} अपने बटुए से ${walletName} नीचे दिखाए गए पते पर। या आप अपने बाहरी वॉलेट से नीचे के पते पर भेज सकते हैं / क्यूआर कोड पर भेज सकते हैं।

कृपया जारी रखने या राशि बदलने के लिए वापस जाने के लिए पुष्टि करें दबाएं.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """आपको अगले पृष्ठ पर दिखाए गए पते पर न्यूनतम ${fetchingLabel} ${from} भेजना होगा। यदि आप ${fetchingLabel} ${from} से कम राशि भेजते हैं तो यह परिवर्तित नहीं हो सकती है और इसे वापस नहीं किया जा सकता है।""";
  @override
  String get exchange_result_write_down_ID => """*कृपया ऊपर दिखाए गए अपने ID को कॉपी या लिख लें.""";
  @override
  String get confirm => """की पुष्टि करें""";
  @override
  String get confirm_sending => """भेजने की पुष्टि करें""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """लेन-देन करें
रकम: ${amount}
शुल्क: ${fee}""";
  @override
  String get sending => """भेजना""";
  @override
  String get transaction_sent => """भेजा गया लेन-देन""";
  @override
  String get expired => """समय सीमा समाप्त""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """संदेश XMR""";
  @override
  String get exchange_new_template => """नया टेम्पलेट""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """अपना पिन दर्ज करो""";
  @override
  String get loading_your_wallet => """अपना बटुआ लोड कर रहा है""";
  @override
  String get new_wallet => """नया बटुआ""";
  @override
  String get wallet_name => """बटुए का नाम""";
  @override
  String get continue_text => """जारी रहना""";
  @override
  String get choose_wallet_currency => """कृपया बटुआ मुद्रा चुनें:""";
  @override
  String get node_new => """नया नोड""";
  @override
  String get node_address => """नोड पता""";
  @override
  String get node_port => """नोड पोर्ट""";
  @override
  String get login => """लॉग इन करें""";
  @override
  String get password => """पारण शब्द""";
  @override
  String get nodes => """नोड्स""";
  @override
  String get node_reset_settings_title => """सेटिंग्स को दुबारा करें""";
  @override
  String get nodes_list_reset_to_default_message => """क्या आप वाकई सेटिंग को डिफ़ॉल्ट पर रीसेट करना चाहते हैं?""";
  @override
  String change_current_node(String node) => """क्या आप वर्तमान नोड को बदलना सुनिश्चित करते हैं ${node}?""";
  @override
  String get change => """परिवर्तन""";
  @override
  String get remove_node => """नोड निकालें""";
  @override
  String get remove_node_message => """क्या आप वाकई चयनित नोड को निकालना चाहते हैं?""";
  @override
  String get remove => """हटाना""";
  @override
  String get delete => """हटाएं""";
  @override
  String get add_new_node => """नया नोड जोड़ें""";
  @override
  String get change_current_node_title => """वर्तमान नोड बदलें""";
  @override
  String get node_test => """परीक्षा""";
  @override
  String get node_connection_successful => """कनेक्शन सफल रहा""";
  @override
  String get node_connection_failed => """कनेक्शन विफल रहा""";
  @override
  String get new_node_testing => """नई नोड परीक्षण""";
  @override
  String get use => """उपयोग """;
  @override
  String get digit_pin => """-अंक पिन""";
  @override
  String get share_address => """पता साझा करें""";
  @override
  String get receive_amount => """रकम""";
  @override
  String get subaddresses => """उप पते""";
  @override
  String get addresses => """पतों""";
  @override
  String get scan_qr_code => """पता प्राप्त करने के लिए QR कोड स्कैन करें""";
  @override
  String get rename => """नाम बदलें""";
  @override
  String get choose_account => """खाता चुनें""";
  @override
  String get create_new_account => """नया खाता बनाएँ""";
  @override
  String get accounts_subaddresses => """लेखा और उपदेस""";
  @override
  String get restore_restore_wallet => """वॉलेट को पुनर्स्थापित करें""";
  @override
  String get restore_title_from_seed_keys => """बीज / कुंजियों से पुनर्स्थापित करें""";
  @override
  String get restore_description_from_seed_keys => """अपने बटुए को बीज से वापस लें/वे कुंजियाँ जिन्हें आपने सुरक्षित स्थान पर सहेजा है""";
  @override
  String get restore_next => """आगामी""";
  @override
  String get restore_title_from_backup => """बैक-अप फ़ाइल से पुनर्स्थापित करें""";
  @override
  String get restore_description_from_backup => """आप से पूरे केक वॉलेट एप्लिकेशन को पुनर्स्थापित कर सकते हैं आपकी बैक-अप फ़ाइल""";
  @override
  String get restore_seed_keys_restore => """बीज / कुंजी पुनर्स्थापित करें""";
  @override
  String get restore_title_from_seed => """बीज से पुनर्स्थापित करें""";
  @override
  String get restore_description_from_seed => """या तो 25 शब्द से अपने वॉलेट को पुनर्स्थापित करें या 13 शब्द संयोजन कोड""";
  @override
  String get restore_title_from_keys => """कुंजी से पुनर्स्थापित करें""";
  @override
  String get restore_description_from_keys => """अपने वॉलेट को जेनरेट से पुनर्स्थापित करें आपकी निजी कुंजी से कीस्ट्रोक्स सहेजे गए""";
  @override
  String get restore_wallet_name => """बटुए का नाम""";
  @override
  String get restore_address => """पता""";
  @override
  String get restore_view_key_private => """कुंजी देखें (निजी)""";
  @override
  String get restore_spend_key_private => """कुंजी खर्च करें (निजीe)""";
  @override
  String get restore_recover => """वसूली""";
  @override
  String get restore_wallet_restore_description => """बटुआ विवरण पुनर्स्थापित करें""";
  @override
  String get restore_new_seed => """नया बीज""";
  @override
  String get restore_active_seed => """सक्रिय बीज""";
  @override
  String get restore_bitcoin_description_from_seed => """24 शब्द संयोजन कोड से अपने वॉलेट को पुनर्स्थापित करें""";
  @override
  String get restore_bitcoin_description_from_keys => """अपने निजी कुंजी से उत्पन्न WIF स्ट्रिंग से अपने वॉलेट को पुनर्स्थापित करें""";
  @override
  String get restore_bitcoin_title_from_keys => """WIF से पुनर्स्थापित करें""";
  @override
  String get restore_from_date_or_blockheight => """कृपया इस वॉलेट को बनाने से कुछ दिन पहले एक तारीख दर्ज करें। या यदि आप ब्लॉकचेट जानते हैं, तो कृपया इसके बजाय इसे दर्ज करें""";
  @override
  String get seed_reminder => """यदि आप अपना फोन खो देते हैं या मिटा देते हैं तो कृपया इन्हें लिख लें""";
  @override
  String get seed_title => """बीज""";
  @override
  String get seed_share => """बीज साझा करें""";
  @override
  String get copy => """प्रतिलिपि""";
  @override
  String get seed_language_choose => """कृपया बीज भाषा चुनें:""";
  @override
  String get seed_choose => """बीज भाषा चुनें""";
  @override
  String get seed_language_next => """आगामी""";
  @override
  String get seed_language_english => """अंग्रेज़ी""";
  @override
  String get seed_language_chinese => """चीनी""";
  @override
  String get seed_language_dutch => """डच""";
  @override
  String get seed_language_german => """जर्मन""";
  @override
  String get seed_language_japanese => """जापानी""";
  @override
  String get seed_language_portuguese => """पुर्तगाली""";
  @override
  String get seed_language_russian => """रूसी""";
  @override
  String get seed_language_spanish => """स्पेनिश""";
  @override
  String get send_title => """संदेश""";
  @override
  String get send_your_wallet => """आपका बटुआ""";
  @override
  String send_address(String cryptoCurrency) => """${cryptoCurrency} पता""";
  @override
  String get send_payment_id => """भुगतान ID (ऐच्छिक)""";
  @override
  String get all => """सब""";
  @override
  String get send_error_minimum_value => """राशि का न्यूनतम मूल्य 0.01 है""";
  @override
  String get send_error_currency => """मुद्रा में केवल संख्याएँ हो सकती हैं""";
  @override
  String get send_estimated_fee => """अनुमानित शुल्क:""";
  @override
  String send_priority(String transactionPriority) => """वर्तमान में शुल्क निर्धारित है ${transactionPriority} प्राथमिकता.
लेन-देन की प्राथमिकता को सेटिंग्स में समायोजित किया जा सकता है""";
  @override
  String get send_creating_transaction => """लेन-देन बनाना""";
  @override
  String get send_templates => """टेम्पलेट्स""";
  @override
  String get send_new => """नया""";
  @override
  String get send_amount => """रकम:""";
  @override
  String get send_fee => """शुल्क:""";
  @override
  String get send_name => """नाम""";
  @override
  String get send_got_it => """समझ गया""";
  @override
  String get send_sending => """भेजना...""";
  @override
  String send_success(String crypto) => """आपका ${crypto} सफलतापूर्वक भेजा गया""";
  @override
  String get settings_title => """सेटिंग्स""";
  @override
  String get settings_nodes => """नोड्स""";
  @override
  String get settings_current_node => """वर्तमान नोड""";
  @override
  String get settings_wallets => """पर्स""";
  @override
  String get settings_display_balance_as => """के रूप में संतुलन प्रदर्शित करें""";
  @override
  String get settings_currency => """मुद्रा""";
  @override
  String get settings_fee_priority => """शुल्क प्राथमिकता""";
  @override
  String get settings_save_recipient_address => """प्राप्तकर्ता का पता सहेजें""";
  @override
  String get settings_personal => """निजी""";
  @override
  String get settings_change_pin => """पिन बदलें""";
  @override
  String get settings_change_language => """भाषा बदलो""";
  @override
  String get settings_allow_biometrical_authentication => """बायोमेट्रिक प्रमाणीकरण की अनुमति दें""";
  @override
  String get settings_dark_mode => """डार्क मोड""";
  @override
  String get settings_transactions => """लेन-देन""";
  @override
  String get settings_trades => """ट्रेडों""";
  @override
  String get settings_display_on_dashboard_list => """डैशबोर्ड सूची पर प्रदर्शित करें""";
  @override
  String get settings_all => """सब""";
  @override
  String get settings_only_trades => """केवल ट्रेड करता है""";
  @override
  String get settings_only_transactions => """केवल लेन-देन""";
  @override
  String get settings_none => """कोई नहीं""";
  @override
  String get settings_support => """समर्थन""";
  @override
  String get settings_terms_and_conditions => """नियम और शर्तें""";
  @override
  String get pin_is_incorrect => """पिन गलत है""";
  @override
  String get setup_pin => """पिन सेट करें""";
  @override
  String get enter_your_pin_again => """फिर से अपना पिन डालें""";
  @override
  String get setup_successful => """आपका पिन सफलतापूर्वक सेट हो गया है""";
  @override
  String get wallet_keys => """बटुआ बीज / चाबियाँ""";
  @override
  String get wallet_seed => """बटुआ का बीज""";
  @override
  String get private_key => """निजी चाबी""";
  @override
  String get public_key => """सार्वजनिक कुंजी""";
  @override
  String get view_key_private => """कुंजी देखें(निजी)""";
  @override
  String get view_key_public => """कुंजी देखें (जनता)""";
  @override
  String get spend_key_private => """खर्च करना (निजी)""";
  @override
  String get spend_key_public => """खर्च करना (जनता)""";
  @override
  String copied_key_to_clipboard(String key) => """की नकल की ${key} क्लिपबोर्ड पर""";
  @override
  String get new_subaddress_title => """नया पता""";
  @override
  String get new_subaddress_label_name => """लेबल का नाम""";
  @override
  String get new_subaddress_create => """सर्जन करना""";
  @override
  String get subaddress_title => """उपखंड सूची""";
  @override
  String get trade_details_title => """व्यापार विवरण""";
  @override
  String get trade_details_id => """आईडी""";
  @override
  String get trade_details_state => """राज्य""";
  @override
  String get trade_details_fetching => """ला रहा है""";
  @override
  String get trade_details_provider => """प्रदाता""";
  @override
  String get trade_details_created_at => """पर बनाया गया""";
  @override
  String get trade_details_pair => """जोड़ा""";
  @override
  String trade_details_copied(String title) => """${title} क्लिपबोर्ड पर नकल""";
  @override
  String get trade_history_title => """व्यापार का इतिहास""";
  @override
  String get transaction_details_title => """लेनदेन का विवरण""";
  @override
  String get transaction_details_transaction_id => """लेनदेन आईडी""";
  @override
  String get transaction_details_date => """तारीख""";
  @override
  String get transaction_details_height => """ऊंचाई""";
  @override
  String get transaction_details_amount => """रकम""";
  @override
  String get transaction_details_fee => """शुल्क""";
  @override
  String transaction_details_copied(String title) => """${title} क्लिपबोर्ड पर नकल""";
  @override
  String get transaction_details_recipient_address => """प्राप्तकर्ता का पता""";
  @override
  String get wallet_list_title => """Monero बटुआ""";
  @override
  String get wallet_list_create_new_wallet => """नया बटुआ बनाएँ""";
  @override
  String get wallet_list_restore_wallet => """वॉलेट को पुनर्स्थापित करें""";
  @override
  String get wallet_list_load_wallet => """वॉलेट लोड करें""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """लोड हो रहा है ${wallet_name} बटुआ""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """लोड करने में विफल ${wallet_name} बटुआ. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """निकाला जा रहा है ${wallet_name} बटुआ""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """निकालने में विफल ${wallet_name} बटुआ. ${error}""";
  @override
  String get widgets_address => """पता""";
  @override
  String get widgets_restore_from_blockheight => """ब्लॉकचेन से पुनर्स्थापित करें""";
  @override
  String get widgets_restore_from_date => """दिनांक से पुनर्स्थापित करें""";
  @override
  String get widgets_or => """या""";
  @override
  String get widgets_seed => """बीज""";
  @override
  String router_no_route(String name) => """के लिए कोई मार्ग निर्धारित नहीं है ${name}""";
  @override
  String get error_text_account_name => """खाता नाम में केवल अक्षर, संख्याएं हो सकती हैं
और 1 और 15 वर्णों के बीच लंबा होना चाहिए""";
  @override
  String get error_text_contact_name => """संपर्क नाम शामिल नहीं हो सकता ` , ' " प्रतीकों
और 1 और 32 वर्णों के बीच लंबा होना चाहिए""";
  @override
  String get error_text_address => """वॉलेट पता प्रकार के अनुरूप होना चाहिए
क्रिप्टोकरेंसी का""";
  @override
  String get error_text_node_address => """कृपया एक IPv4 पता दर्ज करें""";
  @override
  String get error_text_node_port => """नोड पोर्ट में केवल 0 और 65535 के बीच संख्याएँ हो सकती हैं""";
  @override
  String get error_text_payment_id => """पेमेंट आईडी केवल हेक्स में 16 से 64 चार्ट तक हो सकती है""";
  @override
  String get error_text_xmr => """एक्सएमआर मूल्य उपलब्ध शेष राशि से अधिक नहीं हो सकता.
अंश अंकों की संख्या 12 से कम या इसके बराबर होनी चाहिए""";
  @override
  String get error_text_fiat => """राशि का मूल्य उपलब्ध शेष राशि से अधिक नहीं हो सकता.
अंश अंकों की संख्या कम या 2 के बराबर होनी चाहिए""";
  @override
  String get error_text_subaddress_name => """सबड्रेस नाम नहीं हो सकता` , ' " प्रतीकों
और 1 और 20 वर्णों के बीच लंबा होना चाहिए""";
  @override
  String get error_text_amount => """राशि में केवल संख्याएँ हो सकती हैं""";
  @override
  String get error_text_wallet_name => """वॉलेट नाम में केवल अक्षर, संख्याएं हो सकती हैं
और 1 और 20 वर्णों के बीच लंबा होना चाहिए""";
  @override
  String get error_text_keys => """वॉलेट कीज़ में हेक्स में केवल 64 वर्ण हो सकते हैं""";
  @override
  String get error_text_crypto_currency => """अंश अंकों की संख्या
12 से कम या इसके बराबर होना चाहिए""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """व्यापार ${provider} के लिए नहीं बनाया गया है। राशि कम है तो न्यूनतम: ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """व्यापार ${provider} के लिए नहीं बनाया गया है। राशि अधिक है तो अधिकतम: ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """व्यापार ${provider} के लिए नहीं बनाया गया है। लोडिंग की सीमाएं विफल रहीं""";
  @override
  String get error_text_template => """टेम्प्लेट का नाम और पता नहीं हो सकता ` , ' " प्रतीकों
और 1 और 106 वर्णों के बीच लंबा होना चाहिए""";
  @override
  String get auth_store_ban_timeout => """समय की पाबंदी""";
  @override
  String get auth_store_banned_for => """के लिए प्रतिबंधित है """;
  @override
  String get auth_store_banned_minutes => """ मिनट""";
  @override
  String get auth_store_incorrect_password => """गलत पिन""";
  @override
  String get wallet_store_monero_wallet => """मोनरो वॉलेट""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """गलत बीज की लंबाई""";
  @override
  String get full_balance => """पूर्ण संतुलन""";
  @override
  String get available_balance => """उपलब्ध शेष राशि""";
  @override
  String get hidden_balance => """छिपा हुआ संतुलन""";
  @override
  String get sync_status_syncronizing => """सिंक्रनाइज़ करने""";
  @override
  String get sync_status_syncronized => """सिंक्रनाइज़""";
  @override
  String get sync_status_not_connected => """जुड़े नहीं हैं""";
  @override
  String get sync_status_starting_sync => """सिताज़ा करना""";
  @override
  String get sync_status_failed_connect => """डिस्कनेक्ट किया गया""";
  @override
  String get sync_status_connecting => """कनेक्ट""";
  @override
  String get sync_status_connected => """जुड़े हुए""";
  @override
  String get transaction_priority_slow => """धीरे""";
  @override
  String get transaction_priority_regular => """नियमित""";
  @override
  String get transaction_priority_medium => """मध्यम""";
  @override
  String get transaction_priority_fast => """उपवास""";
  @override
  String get transaction_priority_fastest => """सबसे तेजी से""";
  @override
  String trade_for_not_created(String title) => """के लिए व्यापार ${title} निर्मित नहीं है.""";
  @override
  String get trade_not_created => """व्यापार नहीं बनाया गया.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """व्यापार ${tradeId} of ${title} नहीं मिला.""";
  @override
  String get trade_not_found => """व्यापार नहीं मिला""";
  @override
  String get trade_state_pending => """विचाराधीन""";
  @override
  String get trade_state_confirming => """पुष्टि""";
  @override
  String get trade_state_trading => """व्यापार""";
  @override
  String get trade_state_traded => """ट्रेडेड""";
  @override
  String get trade_state_complete => """पूर्ण""";
  @override
  String get trade_state_to_be_created => """बनाए जाने के लिए""";
  @override
  String get trade_state_unpaid => """अवैतनिक""";
  @override
  String get trade_state_underpaid => """के तहत भुगतान किया""";
  @override
  String get trade_state_paid_unconfirmed => """अपुष्ट भुगतान किया""";
  @override
  String get trade_state_paid => """भुगतान किया है""";
  @override
  String get trade_state_btc_sent => """भेज दिया""";
  @override
  String get trade_state_timeout => """समय समाप्त""";
  @override
  String get trade_state_created => """बनाया था""";
  @override
  String get trade_state_finished => """ख़त्म होना""";
  @override
  String get change_language => """भाषा बदलो""";
  @override
  String change_language_to(String language) => """को भाषा बदलें ${language}?""";
  @override
  String get paste => """पेस्ट करें""";
  @override
  String get restore_from_seed_placeholder => """कृपया अपना कोड वाक्यांश यहां दर्ज करें या पेस्ट करें""";
  @override
  String get add_new_word => """नया शब्द जोड़ें""";
  @override
  String get incorrect_seed => """दर्ज किया गया पाठ मान्य नहीं है।""";
  @override
  String get biometric_auth_reason => """प्रमाणित करने के लिए अपने फ़िंगरप्रिंट को स्कैन करें""";
  @override
  String version(String currentVersion) => """संस्करण ${currentVersion}""";
  @override
  String get openalias_alert_title => """XMR प्राप्तकर्ता का पता लगाया""";
  @override
  String openalias_alert_content(String recipient_name) => """आपको धनराशि भेजी जाएगी
${recipient_name}""";
  @override
  String get card_address => """पता:""";
  @override
  String get buy => """खरीदें""";
  @override
  String get placeholder_transactions => """आपके लेनदेन यहां प्रदर्शित होंगे""";
  @override
  String get placeholder_contacts => """आपके संपर्क यहां प्रदर्शित होंगे""";
  @override
  String get template => """खाका""";
  @override
  String get confirm_delete_template => """यह क्रिया इस टेम्पलेट को हटा देगी। क्या आप जारी रखना चाहते हैं?""";
  @override
  String get confirm_delete_wallet => """यह क्रिया इस वॉलेट को हटा देगी। क्या आप जारी रखना चाहते हैं?""";
  @override
  String get picker_description => """ChangeNOW या MorphToken चुनने के लिए, कृपया अपनी ट्रेडिंग जोड़ी को पहले बदलें""";
  @override
  String get change_wallet_alert_title => """वर्तमान बटुआ बदलें""";
  @override
  String change_wallet_alert_content(String wallet_name) => """क्या आप करंट वॉलेट को बदलना चाहते हैं ${wallet_name}?""";
  @override
  String get creating_new_wallet => """नया बटुआ बनाना""";
  @override
  String creating_new_wallet_error(String description) => """त्रुटि: ${description}""";
  @override
  String get seed_alert_title => """ध्यान""";
  @override
  String get seed_alert_content => """बीज आपके बटुए को पुनर्प्राप्त करने का एकमात्र तरीका है। क्या आपने इसे लिखा है?""";
  @override
  String get seed_alert_back => """वापस जाओ""";
  @override
  String get seed_alert_yes => """हाँ मेरे पास है""";
  @override
  String get wallet_name_alert_content => """समान नाम वाला वॉलेट मौजूद है""";
  @override
  String get exchange_sync_alert_content => """कृपया प्रतीक्षा करें जब तक आपका बटुआ सिंक्रनाइज़ नहीं किया जाता है""";
  @override
  String get pre_seed_title => """महत्वपूर्ण""";
  @override
  String pre_seed_description(String words) => """अगले पेज पर आपको ${words} शब्दों की एक श्रृंखला दिखाई देगी। यह आपका अद्वितीय और निजी बीज है और नुकसान या खराबी के मामले में अपने बटुए को पुनर्प्राप्त करने का एकमात्र तरीका है। यह आपकी जिम्मेदारी है कि इसे नीचे लिखें और इसे Cake Wallet ऐप के बाहर सुरक्षित स्थान पर संग्रहीत करें।""";
  @override
  String get pre_seed_button_text => """मै समझता हुँ। मुझे अपना बीज दिखाओ""";
  @override
  String get xmr_to_error => """XMR.TO त्रुटि""";
  @override
  String get xmr_to_error_description => """अवैध राशि। दशमलव बिंदु के बाद अधिकतम सीमा 8 अंक""";
  @override
  String provider_error(String provider) => """${provider} त्रुटि""";
  @override
  String get use_ssl => """उपयोग SSL""";
  @override
  String get color_theme => """रंग विषय""";
  @override
  String get light_theme => """रोशनी""";
  @override
  String get bright_theme => """उज्ज्वल""";
  @override
  String get dark_theme => """अंधेरा""";
  @override
  String get enter_your_note => """अपना नोट दर्ज करें ...""";
  @override
  String get note_optional => """नोट (वैकल्पिक)""";
  @override
  String get note_tap_to_change => """नोट (टैप टू चेंज)""";
  @override
  String get transaction_key => """लेन-देन की""";
  @override
  String get confirmations => """पुष्टिकरण""";
  @override
  String get recipient_address => """प्राप्तकर्ता का पता""";
  @override
  String get extra_id => """अतिरिक्त आईडी:""";
  @override
  String get destination_tag => """गंतव्य टैग:""";
  @override
  String get memo => """ज्ञापन:""";
  @override
  String get backup => """बैकअप""";
  @override
  String get change_password => """पासवर्ड बदलें""";
  @override
  String get backup_password => """बैकअप पासवर्ड""";
  @override
  String get write_down_backup_password => """कृपया अपना बैकअप पासवर्ड लिखें, जिसका उपयोग आपकी बैकअप फ़ाइलों के आयात के लिए किया जाता है।""";
  @override
  String get export_backup => """निर्यात बैकअप""";
  @override
  String get save_backup_password => """कृपया सुनिश्चित करें कि आपने अपना बैकअप पासवर्ड सहेज लिया है। आप इसके बिना अपनी बैकअप फ़ाइलों को आयात नहीं कर पाएंगे।""";
  @override
  String get backup_file => """बैकअपफ़ाइल""";
  @override
  String get edit_backup_password => """बैकअप पासवर्ड संपादित करें""";
  @override
  String get save_backup_password_alert => """बैकअप पासवर्ड सेव करें""";
  @override
  String get change_backup_password_alert => """आपकी पिछली बैकअप फाइलें नए बैकअप पासवर्ड के साथ आयात करने के लिए उपलब्ध नहीं होंगी। नए बैकअप पासवर्ड का उपयोग केवल नई बैकअप फ़ाइलों के लिए किया जाएगा। क्या आप वाकई बैकअप पासवर्ड बदलना चाहते हैं?""";
  @override
  String get enter_backup_password => """यहां बैकअप पासवर्ड डालें""";
  @override
  String get select_backup_file => """बैकअप फ़ाइल का चयन करें""";
  @override
  String get import => """आयात""";
  @override
  String get please_select_backup_file => """कृपया बैकअप फ़ाइल चुनें और बैकअप पासवर्ड डालें।""";
  @override
  String get fixed_rate => """निर्धारित दर""";
  @override
  String get fixed_rate_alert => """फिक्स्ड रेट मोड की जांच करने पर आप प्राप्त राशि दर्ज कर पाएंगे। क्या आप निश्चित दर मोड पर स्विच करना चाहते हैं?""";
  @override
  String get xlm_extra_info => """एक्सचेंज के लिए XLM ट्रांजेक्शन भेजते समय मेमो आईडी निर्दिष्ट करना न भूलें""";
  @override
  String get xrp_extra_info => """एक्सचेंज के लिए एक्सआरपी लेनदेन भेजते समय कृपया गंतव्य टैग निर्दिष्ट करना न भूलें""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """यदि आप अपने केक वॉलेट मोनेरो बैलेंस से एक्सएमआर का आदान-प्रदान करना चाहते हैं, तो कृपया अपने मोनेरो वॉलेट में जाएं।""";
  @override
  String get confirmed => """की पुष्टि की""";
  @override
  String get unconfirmed => """अपुष्ट""";
  @override
  String get displayable => """प्रदर्शन योग्य""";
  @override
  String get submit_request => """एक अनुरोध सबमिट करें""";
  @override
  String get buy_alert_content => """वर्तमान में हम केवल बिटकॉइन और लिटकोइन की खरीद का समर्थन करते हैं। बिटकॉइन या लाइटकोइन खरीदने के लिए, कृपया अपना बिटकॉइन या लाइटकोइन वॉलेट बनाएं या स्विच करें।""";
  @override
  String get outdated_electrum_wallet_description => """केक में बनाए गए नए बिटकॉइन वॉलेट में अब 24-शब्द का बीज है। यह अनिवार्य है कि आप एक नया बिटकॉइन वॉलेट बनाएं और अपने सभी फंड को नए 24-शब्द वाले वॉलेट में स्थानांतरित करें, और 12-शब्द बीज वाले वॉलेट का उपयोग करना बंद करें। कृपया अपने धन को सुरक्षित करने के लिए इसे तुरंत करें।""";
  @override
  String get understand => """मुझे समझ""";
  @override
  String get apk_update => """APK अद्यतन""";
  @override
  String get buy_bitcoin => """बिटकॉइन खरीदें""";
  @override
  String get buy_with => """के साथ खरीदें""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """राशि का मूल्य अधिक है या करने के लिए बराबर होना चाहिए ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """अगर इस वॉलेट में 12 शब्दों का बीज है और इसे केक में बनाया गया है, तो इस वॉलेट में बिटकॉइन जमा न करें। इस वॉलेट में स्थानांतरित किया गया कोई भी बीटीसी खो सकता है। एक नया 24-शब्द वॉलेट बनाएं (ऊपर दाईं ओर स्थित मेनू पर टैप करें, वॉलेट चुनें, नया वॉलेट बनाएं चुनें, फिर बिटकॉइन चुनें) और तुरंत अपना बीटीसी वहां ले जाएं। केक से नए (24-शब्द) बीटीसी वॉलेट सुरक्षित हैं""";
  @override
  String get do_not_show_me => """मुझे यह फिर न दिखाएं""";
  @override
  String get unspent_coins_title => """खर्च न किए गए सिक्के""";
  @override
  String get unspent_coins_details_title => """अव्ययित सिक्कों का विवरण""";
  @override
  String get freeze => """फ्रीज""";
  @override
  String get coin_control => """सिक्का नियंत्रण (वैकल्पिक)""";
  @override
  String get address_detected => """पता लग गया""";
  @override
  String address_from_domain(String domain) => """आपको अजेय डोमेन ${domain} से पता मिला है""";
}

class $ja extends S {
  const $ja();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """ようこそ に""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """Moneroとビットコインのための素晴らしい財布""";
  @override
  String get please_make_selection => """以下を選択してください ウォレットを作成または回復する.""";
  @override
  String get create_new => """新しいウォレットを作成""";
  @override
  String get restore_wallet => """ウォレットを復元""";
  @override
  String get accounts => """アカウント""";
  @override
  String get edit => """編集""";
  @override
  String get account => """アカウント""";
  @override
  String get add => """加える""";
  @override
  String get address_book => """住所録""";
  @override
  String get contact => """接触""";
  @override
  String get please_select => """選んでください:""";
  @override
  String get cancel => """キャンセル""";
  @override
  String get ok => """OK""";
  @override
  String get contact_name => """連絡先""";
  @override
  String get reset => """リセットする""";
  @override
  String get save => """セーブ""";
  @override
  String get address_remove_contact => """連絡先を削除します""";
  @override
  String get address_remove_content => """選択した連絡先を削除してもよろしいですか？""";
  @override
  String get authenticated => """認証済み""";
  @override
  String get authentication => """認証""";
  @override
  String failed_authentication(String state_error) => """認証失敗. ${state_error}""";
  @override
  String get wallet_menu => """ウォレットメニュー""";
  @override
  String Blocks_remaining(String status) => """${status} 残りのブロック""";
  @override
  String get please_try_to_connect_to_another_node => """別のノードに接続してみてください""";
  @override
  String get xmr_hidden => """非表示""";
  @override
  String get xmr_available_balance => """利用可能残高""";
  @override
  String get xmr_full_balance => """フルバランス""";
  @override
  String get send => """送る""";
  @override
  String get receive => """受け取る""";
  @override
  String get transactions => """取引""";
  @override
  String get incoming => """着信""";
  @override
  String get outgoing => """発信""";
  @override
  String get transactions_by_date => """日付ごとの取引""";
  @override
  String get trades => """取引""";
  @override
  String get filters => """フィルタ""";
  @override
  String get today => """今日""";
  @override
  String get yesterday => """昨日""";
  @override
  String get received => """受け取った""";
  @override
  String get sent => """送信済み""";
  @override
  String get pending => """ (保留中)""";
  @override
  String get rescan => """再スキャン""";
  @override
  String get reconnect => """再接続""";
  @override
  String get wallets => """財布""";
  @override
  String get show_seed => """シードを表示""";
  @override
  String get show_keys => """シード/キーを表示する""";
  @override
  String get address_book_menu => """住所録""";
  @override
  String get reconnection => """再接続""";
  @override
  String get reconnect_alert_text => """再接続しますか？""";
  @override
  String get exchange => """交換する""";
  @override
  String get clear => """クリア""";
  @override
  String get refund_address => """払い戻し住所""";
  @override
  String get change_exchange_provider => """Exchangeプロバイダーの変更""";
  @override
  String get you_will_send => """から変換""";
  @override
  String get you_will_get => """に変換""";
  @override
  String get amount_is_guaranteed => """受け取り金額は保証されています""";
  @override
  String get amount_is_estimate => """受け取り金額は見積もりです""";
  @override
  String powered_by(String title) => """搭載 ${title}""";
  @override
  String get error => """エラー""";
  @override
  String get estimated => """推定""";
  @override
  String min_value(String value, String currency) => """分: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """マックス: ${value} ${currency}""";
  @override
  String get change_currency => """通貨を変更する""";
  @override
  String get copy_id => """IDをコピー""";
  @override
  String get exchange_result_write_down_trade_id => """続行するには、取引IDをコピーまたは書き留めてください.""";
  @override
  String get trade_id => """取引ID:""";
  @override
  String get copied_to_clipboard => """クリップボードにコピーしました""";
  @override
  String get saved_the_trade_id => """取引IDを保存しました""";
  @override
  String get fetching => """フェッチング""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """量: """;
  @override
  String get payment_id => """支払いID: """;
  @override
  String get status => """状態: """;
  @override
  String get offer_expires_in => """で有効期限が切れます: """;
  @override
  String trade_is_powered_by(String provider) => """この取引は ${provider}""";
  @override
  String get copy_address => """住所をコピー""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """確認を押すと、送信されます ${fetchingLabel} ${from} と呼ばれるあなたの財布から ${walletName} 下記の住所へ。 または、外部ウォレットから以下のアドレスに送信することもできます/ QRコードに送信できます.

確認を押して続行するか、戻って金額を変更してください.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """次のページに示されているアドレスに最低 ${fetchingLabel} ${from} を送信する必要があります。 ${fetchingLabel} ${from} 未満の金額を送信すると、変換されず、返金されない場合があります。""";
  @override
  String get exchange_result_write_down_ID => """*上記のIDをコピーまたは書き留めてください.""";
  @override
  String get confirm => """確認する""";
  @override
  String get confirm_sending => """送信を確認""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """トランザクションをコミット
量: ${amount}
費用: ${fee}""";
  @override
  String get sending => """送信""";
  @override
  String get transaction_sent => """トランザクションが送信されました！""";
  @override
  String get expired => """期限切れ""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """送る XMR""";
  @override
  String get exchange_new_template => """新しいテンプレート""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """PINを入力してください""";
  @override
  String get loading_your_wallet => """ウォレットをロードしています""";
  @override
  String get new_wallet => """新しいウォレット""";
  @override
  String get wallet_name => """ウォレット名""";
  @override
  String get continue_text => """持続する""";
  @override
  String get choose_wallet_currency => """ウォレット通貨を選択してください：""";
  @override
  String get node_new => """新しいノード""";
  @override
  String get node_address => """ノードアドレス""";
  @override
  String get node_port => """ノードポート""";
  @override
  String get login => """ログイン""";
  @override
  String get password => """パスワード""";
  @override
  String get nodes => """ノード""";
  @override
  String get node_reset_settings_title => """設定をリセット""";
  @override
  String get nodes_list_reset_to_default_message => """設定をデフォルトにリセットしてもよろしいですか？""";
  @override
  String change_current_node(String node) => """現在のノードを変更してよろしいですか ${node}?""";
  @override
  String get change => """変化する""";
  @override
  String get remove_node => """ノードを削除""";
  @override
  String get remove_node_message => """選択したノードを削除してもよろしいですか？""";
  @override
  String get remove => """削除する""";
  @override
  String get delete => """削除する""";
  @override
  String get add_new_node => """新しいノードを追加""";
  @override
  String get change_current_node_title => """現在のノードを変更する""";
  @override
  String get node_test => """テスト""";
  @override
  String get node_connection_successful => """接続に成功しました""";
  @override
  String get node_connection_failed => """接続に失敗しました""";
  @override
  String get new_node_testing => """新しいノードのテスト""";
  @override
  String get use => """使用する """;
  @override
  String get digit_pin => """桁ピン""";
  @override
  String get share_address => """住所を共有する""";
  @override
  String get receive_amount => """量""";
  @override
  String get subaddresses => """サブアドレス""";
  @override
  String get addresses => """住所""";
  @override
  String get scan_qr_code => """QRコードをスキャンして住所を取得します""";
  @override
  String get rename => """リネーム""";
  @override
  String get choose_account => """アカウントを選択""";
  @override
  String get create_new_account => """新しいアカウントを作成する""";
  @override
  String get accounts_subaddresses => """アカウントとサブアドレス""";
  @override
  String get restore_restore_wallet => """ウォレットを復元""";
  @override
  String get restore_title_from_seed_keys => """シード/キーから復元""";
  @override
  String get restore_description_from_seed_keys => """安全な場所に保存したシード/キーから財布を取り戻す""";
  @override
  String get restore_next => """次""";
  @override
  String get restore_title_from_backup => """バックアップファイルから復元する""";
  @override
  String get restore_description_from_backup => """Cake Walletアプリ全体を復元できますバックアップファイル""";
  @override
  String get restore_seed_keys_restore => """シード/キーの復元""";
  @override
  String get restore_title_from_seed => """シードから復元""";
  @override
  String get restore_description_from_seed => """25ワードからウォレットを復元しますまたは13ワードの組み合わせコード""";
  @override
  String get restore_title_from_keys => """キーから復元する""";
  @override
  String get restore_description_from_keys => """生成されたウォレットを復元します秘密鍵から保存されたキーストローク""";
  @override
  String get restore_wallet_name => """ウォレット名""";
  @override
  String get restore_address => """住所""";
  @override
  String get restore_view_key_private => """ビューキー (プライベート)""";
  @override
  String get restore_spend_key_private => """キーを使う (プライベート)""";
  @override
  String get restore_recover => """回復します""";
  @override
  String get restore_wallet_restore_description => """ウォレットの復元""";
  @override
  String get restore_new_seed => """新しい種""";
  @override
  String get restore_active_seed => """アクティブシード""";
  @override
  String get restore_bitcoin_description_from_seed => """24ワードの組み合わせコードからウォレットを復元する""";
  @override
  String get restore_bitcoin_description_from_keys => """秘密鍵から生成されたWIF文字列からウォレットを復元します""";
  @override
  String get restore_bitcoin_title_from_keys => """WIFから復元""";
  @override
  String get restore_from_date_or_blockheight => """このウォレットを作成する数日前に日付を入力してください。 または、ブロックの高さがわかっている場合は、代わりに入力してください""";
  @override
  String get seed_reminder => """スマートフォンを紛失したりワイプした場合に備えて、これらを書き留めてください""";
  @override
  String get seed_title => """シード""";
  @override
  String get seed_share => """シードを共有する""";
  @override
  String get copy => """コピー""";
  @override
  String get seed_language_choose => """シード言語を選択してください:""";
  @override
  String get seed_choose => """シード言語を選択してください""";
  @override
  String get seed_language_next => """次""";
  @override
  String get seed_language_english => """英語""";
  @override
  String get seed_language_chinese => """中国語""";
  @override
  String get seed_language_dutch => """オランダの""";
  @override
  String get seed_language_german => """ドイツ人""";
  @override
  String get seed_language_japanese => """日本語""";
  @override
  String get seed_language_portuguese => """ポルトガル語""";
  @override
  String get seed_language_russian => """ロシア""";
  @override
  String get seed_language_spanish => """スペイン語""";
  @override
  String get send_title => """を送信""";
  @override
  String get send_your_wallet => """あなたの財布""";
  @override
  String send_address(String cryptoCurrency) => """${cryptoCurrency} 住所""";
  @override
  String get send_payment_id => """支払いID (オプショナル)""";
  @override
  String get all => """すべて""";
  @override
  String get send_error_minimum_value => """金額の最小値は0.01です""";
  @override
  String get send_error_currency => """通貨には数字のみを含めることができます""";
  @override
  String get send_estimated_fee => """見積手数料:""";
  @override
  String send_priority(String transactionPriority) => """現在、料金は ${transactionPriority} 優先度.
トランザクションの優先度は設定で調整できます""";
  @override
  String get send_creating_transaction => """トランザクションを作成する""";
  @override
  String get send_templates => """テンプレート""";
  @override
  String get send_new => """新着""";
  @override
  String get send_amount => """量：""";
  @override
  String get send_fee => """費用：""";
  @override
  String get send_name => """名前""";
  @override
  String get send_got_it => """とった""";
  @override
  String get send_sending => """送信...""";
  @override
  String send_success(String crypto) => """${crypto}が送信されました""";
  @override
  String get settings_title => """設定""";
  @override
  String get settings_nodes => """ノード""";
  @override
  String get settings_current_node => """現在のノード""";
  @override
  String get settings_wallets => """財布""";
  @override
  String get settings_display_balance_as => """残高を表示""";
  @override
  String get settings_currency => """通貨""";
  @override
  String get settings_fee_priority => """料金優先""";
  @override
  String get settings_save_recipient_address => """受信者のアドレスを保存""";
  @override
  String get settings_personal => """パーソナル""";
  @override
  String get settings_change_pin => """PINを変更""";
  @override
  String get settings_change_language => """言語を変えてください""";
  @override
  String get settings_allow_biometrical_authentication => """生体認証を許可する""";
  @override
  String get settings_dark_mode => """ダークモード""";
  @override
  String get settings_transactions => """取引""";
  @override
  String get settings_trades => """取引""";
  @override
  String get settings_display_on_dashboard_list => """ダッシュボードリストに表示""";
  @override
  String get settings_all => """すべて""";
  @override
  String get settings_only_trades => """取引のみ""";
  @override
  String get settings_only_transactions => """トランザクションのみ""";
  @override
  String get settings_none => """なし""";
  @override
  String get settings_support => """サポート""";
  @override
  String get settings_terms_and_conditions => """規約と条件""";
  @override
  String get pin_is_incorrect => """PINが間違っています""";
  @override
  String get setup_pin => """PINのセットアップ""";
  @override
  String get enter_your_pin_again => """ピンをもう一度入力してください""";
  @override
  String get setup_successful => """PINは正常に設定されました!""";
  @override
  String get wallet_keys => """ウォレットシード/キー""";
  @override
  String get wallet_seed => """ウォレットシード""";
  @override
  String get private_key => """秘密鍵""";
  @override
  String get public_key => """公開鍵""";
  @override
  String get view_key_private => """ビューキー (プライベート)""";
  @override
  String get view_key_public => """ビューキー (パブリック)""";
  @override
  String get spend_key_private => """キーを使う (プライベート)""";
  @override
  String get spend_key_public => """キーを使う (パブリック)""";
  @override
  String copied_key_to_clipboard(String key) => """コピー済み ${key} クリップボードへ""";
  @override
  String get new_subaddress_title => """新しいアドレス""";
  @override
  String get new_subaddress_label_name => """ラベル名""";
  @override
  String get new_subaddress_create => """作成する""";
  @override
  String get subaddress_title => """サブアドレス一覧""";
  @override
  String get trade_details_title => """取引の詳細""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """状態""";
  @override
  String get trade_details_fetching => """フェッチング""";
  @override
  String get trade_details_provider => """プロバイダー""";
  @override
  String get trade_details_created_at => """で作成""";
  @override
  String get trade_details_pair => """ペア""";
  @override
  String trade_details_copied(String title) => """${title} クリップボードにコピーしました""";
  @override
  String get trade_history_title => """取引履歴""";
  @override
  String get transaction_details_title => """取引の詳細""";
  @override
  String get transaction_details_transaction_id => """トランザクションID""";
  @override
  String get transaction_details_date => """日付""";
  @override
  String get transaction_details_height => """高さ""";
  @override
  String get transaction_details_amount => """量""";
  @override
  String get transaction_details_fee => """費用""";
  @override
  String transaction_details_copied(String title) => """${title} クリップボードにコピーしました""";
  @override
  String get transaction_details_recipient_address => """受取人の住所""";
  @override
  String get wallet_list_title => """Monero 財布""";
  @override
  String get wallet_list_create_new_wallet => """新しいウォレットを作成""";
  @override
  String get wallet_list_restore_wallet => """ウォレットを復元""";
  @override
  String get wallet_list_load_wallet => """ウォレットをロード""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """読み込み中 ${wallet_name} 財布""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """読み込みに失敗しました ${wallet_name} 財布. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """取りはずし ${wallet_name} 財布""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """削除できませんでした ${wallet_name} 財布. ${error}""";
  @override
  String get widgets_address => """住所""";
  @override
  String get widgets_restore_from_blockheight => """ブロックの高さから復元""";
  @override
  String get widgets_restore_from_date => """日付から復元""";
  @override
  String get widgets_or => """または""";
  @override
  String get widgets_seed => """シード""";
  @override
  String router_no_route(String name) => """ルートが定義されていません ${name}""";
  @override
  String get error_text_account_name => """アカウント名には文字のみを含めることができます 
1〜15文字である必要があります""";
  @override
  String get error_text_contact_name => """連絡先名に含めることはできません ` , ' " シンボル
長さは1〜32文字でなければなりません""";
  @override
  String get error_text_address => """ウォレットアドレスは、
暗号通貨""";
  @override
  String get error_text_node_address => """iPv4アドレスを入力してください""";
  @override
  String get error_text_node_port => """ノードポートには、0〜65535の数字のみを含めることができます""";
  @override
  String get error_text_payment_id => """支払いIDには、16進数で16〜64文字しか含めることができません""";
  @override
  String get error_text_xmr => """XMR値は利用可能な残高を超えることはできません.
小数桁数は12以下でなければなりません""";
  @override
  String get error_text_fiat => """金額は利用可能な残高を超えることはできません.
小数桁の数は2以下でなければなりません""";
  @override
  String get error_text_subaddress_name => """サブアドレス名に含めることはできません` , ' " シンボル
1〜20文字の長さである必要があります""";
  @override
  String get error_text_amount => """金額には数字のみを含めることができます""";
  @override
  String get error_text_wallet_name => """ウォレット名には文字のみを含めることができます
1〜20文字である必要があります""";
  @override
  String get error_text_keys => """ウォレットキーには、16進数で64文字しか含めることができません""";
  @override
  String get error_text_crypto_currency => """小数桁数
12以下でなければなりません""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """${provider} の取引は作成されません。 金額は最小額より少ない： ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """${provider} の取引は作成されません。 金額は最大値を超えています： ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """${provider} の取引は作成されません。 制限の読み込みに失敗しました""";
  @override
  String get error_text_template => """テンプレートの名前とアドレスに含めることはできません ` , ' " シンボル
1〜106文字の長さである必要があります""";
  @override
  String get auth_store_ban_timeout => """禁止タイムアウト""";
  @override
  String get auth_store_banned_for => """禁止されています """;
  @override
  String get auth_store_banned_minutes => """ 数分""";
  @override
  String get auth_store_incorrect_password => """間違ったPIN""";
  @override
  String get wallet_store_monero_wallet => """Monero 財布""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """誤ったシード長s""";
  @override
  String get full_balance => """フルバランス""";
  @override
  String get available_balance => """利用可能残高""";
  @override
  String get hidden_balance => """隠れたバランス""";
  @override
  String get sync_status_syncronizing => """同期""";
  @override
  String get sync_status_syncronized => """同期された""";
  @override
  String get sync_status_not_connected => """接続されていません""";
  @override
  String get sync_status_starting_sync => """同期の開始""";
  @override
  String get sync_status_failed_connect => """切断されました""";
  @override
  String get sync_status_connecting => """接続中""";
  @override
  String get sync_status_connected => """接続済み""";
  @override
  String get transaction_priority_slow => """スロー""";
  @override
  String get transaction_priority_regular => """レギュラー""";
  @override
  String get transaction_priority_medium => """中""";
  @override
  String get transaction_priority_fast => """速い""";
  @override
  String get transaction_priority_fastest => """最速""";
  @override
  String trade_for_not_created(String title) => """取引 ${title} 作成されません""";
  @override
  String get trade_not_created => """作成されていない取引""";
  @override
  String trade_id_not_found(String tradeId, String title) => """トレード ${tradeId} of ${title} 見つかりません""";
  @override
  String get trade_not_found => """取引が見つかりません""";
  @override
  String get trade_state_pending => """保留中""";
  @override
  String get trade_state_confirming => """確認中""";
  @override
  String get trade_state_trading => """トレーディング""";
  @override
  String get trade_state_traded => """取引済み""";
  @override
  String get trade_state_complete => """コンプリート""";
  @override
  String get trade_state_to_be_created => """作成される""";
  @override
  String get trade_state_unpaid => """未払い""";
  @override
  String get trade_state_underpaid => """支払不足""";
  @override
  String get trade_state_paid_unconfirmed => """未確認の支払い""";
  @override
  String get trade_state_paid => """有料""";
  @override
  String get trade_state_btc_sent => """送った""";
  @override
  String get trade_state_timeout => """タイムアウト""";
  @override
  String get trade_state_created => """作成した""";
  @override
  String get trade_state_finished => """完成した""";
  @override
  String get change_language => """言語を変えてください""";
  @override
  String change_language_to(String language) => """言語を変更 ${language}?""";
  @override
  String get paste => """ペースト""";
  @override
  String get restore_from_seed_placeholder => """ここにコードフレーズを入力または貼り付けてください""";
  @override
  String get add_new_word => """新しい単語を追加""";
  @override
  String get incorrect_seed => """入力されたテキストは無効です。""";
  @override
  String get biometric_auth_reason => """प指紋をスキャンして認証する""";
  @override
  String version(String currentVersion) => """バージョン ${currentVersion}""";
  @override
  String get openalias_alert_title => """XMR受信者が検出されました""";
  @override
  String openalias_alert_content(String recipient_name) => """に送金します
${recipient_name}""";
  @override
  String get card_address => """住所:""";
  @override
  String get buy => """購入""";
  @override
  String get placeholder_transactions => """あなたの取引はここに表示されます""";
  @override
  String get placeholder_contacts => """連絡先はここに表示されます""";
  @override
  String get template => """テンプレート""";
  @override
  String get confirm_delete_template => """この操作により、このテンプレートが削除されます。 続行しますか？""";
  @override
  String get confirm_delete_wallet => """このアクションにより、このウォレットが削除されます。 続行しますか？""";
  @override
  String get picker_description => """ChangeNOWまたはMorphTokenを選択するには、最初にトレーディングペアを変更してください""";
  @override
  String get change_wallet_alert_title => """現在のウォレットを変更する""";
  @override
  String change_wallet_alert_content(String wallet_name) => """現在のウォレットをに変更しますか ${wallet_name}?""";
  @override
  String get creating_new_wallet => """新しいウォレットの作成""";
  @override
  String creating_new_wallet_error(String description) => """エラー： ${description}""";
  @override
  String get seed_alert_title => """注意""";
  @override
  String get seed_alert_content => """種子はあなたの財布を回復する唯一の方法です。 書き留めましたか？""";
  @override
  String get seed_alert_back => """戻る""";
  @override
  String get seed_alert_yes => """はい、あります""";
  @override
  String get wallet_name_alert_content => """同じ名前のウォレットが存在します""";
  @override
  String get exchange_sync_alert_content => """ウォレットが同期されるまでお待ちください""";
  @override
  String get pre_seed_title => """重要""";
  @override
  String pre_seed_description(String words) => """次のページでは、一連の${words}語が表示されます。 これはあなたのユニークでプライベートなシードであり、紛失や誤動作が発生した場合にウォレットを回復する唯一の方法です。 それを書き留めて、Cake Wallet アプリの外の安全な場所に保管するのはあなたの責任です。""";
  @override
  String get pre_seed_button_text => """わかります。 種を見せて""";
  @override
  String get xmr_to_error => """XMR.TOエラー""";
  @override
  String get xmr_to_error_description => """金額が無効です。 小数点以下8桁の上限""";
  @override
  String provider_error(String provider) => """${provider} エラー""";
  @override
  String get use_ssl => """SSLを使用する""";
  @override
  String get color_theme => """カラーテーマ""";
  @override
  String get light_theme => """光""";
  @override
  String get bright_theme => """明るい""";
  @override
  String get dark_theme => """闇""";
  @override
  String get enter_your_note => """メモを入力してください…""";
  @override
  String get note_optional => """注（オプション）""";
  @override
  String get note_tap_to_change => """注（タップして変更）""";
  @override
  String get transaction_key => """トランザクションキー""";
  @override
  String get confirmations => """確認""";
  @override
  String get recipient_address => """受信者のアドレス""";
  @override
  String get extra_id => """追加ID:""";
  @override
  String get destination_tag => """宛先タグ:""";
  @override
  String get memo => """メモ:""";
  @override
  String get backup => """バックアップ""";
  @override
  String get change_password => """パスワードを変更する""";
  @override
  String get backup_password => """バックアップパスワード""";
  @override
  String get write_down_backup_password => """バックアップファイルのインポートに使用されるバックアップパスワードを書き留めてください。""";
  @override
  String get export_backup => """バックアップのエクスポート""";
  @override
  String get save_backup_password => """バックアップパスワードが保存されていることを確認してください。 それなしではバックアップファイルをインポートすることはできません。""";
  @override
  String get backup_file => """バックアップファイル""";
  @override
  String get edit_backup_password => """バックアップパスワードの編集""";
  @override
  String get save_backup_password_alert => """バックアップパスワードを保存する""";
  @override
  String get change_backup_password_alert => """以前のバックアップファイルは、新しいバックアップパスワードでインポートできなくなります。 新しいバックアップパスワードは、新しいバックアップファイルにのみ使用されます。 バックアップパスワードを変更してもよろしいですか？""";
  @override
  String get enter_backup_password => """ここにバックアップパスワードを入力してください""";
  @override
  String get select_backup_file => """バックアップファイルを選択""";
  @override
  String get import => """インポート""";
  @override
  String get please_select_backup_file => """バックアップファイルを選択し、バックアップパスワードを入力してください。""";
  @override
  String get fixed_rate => """固定金利""";
  @override
  String get fixed_rate_alert => """固定金利モードにチェックを入れると、受取額を入力できるようになります。 固定金利モードに切り替えますか？""";
  @override
  String get xlm_extra_info => """交換用のXLMトランザクションを送信するときに、メモIDを指定することを忘れないでください""";
  @override
  String get xrp_extra_info => """取引所のXRPトランザクションを送信するときに、宛先タグを指定することを忘れないでください""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Cake Wallet Moneroの残高からXMRを交換する場合は、最初にMoneroウォレットに切り替えてください。""";
  @override
  String get confirmed => """確認済み""";
  @override
  String get unconfirmed => """未確認""";
  @override
  String get displayable => """表示可能""";
  @override
  String get submit_request => """リクエストを送信する""";
  @override
  String get buy_alert_content => """現在、ビットコインとライトコインの購入のみをサポートしています。 ビットコインまたはライトコインを購入するには、ビットコインまたはライトコインのウォレットを作成するか、ウォレットに切り替えてください。""";
  @override
  String get outdated_electrum_wallet_description => """Cakeで作成された新しいビットコインウォレットには、24ワードのシードがあります。 新しいビットコインウォレットを作成し、すべての資金を新しい24ワードのウォレットに転送し、12ワードのシードを持つウォレットの使用を停止することが必須です。 あなたの資金を確保するためにこれをすぐに行ってください。""";
  @override
  String get understand => """わかります""";
  @override
  String get apk_update => """APKアップデート""";
  @override
  String get buy_bitcoin => """ビットコインを購入する""";
  @override
  String get buy_with => """で購入""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """金額の値は以上でなければなりません ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """このウォレットに 12 ワードのシードがあり、Cake で作成された場合、このウォレットにビットコインを入金しないでください。 このウォレットに転送された BTC は失われる可能性があります。 新しい 24 ワードのウォレットを作成し (右上のメニューをタップし、[ウォレット]、[新しいウォレットの作成]、[ビットコイン] の順に選択)、すぐに BTC をそこに移動します。 Cake の新しい (24 ワード) BTC ウォレットは安全です""";
  @override
  String get do_not_show_me => """また僕にこれを見せないでください""";
  @override
  String get unspent_coins_title => """未使用のコイン""";
  @override
  String get unspent_coins_details_title => """未使用のコインの詳細""";
  @override
  String get freeze => """氷結""";
  @override
  String get coin_control => """コインコントロール（オプション）""";
  @override
  String get address_detected => """アドレスが検出されました""";
  @override
  String address_from_domain(String domain) => """あなたはからアドレスを得ました unstoppable domain ${domain}""";
}

class $hr extends S {
  const $hr();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """Dobrodošli na""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """Odličan novčanik za Monero i Bitcoin""";
  @override
  String get please_make_selection => """Molimo odaberite opcije niže za izradu novog novčanika ili za oporavak postojećeg.""";
  @override
  String get create_new => """Izradi novi novčanik""";
  @override
  String get restore_wallet => """Oporavi novčanik""";
  @override
  String get accounts => """Računi""";
  @override
  String get edit => """Uredi""";
  @override
  String get account => """Račun""";
  @override
  String get add => """Dodaj""";
  @override
  String get address_book => """Imenik""";
  @override
  String get contact => """Kontakt""";
  @override
  String get please_select => """Molimo odaberite:""";
  @override
  String get cancel => """Poništi""";
  @override
  String get ok => """OK""";
  @override
  String get contact_name => """Ime kontakta""";
  @override
  String get reset => """Resetiraj""";
  @override
  String get save => """Spremi""";
  @override
  String get address_remove_contact => """Ukloni kontakt""";
  @override
  String get address_remove_content => """Jeste li sigurni da želite ukloniti odabrani kontakt?""";
  @override
  String get authenticated => """Autentificiran""";
  @override
  String get authentication => """Autentifikacija""";
  @override
  String failed_authentication(String state_error) => """Autentifikacija neuspješna. ${state_error}""";
  @override
  String get wallet_menu => """Izbornik""";
  @override
  String Blocks_remaining(String status) => """${status} preostalih blokova""";
  @override
  String get please_try_to_connect_to_another_node => """Molimo pokušajte se spojiti na drugi node.""";
  @override
  String get xmr_hidden => """Sakriven""";
  @override
  String get xmr_available_balance => """Raspoloživ iznos""";
  @override
  String get xmr_full_balance => """Ukupan iznos""";
  @override
  String get send => """Pošalji""";
  @override
  String get receive => """Primi""";
  @override
  String get transactions => """Transakcije""";
  @override
  String get incoming => """Dolazno""";
  @override
  String get outgoing => """Odlazno""";
  @override
  String get transactions_by_date => """Transakcije prema datumu""";
  @override
  String get trades => """Razmjene""";
  @override
  String get filters => """Filter""";
  @override
  String get today => """Danas""";
  @override
  String get yesterday => """Jučer""";
  @override
  String get received => """Primljeno""";
  @override
  String get sent => """Poslano""";
  @override
  String get pending => """ (u tijeku)""";
  @override
  String get rescan => """Ponovno skeniranje""";
  @override
  String get reconnect => """Ponovno povezivanje""";
  @override
  String get wallets => """Novčanici""";
  @override
  String get show_seed => """Prikaži pristupni izraz""";
  @override
  String get show_keys => """Prikaži pristupni izraz/ključ""";
  @override
  String get address_book_menu => """Imenik""";
  @override
  String get reconnection => """Ponovno povezivanje""";
  @override
  String get reconnect_alert_text => """Jeste li sigurni da se želite ponovno povezati?""";
  @override
  String get exchange => """Razmijeni""";
  @override
  String get clear => """Izbriši""";
  @override
  String get refund_address => """Adresa za povrat""";
  @override
  String get change_exchange_provider => """Promjena davatelja usluge razmjene""";
  @override
  String get you_will_send => """Razmijeni iz""";
  @override
  String get you_will_get => """Razmijeni u""";
  @override
  String get amount_is_guaranteed => """Iznos koji ćete primiti je zajamčen""";
  @override
  String get amount_is_estimate => """Iznos koji ćete primiti je okviran""";
  @override
  String powered_by(String title) => """Omogućio ${title}""";
  @override
  String get error => """Greška""";
  @override
  String get estimated => """procijenjen""";
  @override
  String min_value(String value, String currency) => """Min.: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """Maks.: ${value} ${currency}""";
  @override
  String get change_currency => """Promijenite valutu""";
  @override
  String get copy_id => """Kopirati ID""";
  @override
  String get exchange_result_write_down_trade_id => """Molimo kopirajte ili zapišite transakcijski ID za nastavak.""";
  @override
  String get trade_id => """Transakcijski ID:""";
  @override
  String get copied_to_clipboard => """Kopirano u međuspremnik""";
  @override
  String get saved_the_trade_id => """Spremio/la sam transakcijski ID""";
  @override
  String get fetching => """Dohvaćanje""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """Iznos: """;
  @override
  String get payment_id => """ID plaćanja: """;
  @override
  String get status => """Status: """;
  @override
  String get offer_expires_in => """Ponuda istječe za: """;
  @override
  String trade_is_powered_by(String provider) => """Razmjenu je omogućio ${provider}""";
  @override
  String get copy_address => """Kopiraj adresu""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """Pritiskom na potvrdi, poslat ćete ${fetchingLabel} ${from} sa svog novčanika pod nazivom ${walletName} na adresu prikazanu ispod ili iznos možete poslati s vanjskog novčanika na niže navedenu adresu. /QR code.

Molimo potvrdite za nastavak ili se vratite natrag za promjenu iznosa.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """Potrebno poslati minimalno ${fetchingLabel} ${from} na adresu prikazanu na sljedećoj stranici. Ukoliko pošaljete iznos manji od ${fetchingLabel} ${from}, postoji mogućnost da razmjena neće biti uspješna i da iznos neće biti vraćen.""";
  @override
  String get exchange_result_write_down_ID => """*Molimo kopirajte ili zapišite svoj ID prikazan ispod.""";
  @override
  String get confirm => """Potvrdi""";
  @override
  String get confirm_sending => """Potvrdi slanje""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """Izvrši transakciju 
Amount: ${amount}
Fee: ${fee}""";
  @override
  String get sending => """Slanje""";
  @override
  String get transaction_sent => """Transakcija provedena!""";
  @override
  String get expired => """Isteklo""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """Pošalji XMR""";
  @override
  String get exchange_new_template => """Novi predložak""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """Upišite PIN""";
  @override
  String get loading_your_wallet => """Novčanik se učitava""";
  @override
  String get new_wallet => """Novi novčanik""";
  @override
  String get wallet_name => """Ime novčanika""";
  @override
  String get continue_text => """Nastavak""";
  @override
  String get choose_wallet_currency => """Molimo odaberite valutu novčanika:""";
  @override
  String get node_new => """Novi node""";
  @override
  String get node_address => """Node adresa""";
  @override
  String get node_port => """Node port""";
  @override
  String get login => """Prijava""";
  @override
  String get password => """Lozinka""";
  @override
  String get nodes => """Nodes""";
  @override
  String get node_reset_settings_title => """Resetiraj postavke""";
  @override
  String get nodes_list_reset_to_default_message => """Jeste li sigurni da se želite vratiti na početne postavke?""";
  @override
  String change_current_node(String node) => """Jeste li sigurni da želite promijeniti trenutni node na ${node}?""";
  @override
  String get change => """Promijeni""";
  @override
  String get remove_node => """Ukloni node""";
  @override
  String get remove_node_message => """Jeste li sigurni da želite ukloniti odabrani node?""";
  @override
  String get remove => """Ukloni""";
  @override
  String get delete => """Izbriši""";
  @override
  String get add_new_node => """Dodaj novi node""";
  @override
  String get change_current_node_title => """Promijeni trenutni node""";
  @override
  String get node_test => """Provjeri""";
  @override
  String get node_connection_successful => """Uspješno spajanje""";
  @override
  String get node_connection_failed => """Neuspješno spajanje""";
  @override
  String get new_node_testing => """Provjera novog nodea""";
  @override
  String get use => """Prebaci na""";
  @override
  String get digit_pin => """-znamenkasti PIN""";
  @override
  String get share_address => """Podijeli adresu""";
  @override
  String get receive_amount => """Iznos""";
  @override
  String get subaddresses => """Podadrese""";
  @override
  String get addresses => """Adrese""";
  @override
  String get scan_qr_code => """Skeniraj QR kod za dobivanje adrese""";
  @override
  String get rename => """Preimenuj""";
  @override
  String get choose_account => """Odaberi račun""";
  @override
  String get create_new_account => """Izradi novi račun""";
  @override
  String get accounts_subaddresses => """Računi i podadrese""";
  @override
  String get restore_restore_wallet => """Oporavi novčanik""";
  @override
  String get restore_title_from_seed_keys => """Oporavi pomoću pristupnog izraza/ključa""";
  @override
  String get restore_description_from_seed_keys => """Oporavi novčanik pomoću pristupnog izraza/ključa spremljenog na sigurno mjesto""";
  @override
  String get restore_next => """Dalje""";
  @override
  String get restore_title_from_backup => """Oporavak pomoću sigurnosne kopije""";
  @override
  String get restore_description_from_backup => """Možete oporaviti cijelu Cake Wallet aplikaciju pomoću vlastite datoteke sa sigurnosnom kopijom""";
  @override
  String get restore_seed_keys_restore => """Oporavak pomoću pristupnog izraza/ključa""";
  @override
  String get restore_title_from_seed => """Oporavi pomoću pristupnog izraza""";
  @override
  String get restore_description_from_seed => """Oporavi novčanik pomoću koda koji sadrži kombinaciju od 25 ili 13 riječi""";
  @override
  String get restore_title_from_keys => """Oporavi pomoću ključa""";
  @override
  String get restore_description_from_keys => """Oporavi novčanik pomoću generiranih pritisaka na tipke spremljenih od vlastitih privatnih ključeva (keys)""";
  @override
  String get restore_wallet_name => """Ime novčanika""";
  @override
  String get restore_address => """Adresa""";
  @override
  String get restore_view_key_private => """View key (privatni)""";
  @override
  String get restore_spend_key_private => """Spend key (privatni)""";
  @override
  String get restore_recover => """Oporavi""";
  @override
  String get restore_wallet_restore_description => """Opis oporavka novčanika""";
  @override
  String get restore_new_seed => """Novi pristupi izraz""";
  @override
  String get restore_active_seed => """Aktivan pristupni izraz""";
  @override
  String get restore_bitcoin_description_from_seed => """Oporavi novčanik pomoću koda od 12 riječi""";
  @override
  String get restore_bitcoin_description_from_keys => """Oporavi novčanik pomoću WIF niza generiranog iz vlastitih privatnih ključeva (keys)""";
  @override
  String get restore_bitcoin_title_from_keys => """Oporavi pomoću formata uvoza novčanika (WIF)""";
  @override
  String get restore_from_date_or_blockheight => """Molimo unesite datum od nekoliko dana prije nego što ste izradili ovaj novčanik ili ako znate visinu bloka, molimo unesite je.""";
  @override
  String get seed_reminder => """Molimo zapišite ih u slučaju da izgubite mobitel ili izbrišete podatke""";
  @override
  String get seed_title => """Prisupni izraz""";
  @override
  String get seed_share => """Podijeli pristupni izraz""";
  @override
  String get copy => """Kopiraj""";
  @override
  String get seed_language_choose => """Molimo odaberite jezik pristupnog izraza:""";
  @override
  String get seed_choose => """Odaberi jezik pristupnog izraza""";
  @override
  String get seed_language_next => """Dalje""";
  @override
  String get seed_language_english => """Engleski""";
  @override
  String get seed_language_chinese => """Kineski""";
  @override
  String get seed_language_dutch => """Nizozemski""";
  @override
  String get seed_language_german => """Njemački""";
  @override
  String get seed_language_japanese => """Japanski""";
  @override
  String get seed_language_portuguese => """Portugalski""";
  @override
  String get seed_language_russian => """Ruski""";
  @override
  String get seed_language_spanish => """Španjolski""";
  @override
  String get send_title => """Pošalji""";
  @override
  String get send_your_wallet => """Tvoj novčanik""";
  @override
  String send_address(String cryptoCurrency) => """${cryptoCurrency} adresa""";
  @override
  String get send_payment_id => """ID plaćanja (nije obvezno)""";
  @override
  String get all => """SVE""";
  @override
  String get send_error_minimum_value => """Minimalna vrijednost iznosa je 0.01""";
  @override
  String get send_error_currency => """Iznos smije sadržavati samo brojeve""";
  @override
  String get send_estimated_fee => """Procijenjena naknada:""";
  @override
  String send_priority(String transactionPriority) => """Trenutno se naknada nalazi na ${transactionPriority} mjestu prioriteta.
Prioritet transakcije moguće je prilagoditi u postavkama""";
  @override
  String get send_creating_transaction => """Izrada transakcije""";
  @override
  String get send_templates => """Predlošci""";
  @override
  String get send_new => """Novi""";
  @override
  String get send_amount => """Iznos:""";
  @override
  String get send_fee => """Naknada:""";
  @override
  String get send_name => """Ime""";
  @override
  String get send_got_it => """U redu""";
  @override
  String get send_sending => """Slanje...""";
  @override
  String send_success(String crypto) => """Vaš ${crypto} je uspješno poslan""";
  @override
  String get settings_title => """Postavke""";
  @override
  String get settings_nodes => """Nodovi""";
  @override
  String get settings_current_node => """Trenutni node""";
  @override
  String get settings_wallets => """Novčanik""";
  @override
  String get settings_display_balance_as => """Prikaži stanje računa kao""";
  @override
  String get settings_currency => """Valuta""";
  @override
  String get settings_fee_priority => """Prioritet naknade""";
  @override
  String get settings_save_recipient_address => """Spremi primateljevu adresu""";
  @override
  String get settings_personal => """Osobni""";
  @override
  String get settings_change_pin => """Promijeni PIN""";
  @override
  String get settings_change_language => """Promijeni jezik""";
  @override
  String get settings_allow_biometrical_authentication => """Dopusti biometrijsku autentifikaciju""";
  @override
  String get settings_dark_mode => """Tamni način rada""";
  @override
  String get settings_transactions => """Transakcije""";
  @override
  String get settings_trades => """Razmjene""";
  @override
  String get settings_display_on_dashboard_list => """Prikaži na listi kontrolne ploče""";
  @override
  String get settings_all => """SVE""";
  @override
  String get settings_only_trades => """Samo razmjene""";
  @override
  String get settings_only_transactions => """Samo transakcije""";
  @override
  String get settings_none => """Nijedno""";
  @override
  String get settings_support => """Podrška""";
  @override
  String get settings_terms_and_conditions => """Uvjeti i odredbe""";
  @override
  String get pin_is_incorrect => """Netočan PIN""";
  @override
  String get setup_pin => """Podesi PIN""";
  @override
  String get enter_your_pin_again => """Ponovno upišite pin""";
  @override
  String get setup_successful => """Vaš je pin uspješno postavljen!""";
  @override
  String get wallet_keys => """Pristupni izraz/ključ novčanika""";
  @override
  String get wallet_seed => """Pristupni izraz novčanika""";
  @override
  String get private_key => """Privatni ključ""";
  @override
  String get public_key => """Javni ključ""";
  @override
  String get view_key_private => """View key (privatni)""";
  @override
  String get view_key_public => """View key (javni)""";
  @override
  String get spend_key_private => """Spend key (privatni)""";
  @override
  String get spend_key_public => """Spend key (javni)""";
  @override
  String copied_key_to_clipboard(String key) => """${key} kopiran u međuspremnik""";
  @override
  String get new_subaddress_title => """Nova adresa""";
  @override
  String get new_subaddress_label_name => """Oznaka""";
  @override
  String get new_subaddress_create => """Izradi""";
  @override
  String get subaddress_title => """Lista podadresa""";
  @override
  String get trade_details_title => """Detalji razmjene""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """Stanje""";
  @override
  String get trade_details_fetching => """Dohvaćanje""";
  @override
  String get trade_details_provider => """Pružatelj""";
  @override
  String get trade_details_created_at => """Stvoreno u""";
  @override
  String get trade_details_pair => """Upari""";
  @override
  String trade_details_copied(String title) => """${title} kopiran u međuspremnik""";
  @override
  String get trade_history_title => """Povijest razmjena""";
  @override
  String get transaction_details_title => """Detalji transakcije""";
  @override
  String get transaction_details_transaction_id => """Transakcijski ID""";
  @override
  String get transaction_details_date => """Datum""";
  @override
  String get transaction_details_height => """Visina""";
  @override
  String get transaction_details_amount => """Iznos""";
  @override
  String get transaction_details_fee => """Naknada""";
  @override
  String transaction_details_copied(String title) => """${title} kopiran u međuspremnik""";
  @override
  String get transaction_details_recipient_address => """Primateljeva adresa""";
  @override
  String get wallet_list_title => """Monero novčanik""";
  @override
  String get wallet_list_create_new_wallet => """Izradi novi novčanik""";
  @override
  String get wallet_list_restore_wallet => """Oporavi novčanik""";
  @override
  String get wallet_list_load_wallet => """Učitaj novčanik""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """Učitavanje novčanika ${wallet_name}""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """Neuspješno učitavanje novčanika ${wallet_name}. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """Uklanjanje novčanika ${wallet_name}""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """Neuspješno uklanjanje novčanika ${wallet_name}. ${error}""";
  @override
  String get widgets_address => """Adresa""";
  @override
  String get widgets_restore_from_blockheight => """Oporavi pomoću visine bloka""";
  @override
  String get widgets_restore_from_date => """Oporavi pomoću datuma""";
  @override
  String get widgets_or => """ili""";
  @override
  String get widgets_seed => """pristupnog izraza""";
  @override
  String router_no_route(String name) => """Nije definirana ruta za ${name}""";
  @override
  String get error_text_account_name => """Ime računa smije sadržavati samo slova i brojeve
te mora biti dužine između 1 i 15 znakova""";
  @override
  String get error_text_contact_name => """Ime kontakta ne smije sadržavati znakove ` , ' " 
i mora biti dužine između 1 i 32 znaka""";
  @override
  String get error_text_address => """Adresa novčanika mora odgovarati
vrsti kriptovalute""";
  @override
  String get error_text_node_address => """Molimo unesite iPv4 adresu""";
  @override
  String get error_text_node_port => """Node port smije sadržavati samo brojeve između 0 i 65535""";
  @override
  String get error_text_payment_id => """ID plaćanja smije sadržavati samo od 16 do 64 znakova hex vrijednosti""";
  @override
  String get error_text_xmr => """XMR vrijednost ne smije biti veća od raspoloživog iznosa.
Broj decimala smije biti 12 ili manji.""";
  @override
  String get error_text_fiat => """Vrijednost iznosa ne smije biti veća od raspoloživog iznosa.
Broj decimala smije biti 2 ili manji.""";
  @override
  String get error_text_subaddress_name => """Ime podadrese ne smije sadržavati znakove ` , ' " 
i mora biti dužine između 1 i 20 znakova""";
  @override
  String get error_text_amount => """Iznos smije sadržavati samo brojeve""";
  @override
  String get error_text_wallet_name => """Ime novčanika smije sadržavati samo slova i brojeve
te mora biti dužine između 1 i 15 znakova""";
  @override
  String get error_text_keys => """Novčanik smije sadržavati samo 64 znakova hex vrijednosti""";
  @override
  String get error_text_crypto_currency => """Broj decimala mora
biti 12 ili manji""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """Razmjena za ${provider} nije izrađena. Iznos je manji od minimalnog: ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """Razmjena za ${provider} nije izrađena. Iznos je veći od maskimalnog: ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """Razmjena za ${provider} nije izrađena. Neuspješno učitavanje limita""";
  @override
  String get error_text_template => """Ime i adresa predloška ne smiju sadržavati znakove ` , ' " 
i moraju biti dužine između 1 i 106 znakova""";
  @override
  String get auth_store_ban_timeout => """ban_timeout""";
  @override
  String get auth_store_banned_for => """Suspendiran na """;
  @override
  String get auth_store_banned_minutes => """ minute""";
  @override
  String get auth_store_incorrect_password => """Pogrešan PIN""";
  @override
  String get wallet_store_monero_wallet => """Monero novčanik""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """Netočna dužina pristupnog izraza""";
  @override
  String get full_balance => """Pun iznos""";
  @override
  String get available_balance => """Raspoloživ iznos""";
  @override
  String get hidden_balance => """Skriven iznos""";
  @override
  String get sync_status_syncronizing => """SINKRONIZIRANJE""";
  @override
  String get sync_status_syncronized => """SINKRONIZIRANO""";
  @override
  String get sync_status_not_connected => """NIJE POVEZANO""";
  @override
  String get sync_status_starting_sync => """ZAPOČINJEMO SINKRONIZIRANJE""";
  @override
  String get sync_status_failed_connect => """ISKLJUČENO""";
  @override
  String get sync_status_connecting => """SPAJANJE""";
  @override
  String get sync_status_connected => """SPOJENO""";
  @override
  String get transaction_priority_slow => """Sporo""";
  @override
  String get transaction_priority_regular => """Uobičajeno""";
  @override
  String get transaction_priority_medium => """Srednje""";
  @override
  String get transaction_priority_fast => """Brzo""";
  @override
  String get transaction_priority_fastest => """Najbrže""";
  @override
  String trade_for_not_created(String title) => """Razmjena za ${title} nije izrađena.""";
  @override
  String get trade_not_created => """Razmjena nije izrađena.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """Razmjena ${tradeId} za ${title} nije pronađena.""";
  @override
  String get trade_not_found => """Razmjena nije pronađena.""";
  @override
  String get trade_state_pending => """U tijeku""";
  @override
  String get trade_state_confirming => """Potvrđivanje""";
  @override
  String get trade_state_trading => """Razmjenjivanje""";
  @override
  String get trade_state_traded => """Razmijenjeno""";
  @override
  String get trade_state_complete => """Dovršeno""";
  @override
  String get trade_state_to_be_created => """Stvaranje""";
  @override
  String get trade_state_unpaid => """Neplaćen""";
  @override
  String get trade_state_underpaid => """Nedovoljno plaćen""";
  @override
  String get trade_state_paid_unconfirmed => """Plaćanje nije potrđeno""";
  @override
  String get trade_state_paid => """Plaćen""";
  @override
  String get trade_state_btc_sent => """BTC poslan""";
  @override
  String get trade_state_timeout => """Isteklo""";
  @override
  String get trade_state_created => """Stvoreno""";
  @override
  String get trade_state_finished => """Završeno""";
  @override
  String get change_language => """Promijeni jezik""";
  @override
  String change_language_to(String language) => """Promijeni jezik u ${language}?""";
  @override
  String get paste => """Zalijepi""";
  @override
  String get restore_from_seed_placeholder => """Molimo unesite ili zalijepite svoj pristupni izraz ovdje""";
  @override
  String get add_new_word => """Dodaj novu riječ""";
  @override
  String get incorrect_seed => """Uneseni tekst nije valjan.""";
  @override
  String get biometric_auth_reason => """Skenirajte svoj otisak prsta za autentifikaciju""";
  @override
  String version(String currentVersion) => """Verzija ${currentVersion}""";
  @override
  String get openalias_alert_title => """XMR primatelj otkriven""";
  @override
  String openalias_alert_content(String recipient_name) => """Poslat ćete sredstva primatelju
${recipient_name}""";
  @override
  String get card_address => """Adresa:""";
  @override
  String get buy => """Kupi""";
  @override
  String get placeholder_transactions => """Vaše će transakcije biti prikazane ovdje""";
  @override
  String get placeholder_contacts => """Vaši će kontakti biti prikazani ovdje""";
  @override
  String get template => """Predložak""";
  @override
  String get confirm_delete_template => """Ovom ćete radnjom izbrisati ovaj predložak. Želite li nastaviti?""";
  @override
  String get confirm_delete_wallet => """Ovom ćete radnjom izbrisati ovaj novčanik. Želite li nastaviti?""";
  @override
  String get picker_description => """Da biste odabrali ChangeNOW ili MorphToken, molimo da prvo odabete dvije valute za trgovanje""";
  @override
  String get change_wallet_alert_title => """Izmijeni trenutni novčanik""";
  @override
  String change_wallet_alert_content(String wallet_name) => """Želite li promijeniti trenutni novčanik u ${wallet_name}?""";
  @override
  String get creating_new_wallet => """Stvaranje novog novčanika""";
  @override
  String creating_new_wallet_error(String description) => """Greška: ${description}""";
  @override
  String get seed_alert_title => """Upozorenje""";
  @override
  String get seed_alert_content => """Pristupni izraz jedini je način za oporavak novčanika. Jeste li ga zapisali?""";
  @override
  String get seed_alert_back => """Vrati se natrag""";
  @override
  String get seed_alert_yes => """Jesam""";
  @override
  String get exchange_sync_alert_content => """Molimo pričekajte dok se Vaš novčanik ne sinkronizira.""";
  @override
  String get pre_seed_title => """VAŽNO""";
  @override
  String pre_seed_description(String words) => """Na sljedećoj ćete stranici vidjeti niz ${words} riječi. Radi se o Vašem jedinstvenom i tajnom pristupnom izrazu koji je ujedno i JEDINI način na koji možete oporaviti svoj novčanik u slučaju gubitka ili kvara. VAŠA je odgovornost zapisati ga te pohraniti na sigurno mjesto izvan Cake Wallet aplikacije.""";
  @override
  String get pre_seed_button_text => """Razumijem. Prikaži mi moj pristupni izraz""";
  @override
  String get xmr_to_error => """XMR.TO greška""";
  @override
  String get xmr_to_error_description => """Nevažeći iznos. Dopušteno je najviše 8 znamenki iza točke""";
  @override
  String provider_error(String provider) => """${provider} greška""";
  @override
  String get use_ssl => """Koristi SSL""";
  @override
  String get color_theme => """Shema boja""";
  @override
  String get light_theme => """Svijetla""";
  @override
  String get bright_theme => """Jarka""";
  @override
  String get dark_theme => """Tamna""";
  @override
  String get enter_your_note => """Unesite svoju poruku…""";
  @override
  String get note_optional => """Poruka (nije obvezno)""";
  @override
  String get note_tap_to_change => """Poruka (dodirnite za promjenu)""";
  @override
  String get transaction_key => """Transakcijski ključ""";
  @override
  String get confirmations => """Potvrde""";
  @override
  String get recipient_address => """Primateljeva adresa""";
  @override
  String get extra_id => """Dodatni ID:""";
  @override
  String get destination_tag => """Odredišna oznaka:""";
  @override
  String get memo => """Memo:""";
  @override
  String get backup => """Sigurnosna kopija""";
  @override
  String get change_password => """Promijeni lozinku""";
  @override
  String get backup_password => """Lozinka za sigurnosnu kopiju""";
  @override
  String get write_down_backup_password => """Molimo zapišite svoju lozinku za sigurnosnu kopiju koja se koristi za uvoz datoteka sigurnosne kopije.""";
  @override
  String get export_backup => """Izvezi sigurnosnu kopiju""";
  @override
  String get save_backup_password => """Molimo pobrinite se da spremite svoju lozinku za sigurnosnu kopiju. Bez nje nećete moći uvesti datoteke sigurnosne kopije.""";
  @override
  String get backup_file => """Sigurnosna kopija datoteke""";
  @override
  String get edit_backup_password => """Uredi lozinku za sigurnosnu kopiju""";
  @override
  String get save_backup_password_alert => """Spremi lozinku za sigurnosnu kopiju""";
  @override
  String get change_backup_password_alert => """Nećemo moći uvesti Vaše prethodne datoteke sigurnosne kopije s novom lozinkom za sigurnosnu kopiju. Novu lozinku za sigurnosnu kopiju moći ćete koristiti samo za nove datoteke sigurnosne kopije. Jeste li sigurni da želite promijeniti lozinku za sigurnosnu kopiju?""";
  @override
  String get enter_backup_password => """Unesite svoju lozinku za sigurnosnu kopiju ovdje""";
  @override
  String get select_backup_file => """Odaberite datoteku sigurnosne kopije""";
  @override
  String get import => """Uvezi""";
  @override
  String get please_select_backup_file => """Molimo odaberite datoteku sigurnosne kopije i unesite lozinku za sigurnosnu kopiju.""";
  @override
  String get fixed_rate => """Fiksna stopa""";
  @override
  String get fixed_rate_alert => """Moći ćete unijeti iznos koji želite primiti nakon što označite način rada fiksne stope. Želite li se prebaciti na način rada fiksne stope?""";
  @override
  String get xlm_extra_info => """Molimo ne zaboravite navesti memo ID prilikom slanja XLM transakcije na razmjenu""";
  @override
  String get xrp_extra_info => """Molimo ne zaboravite navesti odredišnu oznaku prilikom slanja XRP transakcije na razmjenu""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Ako želite razmijeniti XMR s vlastitog Monero računa na Cake Wallet novčaniku, molimo prvo se prebacite na svoj Monero novčanik.""";
  @override
  String get confirmed => """Potvrđeno""";
  @override
  String get unconfirmed => """Nepotvrđeno""";
  @override
  String get displayable => """Dostupno za prikaz""";
  @override
  String get submit_request => """podnesi zahtjev""";
  @override
  String get buy_alert_content => """Trenutno podržavamo samo kupnju Bitcoina i Litecoina. Da biste kupili Bitcoin ili Litecoin, stvorite ili pređite na svoj Bitcoin ili Litecoin novčanik.""";
  @override
  String get outdated_electrum_wallet_description => """Novi Bitcoin novčanici stvoreni u Cakeu sada imaju sjeme od 24 riječi. Obavezno je stvoriti novi Bitcoin novčanik i prenijeti sva svoja sredstva u novi novčanik od 24 riječi te prestati koristiti novčanike s sjemenkom od 12 riječi. Učinite to odmah kako biste osigurali svoja sredstva.""";
  @override
  String get understand => """Razumijem""";
  @override
  String get apk_update => """APK ažuriranje""";
  @override
  String get buy_bitcoin => """Kupite Bitcoin""";
  @override
  String get buy_with => """Kupite s""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """Vrijednost iznosa mora biti veća ili jednaka ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """Ako ovaj novčanik sadrži sjeme od 12 riječi i stvoren je u Torti, NEMOJTE polagati Bitcoin u ovaj novčanik. Bilo koji BTC prebačen u ovaj novčanik može se izgubiti. Stvorite novi novčanik od 24 riječi (taknite izbornik u gornjem desnom dijelu, odaberite Novčanici, odaberite Stvori novi novčanik, a zatim odaberite Bitcoin) i ODMAH premjestite svoj BTC tamo. Novi BTC novčanici (s 24 riječi) tvrtke Cake sigurni su""";
  @override
  String get do_not_show_me => """Ne pokazuj mi ovo više""";
  @override
  String get unspent_coins_title => """Nepotrošeni novčići""";
  @override
  String get unspent_coins_details_title => """Nepotrošeni detalji o novčićima""";
  @override
  String get freeze => """Zamrznuti""";
  @override
  String get coin_control => """Kontrola novca (nije obavezno)""";
  @override
  String get address_detected => """Adresa je otkrivena""";
  @override
  String address_from_domain(String domain) => """Dobili ste adresu od unstoppable domain ${domain}""";
}

class $pt extends S {
  const $pt();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """Bem-vindo ao""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """Uma fantástica carteira para Monero e Bitcoin""";
  @override
  String get please_make_selection => """Escolha se quer criar uma carteira nova ou restaurar uma antiga.""";
  @override
  String get create_new => """Criar nova carteira""";
  @override
  String get restore_wallet => """Restaurar carteira""";
  @override
  String get accounts => """Contas""";
  @override
  String get edit => """Editar""";
  @override
  String get account => """Conta""";
  @override
  String get add => """Adicionar""";
  @override
  String get address_book => """Livro de endereços""";
  @override
  String get contact => """Contato""";
  @override
  String get please_select => """Escolha abaixo:""";
  @override
  String get cancel => """Cancelar""";
  @override
  String get ok => """Ok""";
  @override
  String get contact_name => """Nome do contato""";
  @override
  String get reset => """Limpar""";
  @override
  String get save => """Salvar""";
  @override
  String get address_remove_contact => """Remover contato""";
  @override
  String get address_remove_content => """Tem certeza de que deseja remover o contato selecionado?""";
  @override
  String get authenticated => """Autenticado""";
  @override
  String get authentication => """Autenticação""";
  @override
  String failed_authentication(String state_error) => """Falha na autenticação. ${state_error}""";
  @override
  String get wallet_menu => """Menu""";
  @override
  String Blocks_remaining(String status) => """${status} blocos restantes""";
  @override
  String get please_try_to_connect_to_another_node => """Por favor, tente conectar-se a outro nó""";
  @override
  String get xmr_hidden => """Esconder saldo""";
  @override
  String get xmr_available_balance => """Saldo disponível""";
  @override
  String get xmr_full_balance => """Saldo total""";
  @override
  String get send => """Enviar""";
  @override
  String get receive => """Receber""";
  @override
  String get transactions => """Transações""";
  @override
  String get incoming => """Recebidas""";
  @override
  String get outgoing => """Enviadas""";
  @override
  String get transactions_by_date => """Transações por data""";
  @override
  String get trades => """Trocas""";
  @override
  String get filters => """Filtro""";
  @override
  String get today => """Hoje""";
  @override
  String get yesterday => """Ontem""";
  @override
  String get received => """Recebida""";
  @override
  String get sent => """Enviada""";
  @override
  String get pending => """ (pendente)""";
  @override
  String get rescan => """Reescanear""";
  @override
  String get reconnect => """Reconectar""";
  @override
  String get wallets => """Carteiras""";
  @override
  String get show_seed => """Mostrar semente""";
  @override
  String get show_keys => """Mostrar semente/chaves""";
  @override
  String get address_book_menu => """Livro de endereços""";
  @override
  String get reconnection => """Reconectar""";
  @override
  String get reconnect_alert_text => """Você tem certeza de que deseja reconectar?""";
  @override
  String get exchange => """Trocar""";
  @override
  String get clear => """Limpar""";
  @override
  String get refund_address => """Endereço de reembolso""";
  @override
  String get change_exchange_provider => """Alterar o provedor de troca""";
  @override
  String get you_will_send => """Converter de""";
  @override
  String get you_will_get => """Converter para""";
  @override
  String get amount_is_guaranteed => """O valor recebido é garantido""";
  @override
  String get amount_is_estimate => """O valor a ser recebido informado acima é uma estimativa""";
  @override
  String powered_by(String title) => """Troca realizada por ${title}""";
  @override
  String get error => """Erro""";
  @override
  String get estimated => """Estimado""";
  @override
  String min_value(String value, String currency) => """Mín: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """Máx: ${value} ${currency}""";
  @override
  String get change_currency => """Alterar moeda""";
  @override
  String get copy_id => """Copiar ID""";
  @override
  String get exchange_result_write_down_trade_id => """Copie ou anote o ID da troca para continuar.""";
  @override
  String get trade_id => """ID da troca:""";
  @override
  String get copied_to_clipboard => """Copiado para a área de transferência""";
  @override
  String get saved_the_trade_id => """ID da troca salvo""";
  @override
  String get fetching => """Buscando""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """Quantia: """;
  @override
  String get payment_id => """ID de pagamento: """;
  @override
  String get status => """Status: """;
  @override
  String get offer_expires_in => """A oferta expira em: """;
  @override
  String trade_is_powered_by(String provider) => """Troca realizada por ${provider}""";
  @override
  String get copy_address => """Copiar endereço""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """Ao confirmar, você enviará ${fetchingLabel} ${from} da sua carteira  ${walletName} para o endereço mostrado abaixo. Ou você pode enviar de sua carteira externa para o endereço abaixo/código QR acima.

Pressione Confirmar para continuar ou volte para alterar os valores.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """Você deve enviar no mínimo ${fetchingLabel} ${from} para o endereço mostrado na próxima página. Se você enviar um valor inferior a ${fetchingLabel} ${from}, ele pode não ser convertido e pode não ser reembolsado.""";
  @override
  String get exchange_result_write_down_ID => """*Copie ou anote seu ID mostrado acima.""";
  @override
  String get confirm => """Confirmar""";
  @override
  String get confirm_sending => """Confirmar o envio""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """Confirmar transação
Quantia: ${amount}
Taxa: ${fee}""";
  @override
  String get sending => """Enviando""";
  @override
  String get transaction_sent => """Transação enviada!""";
  @override
  String get expired => """Expirada""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """Enviar XMR""";
  @override
  String get exchange_new_template => """Novo modelo""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """Insira seu PIN""";
  @override
  String get loading_your_wallet => """Abrindo sua carteira""";
  @override
  String get new_wallet => """Nova carteira""";
  @override
  String get wallet_name => """Nome da carteira""";
  @override
  String get continue_text => """Continuar""";
  @override
  String get choose_wallet_currency => """Escolha a moeda da carteira:""";
  @override
  String get node_new => """Novo nó""";
  @override
  String get node_address => """Endereço do nó""";
  @override
  String get node_port => """Porta do nó""";
  @override
  String get login => """Login""";
  @override
  String get password => """Senha""";
  @override
  String get nodes => """Nós""";
  @override
  String get node_reset_settings_title => """Redefinir configurações""";
  @override
  String get nodes_list_reset_to_default_message => """Você realmente deseja redefinir as configurações para o padrão?""";
  @override
  String change_current_node(String node) => """Você realmente deseja alterar o nó atual para ${node}?""";
  @override
  String get change => """Mudar""";
  @override
  String get remove_node => """Remover nó""";
  @override
  String get remove_node_message => """Você realmente deseja remover o nó selecionado?""";
  @override
  String get remove => """Remover""";
  @override
  String get delete => """Excluir""";
  @override
  String get add_new_node => """Adicionar novo nó""";
  @override
  String get change_current_node_title => """Mudar o nó atual""";
  @override
  String get node_test => """Teste""";
  @override
  String get node_connection_successful => """A conexão foi bem sucedida""";
  @override
  String get node_connection_failed => """A conexão falhou""";
  @override
  String get new_node_testing => """Teste de novo nó""";
  @override
  String get use => """Use PIN de """;
  @override
  String get digit_pin => """dígitos""";
  @override
  String get share_address => """Compartilhar endereço""";
  @override
  String get receive_amount => """Quantia""";
  @override
  String get subaddresses => """Sub-endereços""";
  @override
  String get addresses => """Endereços""";
  @override
  String get scan_qr_code => """Digitalize o código QR para obter o endereço""";
  @override
  String get rename => """Renomear""";
  @override
  String get choose_account => """Escolha uma conta""";
  @override
  String get create_new_account => """Criar nova conta""";
  @override
  String get accounts_subaddresses => """Contas e sub-endereços""";
  @override
  String get restore_restore_wallet => """Restaurar carteira""";
  @override
  String get restore_title_from_seed_keys => """Restaurar a partir de sementes/chaves""";
  @override
  String get restore_description_from_seed_keys => """Restaure a sua carteira a partir de sementes/chaves que você salvou em um local seguro""";
  @override
  String get restore_next => """Próximo""";
  @override
  String get restore_title_from_backup => """Restaurar a partir de um arquivo de backup""";
  @override
  String get restore_description_from_backup => """Você pode restaurar todo o aplicativo Cake Wallet de seu arquivo de backup""";
  @override
  String get restore_seed_keys_restore => """Restauração com sementes/chaves""";
  @override
  String get restore_title_from_seed => """Restaurar a partir de semente""";
  @override
  String get restore_description_from_seed => """Restaure sua carteira a partir de semente com 25 palavras ou 13 palavras""";
  @override
  String get restore_title_from_keys => """Restaurar a partir de chaves""";
  @override
  String get restore_description_from_keys => """Restaure sua carteira a partir de suas chaves privadas""";
  @override
  String get restore_wallet_name => """Nome da carteira""";
  @override
  String get restore_address => """Endereço""";
  @override
  String get restore_view_key_private => """Chave de visualização (privada)""";
  @override
  String get restore_spend_key_private => """Chave de gastos (privada)""";
  @override
  String get restore_recover => """Restaurar""";
  @override
  String get restore_wallet_restore_description => """Restauração da carteira""";
  @override
  String get restore_new_seed => """Nova semente""";
  @override
  String get restore_active_seed => """Semente ativa""";
  @override
  String get restore_bitcoin_description_from_seed => """Restaure sua carteira a partir de um código de combinação de 24 palavras""";
  @override
  String get restore_bitcoin_description_from_keys => """Restaure sua carteira a partir da string WIF gerada de suas chaves privadas""";
  @override
  String get restore_bitcoin_title_from_keys => """Restaurar de WIF""";
  @override
  String get restore_from_date_or_blockheight => """Insira uma data alguns dias antes de criar esta carteira. Ou se você souber a altura do bloco, insira-o""";
  @override
  String get seed_reminder => """Anote-os para o caso de perder ou limpar seu telefone""";
  @override
  String get seed_title => """Semente""";
  @override
  String get seed_share => """Compartilhar semente""";
  @override
  String get copy => """Copiar""";
  @override
  String get seed_language_choose => """Por favor, escolha o idioma da semente:""";
  @override
  String get seed_choose => """Escolha o idioma da semente""";
  @override
  String get seed_language_next => """Próximo""";
  @override
  String get seed_language_english => """Inglesa""";
  @override
  String get seed_language_chinese => """Chinesa""";
  @override
  String get seed_language_dutch => """Holandesa""";
  @override
  String get seed_language_german => """Alemã""";
  @override
  String get seed_language_japanese => """Japonês""";
  @override
  String get seed_language_portuguese => """Português""";
  @override
  String get seed_language_russian => """Russa""";
  @override
  String get seed_language_spanish => """Espanhola""";
  @override
  String get send_title => """Enviar""";
  @override
  String get send_your_wallet => """Sua carteira""";
  @override
  String send_address(String cryptoCurrency) => """Endereço ${cryptoCurrency}""";
  @override
  String get send_payment_id => """ID de pagamento (opcional)""";
  @override
  String get all => """TUDO""";
  @override
  String get send_error_minimum_value => """O valor mínimo da quantia é 0,01""";
  @override
  String get send_error_currency => """A moeda só pode conter números""";
  @override
  String get send_estimated_fee => """Taxa estimada:""";
  @override
  String send_priority(String transactionPriority) => """Atualmente, a taxa está definida para a prioridade: ${transactionPriority}.
A prioridade da transação pode ser ajustada nas configurações""";
  @override
  String get send_creating_transaction => """Criando transação""";
  @override
  String get send_templates => """Modelos""";
  @override
  String get send_new => """Novo""";
  @override
  String get send_amount => """Montante:""";
  @override
  String get send_fee => """Taxa:""";
  @override
  String get send_name => """Nome""";
  @override
  String get send_got_it => """Entendi""";
  @override
  String get send_sending => """Enviando...""";
  @override
  String send_success(String crypto) => """Seu ${crypto} foi enviado com sucesso""";
  @override
  String get settings_title => """Configurações""";
  @override
  String get settings_nodes => """Nós""";
  @override
  String get settings_current_node => """Nó atual""";
  @override
  String get settings_wallets => """Carteiras""";
  @override
  String get settings_display_balance_as => """Saldo a exibir""";
  @override
  String get settings_currency => """Moeda""";
  @override
  String get settings_fee_priority => """Prioridade da taxa""";
  @override
  String get settings_save_recipient_address => """Salvar endereço do destinatário""";
  @override
  String get settings_personal => """Pessoal""";
  @override
  String get settings_change_pin => """Mudar PIN""";
  @override
  String get settings_change_language => """Mudar idioma""";
  @override
  String get settings_allow_biometrical_authentication => """Permitir autenticação biométrica""";
  @override
  String get settings_dark_mode => """Modo noturno""";
  @override
  String get settings_transactions => """Transações""";
  @override
  String get settings_trades => """Trocas""";
  @override
  String get settings_display_on_dashboard_list => """Exibir no histórico""";
  @override
  String get settings_all => """Tudo""";
  @override
  String get settings_only_trades => """Somente trocas""";
  @override
  String get settings_only_transactions => """Somente transações""";
  @override
  String get settings_none => """Nada""";
  @override
  String get settings_support => """Suporte""";
  @override
  String get settings_terms_and_conditions => """Termos e Condições""";
  @override
  String get pin_is_incorrect => """PIN incorreto""";
  @override
  String get setup_pin => """Configurar PIN""";
  @override
  String get enter_your_pin_again => """Insira seu PIN novamente""";
  @override
  String get setup_successful => """Seu PIN foi configurado com sucesso!""";
  @override
  String get wallet_keys => """Semente/chaves da carteira""";
  @override
  String get wallet_seed => """Semente de carteira""";
  @override
  String get private_key => """Chave privada""";
  @override
  String get public_key => """Chave pública""";
  @override
  String get view_key_private => """Chave de visualização (privada)""";
  @override
  String get view_key_public => """Chave de visualização (pública)""";
  @override
  String get spend_key_private => """Chave de gastos (privada)""";
  @override
  String get spend_key_public => """Chave de gastos (pública)""";
  @override
  String copied_key_to_clipboard(String key) => """${key} copiada para a área de transferência""";
  @override
  String get new_subaddress_title => """Novo endereço""";
  @override
  String get new_subaddress_label_name => """Nome""";
  @override
  String get new_subaddress_create => """Criar""";
  @override
  String get subaddress_title => """Sub-endereços""";
  @override
  String get trade_details_title => """Detalhes da troca""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """Status""";
  @override
  String get trade_details_fetching => """Buscando""";
  @override
  String get trade_details_provider => """Provedor""";
  @override
  String get trade_details_created_at => """Criada em""";
  @override
  String get trade_details_pair => """Par""";
  @override
  String trade_details_copied(String title) => """${title} copiados para a área de transferência""";
  @override
  String get trade_history_title => """Histórico de trocas""";
  @override
  String get transaction_details_title => """Detalhes da transação""";
  @override
  String get transaction_details_transaction_id => """ID da transação""";
  @override
  String get transaction_details_date => """Data""";
  @override
  String get transaction_details_height => """Altura""";
  @override
  String get transaction_details_amount => """Quantia""";
  @override
  String get transaction_details_fee => """Taxa""";
  @override
  String transaction_details_copied(String title) => """${title} copiados para a área de transferência""";
  @override
  String get transaction_details_recipient_address => """Endereço do destinatário""";
  @override
  String get wallet_list_title => """Carteira Monero""";
  @override
  String get wallet_list_create_new_wallet => """Criar nova carteira""";
  @override
  String get wallet_list_restore_wallet => """Restaurar carteira""";
  @override
  String get wallet_list_load_wallet => """Abrir carteira""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """Abrindo a carteira ${wallet_name}""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """Falha ao abrir a carteira ${wallet_name}. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """Removendo a carteira ${wallet_name}""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """Falha ao remover a carteira ${wallet_name}. ${error}""";
  @override
  String get widgets_address => """Endereço""";
  @override
  String get widgets_restore_from_blockheight => """Restaurar a partir de altura do bloco""";
  @override
  String get widgets_restore_from_date => """Restaurar a partir de data""";
  @override
  String get widgets_or => """ou""";
  @override
  String get widgets_seed => """Semente""";
  @override
  String router_no_route(String name) => """Nenhuma rota definida para ${name}""";
  @override
  String get error_text_account_name => """O nome da conta só pode conter letras, números
e deve ter entre 1 e 15 caracteres""";
  @override
  String get error_text_contact_name => """O nome do contato não pode conter os símbolos ` , ' " 
e deve ter entre 1 e 32 caracteres""";
  @override
  String get error_text_address => """O endereço da carteira deve corresponder à
criptomoeda selecionada""";
  @override
  String get error_text_node_address => """Digite um endereço iPv4""";
  @override
  String get error_text_node_port => """A porta do nó deve conter apenas números entre 0 e 65535""";
  @override
  String get error_text_payment_id => """O ID de pagamento pode conter apenas de 16 a 64 caracteres em hexadecimal""";
  @override
  String get error_text_xmr => """A quantia em XMR não pode exceder o saldo disponível.
TO número de dígitos decimais deve ser menor ou igual a 12""";
  @override
  String get error_text_fiat => """O valor do valor não pode exceder o saldo disponível.
O número de dígitos decimais deve ser menor ou igual a 2""";
  @override
  String get error_text_subaddress_name => """O nome do sub-endereço não pode conter os símbolos ` , ' " 
e deve ter entre 1 e 20 caracteres""";
  @override
  String get error_text_amount => """A quantia deve conter apenas números""";
  @override
  String get error_text_wallet_name => """O nome da carteira só pode conter letras, números
e deve ter entre 1 e 20 caracteres""";
  @override
  String get error_text_keys => """As chaves da carteira podem conter apenas 64 caracteres em hexadecimal""";
  @override
  String get error_text_crypto_currency => """O número de dígitos decimais
deve ser menor ou igual a 12""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """A troca por ${provider} não é criada. O valor é menor que o mínimo: ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """A troca por ${provider} não é criada. O valor é superior ao máximo: ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """A troca por ${provider} não é criada. Falha no carregamento dos limites""";
  @override
  String get error_text_template => """O nome e o endereço do modelo não podem conter os símbolos ` , ' " 
e deve ter entre 1 e 106 caracteres""";
  @override
  String get auth_store_ban_timeout => """ban_timeout""";
  @override
  String get auth_store_banned_for => """Banido por""";
  @override
  String get auth_store_banned_minutes => """ minutos""";
  @override
  String get auth_store_incorrect_password => """PIN incorreto""";
  @override
  String get wallet_store_monero_wallet => """Carteira Monero""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """Comprimento de semente incorreto""";
  @override
  String get full_balance => """Saldo total""";
  @override
  String get available_balance => """Saldo disponível""";
  @override
  String get hidden_balance => """Saldo escondido""";
  @override
  String get sync_status_syncronizing => """SINCRONIZANDO""";
  @override
  String get sync_status_syncronized => """SINCRONIZADO""";
  @override
  String get sync_status_not_connected => """DESCONECTADO""";
  @override
  String get sync_status_starting_sync => """INICIANDO SINCRONIZAÇÃO""";
  @override
  String get sync_status_failed_connect => """DESCONECTADO""";
  @override
  String get sync_status_connecting => """CONECTANDO""";
  @override
  String get sync_status_connected => """CONECTADO""";
  @override
  String get transaction_priority_slow => """Lenta""";
  @override
  String get transaction_priority_regular => """Regular""";
  @override
  String get transaction_priority_medium => """Média""";
  @override
  String get transaction_priority_fast => """Rápida""";
  @override
  String get transaction_priority_fastest => """Muito rápida""";
  @override
  String trade_for_not_created(String title) => """A troca por ${title} não foi criada.""";
  @override
  String get trade_not_created => """Troca não criada.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """A troca ${tradeId} de ${title} não foi encontrada.""";
  @override
  String get trade_not_found => """Troca não encontrada.""";
  @override
  String get trade_state_pending => """Pendente""";
  @override
  String get trade_state_confirming => """Confirmando""";
  @override
  String get trade_state_trading => """Em andamento""";
  @override
  String get trade_state_traded => """Troca realizada""";
  @override
  String get trade_state_complete => """Finalizada""";
  @override
  String get trade_state_to_be_created => """A ser criada""";
  @override
  String get trade_state_unpaid => """Não paga""";
  @override
  String get trade_state_underpaid => """Parcialmente paga""";
  @override
  String get trade_state_paid_unconfirmed => """Pagamento não-confirmado""";
  @override
  String get trade_state_paid => """Paga""";
  @override
  String get trade_state_btc_sent => """BTC enviado""";
  @override
  String get trade_state_timeout => """Tempo esgotado""";
  @override
  String get trade_state_created => """Criada""";
  @override
  String get trade_state_finished => """Finalizada""";
  @override
  String get change_language => """Mudar idioma""";
  @override
  String change_language_to(String language) => """Alterar idioma para ${language}?""";
  @override
  String get paste => """Colar""";
  @override
  String get restore_from_seed_placeholder => """Digite ou cole sua frase de código aqui""";
  @override
  String get add_new_word => """Adicionar nova palavra""";
  @override
  String get incorrect_seed => """O texto digitado não é válido.""";
  @override
  String get biometric_auth_reason => """Digitalize sua impressão digital para autenticar""";
  @override
  String version(String currentVersion) => """Versão ${currentVersion}""";
  @override
  String get openalias_alert_title => """Destinatário XMR detectado""";
  @override
  String openalias_alert_content(String recipient_name) => """Você enviará fundos para
${recipient_name}""";
  @override
  String get card_address => """Endereço:""";
  @override
  String get buy => """Comprar""";
  @override
  String get placeholder_transactions => """Suas transações serão exibidas aqui""";
  @override
  String get placeholder_contacts => """Seus contatos serão exibidos aqui""";
  @override
  String get template => """Modelo""";
  @override
  String get confirm_delete_template => """Esta ação excluirá este modelo. Você deseja continuar?""";
  @override
  String get confirm_delete_wallet => """Esta ação excluirá esta carteira. Você deseja continuar?""";
  @override
  String get picker_description => """Para escolher ChangeNOW ou MorphToken, altere primeiro o seu par de negociação""";
  @override
  String get change_wallet_alert_title => """Alterar carteira atual""";
  @override
  String change_wallet_alert_content(String wallet_name) => """Quer mudar a carteira atual para ${wallet_name}?""";
  @override
  String get creating_new_wallet => """Criando nova carteira""";
  @override
  String creating_new_wallet_error(String description) => """Erro: ${description}""";
  @override
  String get seed_alert_title => """Atenção""";
  @override
  String get seed_alert_content => """A semente é a única forma de recuperar sua carteira. Você escreveu isso?""";
  @override
  String get seed_alert_back => """Volte""";
  @override
  String get seed_alert_yes => """Sim, eu tenho""";
  @override
  String get wallet_name_alert_content => """Já existe carteira com o mesmo nome""";
  @override
  String get exchange_sync_alert_content => """Por favor, espere até que sua carteira seja sincronizada""";
  @override
  String get pre_seed_title => """IMPORTANTE""";
  @override
  String pre_seed_description(String words) => """Na próxima página, você verá uma série de ${words} palavras. Esta é a sua semente única e privada e é a ÚNICA maneira de recuperar sua carteira em caso de perda ou mau funcionamento. É SUA responsabilidade anotá-lo e armazená-lo em um local seguro fora do aplicativo Cake Wallet.""";
  @override
  String get pre_seed_button_text => """Compreendo. Me mostre minha semente""";
  @override
  String get xmr_to_error => """Erro XMR.TO""";
  @override
  String get xmr_to_error_description => """Montante inválido. Limite máximo de 8 dígitos após o ponto decimal""";
  @override
  String provider_error(String provider) => """${provider} erro""";
  @override
  String get use_ssl => """Use SSL""";
  @override
  String get color_theme => """Tema de cor""";
  @override
  String get light_theme => """Luz""";
  @override
  String get bright_theme => """Brilhante""";
  @override
  String get dark_theme => """Sombria""";
  @override
  String get enter_your_note => """Insira sua nota ...""";
  @override
  String get note_optional => """Nota (opcional)""";
  @override
  String get note_tap_to_change => """Nota (toque para alterar)""";
  @override
  String get transaction_key => """Chave de transação""";
  @override
  String get confirmations => """Confirmações""";
  @override
  String get recipient_address => """Endereço do destinatário""";
  @override
  String get extra_id => """ID extra:""";
  @override
  String get destination_tag => """Tag de destino:""";
  @override
  String get memo => """Memorando:""";
  @override
  String get backup => """Cópia de segurança""";
  @override
  String get change_password => """Mudar senha""";
  @override
  String get backup_password => """Senha de backup""";
  @override
  String get write_down_backup_password => """Anote sua senha de backup, que será usada para importar seus arquivos de backup.""";
  @override
  String get export_backup => """Backup de exportação""";
  @override
  String get save_backup_password => """Certifique-se de que salvou sua senha de backup. Você não poderá importar seus arquivos de backup sem ele.""";
  @override
  String get backup_file => """Arquivo de backup""";
  @override
  String get edit_backup_password => """Editar senha de backup""";
  @override
  String get save_backup_password_alert => """Salvar senha de backup""";
  @override
  String get change_backup_password_alert => """Seus arquivos de backup anteriores não estarão disponíveis para importação com a nova senha de backup. A nova senha de backup será usada apenas para novos arquivos de backup. Tem certeza que deseja alterar a senha de backup?""";
  @override
  String get enter_backup_password => """Digite a senha de backup aqui""";
  @override
  String get select_backup_file => """Selecione o arquivo de backup""";
  @override
  String get import => """Importar""";
  @override
  String get please_select_backup_file => """Selecione o arquivo de backup e insira a senha de backup.""";
  @override
  String get fixed_rate => """Taxa fixa""";
  @override
  String get fixed_rate_alert => """Você poderá inserir a quantia recebida quando o modo de taxa fixa estiver marcado. Quer mudar para o modo de taxa fixa?""";
  @override
  String get xlm_extra_info => """Não se esqueça de especificar o Memo ID ao enviar a transação XLM para a troca""";
  @override
  String get xrp_extra_info => """Não se esqueça de especificar a etiqueta de destino ao enviar a transação XRP para a troca""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Se você deseja trocar o XMR de seu saldo da Carteira Monero Cake, troque primeiro para sua carteira Monero.""";
  @override
  String get confirmed => """Confirmada""";
  @override
  String get unconfirmed => """Não confirmado""";
  @override
  String get displayable => """Exibível""";
  @override
  String get submit_request => """enviar um pedido""";
  @override
  String get buy_alert_content => """Atualmente, apoiamos apenas a compra de Bitcoin e Litecoin. Para comprar Bitcoin ou Litecoin, crie ou troque para sua carteira Bitcoin ou Litecoin.""";
  @override
  String get outdated_electrum_wallet_description => """As novas carteiras Bitcoin criadas no Cake agora têm uma semente de 24 palavras. É obrigatório que você crie uma nova carteira Bitcoin e transfira todos os seus fundos para a nova carteira de 24 palavras, e pare de usar carteiras com semente de 12 palavras. Faça isso imediatamente para garantir seus fundos.""";
  @override
  String get understand => """Entendo""";
  @override
  String get apk_update => """Atualização de APK""";
  @override
  String get buy_bitcoin => """Compre Bitcoin""";
  @override
  String get buy_with => """Compre com""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """O valor do montante deve ser maior ou igual a ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """Se esta carteira tiver uma semente de 12 palavras e foi criada no Cake, NÃO deposite Bitcoin nesta carteira. Qualquer BTC transferido para esta carteira pode ser perdido. Crie uma nova carteira de 24 palavras (toque no menu no canto superior direito, selecione Carteiras, escolha Criar Nova Carteira e selecione Bitcoin) e mova IMEDIATAMENTE seu BTC para lá. As novas carteiras BTC (24 palavras) da Cake são seguras""";
  @override
  String get do_not_show_me => """não me mostre isso novamente""";
  @override
  String get unspent_coins_title => """Moedas não gastas""";
  @override
  String get unspent_coins_details_title => """Detalhes de moedas não gastas""";
  @override
  String get freeze => """Congelar""";
  @override
  String get coin_control => """Controle de moedas (opcional)""";
  @override
  String get address_detected => """Endereço detectado""";
  @override
  String address_from_domain(String domain) => """Você obteve o endereço de unstoppable domain ${domain}""";
}

class $de extends S {
  const $de();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """Willkommen bei""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """Eine großartige Wallet für Monero und Bitcoin""";
  @override
  String get please_make_selection => """Bitte treffen Sie unten eine Auswahl zum Erstellen oder Wiederherstellen Ihrer Wallet.""";
  @override
  String get create_new => """Neue Wallet erstellen""";
  @override
  String get restore_wallet => """Wallet wiederherstellen""";
  @override
  String get accounts => """Konten""";
  @override
  String get edit => """Bearbeiten""";
  @override
  String get account => """Konto""";
  @override
  String get add => """Hinzufügen""";
  @override
  String get address_book => """Adressbuch""";
  @override
  String get contact => """Kontakt""";
  @override
  String get please_select => """Bitte auswählen:""";
  @override
  String get cancel => """Abbrechen""";
  @override
  String get ok => """OK""";
  @override
  String get contact_name => """Name des Kontakts""";
  @override
  String get reset => """Zurücksetzen""";
  @override
  String get save => """Speichern""";
  @override
  String get address_remove_contact => """Kontakt entfernen""";
  @override
  String get address_remove_content => """Sind Sie sicher, dass Sie den ausgewählten Kontakt entfernen möchten?""";
  @override
  String get authenticated => """Authentifiziert""";
  @override
  String get authentication => """Authentifizierung""";
  @override
  String failed_authentication(String state_error) => """Authentifizierung fehlgeschlagen. ${state_error}""";
  @override
  String get wallet_menu => """Wallet-Menü""";
  @override
  String Blocks_remaining(String status) => """${status} verbleibende Blöcke""";
  @override
  String get please_try_to_connect_to_another_node => """Bitte versuchen Sie, sich mit einem anderen Knoten zu verbinden""";
  @override
  String get xmr_hidden => """Versteckt""";
  @override
  String get xmr_available_balance => """Verfügbares Guthaben""";
  @override
  String get xmr_full_balance => """Gesamtguthaben""";
  @override
  String get send => """Senden""";
  @override
  String get receive => """Empfangen""";
  @override
  String get transactions => """Transaktionen""";
  @override
  String get incoming => """Eingehend""";
  @override
  String get outgoing => """Ausgehend""";
  @override
  String get transactions_by_date => """Transaktionen nach Datum""";
  @override
  String get trades => """Börsen""";
  @override
  String get filters => """Filter""";
  @override
  String get today => """Heute""";
  @override
  String get yesterday => """Gestern""";
  @override
  String get received => """Empfangen""";
  @override
  String get sent => """Versendet""";
  @override
  String get pending => """ (ausstehend)""";
  @override
  String get rescan => """Erneut scannen""";
  @override
  String get reconnect => """Erneut verbinden""";
  @override
  String get wallets => """Wallets""";
  @override
  String get show_seed => """Seed zeigen""";
  @override
  String get show_keys => """Seed/Schlüssel anzeigen""";
  @override
  String get address_book_menu => """Adressbuch""";
  @override
  String get reconnection => """Neu verbinden""";
  @override
  String get reconnect_alert_text => """Sind Sie sicher, dass Sie sich neu verbinden möchten?""";
  @override
  String get exchange => """Umwechseln""";
  @override
  String get clear => """Zurücksetzen""";
  @override
  String get refund_address => """Rückerstattungsadresse""";
  @override
  String get change_exchange_provider => """Exchange-Anbieter ändern""";
  @override
  String get you_will_send => """Konvertieren von""";
  @override
  String get you_will_get => """Konvertieren zu""";
  @override
  String get amount_is_guaranteed => """Der Empfangsbetrag ist garantiert""";
  @override
  String get amount_is_estimate => """Der empfangene Betrag ist eine Schätzung""";
  @override
  String powered_by(String title) => """Ermöglicht durch ${title}""";
  @override
  String get error => """Fehler""";
  @override
  String get estimated => """Geschätzt""";
  @override
  String min_value(String value, String currency) => """Min: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """Max: ${value} ${currency}""";
  @override
  String get change_currency => """Währung ändern""";
  @override
  String get copy_id => """ID kopieren""";
  @override
  String get exchange_result_write_down_trade_id => """Bitte kopieren oder notieren Sie die Handels-ID, um fortzufahren.""";
  @override
  String get trade_id => """Handels-ID:""";
  @override
  String get copied_to_clipboard => """In die Zwischenablage kopiert""";
  @override
  String get saved_the_trade_id => """Ich habe die Handels-ID gespeichert""";
  @override
  String get fetching => """Frage ab""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """Betrag: """;
  @override
  String get payment_id => """Zahlungs-ID: """;
  @override
  String get status => """Status: """;
  @override
  String get offer_expires_in => """Angebot läuft ab in: """;
  @override
  String trade_is_powered_by(String provider) => """Dieser Handel wird angeboten von ${provider}""";
  @override
  String get copy_address => """Adresse kopieren""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """Durch Drücken von "Bestätigen" wird ${fetchingLabel} ${from} von Ihrer Wallet namens ${walletName} an die unten angegebene Adresse gesendet. Alternativ können Sie von einer externen Wallet an die unten angegebene Adresse / QR-Code senden.

Bitte bestätigen Sie, um fortzufahren, oder gehen Sie zurück, um die Beträge zu ändern.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """Sie müssen mindestens ${fetchingLabel} ${from} an die auf der nächsten Seite angegebene Adresse senden. Wenn Sie einen Betrag unter ${fetchingLabel} ${from} senden, wird dieser möglicherweise nicht konvertiert und möglicherweise nicht erstattet.""";
  @override
  String get exchange_result_write_down_ID => """*Bitte kopieren oder notieren Sie sich die oben gezeigte ID.""";
  @override
  String get confirm => """Bestätigen""";
  @override
  String get confirm_sending => """Senden bestätigen""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """Transaktion absenden
Betrag: ${amount}
Gebühr: ${fee}""";
  @override
  String get sending => """Senden""";
  @override
  String get transaction_sent => """Transaktion gesendet!""";
  @override
  String get expired => """Abgelaufen""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """XMR senden""";
  @override
  String get exchange_new_template => """Neue Vorlage""";
  @override
  String get faq => """Häufig gestellte Fragen""";
  @override
  String get enter_your_pin => """PIN eingeben""";
  @override
  String get loading_your_wallet => """Wallet wird geladen""";
  @override
  String get new_wallet => """Neue Wallet""";
  @override
  String get wallet_name => """Walletname""";
  @override
  String get continue_text => """Weiter""";
  @override
  String get choose_wallet_currency => """Bitte wählen Sie die Währung der Wallet:""";
  @override
  String get node_new => """Neuer Knoten""";
  @override
  String get node_address => """Knotenadresse""";
  @override
  String get node_port => """Knotenport""";
  @override
  String get login => """Einloggen""";
  @override
  String get password => """Passwort""";
  @override
  String get nodes => """Knoten""";
  @override
  String get node_reset_settings_title => """Einstellungen zurücksetzen""";
  @override
  String get nodes_list_reset_to_default_message => """Möchten Sie wirklich die Standardeinstellungen wiederherstellen?""";
  @override
  String change_current_node(String node) => """Möchten Sie den aktuellen Knoten wirklich zu ${node}? ändern?""";
  @override
  String get change => """Ändern""";
  @override
  String get remove_node => """Knoten entfernen""";
  @override
  String get remove_node_message => """Möchten Sie den ausgewählten Knoten wirklich entfernen?""";
  @override
  String get remove => """Entfernen""";
  @override
  String get delete => """Löschen""";
  @override
  String get add_new_node => """Neuen Knoten hinzufügen""";
  @override
  String get change_current_node_title => """Aktuellen Knoten ändern""";
  @override
  String get node_test => """Test""";
  @override
  String get node_connection_successful => """Die Verbindung war erfolgreich""";
  @override
  String get node_connection_failed => """Verbindung fehlgeschlagen""";
  @override
  String get new_node_testing => """Neuen Knoten testen""";
  @override
  String get use => """Wechsel zu """;
  @override
  String get digit_pin => """-stellige PIN""";
  @override
  String get share_address => """Adresse teilen """;
  @override
  String get receive_amount => """Betrag""";
  @override
  String get subaddresses => """Unteradressen""";
  @override
  String get addresses => """Adressen""";
  @override
  String get scan_qr_code => """Scannen Sie den QR-Code, um die Adresse zu erhalten""";
  @override
  String get rename => """Umbenennen""";
  @override
  String get choose_account => """Konto auswählen""";
  @override
  String get create_new_account => """Neues Konto erstellen""";
  @override
  String get accounts_subaddresses => """Konten und Unteradressen""";
  @override
  String get restore_restore_wallet => """Wallet wiederherstellen""";
  @override
  String get restore_title_from_seed_keys => """Aus Seed/Schlüssel wiederherstellen""";
  @override
  String get restore_description_from_seed_keys => """Stellen Sie Ihr Wallet aus Seed/Schlüsseln wieder her, die Sie sicher aufbewahrt haben""";
  @override
  String get restore_next => """Weiter""";
  @override
  String get restore_title_from_backup => """Aus einer Sicherungsdatei wiederherstellen""";
  @override
  String get restore_description_from_backup => """Sie können die gesamte Cake Wallet-App aus Ihrer Sicherungsdatei wiederherstellen""";
  @override
  String get restore_seed_keys_restore => """Seed/Schlüssel wiederherstellen""";
  @override
  String get restore_title_from_seed => """Aus Seed wiederherstellen""";
  @override
  String get restore_description_from_seed => """Stellen Sie Ihre Wallet aus den 25 Wörtern oder dem 13-Wort-Kombinationscode wieder her""";
  @override
  String get restore_title_from_keys => """Aus Schlüsseln wiederherstellen""";
  @override
  String get restore_description_from_keys => """Stellen Sie Ihr Wallet aus generierten Tastenanschlägen her, die von Ihren privaten Schlüsseln gespeichert wurden""";
  @override
  String get restore_wallet_name => """Walletname""";
  @override
  String get restore_address => """Adresse""";
  @override
  String get restore_view_key_private => """View Key (geheim)""";
  @override
  String get restore_spend_key_private => """Spend Key (geheim)""";
  @override
  String get restore_recover => """Wiederherstellen""";
  @override
  String get restore_wallet_restore_description => """Beschreibung zur Wallet-Wiederherstellung""";
  @override
  String get restore_new_seed => """Neuer Seed""";
  @override
  String get restore_active_seed => """Aktiver Seed""";
  @override
  String get restore_bitcoin_description_from_seed => """Stellen Sie Ihre Brieftasche aus dem 24-Wort-Kombinationscode wieder her""";
  @override
  String get restore_bitcoin_description_from_keys => """Stellen Sie Ihre Brieftasche aus der generierten WIF-Zeichenfolge aus Ihren privaten Schlüsseln wieder her""";
  @override
  String get restore_bitcoin_title_from_keys => """Aus WIF wiederherstellen""";
  @override
  String get restore_from_date_or_blockheight => """Bitte geben Sie ein Datum ein, das einige Tage vor dem Erstellen dieser Brieftasche liegt. Oder wenn Sie die Blockhöhe kennen, geben Sie stattdessen diese ein""";
  @override
  String get seed_reminder => """Bitte notieren Sie diese für den Fall, dass Sie Ihr Telefon verlieren oder es kaputtgeht""";
  @override
  String get seed_title => """Seed""";
  @override
  String get seed_share => """Seed teilen""";
  @override
  String get copy => """Kopieren""";
  @override
  String get seed_language_choose => """Bitte wählen Sie die Sprache des Seeds:""";
  @override
  String get seed_choose => """Seed-Sprache auswählen""";
  @override
  String get seed_language_next => """Weiter""";
  @override
  String get seed_language_english => """Englisch""";
  @override
  String get seed_language_chinese => """Chinesisch""";
  @override
  String get seed_language_dutch => """Niederländisch""";
  @override
  String get seed_language_german => """Deutsch""";
  @override
  String get seed_language_japanese => """Japanisch""";
  @override
  String get seed_language_portuguese => """Portugiesisch""";
  @override
  String get seed_language_russian => """Russisch""";
  @override
  String get seed_language_spanish => """Spanisch""";
  @override
  String get send_title => """Senden""";
  @override
  String get send_your_wallet => """Ihre Wallet""";
  @override
  String send_address(String cryptoCurrency) => """${cryptoCurrency}-Adresse""";
  @override
  String get send_payment_id => """Zahlungs-ID (optional)""";
  @override
  String get all => """ALLES""";
  @override
  String get send_error_minimum_value => """Der Mindestbetrag ist 0,01""";
  @override
  String get send_error_currency => """Die Währung darf nur Zahlen enthalten""";
  @override
  String get send_estimated_fee => """Geschätzte Gebühr:""";
  @override
  String send_priority(String transactionPriority) => """Derzeit ist ${transactionPriority} als Gebührenpriorität eingestellt.
Die Transaktionspriorität kann in den Einstellungen angepasst werden""";
  @override
  String get send_creating_transaction => """Erstelle Transaktion""";
  @override
  String get send_templates => """Vorlagen""";
  @override
  String get send_new => """Neu""";
  @override
  String get send_amount => """Betrag:""";
  @override
  String get send_fee => """Gebühr:""";
  @override
  String get send_name => """Name""";
  @override
  String get send_got_it => """Verstanden""";
  @override
  String get send_sending => """Senden...""";
  @override
  String send_success(String crypto) => """Ihr ${crypto} wurde erfolgreich versendet""";
  @override
  String get settings_title => """Einstellungen""";
  @override
  String get settings_nodes => """Knoten""";
  @override
  String get settings_current_node => """Aktueller Knoten""";
  @override
  String get settings_wallets => """Wallets""";
  @override
  String get settings_display_balance_as => """Kontostand anzeigen in""";
  @override
  String get settings_currency => """Währung""";
  @override
  String get settings_fee_priority => """Gebührenpriorität""";
  @override
  String get settings_save_recipient_address => """Empfängeradresse speichern""";
  @override
  String get settings_personal => """Persönlich""";
  @override
  String get settings_change_pin => """PIN ändern""";
  @override
  String get settings_change_language => """Sprache ändern""";
  @override
  String get settings_allow_biometrical_authentication => """Biometrische Authentifizierung zulassen""";
  @override
  String get settings_dark_mode => """Dunkler Modus""";
  @override
  String get settings_transactions => """Transaktionen""";
  @override
  String get settings_trades => """Handel""";
  @override
  String get settings_display_on_dashboard_list => """Anzeige in der Dashboard-Liste""";
  @override
  String get settings_all => """ALLE""";
  @override
  String get settings_only_trades => """Nur Handel""";
  @override
  String get settings_only_transactions => """Nur Transaktionen""";
  @override
  String get settings_none => """Keiner""";
  @override
  String get settings_support => """Unterstützen""";
  @override
  String get settings_terms_and_conditions => """Geschäftsbedingungen""";
  @override
  String get pin_is_incorrect => """PIN ist falsch""";
  @override
  String get setup_pin => """PIN einrichten""";
  @override
  String get enter_your_pin_again => """Geben Sie Ihre PIN erneut ein""";
  @override
  String get setup_successful => """Ihre PIN wurde erfolgreich eingerichtet!""";
  @override
  String get wallet_keys => """Wallet-Seed/-Schlüssel""";
  @override
  String get wallet_seed => """Wallet-Seed""";
  @override
  String get private_key => """Privater Schlüssel""";
  @override
  String get public_key => """Öffentlicher Schlüssel""";
  @override
  String get view_key_private => """View Key (geheim)""";
  @override
  String get view_key_public => """View Key (öffentlich)""";
  @override
  String get spend_key_private => """Spend Key (geheim)""";
  @override
  String get spend_key_public => """Spend Key (öffentlich)""";
  @override
  String copied_key_to_clipboard(String key) => """${key} in Zwischenablage kopiert""";
  @override
  String get new_subaddress_title => """Neue Adresse""";
  @override
  String get new_subaddress_label_name => """Bezeichnung""";
  @override
  String get new_subaddress_create => """Erstellen""";
  @override
  String get subaddress_title => """Unteradressenliste""";
  @override
  String get trade_details_title => """Handelsdetails""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """Status""";
  @override
  String get trade_details_fetching => """Wird ermittelt""";
  @override
  String get trade_details_provider => """Anbieter""";
  @override
  String get trade_details_created_at => """Erzeugt am""";
  @override
  String get trade_details_pair => """Paar""";
  @override
  String trade_details_copied(String title) => """${title} in die Zwischenablage kopiert""";
  @override
  String get trade_history_title => """Handelsverlauf""";
  @override
  String get transaction_details_title => """Transaktionsdetails""";
  @override
  String get transaction_details_transaction_id => """Transaktions-ID""";
  @override
  String get transaction_details_date => """Datum""";
  @override
  String get transaction_details_height => """Höhe""";
  @override
  String get transaction_details_amount => """Betrag""";
  @override
  String get transaction_details_fee => """Gebühr""";
  @override
  String transaction_details_copied(String title) => """${title} in die Zwischenablage kopiert""";
  @override
  String get transaction_details_recipient_address => """Empfängeradresse""";
  @override
  String get wallet_list_title => """Monero-Wallet""";
  @override
  String get wallet_list_create_new_wallet => """Neue Wallet erstellen""";
  @override
  String get wallet_list_restore_wallet => """Wallet wiederherstellen""";
  @override
  String get wallet_list_load_wallet => """Wallet laden""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """Wallet ${wallet_name} wird geladen""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """Laden der Wallet ${wallet_name} fehlgeschlagen. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """Wallet ${wallet_name} wird entfernt""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """Fehler beim Entfernen der Wallet ${wallet_name}. ${error}""";
  @override
  String get widgets_address => """Adresse""";
  @override
  String get widgets_restore_from_blockheight => """Ab Blockhöhe wiederherstellen""";
  @override
  String get widgets_restore_from_date => """Ab Datum wiederherstellen""";
  @override
  String get widgets_or => """oder""";
  @override
  String get widgets_seed => """Seed""";
  @override
  String router_no_route(String name) => """Keine Route definiert für ${name}""";
  @override
  String get error_text_account_name => """Der Kontoname darf nur Buchstaben und Zahlen enthalten
und muss zwischen 1 und 15 Zeichen lang sein""";
  @override
  String get error_text_contact_name => """Kontaktname darf nicht die Zeichen ` , ' " enthalten
und muss zwischen 1 und 32 Zeichen lang sein""";
  @override
  String get error_text_address => """Die Walletadresse muss dem Typ der Kryptowährung
entsprechen""";
  @override
  String get error_text_node_address => """Bitte geben Sie eine iPv4-Adresse ein""";
  @override
  String get error_text_node_port => """Der Knotenport darf nur Nummern zwischen 0 und 65535 enthalten""";
  @override
  String get error_text_payment_id => """Die Zahlungs-ID darf nur 16 bis 64 hexadezimale Zeichen enthalten""";
  @override
  String get error_text_xmr => """Der XMR-Wert darf das verfügbare Guthaben nicht überschreiten.
Die Anzahl der Nachkommastellen muss kleiner oder gleich 12 sein""";
  @override
  String get error_text_fiat => """Der Wert des Betrags darf den verfügbaren Kontostand nicht überschreiten.
Die Anzahl der Nachkommastellen muss kleiner oder gleich 2 sein""";
  @override
  String get error_text_subaddress_name => """Der Name der Unteradresse darf nicht die Zeichen ` , ' " enthalten
und muss zwischen 1 und 20 Zeichen lang sein""";
  @override
  String get error_text_amount => """Betrag darf nur Zahlen enthalten""";
  @override
  String get error_text_wallet_name => """Der Walletname darf nur Buchstaben und Zahlen enthalten
und muss zwischen 1 und 15 Zeichen lang sein""";
  @override
  String get error_text_keys => """Walletschlüssel können nur 64 hexadezimale Zeichen enthalten""";
  @override
  String get error_text_crypto_currency => """Die Anzahl der Nachkommastellen
muss kleiner oder gleich 12 sein.""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """Handel für ${provider} wird nicht erstellt. Menge ist unter dem Minimum: ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """Handel für ${provider} wird nicht erstellt. Menge ist über dem Maximum: ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """Handel für ${provider} wird nicht erstellt. Das Laden der Limits ist fehlgeschlagen""";
  @override
  String get error_text_template => """Vorlagenname und Adresse dürfen nicht die Zeichen ` , ' " enthalten
und müssen zwischen 1 und 106 Zeichen lang sein""";
  @override
  String get auth_store_ban_timeout => """ban_timeout""";
  @override
  String get auth_store_banned_for => """Gebannt für """;
  @override
  String get auth_store_banned_minutes => """ Minuten""";
  @override
  String get auth_store_incorrect_password => """Falsche PIN""";
  @override
  String get wallet_store_monero_wallet => """Monero-Wallet""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """Falsche Seed-Länge""";
  @override
  String get full_balance => """Gesamtguthaben""";
  @override
  String get available_balance => """Verfügbares Guthaben""";
  @override
  String get hidden_balance => """Verstecktes Guthaben""";
  @override
  String get sync_status_syncronizing => """SYNCHRONISIERE""";
  @override
  String get sync_status_syncronized => """SYNCHRONISIERT""";
  @override
  String get sync_status_not_connected => """NICHT VERBUNDEN""";
  @override
  String get sync_status_starting_sync => """STARTE SYNCHRONISIERUNG""";
  @override
  String get sync_status_failed_connect => """GETRENNT""";
  @override
  String get sync_status_connecting => """VERBINDEN""";
  @override
  String get sync_status_connected => """VERBUNDEN""";
  @override
  String get transaction_priority_slow => """Langsam""";
  @override
  String get transaction_priority_regular => """Normal""";
  @override
  String get transaction_priority_medium => """Mittel""";
  @override
  String get transaction_priority_fast => """Schnell""";
  @override
  String get transaction_priority_fastest => """Am schnellsten""";
  @override
  String trade_for_not_created(String title) => """Handel für ${title} wird nicht erstellt.""";
  @override
  String get trade_not_created => """Handel nicht erstellt.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """Handel ${tradeId} von ${title} nicht gefunden.""";
  @override
  String get trade_not_found => """Handel nicht gefunden.""";
  @override
  String get trade_state_pending => """Steht aus""";
  @override
  String get trade_state_confirming => """Bestätigung""";
  @override
  String get trade_state_trading => """Handel""";
  @override
  String get trade_state_traded => """Gehandelt""";
  @override
  String get trade_state_complete => """Abgeschlossen""";
  @override
  String get trade_state_to_be_created => """Noch nicht erstellt""";
  @override
  String get trade_state_unpaid => """Unbezahlt""";
  @override
  String get trade_state_underpaid => """Unterbezahlt""";
  @override
  String get trade_state_paid_unconfirmed => """Unbestätigt bezahlt""";
  @override
  String get trade_state_paid => """Bezahlt""";
  @override
  String get trade_state_btc_sent => """Btc gesendet""";
  @override
  String get trade_state_timeout => """Timeout""";
  @override
  String get trade_state_created => """Erstellt""";
  @override
  String get trade_state_finished => """Fertig""";
  @override
  String get change_language => """Sprache ändern""";
  @override
  String change_language_to(String language) => """Sprache zu ${language} ändern?""";
  @override
  String get paste => """Einfügen""";
  @override
  String get restore_from_seed_placeholder => """Seed bitte hier eingeben oder einfügen""";
  @override
  String get add_new_word => """Neues Wort hinzufügen""";
  @override
  String get incorrect_seed => """Der eingegebene Text ist ungültig.""";
  @override
  String get biometric_auth_reason => """Scannen Sie Ihren Fingerabdruck zur Authentifizierung""";
  @override
  String version(String currentVersion) => """Version ${currentVersion}""";
  @override
  String get openalias_alert_title => """XMR-Empfänger erkannt""";
  @override
  String openalias_alert_content(String recipient_name) => """Sie senden Geld an
${recipient_name}""";
  @override
  String get card_address => """Adresse:""";
  @override
  String get buy => """Kaufen""";
  @override
  String get placeholder_transactions => """Ihre Transaktionen werden hier angezeigt""";
  @override
  String get placeholder_contacts => """Ihre Kontakte werden hier angezeigt""";
  @override
  String get template => """Vorlage""";
  @override
  String get confirm_delete_template => """Diese Aktion löscht diese Vorlage. Möchten Sie fortfahren?""";
  @override
  String get confirm_delete_wallet => """Diese Aktion löscht diese Wallet. Möchten Sie fortfahren?""";
  @override
  String get picker_description => """Um ChangeNOW oder MorphToken zu wählen, ändern Sie bitte zuerst Ihr Handelspaar""";
  @override
  String get change_wallet_alert_title => """Aktuelle Wallet ändern""";
  @override
  String change_wallet_alert_content(String wallet_name) => """Möchten Sie die aktuelle Wallet zu ${wallet_name} ändern?""";
  @override
  String get creating_new_wallet => """Neue Wallet erstellen""";
  @override
  String creating_new_wallet_error(String description) => """Fehler: ${description}""";
  @override
  String get seed_alert_title => """Achtung""";
  @override
  String get seed_alert_content => """Der Seed ist der einzige Weg, Ihre Wallet wiederherzustellen. Haben Sie ihn aufgeschrieben?""";
  @override
  String get seed_alert_back => """Zurückgehen""";
  @override
  String get seed_alert_yes => """Ja, habe ich""";
  @override
  String get wallet_name_alert_content => """Brieftasche mit dem gleichen Namen ist vorhanden""";
  @override
  String get exchange_sync_alert_content => """Bitte warten Sie, bis Ihre Wallet synchronisiert ist""";
  @override
  String get pre_seed_title => """WICHTIG""";
  @override
  String pre_seed_description(String words) => """Auf der nächsten Seite sehen Sie eine Reihe von ${words} Wörtern. Dies ist Ihr einzigartiger und privater Seed und der EINZIGE Weg, um Ihre Wallet im Falle eines Verlusts oder einer Fehlfunktion wiederherzustellen. Es liegt in IHRER Verantwortung, ihn aufzuschreiben und an einem sicheren Ort außerhalb der Cake Wallet-App aufzubewahren.""";
  @override
  String get pre_seed_button_text => """Verstanden. Zeig mir meinen Seed""";
  @override
  String get xmr_to_error => """XMR.TO-Fehler""";
  @override
  String get xmr_to_error_description => """Ungültiger Betrag. Höchstgrenze 8 Stellen nach dem Dezimalpunkt""";
  @override
  String provider_error(String provider) => """${provider}-Fehler""";
  @override
  String get use_ssl => """SSL verwenden""";
  @override
  String get color_theme => """Farbthema""";
  @override
  String get light_theme => """Hell""";
  @override
  String get bright_theme => """Strahlend hell""";
  @override
  String get dark_theme => """Dunkel""";
  @override
  String get enter_your_note => """Geben Sie Ihre Bemerkung ein…""";
  @override
  String get note_optional => """Bemerkung (optional)""";
  @override
  String get note_tap_to_change => """Bemerkung (zum Ändern tippen)""";
  @override
  String get transaction_key => """Transaktionsschlüssel""";
  @override
  String get confirmations => """Bestätigungen""";
  @override
  String get recipient_address => """Empfängeradresse""";
  @override
  String get extra_id => """Extra ID:""";
  @override
  String get destination_tag => """Ziel-Tag:""";
  @override
  String get memo => """Memo:""";
  @override
  String get backup => """Sicherung""";
  @override
  String get change_password => """Passwort ändern""";
  @override
  String get backup_password => """Passwort sichern""";
  @override
  String get write_down_backup_password => """Bitte notieren Sie sich Ihr Sicherungskennwort, das für den Import Ihrer Sicherungsdateien gebraucht wird.""";
  @override
  String get export_backup => """Sicherung exportieren""";
  @override
  String get save_backup_password => """Bitte stellen Sie sicher, dass Sie Ihr Sicherungskennwort gespeichert haben. Ohne dieses können Sie Ihre Sicherungsdateien nicht importieren.""";
  @override
  String get backup_file => """Sicherungsdatei""";
  @override
  String get edit_backup_password => """Sicherungskennwort bearbeiten""";
  @override
  String get save_backup_password_alert => """Sicherungskennwort speichern""";
  @override
  String get change_backup_password_alert => """Ihre vorherigen Sicherungsdateien können nicht mit einem neuen Sicherungskennwort importiert werden. Das neue Sicherungskennwort wird nur für neue Sicherungsdateien verwendet. Sind Sie sicher, dass Sie das Sicherungskennwort ändern möchten?""";
  @override
  String get enter_backup_password => """Sicherungskennwort hier eingeben""";
  @override
  String get select_backup_file => """Sicherungsdatei auswählen""";
  @override
  String get import => """Importieren""";
  @override
  String get please_select_backup_file => """Bitte wählen Sie die Sicherungsdatei und geben Sie das Sicherungskennwort ein.""";
  @override
  String get fixed_rate => """Feste Rate""";
  @override
  String get fixed_rate_alert => """Sie können den Empfangsbetrag eingeben, wenn der Festratenmodus aktiviert ist. Möchten Sie in den Festratenmodus wechseln?""";
  @override
  String get xlm_extra_info => """Bitte vergessen Sie nicht, die Memo-ID anzugeben, während Sie die XLM-Transaktion für den Austausch senden""";
  @override
  String get xrp_extra_info => """Bitte vergessen Sie nicht, das Ziel-Tag anzugeben, während Sie die XRP-Transaktion für den Austausch senden""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Wenn Sie XMR von Ihrem Cake Wallet Monero-Guthaben umtauschen möchten, wechseln Sie bitte zuerst zu Ihrer Monero-Wallet.""";
  @override
  String get confirmed => """Bestätigt""";
  @override
  String get unconfirmed => """Unbestätigt""";
  @override
  String get displayable => """Anzeigebar""";
  @override
  String get submit_request => """Eine Anfrage stellen""";
  @override
  String get buy_alert_content => """Derzeit unterstützen wir nur den Kauf von Bitcoin und Litecoin. Um Bitcoin oder Litecoin zu kaufen, erstellen oder wechseln Sie bitte zu Ihrem Bitcoin- oder Litecoin-Wallet.""";
  @override
  String get outdated_electrum_wallet_description => """Neue Bitcoin-Wallets, die in Cake erstellt wurden, haben jetzt einen 24-Wort-Seed. Sie müssen eine neue Bitcoin-Wallet erstellen, Ihr gesamtes Geld in die neue 24-Wort-Wallet überweisen und keine Wallet mit einem 12-Wort-Seed mehr verwenden. Bitte tun Sie dies sofort, um Ihr Geld zu sichern.""";
  @override
  String get understand => """Ich verstehe""";
  @override
  String get apk_update => """APK-Update""";
  @override
  String get buy_bitcoin => """Bitcoin kaufen""";
  @override
  String get buy_with => """Kaufen mit""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """Der Wert des Betrags muss größer oder gleich ${minAmount} ${fiatCurrency} sein""";
  @override
  String get outdated_electrum_wallet_receive_warning => """Wenn diese Brieftasche einen 12-Wort-Seed hat und in Cake erstellt wurde, zahlen Sie KEINE Bitcoins in diese Brieftasche ein. Alle auf diese Wallet übertragenen BTC können verloren gehen. Erstellen Sie eine neue 24-Wort-Wallet (tippen Sie auf das Menü oben rechts, wählen Sie Wallets, wählen Sie Neue Wallet erstellen und dann Bitcoin) und verschieben Sie Ihre BTC SOFORT dorthin. Neue (24-Wort-)BTC-Wallets von Cake sind sicher""";
  @override
  String get do_not_show_me => """Zeig mir das nicht noch einmal""";
  @override
  String get unspent_coins_title => """Nicht ausgegebene Münzen""";
  @override
  String get unspent_coins_details_title => """Details zu nicht ausgegebenen Münzen""";
  @override
  String get freeze => """Einfrieren""";
  @override
  String get coin_control => """Münzkontrolle (optional)""";
  @override
  String get address_detected => """Adresse erkannt""";
  @override
  String address_from_domain(String domain) => """Sie haben die Adresse von der unaufhaltsamen Domain ${domain} erhalten""";
}

class $it extends S {
  const $it();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """Benvenuto""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """Fantastico portafoglio per Monero e Bitcoin""";
  @override
  String get please_make_selection => """Gentilmente seleziona se vuoi generare o recuperare il tuo portafoglio.""";
  @override
  String get create_new => """Genera nuovo Portafoglio""";
  @override
  String get restore_wallet => """Recupera Portafoglio""";
  @override
  String get accounts => """Accounts""";
  @override
  String get edit => """Modifica""";
  @override
  String get account => """Account""";
  @override
  String get add => """Aggiungi""";
  @override
  String get address_book => """Rubrica indirizzi""";
  @override
  String get contact => """Contatta""";
  @override
  String get please_select => """Gentilmente seleziona:""";
  @override
  String get cancel => """Cancella""";
  @override
  String get ok => """OK""";
  @override
  String get contact_name => """Nome Contatto""";
  @override
  String get reset => """Resetta""";
  @override
  String get save => """Salva""";
  @override
  String get address_remove_contact => """Rimuovi contatto""";
  @override
  String get address_remove_content => """Sei sicuro di voler eliminare il contatto selezionato?""";
  @override
  String get authenticated => """Autenticato""";
  @override
  String get authentication => """Autenticazione""";
  @override
  String failed_authentication(String state_error) => """Autenticazione fallita. ${state_error}""";
  @override
  String get wallet_menu => """Menu""";
  @override
  String Blocks_remaining(String status) => """${status} Blocchi Rimanenti""";
  @override
  String get please_try_to_connect_to_another_node => """Gentilmente prova a connetterti ad un altro nodo""";
  @override
  String get xmr_hidden => """Nascosto""";
  @override
  String get xmr_available_balance => """Saldo Disponibile""";
  @override
  String get xmr_full_balance => """Saldo Completo""";
  @override
  String get send => """Invia""";
  @override
  String get receive => """Ricevi""";
  @override
  String get transactions => """Transazioni""";
  @override
  String get incoming => """In arrivo""";
  @override
  String get outgoing => """In uscita""";
  @override
  String get transactions_by_date => """Transazioni per data""";
  @override
  String get trades => """Scambi""";
  @override
  String get filters => """Filtri""";
  @override
  String get today => """Oggi""";
  @override
  String get yesterday => """Ieri""";
  @override
  String get received => """Ricevuto""";
  @override
  String get sent => """Inviato""";
  @override
  String get pending => """ (pendente)""";
  @override
  String get rescan => """Scansiona di nuovo""";
  @override
  String get reconnect => """Riconnetti""";
  @override
  String get wallets => """Portafogli""";
  @override
  String get show_seed => """Mostra seme""";
  @override
  String get show_keys => """Mostra seme/chiavi""";
  @override
  String get address_book_menu => """Rubrica indirizzi""";
  @override
  String get reconnection => """Riconnessione""";
  @override
  String get reconnect_alert_text => """Sei sicuro di volerti riconnettere?""";
  @override
  String get exchange => """Scambia""";
  @override
  String get clear => """Pulisci""";
  @override
  String get refund_address => """Indirizzo di rimborso""";
  @override
  String get change_exchange_provider => """Cambia Exchange""";
  @override
  String get you_will_send => """Conveti da""";
  @override
  String get you_will_get => """Converti a""";
  @override
  String get amount_is_guaranteed => """L'ammonare da ricevere è fissato""";
  @override
  String get amount_is_estimate => """L'ammontare da ricevere è una stima""";
  @override
  String powered_by(String title) => """Sviluppato da ${title}""";
  @override
  String get error => """Errore""";
  @override
  String get estimated => """Stimato""";
  @override
  String min_value(String value, String currency) => """Min: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """Max: ${value} ${currency}""";
  @override
  String get change_currency => """Cambia Moneta""";
  @override
  String get copy_id => """Copia ID""";
  @override
  String get exchange_result_write_down_trade_id => """Gentilmente fai una copia o trascrivi l'ID dello scambio per continuare.""";
  @override
  String get trade_id => """ID Scambio:""";
  @override
  String get copied_to_clipboard => """Copiato negli Appunti""";
  @override
  String get saved_the_trade_id => """Ho salvato l'ID dello scambio""";
  @override
  String get fetching => """Recupero""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """Ammontare: """;
  @override
  String get payment_id => """ID Pagamento: """;
  @override
  String get status => """Stato: """;
  @override
  String get offer_expires_in => """Offerta termina tra: """;
  @override
  String trade_is_powered_by(String provider) => """Questo scambio è fornito da ${provider}""";
  @override
  String get copy_address => """Copia Indirizzo""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """Cliccando su Conferma, invierai ${fetchingLabel} ${from} dal tuo portafoglio chiamato ${walletName} all'indirizzo mostrato qui in basso. O puoi inviare dal tuo portafoglio esterno all'indirizzo/codice QR mostrato in basso.

Gentilmente clicca su Conferma per continuare o torna indietro per cambiare l'ammontare.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """Devi inviare un minimo di ${fetchingLabel} ${from} all'indirizzo mostrato nella pagina seguente. Se invii un ammontare inferiore a ${fetchingLabel} ${from} la conversione potrebbe non andare a buon fine e l'indirizzo potrebbe non essere rimborsato.""";
  @override
  String get exchange_result_write_down_ID => """*Gentilmente fai una copia o trascrivi il tuo ID mostrato in alto.""";
  @override
  String get confirm => """Conferma""";
  @override
  String get confirm_sending => """Conferma l'invio""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """Invia transazione
Ammontare: ${amount}
Commissione: ${fee}""";
  @override
  String get sending => """Invio""";
  @override
  String get transaction_sent => """Transazione inviata!""";
  @override
  String get expired => """Scaduta""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """Invia XMR""";
  @override
  String get exchange_new_template => """Nuovo modello""";
  @override
  String get faq => """Domande Frequenti""";
  @override
  String get enter_your_pin => """Inserisci il tuo PIN""";
  @override
  String get loading_your_wallet => """Caricamento portafoglio""";
  @override
  String get new_wallet => """Nuovo Portafoglio""";
  @override
  String get wallet_name => """Nome del Portafoglio""";
  @override
  String get continue_text => """Continua""";
  @override
  String get choose_wallet_currency => """Gentilmente scegli la moneta del portafoglio:""";
  @override
  String get node_new => """Nuovo Nodo""";
  @override
  String get node_address => """Indirizzo Nodo""";
  @override
  String get node_port => """Porta Nodo""";
  @override
  String get login => """Accedi""";
  @override
  String get password => """Password""";
  @override
  String get nodes => """Nodi""";
  @override
  String get node_reset_settings_title => """Ripristina impostazioni""";
  @override
  String get nodes_list_reset_to_default_message => """Sei sicuro di voler ripristinare le impostazioni predefinite?""";
  @override
  String change_current_node(String node) => """Sei sicuro di voler cambiare il nodo corrente con ${node}?""";
  @override
  String get change => """Cambia""";
  @override
  String get remove_node => """Rimuovi nodo""";
  @override
  String get remove_node_message => """Sei sicuro di voler rimuovere il nodo selezionato?""";
  @override
  String get remove => """Remuovi""";
  @override
  String get delete => """Elimina""";
  @override
  String get add_new_node => """Aggiungi nuovo nodo""";
  @override
  String get change_current_node_title => """Cambia nodo corrente""";
  @override
  String get node_test => """Test""";
  @override
  String get node_connection_successful => """Connessione avvenuta con successo""";
  @override
  String get node_connection_failed => """Connessione fallita""";
  @override
  String get new_node_testing => """Test novo nodo""";
  @override
  String get use => """Passa a """;
  @override
  String get digit_pin => """-cifre PIN""";
  @override
  String get share_address => """Condividi indirizzo""";
  @override
  String get receive_amount => """Ammontare""";
  @override
  String get subaddresses => """Sottoindirizzi""";
  @override
  String get addresses => """Indirizzi""";
  @override
  String get scan_qr_code => """Scansiona il codice QR per ottenere l'indirizzo""";
  @override
  String get rename => """Rinomina""";
  @override
  String get choose_account => """Scegli account""";
  @override
  String get create_new_account => """Crea nuovo account""";
  @override
  String get accounts_subaddresses => """Accounts e sottoindirizzi""";
  @override
  String get restore_restore_wallet => """Recupera Portafoglio""";
  @override
  String get restore_title_from_seed_keys => """Recupera dal seme/chiavi""";
  @override
  String get restore_description_from_seed_keys => """Recupera il tuo portafoglio dal seme/chiavi che hai salvato in un posto sicuro""";
  @override
  String get restore_next => """Prossimo""";
  @override
  String get restore_title_from_backup => """Recupera da backup""";
  @override
  String get restore_description_from_backup => """Puoi recuperare l'app Cake Wallet per intero dal tuo file di backup""";
  @override
  String get restore_seed_keys_restore => """Recupera Seme/Chiavi""";
  @override
  String get restore_title_from_seed => """Recupera dal seme""";
  @override
  String get restore_description_from_seed => """Recupera il tuo portafoglio da una combinazione di 25 o 13 parole""";
  @override
  String get restore_title_from_keys => """Recupera dalle chiavi""";
  @override
  String get restore_description_from_keys => """Recupera il tuo portafoglio da una sequenza di caratteri generati dalle tue chiavi private""";
  @override
  String get restore_wallet_name => """Nome Portafoglio""";
  @override
  String get restore_address => """Indirizzo""";
  @override
  String get restore_view_key_private => """Chiave di Visualizzazione (privata)""";
  @override
  String get restore_spend_key_private => """Chiave di Spesa (privata)""";
  @override
  String get restore_recover => """Recupera""";
  @override
  String get restore_wallet_restore_description => """Descrizione recupero Portafoglio""";
  @override
  String get restore_new_seed => """Nuovo seme""";
  @override
  String get restore_active_seed => """Seme attivo""";
  @override
  String get restore_bitcoin_description_from_seed => """Recupera il tuo portafoglio da una combinazione di 12 parole""";
  @override
  String get restore_bitcoin_description_from_keys => """Recupera il tuo portafoglio da una stringa WIF generata dalle tue chiavi private""";
  @override
  String get restore_bitcoin_title_from_keys => """Recupera da WIF""";
  @override
  String get restore_from_date_or_blockheight => """Gentilmente inserisci la data di un paio di giorni prima che hai creato questo portafoglio. Oppure inserisci l'altezza del blocco se la conosci""";
  @override
  String get seed_reminder => """Gentilmente trascrivi le parole. Ti tornerà utie in caso perdessi o ripristinassi il tuo telefono""";
  @override
  String get seed_title => """Seme""";
  @override
  String get seed_share => """Condividi seme""";
  @override
  String get copy => """Copia""";
  @override
  String get seed_language_choose => """Gentilmente scegli la lingua del seme:""";
  @override
  String get seed_choose => """Scegli la lingua del seme""";
  @override
  String get seed_language_next => """Prossimo""";
  @override
  String get seed_language_english => """Inglese""";
  @override
  String get seed_language_chinese => """Cinese""";
  @override
  String get seed_language_dutch => """Olandese""";
  @override
  String get seed_language_german => """Tedesco""";
  @override
  String get seed_language_japanese => """Giapponese""";
  @override
  String get seed_language_portuguese => """Portoghese""";
  @override
  String get seed_language_russian => """Russo""";
  @override
  String get seed_language_spanish => """Spagnolo""";
  @override
  String get send_title => """Invia""";
  @override
  String get send_your_wallet => """Il tuo portafoglio""";
  @override
  String send_address(String cryptoCurrency) => """${cryptoCurrency} indirizzo""";
  @override
  String get send_payment_id => """ID Pagamento (opzionale)""";
  @override
  String get all => """TUTTO""";
  @override
  String get send_error_minimum_value => """L'ammontare minimo è 0.01""";
  @override
  String get send_error_currency => """L'ammontare può contenere solo numeri""";
  @override
  String get send_estimated_fee => """Commissione stimata:""";
  @override
  String send_priority(String transactionPriority) => """Attualmente la commissione è impostata a priorità ${transactionPriority} .
La priorità della transazione può essere modificata nelle impostazioni""";
  @override
  String get send_creating_transaction => """Creazione della transazione""";
  @override
  String get send_templates => """Modelli""";
  @override
  String get send_new => """Nuovo""";
  @override
  String get send_amount => """Ammontare:""";
  @override
  String get send_fee => """Commissione:""";
  @override
  String get send_name => """Nome""";
  @override
  String get send_got_it => """Ho capito""";
  @override
  String get send_sending => """Invio...""";
  @override
  String send_success(String crypto) => """ ${crypto} inviati con successo""";
  @override
  String get settings_title => """Impostazioni""";
  @override
  String get settings_nodes => """Nodi""";
  @override
  String get settings_current_node => """Nodo attuale""";
  @override
  String get settings_wallets => """Portafogli""";
  @override
  String get settings_display_balance_as => """Mostra saldo come""";
  @override
  String get settings_currency => """Moneta""";
  @override
  String get settings_fee_priority => """Priorità commissione""";
  @override
  String get settings_save_recipient_address => """Salva indirizzo di destinazione""";
  @override
  String get settings_personal => """Personali""";
  @override
  String get settings_change_pin => """Cambia PIN""";
  @override
  String get settings_change_language => """Cambia lingua""";
  @override
  String get settings_allow_biometrical_authentication => """Consenti autenticazione biometrica""";
  @override
  String get settings_dark_mode => """Tema scuro""";
  @override
  String get settings_transactions => """Transazioni""";
  @override
  String get settings_trades => """Scambi""";
  @override
  String get settings_display_on_dashboard_list => """Mostra nella lista della pagina principale""";
  @override
  String get settings_all => """TUTTO""";
  @override
  String get settings_only_trades => """Solo scambi""";
  @override
  String get settings_only_transactions => """Solo transazioni""";
  @override
  String get settings_none => """Nessuno""";
  @override
  String get settings_support => """Supporto""";
  @override
  String get settings_terms_and_conditions => """Termini e condizioni""";
  @override
  String get pin_is_incorrect => """Il PIN non è corretto""";
  @override
  String get setup_pin => """Imposta PIN""";
  @override
  String get enter_your_pin_again => """Inserisci il tuo pin di nuovo""";
  @override
  String get setup_successful => """Il tuo PIN è stato impostato con successo!""";
  @override
  String get wallet_keys => """Seme Portafoglio /chiavi""";
  @override
  String get wallet_seed => """Seme Portafoglio""";
  @override
  String get private_key => """Chiave privata""";
  @override
  String get public_key => """Chiave pubblica""";
  @override
  String get view_key_private => """Chiave di visualizzazione (privata)""";
  @override
  String get view_key_public => """Chiave di visualizzazione (pubblica)""";
  @override
  String get spend_key_private => """Chiave di spesa (privata)""";
  @override
  String get spend_key_public => """Chiave di spesa (pubblica)""";
  @override
  String copied_key_to_clipboard(String key) => """ ${key} copiata negli Appunti""";
  @override
  String get new_subaddress_title => """Nuovo indirizzo""";
  @override
  String get new_subaddress_label_name => """Nome etichetta""";
  @override
  String get new_subaddress_create => """Crea""";
  @override
  String get subaddress_title => """Lista sottoindirizzi""";
  @override
  String get trade_details_title => """Dettagli Scambio""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """Stato""";
  @override
  String get trade_details_fetching => """Recupero""";
  @override
  String get trade_details_provider => """Fornitore""";
  @override
  String get trade_details_created_at => """Creato alle""";
  @override
  String get trade_details_pair => """Coppia""";
  @override
  String trade_details_copied(String title) => """${title} copiati negli Appunti""";
  @override
  String get trade_history_title => """Storico scambi""";
  @override
  String get transaction_details_title => """Dettagli Transazione""";
  @override
  String get transaction_details_transaction_id => """ID Transazione""";
  @override
  String get transaction_details_date => """Data""";
  @override
  String get transaction_details_height => """Altezza""";
  @override
  String get transaction_details_amount => """Ammontare""";
  @override
  String get transaction_details_fee => """Commissione""";
  @override
  String transaction_details_copied(String title) => """${title} copiati negli Appunti""";
  @override
  String get transaction_details_recipient_address => """Indirizzo destinatario""";
  @override
  String get wallet_list_title => """Portafoglio Monero""";
  @override
  String get wallet_list_create_new_wallet => """Crea Nuovo Portafoglio""";
  @override
  String get wallet_list_restore_wallet => """Recupera Portafoglio""";
  @override
  String get wallet_list_load_wallet => """Caricamento Portafoglio""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """Caricamento portafoglio ${wallet_name}""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """Caricamento portafoglio ${wallet_name} fallito. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """Rimozione portafoglio ${wallet_name}""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """Rimozione portafoglio ${wallet_name} fallita. ${error}""";
  @override
  String get widgets_address => """Indirizzo""";
  @override
  String get widgets_restore_from_blockheight => """Recupera da altezza blocco""";
  @override
  String get widgets_restore_from_date => """Recupera da data""";
  @override
  String get widgets_or => """o""";
  @override
  String get widgets_seed => """Seme""";
  @override
  String router_no_route(String name) => """Nessun percorso definito per ${name}""";
  @override
  String get error_text_account_name => """Il nome dell'Account può contenere solo lettere, numeri
e deve avere una lunghezza compresa tra 1 e 15 caratteri""";
  @override
  String get error_text_contact_name => """Il nome del Contatto non può contenere i simboli ` , ' " 
e deve avere una lunghezza compresa tra 1 e 32 caratteri""";
  @override
  String get error_text_address => """L'indirizzo del Portafoglio deve corrispondere alla tipologia
di criptovaluta""";
  @override
  String get error_text_node_address => """Gentilmente inserisci un indirizzo iPv4""";
  @override
  String get error_text_node_port => """La porta del nodo può contenere solo numeri compresi tra 0 e 65535""";
  @override
  String get error_text_payment_id => """l'ID del pagamento può contenere solo da 16 a 64 caratteri in hex""";
  @override
  String get error_text_xmr => """Il valore XMR non può eccedere il saldo disponibile.
Il numero delle cifre decimali deve essere inferiore o uguale a 12""";
  @override
  String get error_text_fiat => """L'ammontare non può eccedere il saldo dispoinibile.
Il numero di cifre decimali deve essere inferiore o uguale a 2""";
  @override
  String get error_text_subaddress_name => """Il nome del sottoindirizzo non può contenere i simboli ` , ' " 
e deve avere una lunghezza compresa tra 1 e 20 caratteri""";
  @override
  String get error_text_amount => """L'ammontare può contenere solo numeri""";
  @override
  String get error_text_wallet_name => """Il nome del portafoglio può contenere solo lettere, numeri
e deve avere una lunghezza compresa tra 1 e 15 caratteri""";
  @override
  String get error_text_keys => """Le chiavi del portafoglio possono contenere solo 64 caratteri in hex""";
  @override
  String get error_text_crypto_currency => """Il numero delle cifre decimali
deve essere inferiore o uguale a 12""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """Lo scambio per ${provider} non è stato creato. L'ammontare è inferiore al minimo: ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """Lo scambio per ${provider} non è stato creato. L'ammontare è superiore al massimo: ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """Lo scambio per ${provider} non è stato creato. Caricamento dei limiti fallito""";
  @override
  String get error_text_template => """Il nome del modello e l'indirizzo non possono contenere i simboli ` , ' " 
e devono avere una lunghezza compresa tra 1 e 106 caratteri""";
  @override
  String get auth_store_ban_timeout => """ban_timeout""";
  @override
  String get auth_store_banned_for => """Bannato per """;
  @override
  String get auth_store_banned_minutes => """ minuti""";
  @override
  String get auth_store_incorrect_password => """PIN non corretto""";
  @override
  String get wallet_store_monero_wallet => """Portafoglio Monero""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """Lunghezza seme non corretta""";
  @override
  String get full_balance => """Saldo Completo""";
  @override
  String get available_balance => """Saldo Disponibile""";
  @override
  String get hidden_balance => """Saldo Nascosto""";
  @override
  String get sync_status_syncronizing => """SINCRONIZZAZIONE""";
  @override
  String get sync_status_syncronized => """SINCRONIZZATO""";
  @override
  String get sync_status_not_connected => """NON CONNESSO""";
  @override
  String get sync_status_starting_sync => """INIZIO SINC""";
  @override
  String get sync_status_failed_connect => """DISCONNESSO""";
  @override
  String get sync_status_connecting => """CONNESSIONE""";
  @override
  String get sync_status_connected => """CONNESSO""";
  @override
  String get transaction_priority_slow => """Bassa""";
  @override
  String get transaction_priority_regular => """Regolare""";
  @override
  String get transaction_priority_medium => """Media""";
  @override
  String get transaction_priority_fast => """Alta""";
  @override
  String get transaction_priority_fastest => """Massima""";
  @override
  String trade_for_not_created(String title) => """Lo scambio per ${title} non è stato creato.""";
  @override
  String get trade_not_created => """Scambio non creato.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """Scambio ${tradeId} di ${title} not trovato.""";
  @override
  String get trade_not_found => """Scambio non trovato.""";
  @override
  String get trade_state_pending => """In corso""";
  @override
  String get trade_state_confirming => """Conferma""";
  @override
  String get trade_state_trading => """Scambio""";
  @override
  String get trade_state_traded => """Scambiato""";
  @override
  String get trade_state_complete => """Completato""";
  @override
  String get trade_state_to_be_created => """Da creare""";
  @override
  String get trade_state_unpaid => """Non pagato""";
  @override
  String get trade_state_underpaid => """Sottopagato""";
  @override
  String get trade_state_paid_unconfirmed => """Pagato non confermato""";
  @override
  String get trade_state_paid => """Pagato""";
  @override
  String get trade_state_btc_sent => """Btc inviati""";
  @override
  String get trade_state_timeout => """Timeout""";
  @override
  String get trade_state_created => """Creato""";
  @override
  String get trade_state_finished => """Finito""";
  @override
  String get change_language => """Cambia lingua""";
  @override
  String change_language_to(String language) => """Cambia lingua in ${language}?""";
  @override
  String get paste => """Incolla""";
  @override
  String get restore_from_seed_placeholder => """Gentilmente inserisci o incolla il tuo seme qui""";
  @override
  String get add_new_word => """Aggiungi nuova parola""";
  @override
  String get incorrect_seed => """Il testo inserito non è valido.""";
  @override
  String get biometric_auth_reason => """Scansiona la tua impronta per autenticarti""";
  @override
  String version(String currentVersion) => """Versione ${currentVersion}""";
  @override
  String get openalias_alert_title => """XMR Destinatario Rilevato""";
  @override
  String openalias_alert_content(String recipient_name) => """Invierai i tuoi fondi a
${recipient_name}""";
  @override
  String get card_address => """Indirizzo:""";
  @override
  String get buy => """Compra""";
  @override
  String get placeholder_transactions => """Le tue transazioni saranno mostrate qui""";
  @override
  String get placeholder_contacts => """I tuoi contatti saranno mostrati qui""";
  @override
  String get template => """Modello""";
  @override
  String get confirm_delete_template => """Questa azione cancellerà questo modello. Desideri continuare?""";
  @override
  String get confirm_delete_wallet => """Questa azione cancellerà questo portafoglio. Desideri continuare?""";
  @override
  String get picker_description => """Per scegliere ChangeNOW  o MorphToken, gentilmente cambia prima la tua coppia di valute""";
  @override
  String get change_wallet_alert_title => """Cambia portafoglio attuale""";
  @override
  String change_wallet_alert_content(String wallet_name) => """Sei sicuro di voler cambiare il portafoglio attuale con ${wallet_name}?""";
  @override
  String get creating_new_wallet => """Creazione nuovo portafoglio""";
  @override
  String creating_new_wallet_error(String description) => """Errore: ${description}""";
  @override
  String get seed_alert_title => """Attenzione""";
  @override
  String get seed_alert_content => """Il seme è l'unico modo per recuperare il tuo portafoglio. L'hai trascritto?""";
  @override
  String get seed_alert_back => """Torna indietro""";
  @override
  String get seed_alert_yes => """Sì, l'ho fatto""";
  @override
  String get exchange_sync_alert_content => """Gentilmente aspetta che il tuo portafoglio sia sincronizzato""";
  @override
  String get pre_seed_title => """IMPORTANTE""";
  @override
  String pre_seed_description(String words) => """Nella pagina seguente ti sarà mostrata una serie di parole ${words}. Questo è il tuo seme unico e privato ed è l'UNICO modo per recuperare il tuo portafoglio in caso di perdita o malfunzionamento. E' TUA responsabilità trascriverlo e conservarlo in un posto sicuro fuori dall'app Cake Wallet.""";
  @override
  String get pre_seed_button_text => """Ho capito. Mostrami il seme""";
  @override
  String get xmr_to_error => """XMR.TO errore""";
  @override
  String get xmr_to_error_description => """Ammontare invalido. Il limite massimo è 8 cifre dopo il punto decimale""";
  @override
  String provider_error(String provider) => """${provider} errore""";
  @override
  String get use_ssl => """Usa SSL""";
  @override
  String get color_theme => """Colore tema""";
  @override
  String get light_theme => """Bianco""";
  @override
  String get bright_theme => """Colorato""";
  @override
  String get dark_theme => """Scuro""";
  @override
  String get enter_your_note => """Inserisci la tua nota…""";
  @override
  String get note_optional => """Nota (opzionale)""";
  @override
  String get note_tap_to_change => """Nota (clicca per cambiare)""";
  @override
  String get transaction_key => """Chiave Transazione""";
  @override
  String get confirmations => """Conferme""";
  @override
  String get recipient_address => """Indirizzo di destinazione""";
  @override
  String get extra_id => """Extra ID:""";
  @override
  String get destination_tag => """Tag destinazione:""";
  @override
  String get memo => """Memo:""";
  @override
  String get backup => """Backup""";
  @override
  String get change_password => """Cambia password""";
  @override
  String get backup_password => """Backup password""";
  @override
  String get write_down_backup_password => """Gentilmente trascrivi la password del backup, che è usata per importare i tuoi file di backup.""";
  @override
  String get export_backup => """Esporta backup""";
  @override
  String get save_backup_password => """Gentilmente assicurati di aver salvato la password del tuo backup.  Senza questa non sarai in grado di importare i tuoi file di backup.""";
  @override
  String get backup_file => """Backup file""";
  @override
  String get edit_backup_password => """Modifica Password Backup""";
  @override
  String get save_backup_password_alert => """Salva password Backup""";
  @override
  String get change_backup_password_alert => """I precedenti file di backup non potranno essere importati con la nuova password di backup. La nuova password di backup verrà usata soltanto per i nuovi file di backup. Sei sicuro di voler cambiare la tua password di backup?""";
  @override
  String get enter_backup_password => """Inserisci la password di backup qui""";
  @override
  String get select_backup_file => """Seleziona file di backup""";
  @override
  String get import => """Importa""";
  @override
  String get please_select_backup_file => """Gentilmente seleziona il file di backup e inserisci la password di backup.""";
  @override
  String get fixed_rate => """Tasso fisso""";
  @override
  String get fixed_rate_alert => """Potrai inserire l'ammontare da ricevere quando il tasso è fisso. Vuoi cambiare alla modalità tasso fisso?""";
  @override
  String get xlm_extra_info => """Gentilmente ricorda di indicare il Memo ID quando invii la transazione XLM per lo scambio""";
  @override
  String get xrp_extra_info => """Gentilmente ricorda di indicare il Tag di Destinazione quando invii una transazione XRP per lo scambio""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Se vuoi scambiare XMR dal tuo saldo Cake Wallet Monero, gentilmente passa al tuo portafoglio Monero.""";
  @override
  String get confirmed => """Confermato""";
  @override
  String get unconfirmed => """Non confermato""";
  @override
  String get displayable => """Visualizzabile""";
  @override
  String get submit_request => """invia una richiesta""";
  @override
  String get buy_alert_content => """Attualmente supportiamo solo l'acquisto di Bitcoin e Litecoin. Per acquistare Bitcoin o Litecoin, crea o passa al tuo portafoglio Bitcoin o Litecoin.""";
  @override
  String get outdated_electrum_wallet_description => """I nuovi portafogli Bitcoin creati in Cake ora hanno un seme di 24 parole. È obbligatorio creare un nuovo portafoglio Bitcoin e trasferire tutti i fondi nel nuovo portafoglio di 24 parole e smettere di usare portafogli con un seme di 12 parole. Ti preghiamo di farlo immediatamente per proteggere i tuoi fondi.""";
  @override
  String get understand => """Capisco""";
  @override
  String get apk_update => """Aggiornamento APK""";
  @override
  String get buy_bitcoin => """Acquista Bitcoin""";
  @override
  String get buy_with => """Acquista con""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """Il valore dell'importo deve essere maggiore o uguale a ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """Se questo portafoglio ha un seme di 12 parole ed è stato creato in Cake, NON depositare Bitcoin in questo portafoglio. Qualsiasi BTC trasferito su questo portafoglio potrebbe andare perso. Crea un nuovo portafoglio di 24 parole (tocca il menu in alto a destra, seleziona Portafogli, scegli Crea nuovo portafoglio, quindi seleziona Bitcoin) e sposta IMMEDIATAMENTE lì il tuo BTC. I nuovi portafogli BTC (24 parole) di Cake sono sicuri""";
  @override
  String get do_not_show_me => """Non mostrarmelo di nuovo""";
  @override
  String get unspent_coins_title => """Monete non spese""";
  @override
  String get unspent_coins_details_title => """Dettagli sulle monete non spese""";
  @override
  String get freeze => """Congelare""";
  @override
  String get coin_control => """Controllo monete (opzionale)""";
  @override
  String get address_detected => """Indirizzo rilevato""";
  @override
  String address_from_domain(String domain) => """Hai l'indirizzo da unstoppable domain ${domain}""";
}

class $es extends S {
  const $es();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """Bienvenido""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """Impresionante billetera para Monero y Bitcoin""";
  @override
  String get please_make_selection => """Seleccione a continuación para crear o recuperar su billetera.""";
  @override
  String get create_new => """Crear nueva billetera""";
  @override
  String get restore_wallet => """Restaurar billetera""";
  @override
  String get accounts => """Cuentas""";
  @override
  String get edit => """Editar""";
  @override
  String get account => """Cuenta""";
  @override
  String get add => """Añadir""";
  @override
  String get address_book => """Libreta de direcciones""";
  @override
  String get contact => """Contacto""";
  @override
  String get please_select => """Por favor seleccione:""";
  @override
  String get cancel => """Cancelar""";
  @override
  String get ok => """OK""";
  @override
  String get contact_name => """Nombre de contacto""";
  @override
  String get reset => """Reiniciar""";
  @override
  String get save => """Salvar""";
  @override
  String get address_remove_contact => """Remover contacto""";
  @override
  String get address_remove_content => """¿Estás seguro de que quieres eliminar el contacto seleccionado?""";
  @override
  String get authenticated => """Autenticados""";
  @override
  String get authentication => """Autenticación""";
  @override
  String failed_authentication(String state_error) => """Autenticación fallida. ${state_error}""";
  @override
  String get wallet_menu => """Menú de billetera""";
  @override
  String Blocks_remaining(String status) => """${status} Bloques restantes""";
  @override
  String get please_try_to_connect_to_another_node => """Intenta conectarte a otro nodo""";
  @override
  String get xmr_hidden => """Oculto""";
  @override
  String get xmr_available_balance => """Saldo disponible""";
  @override
  String get xmr_full_balance => """Balance total""";
  @override
  String get send => """Enviar""";
  @override
  String get receive => """Recibir""";
  @override
  String get transactions => """Actas""";
  @override
  String get incoming => """Entrante""";
  @override
  String get outgoing => """Saliente""";
  @override
  String get transactions_by_date => """Transacciones por fecha""";
  @override
  String get trades => """Cambios""";
  @override
  String get filters => """Filtrar""";
  @override
  String get today => """Hoy""";
  @override
  String get yesterday => """Ayer""";
  @override
  String get received => """Recibido""";
  @override
  String get sent => """Expedido""";
  @override
  String get pending => """ (pendiente)""";
  @override
  String get rescan => """Reescanear""";
  @override
  String get reconnect => """Volver a conectar""";
  @override
  String get wallets => """Carteras""";
  @override
  String get show_seed => """Mostrar semilla""";
  @override
  String get show_keys => """Mostrar semilla/claves""";
  @override
  String get address_book_menu => """Libreta de direcciones""";
  @override
  String get reconnection => """Reconexión""";
  @override
  String get reconnect_alert_text => """¿Estás seguro de reconectar?""";
  @override
  String get exchange => """Intercambiar""";
  @override
  String get clear => """Claro""";
  @override
  String get refund_address => """Dirección de reembolso""";
  @override
  String get change_exchange_provider => """Cambiar proveedor de intercambio""";
  @override
  String get you_will_send => """Convertir de""";
  @override
  String get you_will_get => """Convertir a""";
  @override
  String get amount_is_guaranteed => """La cantidad recibida está garantizada""";
  @override
  String get amount_is_estimate => """El monto recibido es un estimado""";
  @override
  String powered_by(String title) => """Energizado por ${title}""";
  @override
  String get error => """Error""";
  @override
  String get estimated => """Estimado""";
  @override
  String min_value(String value, String currency) => """Min: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """Max: ${value} ${currency}""";
  @override
  String get change_currency => """Cambiar moneda""";
  @override
  String get copy_id => """Copiar ID""";
  @override
  String get exchange_result_write_down_trade_id => """Por favor, copia o escribe el ID.""";
  @override
  String get trade_id => """Comercial ID:""";
  @override
  String get copied_to_clipboard => """Copiado al portapapeles""";
  @override
  String get saved_the_trade_id => """He salvado comercial ID""";
  @override
  String get fetching => """Cargando""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """Cantidad: """;
  @override
  String get payment_id => """ID de pago: """;
  @override
  String get status => """Estado: """;
  @override
  String get offer_expires_in => """Oferta expira en: """;
  @override
  String trade_is_powered_by(String provider) => """Este comercio es impulsado por ${provider}""";
  @override
  String get copy_address => """Copiar dirección """;
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """Al presionar confirmar, enviará ${fetchingLabel} ${from} desde su billetera llamada ${walletName} a la dirección que se muestra a continuación. O puede enviar desde su billetera externa a la siguiente dirección / código QR anterior.

Presione confirmar para continuar o regrese para cambiar los montos.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """Debe enviar un mínimo de ${fetchingLabel} ${from} a la dirección que se muestra en la página siguiente. Si envía una cantidad inferior a ${fetchingLabel} ${from}, es posible que no se convierta y no se reembolse.""";
  @override
  String get exchange_result_write_down_ID => """*Copie o escriba su identificación que se muestra arriba.""";
  @override
  String get confirm => """Confirmar""";
  @override
  String get confirm_sending => """Confirmar envío""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """Confirmar transacción
Cantidad: ${amount}
Cuota: ${fee}""";
  @override
  String get sending => """Enviando""";
  @override
  String get transaction_sent => """Transacción enviada!""";
  @override
  String get expired => """Muerto""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """Enviar XMR""";
  @override
  String get exchange_new_template => """Nueva plantilla""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """Introduce tu PIN""";
  @override
  String get loading_your_wallet => """Cargando tu billetera""";
  @override
  String get new_wallet => """Nueva billetera""";
  @override
  String get wallet_name => """Nombre de la billetera""";
  @override
  String get continue_text => """Continuar""";
  @override
  String get choose_wallet_currency => """Por favor, elija la moneda de la billetera:""";
  @override
  String get node_new => """Nuevo nodo""";
  @override
  String get node_address => """Dirección de nodo""";
  @override
  String get node_port => """Puerto de nodo""";
  @override
  String get login => """Iniciar sesión""";
  @override
  String get password => """Contraseña""";
  @override
  String get nodes => """Nodos""";
  @override
  String get node_reset_settings_title => """Reiniciar ajustes""";
  @override
  String get nodes_list_reset_to_default_message => """¿Está seguro de que desea restablecer la configuración predeterminada?""";
  @override
  String change_current_node(String node) => """¿Está seguro de cambiar el nodo actual a ${node}?""";
  @override
  String get change => """Cambio""";
  @override
  String get remove_node => """Eliminar nodo""";
  @override
  String get remove_node_message => """¿Está seguro de que desea eliminar el nodo seleccionado?""";
  @override
  String get remove => """Retirar""";
  @override
  String get delete => """Borrar""";
  @override
  String get add_new_node => """Agregar nuevo nodo""";
  @override
  String get change_current_node_title => """Cambiar el nodo actual""";
  @override
  String get node_test => """Prueba""";
  @override
  String get node_connection_successful => """La conexión fue exitosa""";
  @override
  String get node_connection_failed => """La conexión falló""";
  @override
  String get new_node_testing => """Prueba de nuevos nodos""";
  @override
  String get use => """Utilizar a """;
  @override
  String get digit_pin => """-dígito PIN""";
  @override
  String get share_address => """Compartir dirección""";
  @override
  String get receive_amount => """Cantidad""";
  @override
  String get subaddresses => """Subdirecciones""";
  @override
  String get addresses => """Direcciones""";
  @override
  String get scan_qr_code => """Escanee el código QR para obtener la dirección""";
  @override
  String get rename => """Rebautizar""";
  @override
  String get choose_account => """Elegir cuenta""";
  @override
  String get create_new_account => """Crear una nueva cuenta""";
  @override
  String get accounts_subaddresses => """Cuentas y subdirecciones""";
  @override
  String get restore_restore_wallet => """Recuperar Cartera""";
  @override
  String get restore_title_from_seed_keys => """Restaurar desde semilla/claves""";
  @override
  String get restore_description_from_seed_keys => """Recupere su billetera de las semillas/claves que ha guardado en un lugar seguro""";
  @override
  String get restore_next => """Próximo""";
  @override
  String get restore_title_from_backup => """Restaurar desde un archivo de respaldo""";
  @override
  String get restore_description_from_backup => """Puede restaurar toda la aplicación Cake Wallet desde ysu archivo de respaldo""";
  @override
  String get restore_seed_keys_restore => """Restauración de semillas / llaves""";
  @override
  String get restore_title_from_seed => """De la semilla""";
  @override
  String get restore_description_from_seed => """Restaure su billetera desde el código de combinación de 25 palabras i de 13 palabras""";
  @override
  String get restore_title_from_keys => """De las claves""";
  @override
  String get restore_description_from_keys => """Restaure su billetera de las pulsaciones de teclas generadas guardadas de sus claves privadas""";
  @override
  String get restore_wallet_name => """Nombre de la billetera""";
  @override
  String get restore_address => """Dirección""";
  @override
  String get restore_view_key_private => """View clave (privado)""";
  @override
  String get restore_spend_key_private => """Spend clave (privado)""";
  @override
  String get restore_recover => """Recuperar""";
  @override
  String get restore_wallet_restore_description => """Restaurar billetera""";
  @override
  String get restore_new_seed => """Nueva semilla""";
  @override
  String get restore_active_seed => """Semilla activa""";
  @override
  String get restore_bitcoin_description_from_seed => """Restaure su billetera a partir del código de combinación de 24 palabras""";
  @override
  String get restore_bitcoin_description_from_keys => """Restaure su billetera a partir de una cadena WIF generada a partir de sus claves privadas""";
  @override
  String get restore_bitcoin_title_from_keys => """Restaurar desde WIF""";
  @override
  String get restore_from_date_or_blockheight => """Ingrese una fecha unos días antes de crear esta billetera. O si conoce la altura del bloque, ingréselo en su lugar""";
  @override
  String get seed_reminder => """Anótelos en caso de que pierda o borre su teléfono""";
  @override
  String get seed_title => """Semilla""";
  @override
  String get seed_share => """Compartir semillas""";
  @override
  String get copy => """Dupdo""";
  @override
  String get seed_language_choose => """Por favor elija el idioma semilla:""";
  @override
  String get seed_choose => """Elige el idioma semilla""";
  @override
  String get seed_language_next => """Próximo""";
  @override
  String get seed_language_english => """Inglés""";
  @override
  String get seed_language_chinese => """Chino""";
  @override
  String get seed_language_dutch => """Holandés""";
  @override
  String get seed_language_german => """Alemán""";
  @override
  String get seed_language_japanese => """Japonés""";
  @override
  String get seed_language_portuguese => """Portugués""";
  @override
  String get seed_language_russian => """Ruso""";
  @override
  String get seed_language_spanish => """Español""";
  @override
  String get send_title => """Enviar""";
  @override
  String get send_your_wallet => """Tu billetera""";
  @override
  String send_address(String cryptoCurrency) => """Dirección de ${cryptoCurrency}""";
  @override
  String get send_payment_id => """ID de pago (opcional)""";
  @override
  String get all => """TODOS""";
  @override
  String get send_error_minimum_value => """El valor mínimo de la cantidad es 0.01""";
  @override
  String get send_error_currency => """La moneda solo puede contener números""";
  @override
  String get send_estimated_fee => """Tarifa estimada:""";
  @override
  String send_priority(String transactionPriority) => """Actualmente la tarifa se establece en ${transactionPriority} prioridad.
La prioridad de la transacción se puede ajustar en la configuración""";
  @override
  String get send_creating_transaction => """Creando transacción""";
  @override
  String get send_templates => """Plantillas""";
  @override
  String get send_new => """Nuevo""";
  @override
  String get send_amount => """Cantidad:""";
  @override
  String get send_fee => """Cuota:""";
  @override
  String get send_name => """Nombre""";
  @override
  String get send_got_it => """Entendido""";
  @override
  String get send_sending => """Enviando...""";
  @override
  String send_success(String crypto) => """Su ${crypto} fue enviado con éxito""";
  @override
  String get settings_title => """Configuraciones""";
  @override
  String get settings_nodes => """Nodos""";
  @override
  String get settings_current_node => """Nodo actual""";
  @override
  String get settings_wallets => """Carteras""";
  @override
  String get settings_display_balance_as => """Mostrar saldo como""";
  @override
  String get settings_currency => """Moneda""";
  @override
  String get settings_fee_priority => """Prioridad de tasa""";
  @override
  String get settings_save_recipient_address => """Guardar dirección del destinatario""";
  @override
  String get settings_personal => """Personal""";
  @override
  String get settings_change_pin => """Cambiar PIN""";
  @override
  String get settings_change_language => """Cambiar idioma""";
  @override
  String get settings_allow_biometrical_authentication => """Permitir autenticación biométrica""";
  @override
  String get settings_dark_mode => """Modo oscuro""";
  @override
  String get settings_transactions => """Transacciones""";
  @override
  String get settings_trades => """Comercia""";
  @override
  String get settings_display_on_dashboard_list => """Mostrar en la lista del tablero""";
  @override
  String get settings_all => """TODOS""";
  @override
  String get settings_only_trades => """Solo comercia""";
  @override
  String get settings_only_transactions => """Solo transacciones""";
  @override
  String get settings_none => """Ninguno""";
  @override
  String get settings_support => """Apoyo""";
  @override
  String get settings_terms_and_conditions => """Términos y Condiciones""";
  @override
  String get pin_is_incorrect => """PIN es incorrecto""";
  @override
  String get setup_pin => """PIN de configuración""";
  @override
  String get enter_your_pin_again => """Ingrese su PIN nuevamente""";
  @override
  String get setup_successful => """Su PIN se ha configurado correctamente!""";
  @override
  String get wallet_keys => """Billetera semilla/claves""";
  @override
  String get wallet_seed => """Semilla de billetera""";
  @override
  String get private_key => """Clave privada""";
  @override
  String get public_key => """Clave pública""";
  @override
  String get view_key_private => """View clave (privado)""";
  @override
  String get view_key_public => """View clave (público)""";
  @override
  String get spend_key_private => """Spend clave (privado)""";
  @override
  String get spend_key_public => """Spend clave (público)""";
  @override
  String copied_key_to_clipboard(String key) => """Copiado ${key} al portapapeles""";
  @override
  String get new_subaddress_title => """Nueva direccion""";
  @override
  String get new_subaddress_label_name => """Nombre de etiqueta""";
  @override
  String get new_subaddress_create => """Crear""";
  @override
  String get subaddress_title => """Lista de subdirecciones""";
  @override
  String get trade_details_title => """Detalles comerciales""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """Estado""";
  @override
  String get trade_details_fetching => """Cargando""";
  @override
  String get trade_details_provider => """Proveedor""";
  @override
  String get trade_details_created_at => """Creado en""";
  @override
  String get trade_details_pair => """Par""";
  @override
  String trade_details_copied(String title) => """${title} Copiado al portapapeles""";
  @override
  String get trade_history_title => """Historia del comercio""";
  @override
  String get transaction_details_title => """Detalles de la transacción""";
  @override
  String get transaction_details_transaction_id => """ID de transacción""";
  @override
  String get transaction_details_date => """Fecha""";
  @override
  String get transaction_details_height => """Altura""";
  @override
  String get transaction_details_amount => """Cantidad""";
  @override
  String get transaction_details_fee => """Cuota""";
  @override
  String transaction_details_copied(String title) => """${title} Copiado al portapapeles""";
  @override
  String get transaction_details_recipient_address => """Dirección del receptor""";
  @override
  String get wallet_list_title => """Monedero Monero""";
  @override
  String get wallet_list_create_new_wallet => """Crear nueva billetera""";
  @override
  String get wallet_list_restore_wallet => """Restaurar billetera""";
  @override
  String get wallet_list_load_wallet => """Billetera de carga""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """Billetera ${wallet_name} de carga""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """No se pudo cargar  ${wallet_name} la billetera. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """Retirar ${wallet_name} billetera""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """Error al elimina ${wallet_name} billetera. ${error}""";
  @override
  String get widgets_address => """Dirección""";
  @override
  String get widgets_restore_from_blockheight => """Restaurar desde blockheight""";
  @override
  String get widgets_restore_from_date => """Restaurar desde fecha""";
  @override
  String get widgets_or => """o""";
  @override
  String get widgets_seed => """Semilla""";
  @override
  String router_no_route(String name) => """No hay ruta definida para ${name}""";
  @override
  String get error_text_account_name => """El nombre de la cuenta solo puede contener letras, números 
y debe tener entre 1 y 15 caracteres de longitud""";
  @override
  String get error_text_contact_name => """El nombre del contacto no puede contener símbolos `, '" 
y debe tener entre 1 y 32 caracteres de longitud""";
  @override
  String get error_text_address => """La dirección de la billetera debe corresponder al tipo 
de criptomoneda""";
  @override
  String get error_text_node_address => """Por favor, introduzca una dirección iPv4""";
  @override
  String get error_text_node_port => """El puerto de nodo solo puede contener números entre 0 y 65535""";
  @override
  String get error_text_payment_id => """La ID de pago solo puede contener de 16 a 64 caracteres en hexadecimal""";
  @override
  String get error_text_xmr => """El valor XMR no puede exceder el saldo disponible.
TEl número de dígitos de fracción debe ser menor o igual a 12""";
  @override
  String get error_text_fiat => """El valor de la cantidad no puede exceder el saldo disponible.
El número de dígitos de fracción debe ser menor o igual a 2""";
  @override
  String get error_text_subaddress_name => """El nombre de la subdirección no puede contener símbolos `, '" 
y debe tener entre 1 y 20 caracteres de longitud""";
  @override
  String get error_text_amount => """La cantidad solo puede contener números""";
  @override
  String get error_text_wallet_name => """El nombre de la billetera solo puede contener letras, números 
y debe tener entre 1 y 20 caracteres de longitud""";
  @override
  String get error_text_keys => """Las llaves de billetera solo pueden contener 64 caracteres en hexadecimal""";
  @override
  String get error_text_crypto_currency => """El número de dígitos fraccionarios 
debe ser menor o igual a 12""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """El comercio por ${provider} no se crea. La cantidad es menos que mínima: ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """El comercio por ${provider} no se crea. La cantidad es más que el máximo: ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """El comercio por ${provider} no se crea. Límites de carga fallidos""";
  @override
  String get error_text_template => """El nombre y la dirección de la plantilla no pueden contener símbolos ` , '" 
y debe tener entre 1 y 106 caracteres de longitud""";
  @override
  String get auth_store_ban_timeout => """prohibición de tiempo de espera""";
  @override
  String get auth_store_banned_for => """Prohibido para """;
  @override
  String get auth_store_banned_minutes => """ minutos""";
  @override
  String get auth_store_incorrect_password => """Contraseña PIN""";
  @override
  String get wallet_store_monero_wallet => """Monedero Monero""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """Longitud de semilla incorrecta""";
  @override
  String get full_balance => """Balance completo""";
  @override
  String get available_balance => """Balance disponible""";
  @override
  String get hidden_balance => """Balance oculto""";
  @override
  String get sync_status_syncronizing => """SINCRONIZANDO""";
  @override
  String get sync_status_syncronized => """SINCRONIZADO""";
  @override
  String get sync_status_not_connected => """NO CONECTADO""";
  @override
  String get sync_status_starting_sync => """EMPEZANDO A SINCRONIZAR""";
  @override
  String get sync_status_failed_connect => """DESCONECTADO""";
  @override
  String get sync_status_connecting => """CONECTANDO""";
  @override
  String get sync_status_connected => """CONECTADO""";
  @override
  String get transaction_priority_slow => """Lento""";
  @override
  String get transaction_priority_regular => """Regular""";
  @override
  String get transaction_priority_medium => """Medio""";
  @override
  String get transaction_priority_fast => """Rápido""";
  @override
  String get transaction_priority_fastest => """Lo más rápido""";
  @override
  String trade_for_not_created(String title) => """Comercio por ${title} no se crea.""";
  @override
  String get trade_not_created => """Comercio no se crea.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """Comercio ${tradeId} de ${title} no encontrado.""";
  @override
  String get trade_not_found => """Comercio no encontrado.""";
  @override
  String get trade_state_pending => """Pendiente""";
  @override
  String get trade_state_confirming => """Confirmando""";
  @override
  String get trade_state_trading => """Comercio""";
  @override
  String get trade_state_traded => """Negociado""";
  @override
  String get trade_state_complete => """Completar""";
  @override
  String get trade_state_to_be_created => """Ser creado""";
  @override
  String get trade_state_unpaid => """No pagado""";
  @override
  String get trade_state_underpaid => """Poco pagado""";
  @override
  String get trade_state_paid_unconfirmed => """Pagado sin confirmar""";
  @override
  String get trade_state_paid => """Pagado""";
  @override
  String get trade_state_btc_sent => """Btc expedido""";
  @override
  String get trade_state_timeout => """Se acabó el tiempo""";
  @override
  String get trade_state_created => """Creado""";
  @override
  String get trade_state_finished => """Terminado""";
  @override
  String get change_language => """Cambiar idioma""";
  @override
  String change_language_to(String language) => """Cambiar el idioma a ${language}?""";
  @override
  String get paste => """Pegar""";
  @override
  String get restore_from_seed_placeholder => """Ingrese o pegue su frase de código aquí""";
  @override
  String get add_new_word => """Agregar palabra nueva""";
  @override
  String get incorrect_seed => """El texto ingresado no es válido.""";
  @override
  String get biometric_auth_reason => """Escanee su huella digital para autenticar""";
  @override
  String version(String currentVersion) => """Versión ${currentVersion}""";
  @override
  String get openalias_alert_title => """Destinatario XMR detectado""";
  @override
  String openalias_alert_content(String recipient_name) => """Enviará fondos a
${recipient_name}""";
  @override
  String get card_address => """Dirección:""";
  @override
  String get buy => """Comprar""";
  @override
  String get placeholder_transactions => """Sus transacciones se mostrarán aquí""";
  @override
  String get placeholder_contacts => """Tus contactos se mostrarán aquí""";
  @override
  String get template => """Plantilla""";
  @override
  String get confirm_delete_template => """Esta acción eliminará esta plantilla. ¿Desea continuar?""";
  @override
  String get confirm_delete_wallet => """Esta acción eliminará esta billetera. ¿Desea continuar?""";
  @override
  String get picker_description => """Para elegir ChangeNOW o MorphToken, primero cambie su par comercial""";
  @override
  String get change_wallet_alert_title => """Cambiar billetera actual""";
  @override
  String change_wallet_alert_content(String wallet_name) => """¿Quieres cambiar la billetera actual a ${wallet_name}?""";
  @override
  String get creating_new_wallet => """Creando nueva billetera""";
  @override
  String creating_new_wallet_error(String description) => """Error: ${description}""";
  @override
  String get seed_alert_title => """Atención""";
  @override
  String get seed_alert_content => """La semilla es la única forma de recuperar su billetera. ¿Lo has escrito?""";
  @override
  String get seed_alert_back => """Regresa""";
  @override
  String get seed_alert_yes => """Sí tengo""";
  @override
  String get wallet_name_alert_content => """Existe una billetera con el mismo nombre""";
  @override
  String get exchange_sync_alert_content => """Espere hasta que su billetera esté sincronizada""";
  @override
  String get pre_seed_title => """IMPORTANTE""";
  @override
  String pre_seed_description(String words) => """En la página siguiente verá una serie de ${words} palabras. Esta es su semilla única y privada y es la ÚNICA forma de recuperar su billetera en caso de pérdida o mal funcionamiento. Es SU responsabilidad escribirlo y guardarlo en un lugar seguro fuera de la aplicación Cake Wallet.""";
  @override
  String get pre_seed_button_text => """Entiendo. Muéstrame mi semilla""";
  @override
  String get xmr_to_error => """Error de XMR.TO""";
  @override
  String get xmr_to_error_description => """Monto invalido. Límite máximo de 8 dígitos después del punto decimal""";
  @override
  String provider_error(String provider) => """${provider} error""";
  @override
  String get use_ssl => """Utilice SSL""";
  @override
  String get color_theme => """Tema de color""";
  @override
  String get light_theme => """Ligera""";
  @override
  String get bright_theme => """Brillante""";
  @override
  String get dark_theme => """Oscura""";
  @override
  String get enter_your_note => """Ingresa tu nota…""";
  @override
  String get note_optional => """Nota (opcional)""";
  @override
  String get note_tap_to_change => """Nota (toque para cambiar)""";
  @override
  String get transaction_key => """Clave de transacción""";
  @override
  String get confirmations => """Confirmaciones""";
  @override
  String get recipient_address => """Dirección del receptor""";
  @override
  String get extra_id => """ID adicional:""";
  @override
  String get destination_tag => """Etiqueta de destino:""";
  @override
  String get memo => """Memorándum:""";
  @override
  String get backup => """Apoyo""";
  @override
  String get change_password => """Cambia la contraseña""";
  @override
  String get backup_password => """Contraseña de respaldo""";
  @override
  String get write_down_backup_password => """Escriba su contraseña de respaldo, que se utiliza para la importación de sus archivos de respaldo.""";
  @override
  String get export_backup => """Exportar copia de seguridad""";
  @override
  String get save_backup_password => """Asegúrese de haber guardado su contraseña de respaldo. No podrá importar sus archivos de respaldo sin él.""";
  @override
  String get backup_file => """Archivo de respaldo""";
  @override
  String get edit_backup_password => """Editar contraseña de respaldo""";
  @override
  String get save_backup_password_alert => """Guardar contraseña de respaldo""";
  @override
  String get change_backup_password_alert => """Sus archivos de respaldo anteriores no estarán disponibles para importar con la nueva contraseña de respaldo. La nueva contraseña de respaldo se utilizará solo para los nuevos archivos de respaldo. ¿Está seguro de que desea cambiar la contraseña de respaldo?""";
  @override
  String get enter_backup_password => """Ingrese la contraseña de respaldo aquí""";
  @override
  String get select_backup_file => """Seleccionar archivo de respaldo""";
  @override
  String get import => """Importar""";
  @override
  String get please_select_backup_file => """Seleccione el archivo de respaldo e ingrese la contraseña de respaldo.""";
  @override
  String get fixed_rate => """Tipo de interés fijo""";
  @override
  String get fixed_rate_alert => """Podrá ingresar la cantidad recibida cuando el modo de tarifa fija esté marcado. ¿Quieres cambiar al modo de tarifa fija?""";
  @override
  String get xlm_extra_info => """No olvide especificar el ID de nota al enviar la transacción XLM para el intercambio""";
  @override
  String get xrp_extra_info => """No olvide especificar la etiqueta de destino al enviar la transacción XRP para el intercambio""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Si desea intercambiar XMR de su saldo de Cake Wallet Monero, primero cambie a su billetera Monero.""";
  @override
  String get confirmed => """Confirmada""";
  @override
  String get unconfirmed => """Inconfirmado""";
  @override
  String get displayable => """Visualizable""";
  @override
  String get submit_request => """presentar una solicitud""";
  @override
  String get buy_alert_content => """Actualmente solo apoyamos la compra de Bitcoin y Litecoin. Para comprar Bitcoin o Litecoin, cree o cambie a su billetera Bitcoin o Litecoin.""";
  @override
  String get outdated_electrum_wallet_description => """Las nuevas carteras de Bitcoin creadas en Cake ahora tienen una semilla de 24 palabras. Es obligatorio que cree una nueva billetera de Bitcoin y transfiera todos sus fondos a la nueva billetera de 24 palabras, y deje de usar billeteras con una semilla de 12 palabras. Haga esto de inmediato para asegurar sus fondos.""";
  @override
  String get understand => """Entiendo""";
  @override
  String get apk_update => """Actualización de APK""";
  @override
  String get buy_bitcoin => """Comprar Bitcoin""";
  @override
  String get buy_with => """Compra con""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """El valor de la cantidad debe ser mayor o igual a ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """Si esta billetera tiene una semilla de 12 palabras y se creó en Cake, NO deposite Bitcoin en esta billetera. Cualquier BTC transferido a esta billetera se puede perder. Cree una nueva billetera de 24 palabras (toque el menú en la parte superior derecha, seleccione Monederos, elija Crear nueva billetera, luego seleccione Bitcoin) e INMEDIATAMENTE mueva su BTC allí. Las nuevas carteras BTC (24 palabras) de Cake son seguras""";
  @override
  String get do_not_show_me => """no me muestres esto otra vez""";
  @override
  String get unspent_coins_title => """Monedas no gastadas""";
  @override
  String get unspent_coins_details_title => """Detalles de monedas no gastadas""";
  @override
  String get freeze => """Congelar""";
  @override
  String get coin_control => """Control de monedas (opcional)""";
  @override
  String get address_detected => """Dirección detectada""";
  @override
  String address_from_domain(String domain) => """Tienes la dirección de unstoppable domain ${domain}""";
}

class $ko extends S {
  const $ko();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """환영 에""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """Monero 및 Bitcoin을위한 멋진 지갑""";
  @override
  String get please_make_selection => """아래에서 선택하십시오 지갑 만들기 또는 복구.""";
  @override
  String get create_new => """새 월렛 만들기""";
  @override
  String get restore_wallet => """월렛 복원""";
  @override
  String get accounts => """계정""";
  @override
  String get edit => """편집하다""";
  @override
  String get account => """계정""";
  @override
  String get add => """더하다""";
  @override
  String get address_book => """주소록""";
  @override
  String get contact => """접촉""";
  @override
  String get please_select => """선택 해주세요:""";
  @override
  String get cancel => """취소""";
  @override
  String get ok => """승인""";
  @override
  String get contact_name => """담당자 이름""";
  @override
  String get reset => """다시 놓기""";
  @override
  String get save => """구하다""";
  @override
  String get address_remove_contact => """연락처 삭제""";
  @override
  String get address_remove_content => """선택한 연락처를 삭제 하시겠습니까?""";
  @override
  String get authenticated => """인증""";
  @override
  String get authentication => """입증""";
  @override
  String failed_authentication(String state_error) => """인증 실패. ${state_error}""";
  @override
  String get wallet_menu => """월렛 메뉴""";
  @override
  String Blocks_remaining(String status) => """${status} 남은 블록""";
  @override
  String get please_try_to_connect_to_another_node => """다른 노드에 연결을 시도하십시오""";
  @override
  String get xmr_hidden => """숨김""";
  @override
  String get xmr_available_balance => """사용 가능한 잔액""";
  @override
  String get xmr_full_balance => """풀 밸런스""";
  @override
  String get send => """보내다""";
  @override
  String get receive => """받다""";
  @override
  String get transactions => """업무""";
  @override
  String get incoming => """들어오는""";
  @override
  String get outgoing => """나가는""";
  @override
  String get transactions_by_date => """날짜 별 거래""";
  @override
  String get trades => """거래""";
  @override
  String get filters => """필터""";
  @override
  String get today => """오늘""";
  @override
  String get yesterday => """어제""";
  @override
  String get received => """받았습니다""";
  @override
  String get sent => """보냄""";
  @override
  String get pending => """ (보류 중)""";
  @override
  String get rescan => """재검색""";
  @override
  String get reconnect => """다시 연결""";
  @override
  String get wallets => """지갑""";
  @override
  String get show_seed => """종자 표시""";
  @override
  String get show_keys => """시드 / 키 표시""";
  @override
  String get address_book_menu => """주소록""";
  @override
  String get reconnection => """재 연결""";
  @override
  String get reconnect_alert_text => """다시 연결 하시겠습니까?""";
  @override
  String get exchange => """교환""";
  @override
  String get clear => """명확한""";
  @override
  String get refund_address => """환불 주소""";
  @override
  String get change_exchange_provider => """교환 공급자 변경""";
  @override
  String get you_will_send => """다음에서 변환""";
  @override
  String get you_will_get => """로 변환하다""";
  @override
  String get amount_is_guaranteed => """수령 금액이 보장됩니다.""";
  @override
  String get amount_is_estimate => """수신 금액은 견적입니다""";
  @override
  String powered_by(String title) => """에 의해 구동 ${title}""";
  @override
  String get error => """오류""";
  @override
  String get estimated => """예상""";
  @override
  String min_value(String value, String currency) => """최소: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """맥스: ${value} ${currency}""";
  @override
  String get change_currency => """통화 변경""";
  @override
  String get copy_id => """부 ID""";
  @override
  String get exchange_result_write_down_trade_id => """계속하려면 거래 ID를 복사하거나 적어 두십시오..""";
  @override
  String get trade_id => """무역 ID:""";
  @override
  String get copied_to_clipboard => """클립 보드에 복사""";
  @override
  String get saved_the_trade_id => """거래 ID를 저장했습니다""";
  @override
  String get fetching => """가져 오는 중""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """양: """;
  @override
  String get payment_id => """지불 ID: """;
  @override
  String get status => """지위: """;
  @override
  String get offer_expires_in => """쿠폰 만료일: """;
  @override
  String trade_is_powered_by(String provider) => """이 거래는 ${provider}""";
  @override
  String get copy_address => """주소 복사""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """확인을 누르면 전송됩니다 ${fetchingLabel} ${from} 지갑에서 ${walletName} 아래 주소로. 또는 외부 지갑에서 아래 주소로 보낼 수 있습니다 / QR 코드로 보낼 수 있습니다.

확인을 눌러 계속하거나 금액을 변경하려면 돌아가십시오.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """다음 페이지에 표시된 주소로 최소 ${fetchingLabel} ${from} 를 보내야합니다. ${fetchingLabel} ${from} 보다 적은 금액을 보내면 변환되지 않고 환불되지 않을 수 있습니다.""";
  @override
  String get exchange_result_write_down_ID => """*위에 표시된 ID를 복사하거나 적어 두십시오.""";
  @override
  String get confirm => """확인""";
  @override
  String get confirm_sending => """전송 확인""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """커밋 거래
양: ${amount}
보수: ${fee}""";
  @override
  String get sending => """배상""";
  @override
  String get transaction_sent => """거래가 전송되었습니다!""";
  @override
  String get expired => """만료""";
  @override
  String time(String minutes, String seconds) => """${minutes}m ${seconds}s""";
  @override
  String get send_xmr => """보내다 XMR""";
  @override
  String get exchange_new_template => """새 템플릿""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """PIN을 입력하십시오""";
  @override
  String get loading_your_wallet => """지갑 넣기""";
  @override
  String get new_wallet => """새 월렛""";
  @override
  String get wallet_name => """지갑 이름""";
  @override
  String get continue_text => """잇다""";
  @override
  String get choose_wallet_currency => """지갑 통화를 선택하십시오:""";
  @override
  String get node_new => """새로운 노드""";
  @override
  String get node_address => """노드 주소""";
  @override
  String get node_port => """노드 포트""";
  @override
  String get login => """로그인""";
  @override
  String get password => """암호""";
  @override
  String get nodes => """노드""";
  @override
  String get node_reset_settings_title => """설정 초기화""";
  @override
  String get nodes_list_reset_to_default_message => """설정을 기본값으로 재설정 하시겠습니까?""";
  @override
  String change_current_node(String node) => """현재 노드를 다음으로 변경 하시겠습니까 ${node}?""";
  @override
  String get change => """변화""";
  @override
  String get remove_node => """노드 제거""";
  @override
  String get remove_node_message => """선택한 노드를 제거 하시겠습니까?""";
  @override
  String get remove => """없애다""";
  @override
  String get delete => """지우다""";
  @override
  String get add_new_node => """새 노드 추가""";
  @override
  String get change_current_node_title => """현재 노드 변경""";
  @override
  String get node_test => """테스트""";
  @override
  String get node_connection_successful => """성공적으로 연결되었습니다.""";
  @override
  String get node_connection_failed => """연결 실패""";
  @override
  String get new_node_testing => """새로운 노드 테스트""";
  @override
  String get use => """사용하다 """;
  @override
  String get digit_pin => """숫자 PIN""";
  @override
  String get share_address => """주소 공유""";
  @override
  String get receive_amount => """양""";
  @override
  String get subaddresses => """하위 주소""";
  @override
  String get addresses => """구애""";
  @override
  String get scan_qr_code => """QR 코드를 스캔하여 주소를 얻습니다.""";
  @override
  String get rename => """이름 바꾸기""";
  @override
  String get choose_account => """계정을 선택하십시오""";
  @override
  String get create_new_account => """새 계정을 만들""";
  @override
  String get accounts_subaddresses => """계정 및 하위 주소""";
  @override
  String get restore_restore_wallet => """월렛 복원""";
  @override
  String get restore_title_from_seed_keys => """시드 / 키에서 복원""";
  @override
  String get restore_description_from_seed_keys => """안전한 장소에 저장 한 종자 / 키로 지갑을 되 찾으십시오.""";
  @override
  String get restore_next => """다음 것""";
  @override
  String get restore_title_from_backup => """백업 파일에서 복원""";
  @override
  String get restore_description_from_backup => """백업 파일에서 전체 Cake Wallet 앱을 복원 할 수 있습니다.""";
  @override
  String get restore_seed_keys_restore => """종자 / 키 복원""";
  @override
  String get restore_title_from_seed => """종자에서 복원""";
  @override
  String get restore_description_from_seed => """25 단어 또는 13 단어 조합 코드에서 지갑을 복원하십시오.""";
  @override
  String get restore_title_from_keys => """키에서 복원""";
  @override
  String get restore_description_from_keys => """개인 키에서 저장된 생성 된 키 스트로크에서 월렛 복원""";
  @override
  String get restore_wallet_name => """지갑 이름""";
  @override
  String get restore_address => """주소""";
  @override
  String get restore_view_key_private => """키보기 (은밀한)""";
  @override
  String get restore_spend_key_private => """지출 키 (은밀한)""";
  @override
  String get restore_recover => """다시 덮다""";
  @override
  String get restore_wallet_restore_description => """월렛 복원 설명""";
  @override
  String get restore_new_seed => """새로운 씨앗""";
  @override
  String get restore_active_seed => """활성 종자""";
  @override
  String get restore_bitcoin_description_from_seed => """24 단어 조합 코드에서 지갑 복원""";
  @override
  String get restore_bitcoin_description_from_keys => """개인 키에서 생성 된 WIF 문자열에서 지갑 복원""";
  @override
  String get restore_bitcoin_title_from_keys => """WIF에서 복원""";
  @override
  String get restore_from_date_or_blockheight => """이 지갑을 생성하기 며칠 전에 날짜를 입력하십시오. 또는 블록 높이를 알고있는 경우 대신 입력하십시오.""";
  @override
  String get seed_reminder => """휴대 전화를 분실하거나 닦을 경우를 대비해 적어 두세요.""";
  @override
  String get seed_title => """씨""";
  @override
  String get seed_share => """시드 공유""";
  @override
  String get copy => """부""";
  @override
  String get seed_language_choose => """종자 언어를 선택하십시오:""";
  @override
  String get seed_choose => """시드 언어를 선택하십시오""";
  @override
  String get seed_language_next => """다음 것""";
  @override
  String get seed_language_english => """영어""";
  @override
  String get seed_language_chinese => """중국말""";
  @override
  String get seed_language_dutch => """네덜란드 사람""";
  @override
  String get seed_language_german => """독일 사람""";
  @override
  String get seed_language_japanese => """일본어""";
  @override
  String get seed_language_portuguese => """포르투갈 인""";
  @override
  String get seed_language_russian => """러시아인""";
  @override
  String get seed_language_spanish => """스페인의""";
  @override
  String get send_title => """보내다""";
  @override
  String get send_your_wallet => """지갑""";
  @override
  String send_address(String cryptoCurrency) => """${cryptoCurrency} 주소""";
  @override
  String get send_payment_id => """지불 ID (optional)""";
  @override
  String get all => """모든""";
  @override
  String get send_error_minimum_value => """금액의 최소값은 0.01입니다""";
  @override
  String get send_error_currency => """통화는 숫자 만 포함 할 수 있습니다""";
  @override
  String get send_estimated_fee => """예상 수수료:""";
  @override
  String send_priority(String transactionPriority) => """현재 수수료는 ${transactionPriority} 우선 순위.
거래 우선 순위는 설정에서 조정할 수 있습니다""";
  @override
  String get send_creating_transaction => """거래 생성""";
  @override
  String get send_templates => """템플릿""";
  @override
  String get send_new => """새로운""";
  @override
  String get send_amount => """양:""";
  @override
  String get send_fee => """회비:""";
  @override
  String get send_name => """이름""";
  @override
  String get send_got_it => """알았다""";
  @override
  String get send_sending => """배상...""";
  @override
  String send_success(String crypto) => """${crypto}가 성공적으로 전송되었습니다""";
  @override
  String get settings_title => """설정""";
  @override
  String get settings_nodes => """노드""";
  @override
  String get settings_current_node => """현재 노드""";
  @override
  String get settings_wallets => """지갑""";
  @override
  String get settings_display_balance_as => """잔액 표시""";
  @override
  String get settings_currency => """통화""";
  @override
  String get settings_fee_priority => """수수료 우선""";
  @override
  String get settings_save_recipient_address => """수신자 주소 저장""";
  @override
  String get settings_personal => """개인적인""";
  @override
  String get settings_change_pin => """PIN 변경""";
  @override
  String get settings_change_language => """언어 변경""";
  @override
  String get settings_allow_biometrical_authentication => """생체 인증 허용""";
  @override
  String get settings_dark_mode => """다크 모드""";
  @override
  String get settings_transactions => """업무""";
  @override
  String get settings_trades => """거래""";
  @override
  String get settings_display_on_dashboard_list => """대시 보드 목록에 표시""";
  @override
  String get settings_all => """모든""";
  @override
  String get settings_only_trades => """거래 만""";
  @override
  String get settings_only_transactions => """거래 만""";
  @override
  String get settings_none => """없음""";
  @override
  String get settings_support => """지원하다""";
  @override
  String get settings_terms_and_conditions => """이용 약관""";
  @override
  String get pin_is_incorrect => """PIN이 잘못되었습니다""";
  @override
  String get setup_pin => """설정 PIN""";
  @override
  String get enter_your_pin_again => """다시 핀을 입력""";
  @override
  String get setup_successful => """PIN이 성공적으로 설정되었습니다!""";
  @override
  String get wallet_keys => """지갑 시드 / 키""";
  @override
  String get wallet_seed => """지갑 시드""";
  @override
  String get private_key => """개인 키""";
  @override
  String get public_key => """공개 키""";
  @override
  String get view_key_private => """키보기(은밀한)""";
  @override
  String get view_key_public => """키보기 (공공의)""";
  @override
  String get spend_key_private => """지출 키 (은밀한)""";
  @override
  String get spend_key_public => """지출 키 (공공의)""";
  @override
  String copied_key_to_clipboard(String key) => """복사 ${key} 클립 보드로""";
  @override
  String get new_subaddress_title => """새 주소""";
  @override
  String get new_subaddress_label_name => """라벨 이름""";
  @override
  String get new_subaddress_create => """몹시 떠들어 대다""";
  @override
  String get subaddress_title => """하위 주소 목록""";
  @override
  String get trade_details_title => """거래 세부 사항""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """상태""";
  @override
  String get trade_details_fetching => """가져 오는 중""";
  @override
  String get trade_details_provider => """공급자""";
  @override
  String get trade_details_created_at => """에 작성""";
  @override
  String get trade_details_pair => """쌍""";
  @override
  String trade_details_copied(String title) => """${title} 클립 보드에 복사""";
  @override
  String get trade_history_title => """무역 역사""";
  @override
  String get transaction_details_title => """상세 거래 내역""";
  @override
  String get transaction_details_transaction_id => """트랜잭션 ID""";
  @override
  String get transaction_details_date => """날짜""";
  @override
  String get transaction_details_height => """신장""";
  @override
  String get transaction_details_amount => """양""";
  @override
  String get transaction_details_fee => """회비""";
  @override
  String transaction_details_copied(String title) => """${title} 클립 보드에 복사""";
  @override
  String get transaction_details_recipient_address => """받는 사람 주소""";
  @override
  String get wallet_list_title => """모네로 월렛""";
  @override
  String get wallet_list_create_new_wallet => """새 월렛 만들기""";
  @override
  String get wallet_list_restore_wallet => """월렛 복원""";
  @override
  String get wallet_list_load_wallet => """지갑로드""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """로딩 ${wallet_name} 지갑""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """불러 오지 못했습니다 ${wallet_name} 지갑. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """풀이 ${wallet_name} 지갑""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """제거하지 못했습니다 ${wallet_name} 지갑. ${error}""";
  @override
  String get widgets_address => """주소""";
  @override
  String get widgets_restore_from_blockheight => """블록 높이에서 복원""";
  @override
  String get widgets_restore_from_date => """날짜에서 복원""";
  @override
  String get widgets_or => """또는""";
  @override
  String get widgets_seed => """씨""";
  @override
  String router_no_route(String name) => """에 정의 된 경로가 없습니다 ${name}""";
  @override
  String get error_text_account_name => """계정 이름은 문자, 숫자 만 포함 할 수 있습니다
1 ~ 15 자 사이 여야합니다""";
  @override
  String get error_text_contact_name => """담당자 이름은 포함 할 수 없습니다 ` , ' " 기호
1 자에서 32 자 사이 여야합니다""";
  @override
  String get error_text_address => """지갑 주소는 유형과 일치해야합니다
암호 화폐""";
  @override
  String get error_text_node_address => """iPv4 주소를 입력하십시오""";
  @override
  String get error_text_node_port => """노드 포트는 0에서 65535 사이의 숫자 만 포함 할 수 있습니다""";
  @override
  String get error_text_payment_id => """지불 ID는 16 ~ 64 자의 16 진 문자 만 포함 할 수 있습니다""";
  @override
  String get error_text_xmr => """XMR 값은 사용 가능한 잔액을 초과 할 수 없습니다.
소수 자릿수는 12 이하 여야합니다""";
  @override
  String get error_text_fiat => """금액은 사용 가능한 잔액을 초과 할 수 없습니다.
소수 자릿수는 2보다 작거나 같아야합니다""";
  @override
  String get error_text_subaddress_name => """하위 주소 이름은 포함 할 수 없습니다 ` , ' " 기호 
1 ~ 20 자 사이 여야합니다""";
  @override
  String get error_text_amount => """금액은 숫자 만 포함 할 수 있습니다""";
  @override
  String get error_text_wallet_name => """지갑 이름은 문자, 숫자 만 포함 할 수 있습니다
1 ~ 20 자 사이 여야합니다""";
  @override
  String get error_text_keys => """지갑 키는 16 진수로 64 자만 포함 할 수 있습니다""";
  @override
  String get error_text_crypto_currency => """소수 자릿수
12 이하 여야합니다""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """거래 ${provider} 가 생성되지 않습니다. 금액이 최소보다 적습니다. ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """거래 ${provider} 가 생성되지 않습니다. 금액이 최대 값보다 많습니다. ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """거래 ${provider} 가 생성되지 않습니다. 로딩 실패""";
  @override
  String get error_text_template => """템플릿 이름과 주소는 포함 할 수 없습니다 ` , ' " 기호 
1 ~ 106 자 사이 여야합니다""";
  @override
  String get auth_store_ban_timeout => """타임 아웃 금지""";
  @override
  String get auth_store_banned_for => """금지""";
  @override
  String get auth_store_banned_minutes => """ 의사록""";
  @override
  String get auth_store_incorrect_password => """잘못된 PIN""";
  @override
  String get wallet_store_monero_wallet => """모네로 월렛""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """시드 길이가 잘못되었습니다""";
  @override
  String get full_balance => """풀 밸런스""";
  @override
  String get available_balance => """사용 가능한 잔액""";
  @override
  String get hidden_balance => """숨겨진 균형""";
  @override
  String get sync_status_syncronizing => """동기화""";
  @override
  String get sync_status_syncronized => """동기화""";
  @override
  String get sync_status_not_connected => """연결되지 않은""";
  @override
  String get sync_status_starting_sync => """동기화 시작""";
  @override
  String get sync_status_failed_connect => """연결 해제""";
  @override
  String get sync_status_connecting => """연결 중""";
  @override
  String get sync_status_connected => """연결됨""";
  @override
  String get transaction_priority_slow => """느린""";
  @override
  String get transaction_priority_regular => """정규병""";
  @override
  String get transaction_priority_medium => """매질""";
  @override
  String get transaction_priority_fast => """빠른""";
  @override
  String get transaction_priority_fastest => """가장 빠른""";
  @override
  String trade_for_not_created(String title) => """거래 ${title} 생성되지 않습니다.""";
  @override
  String get trade_not_created => """거래가 생성되지 않았습니다.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """무역 ${tradeId} 의 ${title} 찾을 수 없습니다.""";
  @override
  String get trade_not_found => """거래를 찾을 수 없습니다.""";
  @override
  String get trade_state_pending => """대기 중""";
  @override
  String get trade_state_confirming => """확인 중""";
  @override
  String get trade_state_trading => """거래""";
  @override
  String get trade_state_traded => """거래""";
  @override
  String get trade_state_complete => """완전한""";
  @override
  String get trade_state_to_be_created => """만들려면""";
  @override
  String get trade_state_unpaid => """미지급""";
  @override
  String get trade_state_underpaid => """미지급""";
  @override
  String get trade_state_paid_unconfirmed => """미확인 유료""";
  @override
  String get trade_state_paid => """유료""";
  @override
  String get trade_state_btc_sent => """보냄""";
  @override
  String get trade_state_timeout => """타임 아웃""";
  @override
  String get trade_state_created => """만들어진""";
  @override
  String get trade_state_finished => """끝마친""";
  @override
  String get change_language => """언어 변경""";
  @override
  String change_language_to(String language) => """언어를로 변경 ${language}?""";
  @override
  String get paste => """풀""";
  @override
  String get restore_from_seed_placeholder => """여기에 코드 문구를 입력하거나 붙여 넣으십시오.""";
  @override
  String get add_new_word => """새로운 단어 추가""";
  @override
  String get incorrect_seed => """입력하신 텍스트가 유효하지 않습니다.""";
  @override
  String get biometric_auth_reason => """지문을 스캔하여 인증""";
  @override
  String version(String currentVersion) => """버전 ${currentVersion}""";
  @override
  String get openalias_alert_title => """XMR 수신자 감지""";
  @override
  String openalias_alert_content(String recipient_name) => """당신은에 자금을 보낼 것입니다
${recipient_name}""";
  @override
  String get card_address => """주소:""";
  @override
  String get buy => """구입""";
  @override
  String get placeholder_transactions => """거래가 여기에 표시됩니다""";
  @override
  String get placeholder_contacts => """연락처가 여기에 표시됩니다""";
  @override
  String get template => """주형""";
  @override
  String get confirm_delete_template => """이 작업은이 템플릿을 삭제합니다. 계속 하시겠습니까?""";
  @override
  String get confirm_delete_wallet => """이 작업은이 지갑을 삭제합니다. 계속 하시겠습니까?""";
  @override
  String get picker_description => """ChangeNOW 또는 MorphToken을 선택하려면 먼저 거래 쌍을 변경하십시오.""";
  @override
  String get change_wallet_alert_title => """현재 지갑 변경""";
  @override
  String change_wallet_alert_content(String wallet_name) => """현재 지갑을 다음으로 변경 하시겠습니까 ${wallet_name}?""";
  @override
  String get creating_new_wallet => """새 지갑 생성""";
  @override
  String creating_new_wallet_error(String description) => """오류: ${description}""";
  @override
  String get seed_alert_title => """주의""";
  @override
  String get seed_alert_content => """씨앗은 지갑을 복구하는 유일한 방법입니다. 적어 보셨나요?""";
  @override
  String get seed_alert_back => """돌아 가기""";
  @override
  String get seed_alert_yes => """네, 있어요""";
  @override
  String get wallet_name_alert_content => """같은 이름의 지갑이 있습니다.""";
  @override
  String get exchange_sync_alert_content => """지갑이 동기화 될 때까지 기다리십시오""";
  @override
  String get pre_seed_title => """중대한""";
  @override
  String pre_seed_description(String words) => """다음 페이지에서 ${words} 개의 단어를 볼 수 있습니다. 이것은 귀하의 고유하고 개인적인 시드이며 분실 또는 오작동시 지갑을 복구하는 유일한 방법입니다. 기록해두고 Cake Wallet 앱 외부의 안전한 장소에 보관하는 것은 귀하의 책임입니다.""";
  @override
  String get pre_seed_button_text => """이해 했어요. 내 씨앗을 보여줘""";
  @override
  String get xmr_to_error => """XMR.TO 오류""";
  @override
  String get xmr_to_error_description => """금액이 잘못되었습니다. 소수점 이하 최대 8 자리""";
  @override
  String provider_error(String provider) => """${provider} 오류""";
  @override
  String get use_ssl => """SSL 사용""";
  @override
  String get color_theme => """색상 테마""";
  @override
  String get light_theme => """빛""";
  @override
  String get bright_theme => """선명한""";
  @override
  String get dark_theme => """어두운""";
  @override
  String get enter_your_note => """메모를 입력하세요…""";
  @override
  String get note_optional => """참고 (선택 사항)""";
  @override
  String get note_tap_to_change => """메모 (변경하려면 탭하세요)""";
  @override
  String get transaction_key => """거래 키""";
  @override
  String get confirmations => """확인""";
  @override
  String get recipient_address => """받는 사람 주소""";
  @override
  String get extra_id => """추가 ID:""";
  @override
  String get destination_tag => """목적지 태그:""";
  @override
  String get memo => """메모:""";
  @override
  String get backup => """지원""";
  @override
  String get change_password => """비밀번호 변경""";
  @override
  String get backup_password => """백업 비밀번호""";
  @override
  String get write_down_backup_password => """백업 파일 가져 오기에 사용되는 백업 암호를 적어 두십시오.""";
  @override
  String get export_backup => """백업 내보내기""";
  @override
  String get save_backup_password => """백업 암호를 저장했는지 확인하십시오. 그것 없이는 백업 파일을 가져올 수 없습니다.""";
  @override
  String get backup_file => """백업 파일""";
  @override
  String get edit_backup_password => """편집 백업 암호""";
  @override
  String get save_backup_password_alert => """백업 비밀번호 저장""";
  @override
  String get change_backup_password_alert => """이전 백업 파일은 새 백업 암호로 가져올 수 없습니다. 새 백업 암호는 새 백업 파일에만 사용됩니다. 백업 비밀번호를 변경 하시겠습니까?""";
  @override
  String get enter_backup_password => """여기에 백업 비밀번호를 입력하세요.""";
  @override
  String get select_backup_file => """백업 파일 선택""";
  @override
  String get import => """수입""";
  @override
  String get please_select_backup_file => """백업 파일을 선택하고 백업 암호를 입력하십시오.""";
  @override
  String get fixed_rate => """고정 비율""";
  @override
  String get fixed_rate_alert => """고정 금리 모드 체크시 수취 금액 입력이 가능합니다. 고정 속도 모드로 전환 하시겠습니까?""";
  @override
  String get xlm_extra_info => """교환을 위해 XLM 거래를 보낼 때 메모 ID를 지정하는 것을 잊지 마십시오""";
  @override
  String get xrp_extra_info => """교환을 위해 XRP 트랜잭션을 보내는 동안 대상 태그를 지정하는 것을 잊지 마십시오""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Cake Wallet Monero 잔액에서 XMR을 교환하려면 먼저 Monero 지갑으로 전환하십시오.""";
  @override
  String get confirmed => """확인""";
  @override
  String get unconfirmed => """미확인""";
  @override
  String get displayable => """표시 가능""";
  @override
  String get submit_request => """요청을 제출""";
  @override
  String get buy_alert_content => """현재 우리는 비트 코인과 라이트 코인 구매 만 지원합니다. 비트 코인 또는 라이트 코인을 구매하려면 비트 코인 또는 라이트 코인 지갑을 생성하거나 전환하십시오.""";
  @override
  String get outdated_electrum_wallet_description => """Cake에서 생성 된 새로운 비트 코인 지갑에는 이제 24 단어 시드가 있습니다. 새로운 비트 코인 지갑을 생성하고 모든 자금을 새로운 24 단어 지갑으로 이체하고 12 단어 시드가있는 지갑 사용을 중지해야합니다. 자금을 확보하려면 즉시이 작업을 수행하십시오.""";
  @override
  String get understand => """이해 했어요""";
  @override
  String get apk_update => """APK 업데이트""";
  @override
  String get buy_bitcoin => """비트 코인 구매""";
  @override
  String get buy_with => """구매""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """금액은 다음보다 크거나 같아야합니다 ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """이 지갑에 12 단어 시드가 있고 Cake에서 생성 된 경우이 지갑에 비트 코인을 입금하지 마십시오. 이 지갑으로 전송 된 모든 BTC는 손실 될 수 있습니다. 새로운 24 단어 지갑을 생성하고 (오른쪽 상단의 메뉴를 탭하고 지갑을 선택한 다음 새 지갑 생성을 선택한 다음 비트 코인을 선택하십시오) 즉시 BTC를 그곳으로 이동하십시오. Cake의 새로운 (24 단어) BTC 지갑은 안전합니다""";
  @override
  String get do_not_show_me => """나를 다시 표시하지 않음""";
  @override
  String get unspent_coins_title => """사용하지 않은 동전""";
  @override
  String get unspent_coins_details_title => """사용하지 않은 동전 세부 정보""";
  @override
  String get freeze => """얼다""";
  @override
  String get coin_control => """코인 제어 (옵션)""";
  @override
  String get address_detected => """주소 감지""";
  @override
  String address_from_domain(String domain) => """주소는 unstoppable domain ${domain}""";
}

class $uk extends S {
  const $uk();
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  @override
  String get welcome => """Вітаємо в""";
  @override
  String get cake_wallet => """Cake Wallet""";
  @override
  String get first_wallet_text => """В самому зручному гаманці для Monero та Bitcoin""";
  @override
  String get please_make_selection => """Оберіть спосіб створення гаманця: створити новий чи відновити ваш існуючий.""";
  @override
  String get create_new => """Створити новий гаманець""";
  @override
  String get restore_wallet => """Відновити гаманець""";
  @override
  String get accounts => """Акаунти""";
  @override
  String get edit => """Редагувати""";
  @override
  String get account => """Акаунт""";
  @override
  String get add => """Добавити""";
  @override
  String get address_book => """Адресна книга""";
  @override
  String get contact => """Контакт""";
  @override
  String get please_select => """Будь ласка, виберіть:""";
  @override
  String get cancel => """Відмінити""";
  @override
  String get ok => """OK""";
  @override
  String get contact_name => """Ім'я контакту""";
  @override
  String get reset => """Скинути""";
  @override
  String get save => """Зберегти""";
  @override
  String get address_remove_contact => """Видалити контакт""";
  @override
  String get address_remove_content => """Ви впевнені, що хочете видалити вибраний контакт?""";
  @override
  String get authenticated => """Аутентифіковано""";
  @override
  String get authentication => """Аутентифікація""";
  @override
  String failed_authentication(String state_error) => """Помилка аутентифікації. ${state_error}""";
  @override
  String get wallet_menu => """Меню гаманця""";
  @override
  String Blocks_remaining(String status) => """${status} Залишилось блоків""";
  @override
  String get please_try_to_connect_to_another_node => """Будь ласка, спробуйте підключитися до іншого вузлу""";
  @override
  String get xmr_hidden => """Приховано""";
  @override
  String get xmr_available_balance => """Доступний баланс""";
  @override
  String get xmr_full_balance => """Весь баланс""";
  @override
  String get send => """Відправити""";
  @override
  String get receive => """Отримати""";
  @override
  String get transactions => """Транзакції""";
  @override
  String get incoming => """Вхідні""";
  @override
  String get outgoing => """Вихідні""";
  @override
  String get transactions_by_date => """Сортувати по даті""";
  @override
  String get trades => """Торгові операції""";
  @override
  String get filters => """Фільтр""";
  @override
  String get today => """Сьогодні""";
  @override
  String get yesterday => """Вчора""";
  @override
  String get received => """Отримані""";
  @override
  String get sent => """Відправлені""";
  @override
  String get pending => """ (в очікуванні)""";
  @override
  String get rescan => """Пересканувати""";
  @override
  String get reconnect => """Перепідключитися""";
  @override
  String get wallets => """Гаманці""";
  @override
  String get show_seed => """Показати мнемонічну фразу""";
  @override
  String get show_keys => """Показати мнемонічну фразу/ключі""";
  @override
  String get address_book_menu => """Адресна книга""";
  @override
  String get reconnection => """Перепідключення""";
  @override
  String get reconnect_alert_text => """Ви хочете перепідключитися?""";
  @override
  String get exchange => """Обмін""";
  @override
  String get clear => """Очистити""";
  @override
  String get refund_address => """Адреса повернення коштів""";
  @override
  String get change_exchange_provider => """Змінити провайдера обміну""";
  @override
  String get you_will_send => """Конвертувати з""";
  @override
  String get you_will_get => """Конвертувати в""";
  @override
  String get amount_is_guaranteed => """Отримана сума є гарантованою""";
  @override
  String get amount_is_estimate => """Отримана сума є приблизною""";
  @override
  String powered_by(String title) => """Використовуючи ${title}""";
  @override
  String get error => """Помилка""";
  @override
  String get estimated => """Приблизно """;
  @override
  String min_value(String value, String currency) => """Мін: ${value} ${currency}""";
  @override
  String max_value(String value, String currency) => """Макс: ${value} ${currency}""";
  @override
  String get change_currency => """Змінити валюту""";
  @override
  String get copy_id => """Скопіювати ID""";
  @override
  String get exchange_result_write_down_trade_id => """Будь ласка, скопіюйте або запишіть ID операції.""";
  @override
  String get trade_id => """ID операції:""";
  @override
  String get copied_to_clipboard => """Скопійовано в буфер обміну""";
  @override
  String get saved_the_trade_id => """Я зберіг ID операції""";
  @override
  String get fetching => """Завантаження""";
  @override
  String get id => """ID: """;
  @override
  String get amount => """Сума: """;
  @override
  String get payment_id => """ID платежу: """;
  @override
  String get status => """Статус: """;
  @override
  String get offer_expires_in => """Пропозиція закінчиться через: """;
  @override
  String trade_is_powered_by(String provider) => """Операція виконана через ${provider}""";
  @override
  String get copy_address => """Cкопіювати адресу""";
  @override
  String exchange_result_confirm(String fetchingLabel, String from, String walletName) => """Натиснувши підтвердити, ви відправите ${fetchingLabel} ${from} з вашого гаманця ${walletName} на адресу вказану нижче. Або ви можете відправити зі свого зовнішнього гаманця на нижчевказану адресу/QR-код.

Будь ласка, натисніть підтвердити для продовження або поверніться назад щоб змінити суму.""";
  @override
  String exchange_result_description(String fetchingLabel, String from) => """Ви повинні надіслати мінімум ${fetchingLabel} ${from} на адресу, вказану на наступній сторінці. Якщо ви надішлете суму меншу за ${fetchingLabel} ${from}, то вона може бути не конвертованою і не поверненою.""";
  @override
  String get exchange_result_write_down_ID => """*Будь ласка, скопіюйте або запишіть ID, вказаний вище.""";
  @override
  String get confirm => """Підтвердити""";
  @override
  String get confirm_sending => """Підтвердити відправлення""";
  @override
  String commit_transaction_amount_fee(String amount, String fee) => """Підтвердити транзакцію 
Сума: ${amount}
Комісія: ${fee}""";
  @override
  String get sending => """Відправлення""";
  @override
  String get transaction_sent => """Tранзакцію відправлено!""";
  @override
  String get expired => """Закінчується""";
  @override
  String time(String minutes, String seconds) => """${minutes}хв ${seconds}сек""";
  @override
  String get send_xmr => """Відправити XMR""";
  @override
  String get exchange_new_template => """Новий шаблон""";
  @override
  String get faq => """FAQ""";
  @override
  String get enter_your_pin => """Введіть ваш PIN""";
  @override
  String get loading_your_wallet => """Завантаження гаманця""";
  @override
  String get new_wallet => """Новий гаманець""";
  @override
  String get wallet_name => """Ім'я гаманця""";
  @override
  String get continue_text => """Продовжити""";
  @override
  String get choose_wallet_currency => """Будь ласка, виберіть валюту гаманця:""";
  @override
  String get node_new => """Новий вузол""";
  @override
  String get node_address => """Адреса вузла""";
  @override
  String get node_port => """Порт вузла""";
  @override
  String get login => """Логін""";
  @override
  String get password => """Пароль""";
  @override
  String get nodes => """Вузли""";
  @override
  String get node_reset_settings_title => """Скинути налаштування""";
  @override
  String get nodes_list_reset_to_default_message => """Ви впевнені, що хочете скинути до налаштувань за замовченням?""";
  @override
  String change_current_node(String node) => """Ви впевнені, що хочете змінити поточний вузол на ${node}?""";
  @override
  String get change => """Змінити""";
  @override
  String get remove_node => """Видалити вузол""";
  @override
  String get remove_node_message => """Ви впевнені, що хочете видалити поточний вузол?""";
  @override
  String get remove => """Видалити""";
  @override
  String get delete => """Видалити""";
  @override
  String get add_new_node => """Додати новий вузол""";
  @override
  String get change_current_node_title => """Змінити поточний вузол""";
  @override
  String get node_test => """Тест""";
  @override
  String get node_connection_successful => """З'єднання було успішним""";
  @override
  String get node_connection_failed => """Помилка з’єднання""";
  @override
  String get new_node_testing => """Тестування нового вузла""";
  @override
  String get use => """Використати """;
  @override
  String get digit_pin => """-значний PIN""";
  @override
  String get share_address => """Поділитися адресою""";
  @override
  String get receive_amount => """Сума""";
  @override
  String get subaddresses => """Субадреси""";
  @override
  String get addresses => """Адреси""";
  @override
  String get scan_qr_code => """Скануйте QR-код для одержання адреси""";
  @override
  String get rename => """Перейменувати""";
  @override
  String get choose_account => """Оберіть акаунт""";
  @override
  String get create_new_account => """Створити новий акаунт""";
  @override
  String get accounts_subaddresses => """Акаунти та субадреси""";
  @override
  String get restore_restore_wallet => """Відновити гаманець""";
  @override
  String get restore_title_from_seed_keys => """Відновити з мнемонічної фрази/ключів""";
  @override
  String get restore_description_from_seed_keys => """Ви можете відновити гаманець з мнемонічної фрази/ключів, які ви зберегли раніше""";
  @override
  String get restore_next => """Продовжити""";
  @override
  String get restore_title_from_backup => """Відновити із резервного файлу""";
  @override
  String get restore_description_from_backup => """Ви можете відновити Cake Wallet з вашого резервного файлу""";
  @override
  String get restore_seed_keys_restore => """Відновити за допомогою мнемонічної фрази/ключів""";
  @override
  String get restore_title_from_seed => """Відновити з мнемонічної фрази""";
  @override
  String get restore_description_from_seed => """Ви можете відновити гаманець використовуючи 25-ти слівну мнемонічну фразу""";
  @override
  String get restore_title_from_keys => """Відновити за допомогою ключів""";
  @override
  String get restore_description_from_keys => """Ви можете відновити гаманець за допомогою приватних ключів""";
  @override
  String get restore_wallet_name => """Ім'я гаманця""";
  @override
  String get restore_address => """Адреса""";
  @override
  String get restore_view_key_private => """Приватний ключ перегляду""";
  @override
  String get restore_spend_key_private => """Приватний ключ витрати""";
  @override
  String get restore_recover => """Відновити""";
  @override
  String get restore_wallet_restore_description => """Опис відновлюваного гаманця""";
  @override
  String get restore_new_seed => """Нова мнемонічна фраза""";
  @override
  String get restore_active_seed => """Активна мнемонічна фраза""";
  @override
  String get restore_bitcoin_description_from_seed => """Ви можете відновити гаманець використовуючи 24-ти слівну мнемонічну фразу""";
  @override
  String get restore_bitcoin_description_from_keys => """Ви можете відновити гаманець за допомогою WIF""";
  @override
  String get restore_bitcoin_title_from_keys => """Відновити за допомогою WIF""";
  @override
  String get restore_from_date_or_blockheight => """Будь ласка, введіть дату за кілька днів до створення цього гаманця. Або, якщо ви знаєте висоту блоку, введіть її значення""";
  @override
  String get seed_reminder => """Будь ласка, запишіть мнемонічну фразу на випадок втрати або очищення телефону""";
  @override
  String get seed_title => """Мнемонічна фраза""";
  @override
  String get seed_share => """Поділитися мнемонічною фразою""";
  @override
  String get copy => """Скопіювати""";
  @override
  String get seed_language_choose => """Будь ласка, виберіть мову мнемонічної фрази:""";
  @override
  String get seed_choose => """Виберіть мову мнемонічної фрази""";
  @override
  String get seed_language_next => """Продовжити""";
  @override
  String get seed_language_english => """Англійська""";
  @override
  String get seed_language_chinese => """Китайська""";
  @override
  String get seed_language_dutch => """Голландська""";
  @override
  String get seed_language_german => """Німецька""";
  @override
  String get seed_language_japanese => """Японська""";
  @override
  String get seed_language_portuguese => """Португальська""";
  @override
  String get seed_language_russian => """Російська""";
  @override
  String get seed_language_spanish => """Іспанська""";
  @override
  String get send_title => """Відправити""";
  @override
  String get send_your_wallet => """Ваш гаманець""";
  @override
  String send_address(String cryptoCurrency) => """${cryptoCurrency} адреса""";
  @override
  String get send_payment_id => """ID платежу (опційно)""";
  @override
  String get all => """ВСЕ""";
  @override
  String get send_error_minimum_value => """Мінімальна сума 0.01""";
  @override
  String get send_error_currency => """Валюта може містити тільки цифри""";
  @override
  String get send_estimated_fee => """Ймовірна комісія:""";
  @override
  String send_priority(String transactionPriority) => """Комісія встановлена в залежності від пріоритету: ${transactionPriority}.
Пріоритет транзакції може бути змінений в налаштуваннях""";
  @override
  String get send_creating_transaction => """Створити транзакцію""";
  @override
  String get send_templates => """Шаблони""";
  @override
  String get send_new => """Новий""";
  @override
  String get send_amount => """Сума:""";
  @override
  String get send_fee => """Комісія:""";
  @override
  String get send_name => """Ім'я""";
  @override
  String get send_got_it => """Зрозумів""";
  @override
  String get send_sending => """Відправлення...""";
  @override
  String send_success(String crypto) => """Ваш ${crypto} успішно надісланий""";
  @override
  String get settings_title => """Налаштування""";
  @override
  String get settings_nodes => """Вузли""";
  @override
  String get settings_current_node => """Поточний вузол""";
  @override
  String get settings_wallets => """Гаманці""";
  @override
  String get settings_display_balance_as => """Відображати баланс як""";
  @override
  String get settings_currency => """Валюта""";
  @override
  String get settings_fee_priority => """Пріоритет транзакції""";
  @override
  String get settings_save_recipient_address => """Зберігати адресу отримувача""";
  @override
  String get settings_personal => """Персональні""";
  @override
  String get settings_change_pin => """Змінити PIN""";
  @override
  String get settings_change_language => """Змінити мову""";
  @override
  String get settings_allow_biometrical_authentication => """Включити біометричну аутентифікацію""";
  @override
  String get settings_dark_mode => """Темний режим""";
  @override
  String get settings_transactions => """Транзакції""";
  @override
  String get settings_trades => """Операції""";
  @override
  String get settings_display_on_dashboard_list => """Відображати в списку транзакцій""";
  @override
  String get settings_all => """ВСІ""";
  @override
  String get settings_only_trades => """Операції""";
  @override
  String get settings_only_transactions => """Транзакції""";
  @override
  String get settings_none => """Нічого""";
  @override
  String get settings_support => """Підтримка""";
  @override
  String get settings_terms_and_conditions => """Умови та положення""";
  @override
  String get pin_is_incorrect => """Некоректний PIN""";
  @override
  String get setup_pin => """Встановити PIN""";
  @override
  String get enter_your_pin_again => """Введіть PIN ще раз""";
  @override
  String get setup_successful => """PIN було успішно встановлено!""";
  @override
  String get wallet_keys => """Мнемонічна фраза/ключі гаманця""";
  @override
  String get wallet_seed => """Мнемонічна фраза гаманця""";
  @override
  String get private_key => """Приватний ключ""";
  @override
  String get public_key => """Публічний ключ""";
  @override
  String get view_key_private => """Приватний ключ перегляду""";
  @override
  String get view_key_public => """Публічний ключ перегляду""";
  @override
  String get spend_key_private => """Приватний ключ витрати""";
  @override
  String get spend_key_public => """Публічний ключ витрати""";
  @override
  String copied_key_to_clipboard(String key) => """Скопійовано ${key} в буфер обміну""";
  @override
  String get new_subaddress_title => """Нова адреса""";
  @override
  String get new_subaddress_label_name => """Ім'я""";
  @override
  String get new_subaddress_create => """Створити""";
  @override
  String get subaddress_title => """Список Субадрес""";
  @override
  String get trade_details_title => """Деталі операцій""";
  @override
  String get trade_details_id => """ID""";
  @override
  String get trade_details_state => """Статус""";
  @override
  String get trade_details_fetching => """Отримання""";
  @override
  String get trade_details_provider => """Провайдер""";
  @override
  String get trade_details_created_at => """Створено""";
  @override
  String get trade_details_pair => """Пара""";
  @override
  String trade_details_copied(String title) => """${title} скопійовано в буфер обміну""";
  @override
  String get trade_history_title => """Історія операцій""";
  @override
  String get transaction_details_title => """Деталі транзакції""";
  @override
  String get transaction_details_transaction_id => """ID транзакції""";
  @override
  String get transaction_details_date => """Дата""";
  @override
  String get transaction_details_height => """Висота""";
  @override
  String get transaction_details_amount => """Сума""";
  @override
  String get transaction_details_fee => """Комісія""";
  @override
  String transaction_details_copied(String title) => """${title} скопійовано в буфер обміну""";
  @override
  String get transaction_details_recipient_address => """Адреса отримувача""";
  @override
  String get wallet_list_title => """Monero Гаманець""";
  @override
  String get wallet_list_create_new_wallet => """Створити новий гаманець""";
  @override
  String get wallet_list_restore_wallet => """Відновити гаманець""";
  @override
  String get wallet_list_load_wallet => """Завантаження гаманця""";
  @override
  String wallet_list_loading_wallet(String wallet_name) => """Завантаження ${wallet_name} гаманця""";
  @override
  String wallet_list_failed_to_load(String wallet_name, String error) => """Помилка при завантаженні ${wallet_name} гаманця. ${error}""";
  @override
  String wallet_list_removing_wallet(String wallet_name) => """Видалення ${wallet_name} гаманця""";
  @override
  String wallet_list_failed_to_remove(String wallet_name, String error) => """Помилка при видаленні ${wallet_name} гаманця. ${error}""";
  @override
  String get widgets_address => """Адреса""";
  @override
  String get widgets_restore_from_blockheight => """Відновити на висоті блоку""";
  @override
  String get widgets_restore_from_date => """Відновити з дати""";
  @override
  String get widgets_or => """або""";
  @override
  String get widgets_seed => """Мнемонічна фраза""";
  @override
  String router_no_route(String name) => """Не встановлено маршрут для ${name}""";
  @override
  String get error_text_account_name => """Ім'я акаунту може містити тільки букви, цифри
і повинно бути від 1 до 15 символів в довжину""";
  @override
  String get error_text_contact_name => """Ім'я контакту не може містити ` , ' " символи
 і повинно бути від 1 до 32 символів в довжину""";
  @override
  String get error_text_address => """Адреса гаманця повинна відповідати типу
криптовалюти""";
  @override
  String get error_text_node_address => """Будь ласка, введіть iPv4 адресу""";
  @override
  String get error_text_node_port => """Порт вузла може містити тільки цифри від 0 до 65535""";
  @override
  String get error_text_payment_id => """Ідентифікатор платежу може містити від 16 до 64 символів в hex""";
  @override
  String get error_text_xmr => """Значення XMR не може перевищувати доступний баланс.
Кількість цифр після коми повинно бути меншим або дорівнювати 12""";
  @override
  String get error_text_fiat => """Значення суми не може перевищувати доступний баланс.
Кількість цифр після коми повинно бути меншим або дорівнювати 2""";
  @override
  String get error_text_subaddress_name => """Ім'я субадреси не може містити ` , ' " символи
і може бути від 1 до 20 символів в довжину""";
  @override
  String get error_text_amount => """Баланс може містити тільки цифри""";
  @override
  String get error_text_wallet_name => """Ім'я гаманця може містити тільки букви, цифри
і повинно бути від 1 до 20 символів у довжину""";
  @override
  String get error_text_keys => """Ключі гаманця можуть містити тільки 64 символів в hex""";
  @override
  String get error_text_crypto_currency => """Кількість цифр після коми
повинно бути меншим або дорівнювати 12""";
  @override
  String error_text_minimal_limit(String provider, String min, String currency) => """Операція для ${provider} не створена. Сума менша мінімальної: ${min} ${currency}""";
  @override
  String error_text_maximum_limit(String provider, String max, String currency) => """Операція для ${provider} не створена. Сума більше максимальної: ${max} ${currency}""";
  @override
  String error_text_limits_loading_failed(String provider) => """Операція для ${provider} не створена. Помилка завантаження лімітів""";
  @override
  String get error_text_template => """Ім'я та адреса шаблону не може містити ` , ' " символи
і може бути від 1 до 106 символів в довжину""";
  @override
  String get auth_store_ban_timeout => """ban_timeout""";
  @override
  String get auth_store_banned_for => """Заблоковано на """;
  @override
  String get auth_store_banned_minutes => """ хвилин""";
  @override
  String get auth_store_incorrect_password => """Некоректний PIN""";
  @override
  String get wallet_store_monero_wallet => """Monero гаманець""";
  @override
  String get wallet_restoration_store_incorrect_seed_length => """Невірна довжина мнемонічної фрази""";
  @override
  String get full_balance => """Весь баланс""";
  @override
  String get available_balance => """Доступний баланс""";
  @override
  String get hidden_balance => """Прихований баланс""";
  @override
  String get sync_status_syncronizing => """СИНХРОНІЗАЦІЯ""";
  @override
  String get sync_status_syncronized => """СИНХРОНІЗОВАНИЙ""";
  @override
  String get sync_status_not_connected => """НЕ ПІДКЛЮЧЕННИЙ""";
  @override
  String get sync_status_starting_sync => """ПОЧАТОК СИНХРОНІЗАЦІЇ""";
  @override
  String get sync_status_failed_connect => """ВІДКЛЮЧЕНО""";
  @override
  String get sync_status_connecting => """ПІДКЛЮЧЕННЯ""";
  @override
  String get sync_status_connected => """ПІДКЛЮЧЕНО""";
  @override
  String get transaction_priority_slow => """Повільний""";
  @override
  String get transaction_priority_regular => """Звичайний""";
  @override
  String get transaction_priority_medium => """Середній""";
  @override
  String get transaction_priority_fast => """Швидкий""";
  @override
  String get transaction_priority_fastest => """Найшвидший""";
  @override
  String trade_for_not_created(String title) => """Операція для ${title} не створена.""";
  @override
  String get trade_not_created => """Операція не створена.""";
  @override
  String trade_id_not_found(String tradeId, String title) => """Операція ${tradeId} ${title} не знайдена.""";
  @override
  String get trade_not_found => """Операція не знайдена.""";
  @override
  String get trade_state_pending => """Очікування""";
  @override
  String get trade_state_confirming => """Підтвердження""";
  @override
  String get trade_state_trading => """Виконання операції""";
  @override
  String get trade_state_traded => """Операція виконана""";
  @override
  String get trade_state_complete => """Завершено""";
  @override
  String get trade_state_to_be_created => """Буде створена""";
  @override
  String get trade_state_unpaid => """Неоплачена""";
  @override
  String get trade_state_underpaid => """Недоплачена""";
  @override
  String get trade_state_paid_unconfirmed => """Оплата непідтверджена""";
  @override
  String get trade_state_paid => """Оплачена""";
  @override
  String get trade_state_btc_sent => """BTC надіслано""";
  @override
  String get trade_state_timeout => """Таймаут""";
  @override
  String get trade_state_created => """Створена""";
  @override
  String get trade_state_finished => """Завершена""";
  @override
  String get change_language => """Змінити мову""";
  @override
  String change_language_to(String language) => """Змінити мову на ${language}?""";
  @override
  String get paste => """Вставити""";
  @override
  String get restore_from_seed_placeholder => """Введіть або вставте мнемонічну фразу вашого гаманця""";
  @override
  String get add_new_word => """Добавити нове слово""";
  @override
  String get incorrect_seed => """Введений текст невірний.""";
  @override
  String get biometric_auth_reason => """Відскануйте свій відбиток пальця для аутентифікації""";
  @override
  String version(String currentVersion) => """Версія ${currentVersion}""";
  @override
  String get openalias_alert_title => """Отримувача XMR виявлено""";
  @override
  String openalias_alert_content(String recipient_name) => """Ви будете відправляти кошти
${recipient_name}""";
  @override
  String get card_address => """Адреса:""";
  @override
  String get buy => """Купити""";
  @override
  String get placeholder_transactions => """Тут відображатимуться ваші транзакції""";
  @override
  String get placeholder_contacts => """Тут будуть показані ваші контакти""";
  @override
  String get template => """Шаблон""";
  @override
  String get confirm_delete_template => """Ця дія видалить шаблон. Ви хочете продовжити?""";
  @override
  String get confirm_delete_wallet => """Ця дія видалить гаманець. Ви хочете продовжити?""";
  @override
  String get picker_description => """Щоб вибрати ChangeNOW або MorphToken, спочатку змініть пару для обміну""";
  @override
  String get change_wallet_alert_title => """Змінити поточний гаманець""";
  @override
  String change_wallet_alert_content(String wallet_name) => """Ви хочете змінити поточний гаманець на ${wallet_name}?""";
  @override
  String get creating_new_wallet => """Створення нового гаманця""";
  @override
  String creating_new_wallet_error(String description) => """Помилка: ${description}""";
  @override
  String get seed_alert_title => """Увага""";
  @override
  String get seed_alert_content => """Мнемонічна фраза - єдиний спосіб відновити ваш гаманець. Ви записали її?""";
  @override
  String get seed_alert_back => """Назад""";
  @override
  String get seed_alert_yes => """Так""";
  @override
  String get wallet_name_alert_content => """Гаманець з такою ж назвою існує""";
  @override
  String get exchange_sync_alert_content => """Зачекайте, поки ваш гаманець не синхронізується""";
  @override
  String get pre_seed_title => """ВАЖЛИВО""";
  @override
  String pre_seed_description(String words) => """На наступній сторінці ви побачите серію з ${words} слів. Це ваша унікальна та приватна мнемонічна фраза, і це ЄДИНИЙ спосіб відновити ваш гаманець на випадок втрати або несправності. ВАМ необхідно записати її та зберігати в безпечному місці поза програмою Cake Wallet.""";
  @override
  String get pre_seed_button_text => """Зрозуміло. Покажіть мнемонічну фразу""";
  @override
  String get xmr_to_error => """Помилка XMR.TO""";
  @override
  String get xmr_to_error_description => """Неприпустима сума. Максимум 8 цифр після десяткової коми""";
  @override
  String provider_error(String provider) => """${provider} помилка""";
  @override
  String get use_ssl => """Використати SSL""";
  @override
  String get color_theme => """Кольорова тема""";
  @override
  String get light_theme => """Світла""";
  @override
  String get bright_theme => """Яскрава""";
  @override
  String get dark_theme => """Темна""";
  @override
  String get enter_your_note => """Введіть примітку…""";
  @override
  String get note_optional => """Примітка (необов’язково)""";
  @override
  String get note_tap_to_change => """Примітка (натисніть для зміни)""";
  @override
  String get transaction_key => """Ключ транзакції""";
  @override
  String get confirmations => """Підтвердження""";
  @override
  String get recipient_address => """Адреса одержувача""";
  @override
  String get extra_id => """Додатковий ID:""";
  @override
  String get destination_tag => """Тег призначення:""";
  @override
  String get memo => """Пам’ятка:""";
  @override
  String get backup => """Резервна копія""";
  @override
  String get change_password => """Змінити пароль""";
  @override
  String get backup_password => """Пароль резервної копії""";
  @override
  String get write_down_backup_password => """Запишіть пароль резервної копії, який використовується для імпорту файлів резервних копій.""";
  @override
  String get export_backup => """Експортувати резервну копію""";
  @override
  String get save_backup_password => """Переконайтеся, що ви зберегли свій пароль резервної копії. Без нього ви не зможете імпортувати файли резервних копій.""";
  @override
  String get backup_file => """Файл резервної копії""";
  @override
  String get edit_backup_password => """Змінити пароль резервної копії""";
  @override
  String get save_backup_password_alert => """Зберегти пароль резервної копії""";
  @override
  String get change_backup_password_alert => """Ваші попередні файли резервних копій будуть недоступні для імпорту з новим паролем резервної копії. Новий пароль резервної копії буде використовуватися тільки для нових файлів резервних копій. Ви впевнені, що хочете змінити пароль резервної копії?""";
  @override
  String get enter_backup_password => """Введіть пароль резервної копії""";
  @override
  String get select_backup_file => """Виберіть файл резервної копії""";
  @override
  String get import => """Імпортувати""";
  @override
  String get please_select_backup_file => """Виберіть файл резервної копії та введіть пароль резервної копії.""";
  @override
  String get fixed_rate => """Фіксована ставка""";
  @override
  String get fixed_rate_alert => """Ви зможете ввести суму отримання тоді, коли буде встановлений режим фіксованої ставки. Ви хочете перейти в режим фіксованої ставки?""";
  @override
  String get xlm_extra_info => """Будь ласка, не забудьте вказати ідентифікатор пам'ятки під час надсилання транзакції XLM для обміну""";
  @override
  String get xrp_extra_info => """Будь ласка, не забудьте вказати тег призначення під час надсилання XRP-транзакції для обміну""";
  @override
  String get exchange_incorrect_current_wallet_for_xmr => """Якщо ви хочете обміняти XMR із вашого балансу Cake Wallet Monero, спочатку перейдіть на свій гаманець Monero.""";
  @override
  String get confirmed => """Підтверджено""";
  @override
  String get unconfirmed => """Непідтверджений""";
  @override
  String get displayable => """Відображуваний""";
  @override
  String get submit_request => """надіслати запит""";
  @override
  String get buy_alert_content => """В даний час ми підтримуємо лише придбання Bitcoin та Litecoin. Щоб купити Bitcoin або Litecoin, будь ласка, створіть або перейдіть на свій гаманець Bitcoin або Litecoin.""";
  @override
  String get outdated_electrum_wallet_description => """Нові біткойн-гаманці, створені в Cake, тепер містять мнемонічну фразу з 24 слів. Обов’язково стовріть новий біткойн-гаманець, переведіть всі кошти на новий гаманець із 24 слів і припиніть використання гаманців із мнемонічною фразою з 12 слів. Зробіть це негайно, щоб убезпечити свої кошти.""";
  @override
  String get understand => """Зрозуміло""";
  @override
  String get apk_update => """Оновлення APK""";
  @override
  String get buy_bitcoin => """Купити Bitcoin""";
  @override
  String get buy_with => """Купити за допомогою""";
  @override
  String moonpay_alert_text(String minAmount, String fiatCurrency) => """Значення суми має бути більшим або дорівнювати ${minAmount} ${fiatCurrency}""";
  @override
  String get outdated_electrum_wallet_receive_warning => """Якщо цей гаманець має мнемонічну фразу з 12 слів і був створений у Cake, НЕ переводьте біткойни на цей гаманець. Будь-які BTC, переведений на цей гаманець, можуть бути втраченими. Створіть новий гаманець з мнемонічною фразою з 24 слів (торкніться меню у верхньому правому куті, виберіть Гаманці, виберіть Створити новий гаманець, потім виберіть Bitcoin) і НЕГАЙНО переведіть туди свії BTC. Нові (з мнемонічною фразою з 24 слів) гаманці BTC від Cake надійно захищені""";
  @override
  String get do_not_show_me => """Не показуй мені це знову""";
  @override
  String get unspent_coins_title => """Невитрачені монети""";
  @override
  String get unspent_coins_details_title => """Відомості про невитрачені монети""";
  @override
  String get freeze => """Заморозити""";
  @override
  String get coin_control => """Контроль монет (необов’язково)""";
  @override
  String get address_detected => """Виявлено адресу""";
  @override
  String address_from_domain(String domain) => """Ви отримали адресу від unstoppable domain ${domain}""";
}

class GeneratedLocalizationsDelegate extends LocalizationsDelegate<S> {
  const GeneratedLocalizationsDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale("nl", ""),
      Locale("zh", ""),
      Locale("ru", ""),
      Locale("pl", ""),
      Locale("en", ""),
      Locale("hi", ""),
      Locale("ja", ""),
      Locale("hr", ""),
      Locale("pt", ""),
      Locale("de", ""),
      Locale("it", ""),
      Locale("es", ""),
      Locale("ko", ""),
      Locale("uk", ""),
    ];
  }

  LocaleListResolutionCallback listResolution({Locale fallback, bool withCountry = true}) {
    return (List<Locale> locales, Iterable<Locale> supported) {
      if (locales == null || locales.isEmpty) {
        return fallback ?? supported.first;
      } else {
        return _resolve(locales.first, fallback, supported, withCountry);
      }
    };
  }

  LocaleResolutionCallback resolution({Locale fallback, bool withCountry = true}) {
    return (Locale locale, Iterable<Locale> supported) {
      return _resolve(locale, fallback, supported, withCountry);
    };
  }

  @override
  Future<S> load(Locale locale) {
    final String lang = getLang(locale);
    if (lang != null) {
      switch (lang) {
        case "nl":
          S.current = const $nl();
          return SynchronousFuture<S>(S.current);
        case "zh":
          S.current = const $zh();
          return SynchronousFuture<S>(S.current);
        case "ru":
          S.current = const $ru();
          return SynchronousFuture<S>(S.current);
        case "pl":
          S.current = const $pl();
          return SynchronousFuture<S>(S.current);
        case "en":
          S.current = const $en();
          return SynchronousFuture<S>(S.current);
        case "hi":
          S.current = const $hi();
          return SynchronousFuture<S>(S.current);
        case "ja":
          S.current = const $ja();
          return SynchronousFuture<S>(S.current);
        case "hr":
          S.current = const $hr();
          return SynchronousFuture<S>(S.current);
        case "pt":
          S.current = const $pt();
          return SynchronousFuture<S>(S.current);
        case "de":
          S.current = const $de();
          return SynchronousFuture<S>(S.current);
        case "it":
          S.current = const $it();
          return SynchronousFuture<S>(S.current);
        case "es":
          S.current = const $es();
          return SynchronousFuture<S>(S.current);
        case "ko":
          S.current = const $ko();
          return SynchronousFuture<S>(S.current);
        case "uk":
          S.current = const $uk();
          return SynchronousFuture<S>(S.current);
        default:
      }
    }
    S.current = const S();
    return SynchronousFuture<S>(S.current);
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale, true);

  @override
  bool shouldReload(GeneratedLocalizationsDelegate old) => false;

  Locale _resolve(Locale locale, Locale fallback, Iterable<Locale> supported, bool withCountry) {
    if (locale == null || !_isSupported(locale, withCountry)) {
      return fallback ?? supported.first;
    }

    final Locale languageLocale = Locale(locale.languageCode, "");
    if (supported.contains(locale)) {
      return locale;
    } else if (supported.contains(languageLocale)) {
      return languageLocale;
    } else {
      final Locale fallbackLocale = fallback ?? supported.first;
      return fallbackLocale;
    }
  }

  bool _isSupported(Locale locale, bool withCountry) {
    if (locale != null) {
      for (Locale supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode != locale.languageCode) {
          continue;
        }
        if (supportedLocale.countryCode == locale.countryCode) {
          return true;
        }
        if (true != withCountry && (supportedLocale.countryCode == null || supportedLocale.countryCode.isEmpty)) {
          return true;
        }
      }
    }
    return false;
  }
}

String getLang(Locale l) => l == null
  ? null
  : l.countryCode != null && l.countryCode.isEmpty
    ? l.languageCode
    : l.toString();
