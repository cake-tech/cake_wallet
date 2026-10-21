import "dart:convert";

import "package:cw_core/get_height_by_date_btc.dart";
import "package:cw_core/get_height_by_date_xmr.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:intl/intl.dart";

int getMoneroHeigthByDate({required DateTime date}) =>
    MoneroHeight.getBlockHeightByTime(date.subtract(const Duration(days: 1)));

final dateFormat = DateFormat("yyyy-MM");

DateTime formatMapKey(String key) => dateFormat.parse(key);

Future<int> getBitcoinHeightByDateAPI({required DateTime date}) async {
  final req = await ProxyWrapper()
      .getHttpClient()
      .getUrl(
        Uri.parse(
          "https://mempool.cakewallet.com/api/v1/mining/blocks/timestamp/${(date.millisecondsSinceEpoch / 1000).round()}",
        ),
      )
      .timeout(const Duration(seconds: 15));
  final response = await req.close();
  final stringResponse = await response.transform(utf8.decoder).join();

  return jsonDecode(stringResponse)["height"] as int;
}

int getBitcoinHeightByDate({required DateTime date}) => BitcoinHeight.getBlockHeightByTime(date);

DateTime getDateByBitcoinHeight(int height) {
  final estimatedDate = BitcoinHeight.getTimeByBlockHeight(height);

  return estimatedDate.isAfter(DateTime.now()) ? DateTime.now() : estimatedDate;
}

int getLtcHeightByDate({required DateTime date}) {
  // TODO: use the proxy layer to get the height with a binary search of blocked header heights
  return 0;
}

// TODO: enhance all of this global const lists
const wowDates = {
  "2023-12": 583048,
  "2023-11": 575048,
  "2023-10": 566048,
  "2023-09": 558048,
  "2023-08": 549048,
  "2023-07": 540048,
  "2023-06": 532048,
  "2023-05": 523048,
  "2023-04": 514048,
  "2023-03": 505048,
  "2023-02": 497048,
  "2023-01": 488048,
  "2022-12": 479048,
  "2022-11": 471048,
  "2022-10": 462048,
  "2022-09": 453048,
  "2022-08": 444048,
  "2022-07": 435048,
  "2022-06": 427048,
  "2022-05": 418048,
  "2022-04": 410048,
  "2022-03": 401048,
  "2022-02": 393048,
  "2022-01": 384048,
  "2021-12": 375048,
  "2021-11": 367048,
  "2021-10": 358048,
  "2021-09": 349048,
  "2021-08": 340048,
  "2021-07": 331048,
  "2021-06": 322048,
  "2021-05": 313048,
  "2021-04": 305048,
  "2021-03": 295048,
  "2021-02": 287048,
  "2021-01": 279148,
  "2020-10": 252000,
  "2020-09": 243000,
  "2020-08": 234000,
  "2020-07": 225000,
  "2020-06": 217500,
  "2020-05": 208500,
  "2020-04": 199500,
  "2020-03": 190500,
  "2020-02": 183000,
  "2020-01": 174000,
  "2019-12": 165000,
  "2019-11": 156000,
  "2019-10": 147000,
  "2019-09": 138000,
  "2019-08": 129000,
  "2019-07": 120000,
  "2019-06": 112500,
  "2019-05": 103500,
  "2019-04": 94500,
  "2019-03": 85500,
  "2019-02": 79500,
  "2019-01": 73500,
  "2018-12": 67500,
  "2018-11": 61500,
  "2018-10": 52500,
  "2018-09": 45000,
  "2018-08": 36000,
  "2018-07": 27000,
  "2018-06": 18000,
  "2018-05": 9000,
  "2018-04": 1,
};

int getWowneroHeightByDate({required DateTime date}) {
  final String closestKey =
      wowDates.keys.firstWhere((key) => formatMapKey(key).isBefore(date), orElse: () => "");

  return wowDates[closestKey] ?? 0;
}
