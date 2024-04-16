import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:intl/intl.dart';

import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_lightning/lightning_wallet_service.dart';
import 'package:cw_lightning/lightning_receive_page_option.dart';

part 'cw_lightning.dart';

Lightning? lightning = CWLightning();

abstract class Lightning {
  String formatterLightningAmountToString({required int amount});
  double formatterLightningAmountToDouble({required int amount});
  int formatterStringDoubleToLightningAmount(String amount);
  WalletService createLightningWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource);
  List<ReceivePageOption> getLightningReceivePageOptions();
  String satsToLightningString(int sats);
  ReceivePageOption getOptionInvoice();
  ReceivePageOption getOptionOnchain();
  String bitcoinAmountToLightningString({required int amount});
  int bitcoinAmountToLightningAmount({required int amount});
  double bitcoinDoubleToLightningDouble({required double amount});
  double lightningDoubleToBitcoinDouble({required double amount});
}
  