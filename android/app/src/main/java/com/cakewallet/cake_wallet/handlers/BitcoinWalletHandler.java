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
import org.bitcoinj.crypto.DeterministicKey;
import org.bitcoinj.net.BlockingClient;
import org.bitcoinj.net.BlockingClientManager;
import org.bitcoinj.params.MainNetParams;
import org.bitcoinj.net.discovery.DnsDiscovery;
import org.bitcoinj.script.Script;
import org.bitcoinj.store.BlockStore;
import org.bitcoinj.store.MemoryBlockStore;
import org.bitcoinj.store.SPVBlockStore;
import org.bitcoinj.wallet.DeterministicSeed;
import org.bitcoinj.wallet.Wallet;
import org.bitcoinj.wallet.listeners.WalletCoinsReceivedEventListener;
import org.bouncycastle.util.StreamParser;
import org.bouncycastle.util.StreamParsingException;

import java.util.Map;
import java.util.concurrent.TimeUnit;

import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
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
    public static final int SYNCING_START = 1;
    public static final int SYNCING_IN_PROGRESS = 2;
    public static final int SYNCING_FINISHED = 0;
    public static final int NEED_TO_REFRESH = 0;

    private PeerGroup peerGroup;
    private BlockChain chain;
    private SPVBlockStore blockStore;
    private Wallet currentWallet;
    private String path;
    private String password;
    private BasicMessageChannel<ByteBuffer> progressChannel;
    private BasicMessageChannel<ByteBuffer> balanceChannel;
    private Handler mainHandler = new Handler(Looper.getMainLooper());

    public void setProgressChannel(BasicMessageChannel progressChannel) {
        this.progressChannel = progressChannel;
    }

    public void setBalanceChannel(BasicMessageChannel balanceChannel) {
        this.balanceChannel = balanceChannel;
    }

    public void setWalletListeners() {
        AsyncTask.execute(() -> {
            if (currentWallet != null) {
                currentWallet.addCoinsReceivedEventListener((wallet, tx, prevBalance, newBalance) -> {
                    ByteBuffer buffer = ByteBuffer.allocateDirect(4);
                    buffer.putInt(NEED_TO_REFRESH);

                    mainHandler.post(() -> balanceChannel.send(buffer));
                });

                currentWallet.addCoinsSentEventListener((wallet, tx, prevBalance, newBalance) -> {
                    ByteBuffer buffer = ByteBuffer.allocateDirect(4);
                    buffer.putInt(NEED_TO_REFRESH);

                    mainHandler.post(() -> balanceChannel.send(buffer));
                });
            }
        });
    }

    public void saveWalletToFile() throws Exception{
        File file = new File(path);

        currentWallet.encrypt(password);
        currentWallet.saveToFile(file);
        currentWallet.decrypt(password);
    }

    public void shutDownWallet() throws Exception {
        if (peerGroup != null && peerGroup.isRunning()) {
            peerGroup.stop();
        }

        if (currentWallet != null) {
            File file = new File(path);
            currentWallet.encrypt(password);
            currentWallet.saveToFile(file);
        }

        if (blockStore != null) {
            blockStore.close();
        }

        peerGroup = null;
        chain = null;
        blockStore = null;
        currentWallet = null;
    }

    public void installShutDownHook() {
        Runtime.getRuntime().addShutdownHook(new Thread() {
            @Override
            public void run() {
                try {
                    shutDownWallet();
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            }
        });
    }

    public boolean createWallet(String path, String password) throws Exception {
        this.path = path;
        this.password = password;

        NetworkParameters params = MainNetParams.get();

        currentWallet = Wallet.createDeterministic(params, Script.ScriptType.P2PKH);

        setWalletListeners();

        saveWalletToFile();
        return true;
    }

    public boolean openWallet(String path, String password) throws Exception {
        this.path = path;
        this.password = password;

        File file = new File(path);

        currentWallet = Wallet.loadFromFile(file);
        currentWallet.decrypt(password);

        setWalletListeners();
        return true;
    }

    public boolean restoreWalletFromSeed(String path, String password, String seed, String passphrase)
            throws Exception {
        this.path = path;
        this.password = password;

        NetworkParameters params = MainNetParams.get();
        long creationTime = 1409478661L;

        DeterministicSeed deterministicSeed = new DeterministicSeed(seed, null, passphrase, creationTime);
        currentWallet = Wallet.fromSeed(params, deterministicSeed, Script.ScriptType.P2PKH);

        setWalletListeners();

        saveWalletToFile();
        return true;
    }

    public boolean restoreWalletFromKey(String path, String password, String privateKey) throws Exception {
        this.path = path;
        this.password = password;

        NetworkParameters params = MainNetParams.get();

        DeterministicKey restoreKey = DeterministicKey.deserializeB58(privateKey, params);
        currentWallet = Wallet.fromWatchingKey(params, restoreKey, Script.ScriptType.P2PKH);

        setWalletListeners();

        saveWalletToFile();
        return true;
    }

    public void handle(MethodCall call, MethodChannel.Result result) {
        try {
            switch (call.method) {
            case "getAddress":
                getAddress(call, result);
                break;
            case "getUnlockedBalance":
                getUnlockedBalance(call, result);
                break;
            case "getFullBalance":
                getFullBalance(call, result);
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
            case "getNodeHeight":
                getNodeHeight(call, result);
                break;
            default:
                result.notImplemented();
            }
        } catch (Exception e) {
            result.error("UNCAUGHT_ERROR", e.getMessage(), null);
        }
    }

    private void getAddress(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            Address currentAddress = currentWallet.currentReceiveAddress();
            mainHandler.post(() -> result.success(currentAddress.toString()));
        });
    }

    private void getUnlockedBalance(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            Coin availableBalance = currentWallet.getBalance();
            mainHandler.post(() -> result.success(availableBalance.getValue()));
        });
    }

    private void getFullBalance(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            Coin fullBalance = currentWallet.getBalance(Wallet.BalanceType.ESTIMATED);
            mainHandler.post(() -> result.success(fullBalance.getValue()));
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
            NetworkParameters params = MainNetParams.get();

            DeterministicKey restoreKey = currentWallet.getWatchingKey();
            mainHandler.post(() -> result.success(restoreKey.serializePrivB58(params)));
        });
    }

    private void getNodeHeight(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            try {
                mainHandler.post(() -> result.success(chain.getBestChainHeight()));
            } catch (Exception e) {
                mainHandler.post(() -> result.error("GET_NODE_HEIGHT", e.getMessage(), null));
            }
        });
    }

    private void connectToNode(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            try {
                String host = "94.75.124.54"; // FIXME get host from call
                int port = 8333;

                NetworkParameters params = MainNetParams.get();

                File chainFile = new File(path + ".spvchain");
                blockStore = new SPVBlockStore(params, chainFile);
                chain = new BlockChain(params, blockStore);

                //InetAddress inetAddress = InetAddress.getByName(host);
                //PeerAddress peerAddress = new PeerAddress(params, inetAddress, port);

                peerGroup = new PeerGroup(params, chain);

                if (!host.equals("localhost")) {
                    peerGroup.addPeerDiscovery(new DnsDiscovery(params));
                } else {
                    PeerAddress addr = new PeerAddress(params, InetAddress.getLocalHost());
                    peerGroup.addAddress(addr);
                }

                chain.addWallet(currentWallet);
                peerGroup.addWallet(currentWallet);

                DownloadProgressTracker tracker = new DownloadProgressTracker() {
                    @Override
                    protected void startDownload(int blocks) {
                        ByteBuffer buffer = ByteBuffer.allocateDirect(4);
                        buffer.putInt(SYNCING_START);

                        mainHandler.post(() -> progressChannel.send(buffer));
                    }

                    @Override
                    protected void progress(double pct, int blocksSoFar, Date date) {
                        ByteBuffer buffer = ByteBuffer.allocateDirect(12);
                        buffer.putInt(SYNCING_IN_PROGRESS);
                        buffer.putInt((int) pct);
                        buffer.putInt(blocksSoFar);
                        
                        mainHandler.post(() -> progressChannel.send(buffer));
                    }

                    @Override
                    protected void doneDownload() {
                        ByteBuffer buffer = ByteBuffer.allocateDirect(4);
                        buffer.putInt(SYNCING_FINISHED);

                        mainHandler.post(() -> progressChannel.send(buffer));
                    }
                };

                peerGroup.start();
                installShutDownHook();
                peerGroup.startBlockChainDownload(tracker);

                mainHandler.post(() -> result.success(null));
            } catch (Exception e) {
                mainHandler.post(() -> result.error("CONNECTION_ERROR", e.getMessage(), null));
            }
        });
    }

    public void getTransactions(MethodCall call, MethodChannel.Result result) {
        AsyncTask.execute(() -> {
            List<Transaction> transactionList = currentWallet.getTransactionsByTime();
            ArrayList<Map<String, String>> transactionInfo = new ArrayList<>();

            for (Transaction elem : transactionList) {
                HashMap<String, String> hashMap = new HashMap<>();
                hashMap.put("hash", elem.getTxId().toString());

                int height = elem.getConfidence().getConfidenceType() == TransactionConfidence.ConfidenceType.BUILDING
                        ? elem.getConfidence().getAppearedAtChainHeight()
                        : 0;
                hashMap.put("height", String.valueOf(height));

                Coin difference = elem.getValue(currentWallet);
                int direction;
                int amount;

                if (difference.isPositive()) {
                    direction = 0;
                    amount = (int) difference.value;
                } else {
                    direction = 1;
                    amount = (int) (-difference.value);
                }

                hashMap.put("direction", String.valueOf(direction));

                long timestamp = elem.getUpdateTime().getTime();
                hashMap.put("timestamp", String.valueOf(timestamp));

                boolean isPending = elem.isPending();
                hashMap.put("isPending", String.valueOf(isPending));

                hashMap.put("amount", String.valueOf(amount));
                hashMap.put("accountIndex", ""); // FIXME

                transactionInfo.add(hashMap);
            }

            if (transactionInfo.size() > 0) {
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
                
                mainHandler.post(() -> result.success(null));
            } catch (Exception e) {
                mainHandler.post(() -> result.error("CONNECTION_ERROR", e.getMessage(), null));
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
                shutDownWallet();
                mainHandler.post(() -> result.success(null));
            } catch (Exception e) {
                mainHandler.post(() -> result.error("IO_ERROR", e.getMessage(), null));
            }
        });
    }
}
