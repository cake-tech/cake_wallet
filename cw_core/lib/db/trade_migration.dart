import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

Future<void> migrateTradeTableToNewSchema(Database db) async {
  await db.execute("ALTER TABLE Trade RENAME TO Trade_old;");
  await createTradeTable(db);
  final List<Map<String, Object?>> oldTrades = await db.query("Trade_old");

  for (final row in oldTrades) {
    try {
      final depositMoney = Money.safeParse(
        row["amount"] as String? ?? "0",
        _reconstructCurrency(row, "from"),
      );
      final payoutMoney = Money.safeParse(
        row["receiveAmount"] as String? ?? "0",
        _reconstructCurrency(row, "to"),
      );

      final newRow = {
        "tradeId": row["tradeId"],
        "id": row["id"],
        "provider": row["providerRaw"] ?? 0,
        "state": row["stateRaw"] ?? "",
        "depositAmount": depositMoney.serialized,
        "payoutAmount": payoutMoney.serialized,
        "fundingAddress": row["inputAddress"],
        "refundAddress": row["refundAddress"],
        "payoutAddress": row["payoutAddress"],
        "createdAt": row["createdAt"],
        "expiredAt": row["expiredAt"],
        "extraId": row["extraId"],
        "outputTransaction": row["outputTransaction"],
        "walletId": row["walletId"],
        "toAddressExtraId": row["toAddressExtraId"],
        "password": row["password"],
        "providerId": row["providerId"],
        "memo": row["memo"],
        "txId": row["txId"],
        "isRefund": row["isRefund"],
        "chainId": row["chainId"],
      };

      await db.insert("Trade", newRow, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {}
  }
}

CryptoCurrency _reconstructCurrency(Map<String, dynamic> row, String prefix) {
  final title = row["${prefix}Title"] as String;

  final tag = row["${prefix}Tag"] as String?;

  final live = CryptoCurrency.safeParseCurrencyFromString(title, tag: tag);
  if (live != null) return live;

  return CryptoCurrency(
    title: title,
    name: row["${prefix}Name"] as String? ?? "",
    tag: tag,
    fullName: row["${prefix}FullName"] as String?,
    decimals: row["${prefix}Decimals"] as int? ?? 1,
    raw: row["${prefix}Raw"] as int? ?? -1,
    iconPath: row["${prefix}IconPath"] as String?,
    flatIconPath: row["${prefix}FlatIconPath"] as String?,
    chainIconPath: row["${prefix}ChainIconPath"] as String?,
  );
}
