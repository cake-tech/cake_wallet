import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";

/// Stands in for the real store, which pulls in mobx, hive and a dozen services.
///
/// Only two providers take one: ChangeNOW reads [appVersion] into its create-trade
/// payload, and Swaps.xyz reads fee settings, but only from `createTransaction`, which is
/// not part of the four functions under test.
class FakeSettingsStore implements SettingsStore {
  @override
  String appVersion = "1.2.3";

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    "${invocation.memberName} is not faked on FakeSettingsStore",
  );
}

/// Stands in for the solana plugin, which Jupiter asks for spl token mints.
class FakeSolana implements Solana {
  FakeSolana();

  /// Currency title + tag to mint address.
  final Map<String, String> mints = {
  "${CryptoCurrency.usdcsol.title}.${CryptoCurrency.usdcsol.tag}":
  "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
};

  @override
  String getTokenAddress(CryptoCurrency asset) {
    final mint = mints["${asset.title}.${asset.tag}"];

    if (mint == null) {
      throw ArgumentError("FakeSolana has no mint for ${asset.title} (${asset.tag})");
    }

    return mint;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    "${invocation.memberName} is not faked on FakeSolana",
  );
}
