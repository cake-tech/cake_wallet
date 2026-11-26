import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

import "wc_service_rig.dart";

const _evmAddress = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";
const _evmKey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const _solanaAddress = "7ZmvpTUhQ4JmZVCkYkUDa8qg3hkTJ6dQ5mY2yq4CMK2z";
const _solanaKey = "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const _tronAddress = "TJRabPrwbZy45sbavfcjinPJC18kjpRTv8";
const _tronKey = "5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";

class _CountingEvm extends Fake implements EVM {
  int privateKeyReads = 0;

  @override
  ChainInfo? getCurrentChain(WalletBase wallet) =>
      const ChainInfo(chainId: 1, name: "Ethereum", shortCode: "eth", currency: CryptoCurrency.eth);

  @override
  String getCaip2ByChainId(int chainId) => "eip155:$chainId";

  @override
  String getPublicKey(WalletBase wallet) => _evmAddress;

  @override
  String getPrivateKey(WalletBase wallet) {
    privateKeyReads += 1;
    return _evmKey;
  }
}

class _CountingSolana extends Fake implements Solana {
  int privateKeyReads = 0;

  @override
  String getPublicKey(WalletBase wallet) => _solanaAddress;

  @override
  String getPrivateKey(WalletBase wallet) {
    privateKeyReads += 1;
    return _solanaKey;
  }
}

class _AddressOnlyTron extends Fake implements Tron {
  @override
  String getAddress(WalletBase wallet) => _tronAddress;
}

class _CountingTronWallet extends Fake implements AnyWallet {
  int privateKeyReads = 0;

  @override
  WalletType get type => WalletType.tron;

  @override
  String? get privateKey {
    privateKeyReads += 1;
    return _tronKey;
  }
}

RigWallet _wallet(WalletType type) =>
    RigWallet("Wallet", address: "", privateKey: "", chains: const [], type: type);

void main() {
  final service = KeyServiceImpl();
  late _CountingEvm evmProxy;
  late _CountingSolana solanaProxy;
  late _CountingTronWallet tronWallet;

  setUp(() {
    evm = evmProxy = _CountingEvm();
    solana = solanaProxy = _CountingSolana();
    tron = _AddressOnlyTron();
    tronWallet = _CountingTronWallet();
  });

  test("an EVM wallet's address and chains are read without its private key", () {
    final wallet = _wallet(WalletType.ethereum);

    expect(service.getKeysForChain(wallet).single.publicKey, _evmAddress);
    expect(service.getKeys(wallet).single.chains, contains("eip155:137"));
    expect(evmProxy.privateKeyReads, 0);

    expect(service.getPrivateKey(wallet), _evmKey);
    expect(evmProxy.privateKeyReads, 1);
  });

  test("a Solana wallet's address and chains are read without its private key", () {
    final wallet = _wallet(WalletType.solana);

    expect(service.getKeysForChain(wallet).single.publicKey, _solanaAddress);
    expect(service.getKeys(wallet).single.chains, hasLength(2));
    expect(solanaProxy.privateKeyReads, 0);

    expect(service.getPrivateKey(wallet), _solanaKey);
    expect(solanaProxy.privateKeyReads, 1);
  });

  test("a Tron wallet's address and chains are read without its private key", () {
    expect(service.getKeysForChain(tronWallet).single.publicKey, _tronAddress);
    expect(service.getKeys(tronWallet).single.chains, ["tron:0x2b6653dc"]);
    expect(tronWallet.privateKeyReads, 0);

    expect(service.getPrivateKey(tronWallet), _tronKey);
    expect(tronWallet.privateKeyReads, 1);
  });

  test("what a key model prints holds the address and no key", () {
    final printed = service.getKeysForChain(_wallet(WalletType.ethereum)).single.toString();

    expect(printed, contains(_evmAddress));
    expect(printed, isNot(contains(_evmKey)));
  });
}
