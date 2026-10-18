import "package:cake_wallet/entities/block_explorer_settings.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/custom_block_explorers.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

void main() {
  late SharedPreferences prefs;
  late BlockExplorerSettings settings;

  const bitcoin = BlockExplorerScope(WalletType.bitcoin);
  const monero = BlockExplorerScope(WalletType.monero);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settings = BlockExplorerSettings(prefs);
  });

  test("uses the default until an added explorer is selected", () async {
    final explorer = await settings.add(monero, name: "Mine", url: "http://xmr.onion/");

    expect(settings.explorers(monero).single.url, "http://xmr.onion/");
    expect(settings.selected(monero), isNull);
    expect(settings.customTxUrl(WalletType.monero, "ab12"), isNull);

    await settings.select(monero, explorer.id);
    expect(settings.customTxUrl(WalletType.monero, "ab12"), "http://xmr.onion/tx/ab12");
    expect(settings.customTxUrl(WalletType.monero, "ab12", isTestnet: true), isNull);

    await settings.select(monero, null);
    expect(settings.customTxUrl(WalletType.monero, "ab12"), isNull);
  });

  test("the selected Bitcoin explorer is mirrored for cw_bitcoin's data requests", () async {
    final explorer = await settings.add(bitcoin, name: "", url: "https://mempool.example.com/api/");
    expect(prefs.getString(CustomBlockExplorers.mempoolApiPrefsKey), isNull);

    await settings.select(bitcoin, explorer.id);
    expect(prefs.getString(CustomBlockExplorers.mempoolApiPrefsKey), "https://mempool.example.com");
    expect(settings.customTxUrl(WalletType.bitcoin, "ab12"), "https://mempool.example.com/tx/ab12");

    await settings.update(
        bitcoin, SavedBlockExplorer(id: explorer.id, name: "Home", url: "http://mempool.onion"));
    expect(prefs.getString(CustomBlockExplorers.mempoolApiPrefsKey), "http://mempool.onion");

    await settings.remove(bitcoin, explorer.id);
    expect(settings.selected(bitcoin), isNull);
    expect(prefs.getString(CustomBlockExplorers.mempoolApiPrefsKey), isNull);
    expect(prefs.getString(BlockExplorerSettings.prefsKey), isNull);
  });

  test("validates Bitcoin explorers as mempool addresses", () {
    expect(BlockExplorerSettings.isValidExplorer(bitcoin, "https://mempool.example.com"), isTrue);
    expect(BlockExplorerSettings.isValidExplorer(bitcoin, "https://m.example/tx/{txid}"), isFalse);
    expect(BlockExplorerSettings.isValidExplorer(monero, "https://m.example/tx/{txid}"), isTrue);
    expect(BlockExplorerSettings.isValidExplorer(monero, ""), isFalse);
  });

  test("the setting shows for supported mainnet wallets only", () {
    _MockWallet wallet(WalletType type, {bool testnet = false}) {
      final w = _MockWallet();
      when(() => w.type).thenReturn(type);
      when(() => w.isTestnet).thenReturn(testnet);
      return w;
    }

    expect(BlockExplorerSettings.isAvailableFor(wallet(WalletType.bitcoin)), isTrue);
    expect(
        BlockExplorerSettings.isAvailableFor(wallet(WalletType.bitcoin, testnet: true)), isFalse);
    expect(BlockExplorerSettings.isAvailableFor(wallet(WalletType.ethereum)), isFalse);
  });
}
