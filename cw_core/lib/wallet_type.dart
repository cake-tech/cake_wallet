import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'wallet_type.g.dart';

const walletTypes = [
  WalletType.monero,
  WalletType.bitcoin,
  WalletType.litecoin,
  WalletType.haven,
  WalletType.ethereum,
  WalletType.bitcoinCash,
  WalletType.nano,
  WalletType.banano,
  WalletType.polygon,
  WalletType.solana,
  WalletType.tron,
  WalletType.zano,
  WalletType.decred,
  WalletType.dogecoin,
  WalletType.base,
  WalletType.arbitrum,
  WalletType.evm,
];

@HiveType(typeId: WALLET_TYPE_TYPE_ID)
enum WalletType {
  @HiveField(0)
  monero,

  @HiveField(1)
  none,

  @HiveField(2)
  bitcoin,

  @HiveField(3)
  litecoin,

  @HiveField(4)
  haven,

  @HiveField(5)
  ethereum,

  @HiveField(6)
  nano,

  @HiveField(7)
  banano,

  @HiveField(8)
  bitcoinCash,

  @HiveField(9)
  polygon,

  @HiveField(10)
  solana,

  @HiveField(11)
  tron,

  @HiveField(12)
  wownero,

  @HiveField(13)
  zano,

  @HiveField(14)
  decred,

  @HiveField(15)
  dogecoin,

  @HiveField(16)
  base,

  @HiveField(17)
  arbitrum,

  @HiveField(18)
  evm,
}

int serializeToInt(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return 0;
    case WalletType.bitcoin:
      return 1;
    case WalletType.litecoin:
      return 2;
    case WalletType.haven:
      return 3;
    case WalletType.ethereum:
      return 4;
    case WalletType.nano:
      return 5;
    case WalletType.banano:
      return 6;
    case WalletType.bitcoinCash:
      return 7;
    case WalletType.polygon:
      return 8;
    case WalletType.solana:
      return 9;
    case WalletType.tron:
      return 10;
    case WalletType.wownero:
      return 11;
    case WalletType.zano:
      return 12;
    case WalletType.decred:
      return 13;
    case WalletType.dogecoin:
      return 14;
    case WalletType.base:
      return 15;
    case WalletType.arbitrum:
      return 16;
    case WalletType.evm:
      return 18;
    case WalletType.none:
      return -1;
  }
}

WalletType deserializeFromInt(int raw) {
  switch (raw) {
    case 0:
      return WalletType.monero;
    case 1:
      return WalletType.bitcoin;
    case 2:
      return WalletType.litecoin;
    case 3:
      return WalletType.haven;
    case 4:
      return WalletType.ethereum;
    case 5:
      return WalletType.nano;
    case 6:
      return WalletType.banano;
    case 7:
      return WalletType.bitcoinCash;
    case 8:
      return WalletType.polygon;
    case 9:
      return WalletType.solana;
    case 10:
      return WalletType.tron;
    case 11:
      return WalletType.wownero;
    case 12:
      return WalletType.zano;
    case 13:
      return WalletType.decred;
    case 14:
      return WalletType.dogecoin;
    case 15:
      return WalletType.base;
    case 16:
      return WalletType.arbitrum;
    case 18:
      return WalletType.evm;
    default:
      throw Exception('Unexpected token: $raw for WalletType deserializeFromInt');
  }
}

String walletTypeToString(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return 'Monero';
    case WalletType.bitcoin:
      return 'Bitcoin';
    case WalletType.litecoin:
      return 'Litecoin';
    case WalletType.haven:
      return 'Haven';
    case WalletType.ethereum:
      return 'Ethereum';
    case WalletType.bitcoinCash:
      return 'Bitcoin Cash';
    case WalletType.nano:
      return 'Nano';
    case WalletType.banano:
      return 'Banano';
    case WalletType.polygon:
      return 'Polygon';
    case WalletType.solana:
      return 'Solana';
    case WalletType.tron:
      return 'Tron';
    case WalletType.wownero:
      return 'Wownero';
    case WalletType.zano:
      return 'Zano';
    case WalletType.decred:
      return 'Decred';
    case WalletType.dogecoin:
      return 'Dogecoin';
    case WalletType.base:
      return 'Base';
    case WalletType.arbitrum:
      return 'Arbitrum';
    case WalletType.evm:
      return 'EVM';
    case WalletType.none:
      return '';
  }
}

String walletTypeToDisplayName(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return 'Monero (XMR)';
    case WalletType.bitcoin:
      return 'Bitcoin (BTC)';
    case WalletType.litecoin:
      return 'Litecoin (LTC)';
    case WalletType.haven:
      return 'Haven (XHV)';
    case WalletType.ethereum:
      return 'Ethereum (ETH)';
    case WalletType.bitcoinCash:
      return 'Bitcoin Cash (BCH)';
    case WalletType.nano:
      return 'Nano (XNO)';
    case WalletType.banano:
      return 'Banano (BAN)';
    case WalletType.polygon:
      return 'Polygon (POL)';
    case WalletType.solana:
      return 'Solana (SOL)';
    case WalletType.tron:
      return 'Tron (TRX)';
    case WalletType.wownero:
      return 'Wownero (WOW)';
    case WalletType.zano:
      return 'Zano (ZANO)';
    case WalletType.decred:
      return 'Decred (DCR)';
    case WalletType.dogecoin:
      return 'Dogecoin (DOGE)';
    case WalletType.base:
      return 'Base (BASE)';
    case WalletType.arbitrum:
      return 'Arbitrum (ARB)';
    case WalletType.evm:
      return 'EVM';
    case WalletType.none:
      return '';
  }
}

WalletType? cryptoCurrencyToWalletType(CryptoCurrency type) {
  switch (type) {
    case CryptoCurrency.xmr:
      return WalletType.monero;
    case CryptoCurrency.btc:
    case CryptoCurrency.btcln:
      return WalletType.bitcoin;
    case CryptoCurrency.ltc:
      return WalletType.litecoin;
    case CryptoCurrency.xhv:
      return WalletType.haven;
    case CryptoCurrency.eth:
    case CryptoCurrency.maticpoly:
    case CryptoCurrency.baseEth:
    case CryptoCurrency.arbEth:
      return WalletType.evm;
    case CryptoCurrency.bch:
      return WalletType.bitcoinCash;
    case CryptoCurrency.nano:
      return WalletType.nano;
    case CryptoCurrency.banano:
      return WalletType.banano;
    case CryptoCurrency.sol:
      return WalletType.solana;
    case CryptoCurrency.trx:
      return WalletType.tron;
    case CryptoCurrency.wow:
      return WalletType.wownero;
    case CryptoCurrency.zano:
      return WalletType.zano;
    case CryptoCurrency.dcr:
      return WalletType.decred;
    case CryptoCurrency.doge:
      return WalletType.dogecoin;
    default:
      return null;
  }
}
