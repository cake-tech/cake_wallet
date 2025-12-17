import 'package:cake_wallet/arbitrum/arbitrum.dart';
import 'package:cake_wallet/base/base.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/dogecoin/dogecoin.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_type.dart';

List<TransactionPriority> priorityForWalletType(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return monero!.getTransactionPriorities();
    case WalletType.wownero:
      return wownero!.getTransactionPriorities();
    case WalletType.bitcoin:
      return bitcoin!.getTransactionPriorities();
    case WalletType.litecoin:
      return bitcoin!.getLitecoinTransactionPriorities();
    case WalletType.ethereum:
      return ethereum!.getTransactionPriorities();
    case WalletType.bitcoinCash:
      return bitcoinCash!.getTransactionPriorities();
    case WalletType.dogecoin:
      return dogecoin!.getTransactionPriorities();
    case WalletType.polygon:
      return polygon!.getTransactionPriorities();
    case WalletType.base:
      return base!.getTransactionPriorities();
    case WalletType.arbitrum:
    case WalletType.nano:
    case WalletType.banano:
    case WalletType.solana:
    case WalletType.tron:
      return [];
    case WalletType.zano:
      return zano!.getTransactionPriorities();
    case WalletType.decred:
      return decred!.getTransactionPriorities();
    case WalletType.zcash:
      return zcash!.getTransactionPriorities();
    case WalletType.none:
    case WalletType.haven:
      return [];
  }
}
