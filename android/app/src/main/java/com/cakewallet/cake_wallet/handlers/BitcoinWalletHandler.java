package com.cakewallet.cake_wallet.handlers;

import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;

import org.bitcoinj.core.Address;
import org.bitcoinj.core.Block;
import org.bitcoinj.core.BlockChain;
import org.bitcoinj.core.Coin;
import org.bitcoinj.core.ECKey;
import org.bitcoinj.core.FilteredBlock;
import org.bitcoinj.core.NetworkParameters;
import org.bitcoinj.core.Peer;
import org.bitcoinj.core.PeerAddress;
import org.bitcoinj.core.PeerGroup;
import org.bitcoinj.core.Transaction;
import org.bitcoinj.core.TransactionConfidence;
import org.bitcoinj.core.listeners.BlocksDownloadedEventListener;
import org.bitcoinj.core.listeners.DownloadProgressTracker;
import org.bitcoinj.core.listeners.OnTransactionBroadcastListener;
import org.bitcoinj.core.listeners.PeerConnectedEventListener;
import org.bitcoinj.net.BlockingClient;
import org.bitcoinj.net.BlockingClientManager;
import org.bitcoinj.params.MainNetParams;
import org.bitcoinj.script.Script;
import org.bitcoinj.store.BlockStore;
import org.bitcoinj.store.MemoryBlockStore;
import org.bitcoinj.wallet.DeterministicSeed;
import org.bitcoinj.wallet.Wallet;
import org.bouncycastle.util.StreamParser;
import org.bouncycastle.util.StreamParsingException;

import java.io.File;
import java.io.IOException;
import java.math.BigInteger;
import java.net.InetAddress;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.AbstractExecutorService;

import javax.annotation.Nullable;
import javax.net.SocketFactory;

import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class BitcoinWalletHandler {
    public static final String BITCOIN_WALLET_CHANNEL = "com.cakewallet.cake_wallet/bitcoin-wallet";
    private PeerGroup peerGroup;
    private Wallet currentWallet;
    private String path;
    private String password;
    private BasicMessageChannel<String> progressChannel;
    private Handler mainHandler = new Handler(Looper.getMainLooper());

    public void setProgressChannel(BasicMessageChannel progressChannel) {
        this.progressChannel = progressChannel;
    }

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
                case "getFileName":
                    getFileName(call, result);
                    break;
                case "getName":
                    getName(call, result);
                    break;
                case "close":
                    close(call, result);
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception e){
            result.error("UNCAUGHT_ERROR", e.getMessage(), null);
        }
    }

    private void getAddress(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            Address currentAddress = currentWallet.currentReceiveAddress();
            mainHandler.post(() -> result.success(currentAddress.toString()));
        });
    }

    private void getBalance(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            Coin availableBalance = currentWallet.getBalance();
            mainHandler.post(() -> result.success(availableBalance.value));
        });
    }

    private void getSeed(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            DeterministicSeed seed = currentWallet.getKeyChainSeed();
            mainHandler.post(() -> result.success(seed.getMnemonicCode()));
        });
    }

    private void getPrivateKey(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            List<ECKey> keys = currentWallet.getImportedKeys();
            if (keys != null && keys.size() > 0) {
                mainHandler.post(() -> result.success(keys.get(0).getPrivKey().toString()));
            } else {
                mainHandler.post(() -> {
                    result.error("getPrivateKey", "Can't find private key", null);
                });
            }
        });
    }

    private void connectToNode(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            try {
                String host = "94.75.124.54";
                int port = 8333;

                NetworkParameters params = MainNetParams.get();
                BlockStore blockStore = new MemoryBlockStore(params); // FIXME: MemoryBlockStore applied only for test
                BlockChain chain = new BlockChain(params, blockStore);

                InetAddress inetAddress = InetAddress.getByName(host);
                PeerAddress peerAddress = new PeerAddress(params, inetAddress, port);

                PeerGroup peerGroup = new PeerGroup(params, chain);
                peerGroup.addAddress(peerAddress);

                chain.addWallet(currentWallet);
                peerGroup.addWallet(currentWallet);

                DownloadProgressTracker tracker = new DownloadProgressTracker() {
                    @Override
                    protected void progress(double pct, int blocksSoFar, Date date) {
                        super.progress(pct, blocksSoFar, date);
                        mainHandler.post(() -> progressChannel.send(String.valueOf(pct)));
                    }
                };

                peerGroup.startAsync();
                peerGroup.startBlockChainDownload(tracker);
                peerGroup.stopAsync();

                mainHandler.post(() -> result.success(null));
            } catch (Exception e) {
                mainHandler.post(() -> result.error("CONNECTION_ERROR", e.getMessage(), null));
            }
        });
    }

    public void getTransactions(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
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
                mainHandler.post(() -> result.success(transactionInfo));
            } else {
                mainHandler.post(() -> result.success(null));
            }
        });
    }

    public void countOfTransactions(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            List<Transaction> transactionList = currentWallet.getTransactionsByTime();
            mainHandler.post(() -> result.success(transactionList.size()));
        });
    }

    public void refresh(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            try {
                /*if (peerGroup != null) {
                    peerGroup.startAsync();
                    peerGroup.downloadBlockChain();
                    peerGroup.stopAsync();

                    File file = new File(path);
                    currentWallet.encrypt(password);
                    currentWallet.saveToFile(file);
                    currentWallet.decrypt(password);
                }*/
                mainHandler.post(() -> result.success(null));
            } catch (Exception e) {
                mainHandler.post(() -> result.error("IO_ERROR", e.getMessage(), null));
            }
        });
    }

    public void getFileName(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            File file = new File(path);
            mainHandler.post(() -> result.success(file.getPath()));
        });
    }

    public void getName(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            File file = new File(path);
            mainHandler.post(() -> result.success(file.getName()));
        });
    }

    public void close(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            try {
                File file = new File(path);
                currentWallet.encrypt(password);
                currentWallet.saveToFile(file);
                mainHandler.post(() -> result.success(null));
            } catch (Exception e) {
                mainHandler.post(() -> result.error("IO_ERROR", e.getMessage(), null));
            }
        });
    }
}
