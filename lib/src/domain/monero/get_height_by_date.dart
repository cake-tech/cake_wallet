import 'package:intl/intl.dart';

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
  "2019-8": 1888590,
  "2019-9": 1898590,
};

int getHeigthByDate({DateTime date}) {
  final raw = '${date.year}' + '-' + '${date.month}';
  var endHeight = dates[raw] ?? 0;
  int preLastYear = date.year;
  int preLastMonth = date.month - 1;

  if (endHeight <= 0) {
    endHeight = dates.values.toList()[dates.length - 1];
    final preLastDate = dateFormat.parse(dates.keys.elementAt(dates.keys.length - 2));
    preLastYear = preLastDate.year;
    preLastMonth = preLastDate.month;
  } else {
    preLastYear = date.year;
    preLastMonth = date.month - 1;
  }

  if (preLastMonth <= 0) {
    preLastMonth = 12;
    preLastYear -= 1;
  }

  var startRaw = '$preLastYear' + '-' + '$preLastMonth';
  var startHeight = dates[startRaw];
  var diff = endHeight - startHeight;
  var heightPerDay = diff / 30;
  var daysHeight = date.day * heightPerDay.round();
  var height = endHeight + daysHeight;

  return height;
}
