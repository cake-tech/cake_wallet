import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:convert/convert.dart';

class SecretKey {
  const SecretKey(this.name, this.generate);

  static final base = [
    SecretKey('salt', () => hex.encode(encrypt.Key.fromSecureRandom(16).bytes)),
    SecretKey('keychainSalt', () => hex.encode(encrypt.Key.fromSecureRandom(12).bytes)),
    SecretKey('key', () => hex.encode(encrypt.Key.fromSecureRandom(16).bytes)),
    SecretKey('walletSalt', () => hex.encode(encrypt.Key.fromSecureRandom(4).bytes)),
    SecretKey('shortKey', () => hex.encode(encrypt.Key.fromSecureRandom(12).bytes)),
    SecretKey('backupSalt', () => hex.encode(encrypt.Key.fromSecureRandom(8).bytes)),
    SecretKey('backupKeychainSalt', () => hex.encode(encrypt.Key.fromSecureRandom(12).bytes)),
    SecretKey('changeNowCakeWalletApiKey', () => ''),
    SecretKey('changeNowMoneroApiKey', () => ''),
    SecretKey('wyreSecretKey', () => ''),
    SecretKey('wyreApiKey', () => ''),
    SecretKey('wyreAccountId', () => ''),
    SecretKey('moonPayApiKey', () => ''),
    SecretKey('moonPaySecretKey', () => ''),
    SecretKey('sideShiftAffiliateId', () => ''),
    SecretKey('simpleSwapApiKey', () => ''),
    SecretKey('simpleSwapApiKeyDesktop', () => ''),
    SecretKey('anypayToken', () => ''),
    SecretKey('onramperApiKey', () => ''),
    SecretKey('ioniaClientId', () => ''),
    SecretKey('trocadorApiKey', () => ''),
    SecretKey('trocadorMoneroApiKey', () => ''),
    SecretKey('trocadorExchangeMarkup', () => ''),
    SecretKey('twitterBearerToken', () => ''),
    SecretKey('anonPayReferralCode', () => ''),
    SecretKey('fiatApiKey', () => ''),
    SecretKey('chatwootWebsiteToken', () => ''),
    SecretKey('exolixCakeWalletApiKey', () => ''),
    SecretKey('exolixMoneroApiKey', () => ''),
    SecretKey('robinhoodApplicationId', () => ''),
    SecretKey('exchangeHelperApiKey', () => ''),
    SecretKey('walletConnectProjectId', () => ''),
    SecretKey('moralisApiKey', () => ''),
    SecretKey('ankrApiKey', () => ''),
    SecretKey('chainStackApiKey', () => ''),
    SecretKey('swapTradeExchangeMarkup', () => ''),
    SecretKey('seeds', () => ''),
    SecretKey('testCakePayApiKey', () => ''),
    SecretKey('cakePayApiKey', () => ''),
    SecretKey('CSRFToken', () => ''),
    SecretKey('authorization', () => ''),
    SecretKey('meldTestApiKey', () => ''),
    SecretKey('meldTestPublicKey', () => ''),
    SecretKey('moneroTestWalletSeeds', () => ''),
    SecretKey('moneroLegacyTestWalletSeeds ', () => ''),
    SecretKey('bitcoinTestWalletSeeds', () => ''),
    SecretKey('ethereumTestWalletSeeds', () => ''),
    SecretKey('litecoinTestWalletSeeds', () => ''),
    SecretKey('bitcoinCashTestWalletSeeds', () => ''),
    SecretKey('polygonTestWalletSeeds', () => ''),
    SecretKey('baseTestWalletSeeds', () => ''),
    SecretKey('arbitrumTestWalletSeeds', () => ''),
    SecretKey('solanaTestWalletSeeds', () => ''),
    SecretKey('tronTestWalletSeeds', () => ''),
    SecretKey('nanoTestWalletSeeds', () => ''),
    SecretKey('wowneroTestWalletSeeds', () => ''),
    SecretKey('moneroTestWalletReceiveAddress', () => ''),
    SecretKey('bitcoinTestWalletReceiveAddress', () => ''),
    SecretKey('ethereumTestWalletReceiveAddress', () => ''),
    SecretKey('litecoinTestWalletReceiveAddress', () => ''),
    SecretKey('bitcoinCashTestWalletReceiveAddress', () => ''),
    SecretKey('polygonTestWalletReceiveAddress', () => ''),
    SecretKey('baseTestWalletReceiveAddress', () => ''),
    SecretKey('arbitrumTestWalletReceiveAddress', () => ''),
    SecretKey('solanaTestWalletReceiveAddress', () => ''),
    SecretKey('tronTestWalletReceiveAddress', () => ''),
    SecretKey('nanoTestWalletReceiveAddress', () => ''),
    SecretKey('wowneroTestWalletReceiveAddress', () => ''),
    SecretKey('etherScanApiKey', () => ''),
    SecretKey('polygonScanApiKey', () => ''),
    SecretKey('letsExchangeBearerToken', () => ''),
    SecretKey('letsExchangeAffiliateId', () => ''),
    SecretKey('stealthExBearerToken', () => ''),
    SecretKey('stealthExAdditionalFeePercent', () => ''),
    SecretKey('moneroTestWalletBlockHeight', () => ''),
    SecretKey('chainflipApiKey', () => ''),
    SecretKey('chainflipAffiliateFee', () => ''),
    SecretKey('kryptonimApiKey', () => ''),
    SecretKey('walletGroupSalt', () => hex.encode(encrypt.Key.fromSecureRandom(16).bytes)),
    SecretKey('swapsXyzApiKey', () => ''),
    SecretKey('nearIntentsBearerToken', () => ''),
    SecretKey('nearIntentsAppFee', () => ''),
    SecretKey('nearIntentsAppFeeRecipient', () => ''),
  ];

  static final evmChainsSecrets = [
    SecretKey('etherScanApiKey', () => ''),
    SecretKey('polygonScanApiKey', () => ''),
    SecretKey('moralisApiKey', () => ''),
    SecretKey('nowNodesApiKey ', () => ''),
    SecretKey('blinkApiKey', () => ''),
  ];

  static final solanaSecrets = [
    SecretKey('ankrApiKey', () => ''),
    SecretKey('nowNodesApiKey', () => ''),
    SecretKey('chainStackApiKey', () => ''),
    SecretKey('moralisApiKey', () => ''),
  ];

  static final nanoSecrets = [
    SecretKey('nano2ApiKey', () => ''),
    SecretKey('nanoNowNodesApiKey', () => ''),
  ];

  static final tronSecrets = [
    SecretKey('tronGridApiKey', () => ''),
    SecretKey('tronNowNodesApiKey', () => ''),
  ];

  final String name;
  final String Function() generate;
}
