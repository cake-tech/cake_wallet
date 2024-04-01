double? _toDouble(num v) {
  return double.tryParse(v.toString());
}

BigInt _toBigInt(num v) {
  return BigInt.from(v);
}

N2Node _$N2NodeFromJson(Map<String, dynamic> json) => N2Node(
      weight: _toDouble(json['weight'] as num),
      uptime: json['uptime'] as String?,
      score: json['score'] as int?,
      account: json['rep_address'] as String?,
      alias: json['alias'] as String?,
    );

Map<String, dynamic> _$N2NodeToJson(N2Node instance) => <String, dynamic>{
      'uptime': instance.uptime,
      'weight': instance.weight,
      'score': instance.score,
      'rep_address': instance.account,
      'alias': instance.alias,
    };

class N2Node {
  N2Node({this.weight, this.uptime, this.score, this.account, this.alias});

  factory N2Node.fromJson(Map<String, dynamic> json) => _$N2NodeFromJson(json);
  String? uptime;
  double? weight;
  int? score;
  String? account;
  String? alias;

  Map<String, dynamic> toJson() => _$N2NodeToJson(this);
}
