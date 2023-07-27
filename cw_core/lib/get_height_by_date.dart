import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// FIXME: Hardcoded values; Works only for monero

final dateFormat = DateFormat('yyyy-MM');
final dates = {
  "2014-5": 18844,
  "2014-6": 65406,
  "2014-7": 108882,
  "2014-8": 153594,
  "2014-9": 198072,
  "2014-10": 241088,
  "2014-11": 285305,
  "2014-12": 328069,
  "2015-1": 372369,
  "2015-2": 416505,
  "2015-3": 456631,
  "2015-4": 501084,
  "2015-5": 543973,
  "2015-6": 588326,
  "2015-7": 631187,
  "2015-8": 675484,
  "2015-9": 719725,
  "2015-10": 762463,
  "2015-11": 806528,
  "2015-12": 849041,
  "2016-1": 892866,
  "2016-2": 936736,
  "2016-3": 977691,
  "2016-4": 1015848,
  "2016-5": 1037417,
  "2016-6": 1059651,
  "2016-7": 1081269,
  "2016-8": 1103630,
  "2016-9": 1125983,
  "2016-10": 1147617,
  "2016-11": 1169779,
  "2016-12": 1191402,
  "2017-1": 1213861,
  "2017-2": 1236197,
  "2017-3": 1256358,
  "2017-4": 1278622,
  "2017-5": 1300239,
  "2017-6": 1322564,
  "2017-7": 1344225,
  "2017-8": 1366664,
  "2017-9": 1389113,
  "2017-10": 1410738,
  "2017-11": 1433039,
  "2017-12": 1454639,
  "2018-1": 1477201,
  "2018-2": 1499599,
  "2018-3": 1519796,
  "2018-4": 1542067,
  "2018-5": 1562861,
  "2018-6": 1585135,
  "2018-7": 1606715,
  "2018-8": 1629017,
  "2018-9": 1651347,
  "2018-10": 1673031,
  "2018-11": 1695128,
  "2018-12": 1716687,
  "2019-1": 1738923,
  "2019-2": 1761435,
  "2019-3": 1781681,
  "2019-4": 1803081,
  "2019-5": 1824671,
  "2019-6": 1847005,
  "2019-7": 1868590,
  "2019-8": 1890552,
  "2019-9": 1912212,
  "2019-10": 1932200,
  "2019-11": 1957040,
  "2019-12": 1978090,
  "2020-1": 2001290,
  "2020-2": 2022688,
  "2020-3": 2043987,
  "2020-4": 2066536,
  "2020-5": 2090797,
  "2020-6": 2111633,
  "2020-7": 2131433,
  "2020-8": 2153983,
  "2020-9": 2176466,
  "2020-10": 2198453,
  "2020-11": 2220000
};

int getMoneroHeigthByDate({required DateTime date}) {
  final raw = '${date.year}' + '-' + '${date.month}';
  final lastHeight = dates.values.last;
  int startHeight;
  int endHeight;
  int height = 0;

  try {
    if ((dates[raw] == null) || (dates[raw] == lastHeight)) {
      startHeight = dates.values.toList()[dates.length - 2];
      endHeight = dates.values.toList()[dates.length - 1];
      final heightPerDay = (endHeight - startHeight) / 31;
      final endDateRaw = dates.keys.toList()[dates.length - 1].split('-');
      final endYear = int.parse(endDateRaw[0]);
      final endMonth = int.parse(endDateRaw[1]);
      final endDate = DateTime(endYear, endMonth);
      final differenceInDays = date.difference(endDate).inDays;
      final daysHeight = (differenceInDays * heightPerDay).round();
      height = endHeight + daysHeight;
    } else {
      startHeight = dates[raw]!;
      final index = dates.values.toList().indexOf(startHeight);
      endHeight = dates.values.toList()[index + 1];
      final heightPerDay = ((endHeight - startHeight) / 31).round();
      final daysHeight = (date.day - 1) * heightPerDay;
      height = startHeight + daysHeight - heightPerDay;
    }
  } catch (e) {
    print(e.toString());
  }

  return height;
}

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

DateTime formatMapKey(String key) => dateFormat.parse(key);

int getHavenHeightByDate({required DateTime date}) {
  String closestKey =
      havenDates.keys.firstWhere((key) => formatMapKey(key).isBefore(date), orElse: () => '');

  return havenDates[closestKey] ?? 0;
}

Future<int> getHavenCurrentHeight() async {
  final response = await http.get(Uri.parse('https://explorer.havenprotocol.org/api/networkinfo'));

  if (response.statusCode == 200) {
    final info = jsonDecode(response.body);
    return info['data']['height'] as int;
  } else {
    throw Exception('Failed to load current blockchain height');
  }
}
