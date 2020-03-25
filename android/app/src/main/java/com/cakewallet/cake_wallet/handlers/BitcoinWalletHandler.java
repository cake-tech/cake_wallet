package com.cakewallet.cake_wallet.handlers;

import org.bitcoinj.core.Address;
import org.bitcoinj.core.BlockChain;
import org.bitcoinj.core.Coin;
import org.bitcoinj.core.ECKey;
import org.bitcoinj.core.NetworkParameters;
import org.bitcoinj.core.PeerGroup;
import org.bitcoinj.core.Transaction;
import org.bitcoinj.core.TransactionConfidence;
import org.bitcoinj.net.BlockingClientManager;
import org.bitcoinj.params.MainNetParams;
import org.bitcoinj.script.Script;
import org.bitcoinj.store.BlockStore;
import org.bitcoinj.store.MemoryBlockStore;
import org.bitcoinj.wallet.DeterministicSeed;
import org.bitcoinj.wallet.Wallet;

import java.io.File;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class BitcoinWalletHandler {
    public static final String BITCOIN_WALLET_CHANNEL = "com.cakewallet.cake_wallet/bitcoin-wallet";
    private PeerGroup peerGroup;
    private Wallet currentWallet;
    private String path;
    private String password;

    public boolean createWallet(String path, String password) throws Exception {
        this.path = path;
        this.password = password;

        NetworkParameters params = MainNetParams.get();
        ECKey key = new ECKey();
        File file = new File(path);

        currentWallet = Wallet.createDeterministic(params, Script.ScriptType.P2PKH);
        currentWallet.importKey(key);
        currentWallet.encrypt(password);
        currentWallet.saveToFile(file);
        currentWallet.decrypt(password);
        return true;
    }

    public boolean openWallet(String path, String password) throws Exception {
        this.path = path;
        this.password = password;

        File file = new File(path);

        currentWallet = Wallet.loadFromFile(file);
        currentWallet.decrypt(password);
        return true;
    }

    public boolean restoreWalletFromSeed(String path, String password, String seed, String passphrase) throws Exception {
        this.path = path;
        this.password = password;

        NetworkParameters params = MainNetParams.get();
        File file = new File(path);
        long creationTime = 1409478661L;
        ECKey key = new ECKey();

        DeterministicSeed deterministicSeed = new DeterministicSeed(seed, null, passphrase, creationTime);
        currentWallet = Wallet.fromSeed(params, deterministicSeed, Script.ScriptType.P2PKH);
        currentWallet.importKey(key);
        currentWallet.encrypt(password);
        currentWallet.saveToFile(file);
        currentWallet.decrypt(password);
        return true;
    }

    public boolean restoreWalletFromKey(String path, String password, String privateKey) throws Exception {
        this.path = path;
        this.password = password;

        NetworkParameters params = MainNetParams.get();
        File file = new File(path);
        BigInteger privKey = new BigInteger(privateKey);
        ECKey key = ECKey.fromPrivate(privKey);

        currentWallet = Wallet.createDeterministic(params, Script.ScriptType.P2PKH);
        currentWallet.importKey(key);
        currentWallet.encrypt(password);
        currentWallet.saveToFile(file);
        currentWallet.decrypt(password);
        return true;
    }

    public void handle(MethodCall call, MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "getAddress":
                    getAddress(call, result);
                    break;
                case "getBalance":
                    getBalance(call, result);
                    break;
                case "getSeed":
                    getSeed(call, result);
                    break;
                case "getPrivateKey":
                    getPrivateKey(call, result);
                    break;
                case "connectToNode":
                    connectToNode(call, result);
                    break;
                case "getTransactions":
                    getTransactions(call, result);
                    break;
                case "countOfTransactions":
                    countOfTransactions(call, result);
                    break;
                case "refresh":
                    refresh(call, result);
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception e){
            result.error("UNCAUGHT_ERROR", e.getMessage(), null);
        }
    }

    private void getAddress(MethodCall call, MethodChannel.Result result) {
        Address currentAddress = currentWallet.currentReceiveAddress();
        result.success(currentAddress.toString());
    }

    private void getBalance(MethodCall call, MethodChannel.Result result) {
        Coin availableBalance = currentWallet.getBalance();
        result.success(availableBalance.value);
    }

    private void getSeed(MethodCall call, MethodChannel.Result result) {
        DeterministicSeed seed = currentWallet.getKeyChainSeed();
        result.success(seed.getMnemonicCode());
    }

    private void getPrivateKey(MethodCall call, MethodChannel.Result result) {
        List<ECKey> keys = currentWallet.getImportedKeys();
        if (keys != null && keys.size() > 0) {
            result.success(keys.get(0).getPrivKey().toString());
        } else {
            result.error("getPrivateKey", "Error in the getPrivateKey", null);
        }
    }

    private void connectToNode(MethodCall call, MethodChannel.Result result) throws Exception {
        System.setProperty("socksProxyHost", "94.75.124.54"); // from bitnodes.io
        System.setProperty("socksProxyPort", "8333");

        NetworkParameters params = MainNetParams.get();
        BlockStore blockStore = new MemoryBlockStore(params);
        BlockChain chain = new BlockChain(params, blockStore);
        peerGroup = new PeerGroup(params, chain, new BlockingClientManager());
        peerGroup.addWallet(currentWallet);
        peerGroup.start();
        peerGroup.downloadBlockChain();
        peerGroup.stop();
    }

    public void getTransactions(MethodCall call, MethodChannel.Result result) {
        List<Transaction> transactionList = currentWallet.getTransactionsByTime();
        ArrayList<HashMap<String, String>> transactionInfo = new ArrayList<>();

        for (Transaction elem : transactionList) {
            HashMap<String, String> hashMap = new HashMap<>();
            hashMap.put("hash", elem.getTxId().toString());

            int height = elem.getConfidence().getConfidenceType() == TransactionConfidence.ConfidenceType.BUILDING
                    ? elem.getConfidence().getAppearedAtChainHeight() : 0;
            hashMap.put("height", String.valueOf(height));

            Coin difference = elem.getValue(currentWallet);
            int direction;
            int amount;

            if (difference.isPositive()) {
                direction = 0;
                amount = (int)difference.value;
            } else {
                direction = 1;
                amount = (int)(-difference.value);
            }

            hashMap.put("direction", String.valueOf(direction));

            Date timestamp = elem.getUpdateTime();
            hashMap.put("timestamp", timestamp.toString());

            boolean isPending = elem.isPending();
            hashMap.put("isPending", String.valueOf(isPending));

            hashMap.put("amount", String.valueOf(amount));
            hashMap.put("accountIndex", "");

            transactionInfo.add(hashMap);
        }

        if (transactionInfo.size() > 0 ) {
            result.success(transactionInfo);
        } else {
            result.success(null);
        }
    }

    public void countOfTransactions(MethodCall call, MethodChannel.Result result) {
        List<Transaction> transactionList = currentWallet.getTransactionsByTime();
        result.success(transactionList.size());
    }

    public void refresh(MethodCall call, MethodChannel.Result result) {
        if (peerGroup != null) {
            peerGroup.start();
            peerGroup.downloadBlockChain();
            peerGroup.stop();
        }
    }
}
