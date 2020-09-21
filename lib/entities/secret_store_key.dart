enum SecretStoreKey { moneroWalletPassword, pinCodePassword }

const moneroWalletPassword = "MONERO_WALLET_PASSWORD";
const pinCodePassword = "PIN_CODE_PASSWORD";

String generateStoreKeyFor({SecretStoreKey key, String walletName = "",}) {
  var _key = "";

  switch (key) {
    case SecretStoreKey.moneroWalletPassword:
      {
        _key = moneroWalletPassword + "_" + walletName.toUpperCase();
      }
      break;

    case SecretStoreKey.pinCodePassword:
      {
        _key = pinCodePassword;
      }
      break;

    default:
      {}
  }

  return _key;
}