import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:intl/intl.dart';
import 'package:cw_core/get_height_by_date_xmr.dart';
import 'dart:convert';

// FIXME: Hardcoded values; Works only for monero

int getMoneroHeigthByDate({required DateTime date}) =>
    MoneroHeight.getBlockHeightByTime(date..subtract(Duration(days: 1)));

const havenDates = {
  "2023-05": 1352995,
  "2023-04": 1331460,
  "2023-03": 1309180,
  "2023-01": 1266810,
  "2022-12": 1244510,
  "2022-11": 1222970,
  "2022-10": 1200700,
  "2022-09": 1179140,
  "2022-08": 1156870,
  "2022-07": 1134600,
  "2022-06": 1113030,
  "2022-05": 1090800,
  "2022-04": 1069250,
  "2022-03": 1047000,
  "2022-02": 1026960,
  "2022-01": 1004700,
  "2021-12": 982400,
  "2021-11": 961000,
  "2021-10": 938600,
  "2021-09": 917000,
  "2021-08": 894800,
  "2021-07": 886000,
  "2021-06": 867300,
  "2021-05": 845000,
  "2021-04": 823500,
  "2021-03": 801500,
  "2021-02": 781000,
  "2021-01": 759000,
  "2020-12": 736500,
  "2020-11": 715000,
  "2020-10": 693000,
  "2020-09": 671000,
  "2020-08": 649000,
  "2020-07": 626600,
  "2020-06": 605000,
  "2020-05": 582700,
  "2020-04": 561100,
  "2020-03": 539000,
  "2020-02": 518000,
  "2020-01": 496000,
  "2019-12": 473400,
  "2019-11": 451900,
  "2019-10": 429600,
  "2019-09": 408000,
  "2019-08": 385700,
  "2019-07": 363800,
  "2019-06": 342200,
  "2019-05": 320000,
  "2019-04": 298400,
  "2019-03": 276000,
  "2019-02": 256000,
  "2019-01": 233700,
  "2018-12": 211400,
  "2018-11": 189800,
  "2018-10": 167500,
  "2018-09": 145900,
  "2018-08": 123700,
  "2018-07": 101400,
  "2018-06": 80000,
  "2018-05": 57550,
  "2018-04": 32000,
  "2018-03": 8500
};
final dateFormat = DateFormat('yyyy-MM');

DateTime formatMapKey(String key) => dateFormat.parse(key);

int getHavenHeightByDate({required DateTime date}) {
  String closestKey =
      havenDates.keys.firstWhere((key) => formatMapKey(key).isBefore(date), orElse: () => '');

  return havenDates[closestKey] ?? 0;
}

Future<int> getHavenCurrentHeight() async {
  final req = await ProxyWrapper()
      .getHttpClient()
      .getUrl(Uri.parse('https://explorer.havenprotocol.org/api/networkinfo'))
      .timeout(Duration(seconds: 15));
  final response = await req.close();
  final stringResponse = await response.transform(utf8.decoder).join();

  if (response.statusCode == 200) {
    final info = jsonDecode(stringResponse);
    return info['data']['height'] as int;
  } else {
    throw Exception('Failed to load current blockchain height');
  }
}

// Data taken from https://timechaincalendar.com/
const bitcoinDates = {
  "2024-08": 854889,
  "2024-07": 850182,
  "2024-06": 846005,
  "2024-05": 841590,
  "2024-04": 837182,
  "2024-03": 832623,
  "2024-02": 828319,
  "2024-01": 823807,
  "2023-12": 819206,
  "2023-11": 814765,
  "2023-10": 810098,
  "2023-09": 805675,
  "2023-08": 801140,
  "2023-07": 796640,
  "2023-06": 792330,
  "2023-05": 787733,
  "2023-04": 783403,
  "2023-03": 778740,
  "2023-02": 774525,
  "2023-01": 769810,
};

Future<int> getBitcoinHeightByDateAPI({required DateTime date}) async {
  final req = await ProxyWrapper()
      .getHttpClient()
      .getUrl(Uri.parse(
          "https://mempool.cakewallet.com/api/v1/mining/blocks/timestamp/${(date.millisecondsSinceEpoch / 1000).round()}"))
      .timeout(Duration(seconds: 15));
  final response = await req.close();
  final stringResponse = await response.transform(utf8.decoder).join();

  return jsonDecode(stringResponse)['height'] as int;
}

int getBitcoinHeightByDate({required DateTime date}) {
  String dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
  final closestKey = bitcoinDates.keys
      .firstWhere((key) => formatMapKey(key).isBefore(date), orElse: () => bitcoinDates.keys.last);
  final beginningBlock = bitcoinDates[dateKey] ?? bitcoinDates[closestKey]!;

  final startOfMonth = DateTime(date.year, date.month);
  final daysDifference = date.difference(startOfMonth).inDays;

  // approximately 6 blocks per hour, 24 hours per day
  int estimatedBlocksSinceStartOfMonth = (daysDifference * 24 * 6);

  return beginningBlock + estimatedBlocksSinceStartOfMonth;
}

DateTime getDateByBitcoinHeight(int height) {
  final closestEntry = bitcoinDates.entries
      .lastWhere((entry) => entry.value >= height, orElse: () => bitcoinDates.entries.first);
  final beginningBlock = closestEntry.value;

  final startOfMonth = formatMapKey(closestEntry.key);
  final blocksDifference = height - beginningBlock;
  final hoursDifference = blocksDifference / 5.5;

  final estimatedDate = startOfMonth.add(Duration(hours: hoursDifference.ceil()));

  if (estimatedDate.isAfter(DateTime.now())) {
    return DateTime.now();
  }

  return estimatedDate;
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
  "2018-04": 1
};

int getWowneroHeightByDate({required DateTime date}) {
  String closestKey =
      wowDates.keys.firstWhere((key) => formatMapKey(key).isBefore(date), orElse: () => '');

  return wowDates[closestKey] ?? 0;
}
